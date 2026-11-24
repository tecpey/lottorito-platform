import { createHash, randomUUID } from "node:crypto";

function canonicalEntries(entries) {
  return entries
    .map((entry) => ({
      account_id: entry.account_id,
      currency_code: entry.currency_code,
      side: entry.side,
      amount: entry.amount
    }))
    .sort((a, b) =>
      [a.account_id, a.currency_code, a.side, a.amount].join("|")
        .localeCompare([b.account_id, b.currency_code, b.side, b.amount].join("|"))
    );
}

function fingerprintFor(input) {
  const canonical = {
    tenant_id: input.tenant_id,
    product_id: input.product_id,
    effect_type: input.effect_type,
    source_event_id: input.source_event_id,
    effect_key: input.effect_key,
    entries: canonicalEntries(input.entries)
  };
  return createHash("sha256").update(JSON.stringify(canonical)).digest("hex");
}

function validateInput(input) {
  for (const key of ["tenant_id", "product_id", "effect_type", "source_event_id", "effect_key", "idempotency_key"]) {
    if (typeof input[key] !== "string" || input[key].length === 0) {
      throw new TypeError(key + " is required");
    }
  }
  if (!Array.isArray(input.entries) || input.entries.length < 2) {
    throw new TypeError("at least two ledger entries are required");
  }
  for (const entry of input.entries) {
    if (typeof entry.account_id !== "string" ||
        typeof entry.currency_code !== "string" ||
        !["debit", "credit"].includes(entry.side) ||
        typeof entry.amount !== "string" ||
        !/^(?:0|[1-9][0-9]*)(?:\.[0-9]{1,18})?$/.test(entry.amount) ||
        !/[1-9]/.test(entry.amount)) {
      throw new TypeError("entries require UUID account_id, currency_code, debit/credit side and a positive exact decimal string");
    }
  }
}

export async function withLedgerTransaction(pool, tenantId, productId, callback) {
  const client = await pool.connect();
  let open = false;
  try {
    await client.query("BEGIN");
    open = true;
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenantId]);
    await client.query("SELECT set_config('app.product_id', $1, true)", [productId]);
    const result = await callback(client);
    await client.query("COMMIT");
    open = false;
    return result;
  } catch (error) {
    if (open) {
      try { await client.query("ROLLBACK"); } catch {}
    }
    throw error;
  } finally {
    client.release();
  }
}

export async function postLedgerEffect(pool, input) {
  validateInput(input);
  const fingerprint = fingerprintFor(input);
  const journalId = randomUUID();
  const client = await pool.connect();
  let open = false;

  try {
    await client.query("BEGIN");
    open = true;
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [input.tenant_id]);
    await client.query("SELECT set_config('app.product_id', $1, true)", [input.product_id]);

    const sourceEvent = await client.query(
      `SELECT source_event_id
         FROM public.source_events
        WHERE tenant_id = $1 AND product_id = $2
          AND source_event_id = $3 AND effect_key = $4`,
      [input.tenant_id, input.product_id, input.source_event_id, input.effect_key]
    );
    if (sourceEvent.rowCount !== 1) {
      throw Object.assign(new Error("source financial event was not found in this tenant/product scope"), {
        code: "P02_SOURCE_EVENT_NOT_FOUND"
      });
    }

    await client.query(
      `INSERT INTO public.journal_transactions
        (tenant_id, product_id, journal_id, source_event_id, effect_type,
         effect_key, idempotency_key, request_fingerprint, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'draft')`,
      [input.tenant_id, input.product_id, journalId, input.source_event_id,
       input.effect_type, input.effect_key, input.idempotency_key, fingerprint]
    );

    const effect = await client.query(
      `INSERT INTO public.economic_effects
        (tenant_id, product_id, effect_type, source_event_id, effect_key,
         idempotency_key, request_fingerprint, journal_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT DO NOTHING
       RETURNING journal_id`,
      [input.tenant_id, input.product_id, input.effect_type, input.source_event_id,
       input.effect_key, input.idempotency_key, fingerprint, journalId]
    );

    if (effect.rowCount === 0) {
      await client.query(
        "DELETE FROM public.journal_transactions WHERE tenant_id = $1 AND product_id = $2 AND journal_id = $3 AND status = 'draft'",
        [input.tenant_id, input.product_id, journalId]
      );
      const existing = await client.query(
        `SELECT journal_id, request_fingerprint
           FROM public.economic_effects
          WHERE tenant_id = $1
            AND product_id = $2
            AND ((effect_type = $3 AND source_event_id = $4 AND effect_key = $5)
                 OR idempotency_key = $6)
          ORDER BY journal_id
          LIMIT 2`,
        [input.tenant_id, input.product_id, input.effect_type, input.source_event_id,
         input.effect_key, input.idempotency_key]
      );
      if (existing.rowCount !== 1 || existing.rows[0].request_fingerprint !== fingerprint) {
        throw Object.assign(new Error("idempotency key or economic effect identity was reused with a different request"), {
          code: "P02_IDEMPOTENCY_CONFLICT"
        });
      }
      await client.query("COMMIT");
      open = false;
      return { status: "duplicate", journal_id: existing.rows[0].journal_id };
    }

    for (let index = 0; index < input.entries.length; index += 1) {
      const entry = input.entries[index];
      await client.query(
        `INSERT INTO public.ledger_entries
          (tenant_id, product_id, journal_id, line_no, account_id,
           currency_code, side, amount)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8::numeric)`,
        [input.tenant_id, input.product_id, journalId, index + 1,
         entry.account_id, entry.currency_code, entry.side, entry.amount]
      );
    }

    await client.query(
      `UPDATE public.journal_transactions
          SET status = 'posted'
        WHERE tenant_id = $1 AND product_id = $2 AND journal_id = $3`,
      [input.tenant_id, input.product_id, journalId]
    );

    await client.query(
      `INSERT INTO public.outbox_events
        (tenant_id, product_id, event_id, journal_id, event_type, payload)
       VALUES ($1, $2, $3, $4, 'ledger.journal.posted', $5::jsonb)`,
      [input.tenant_id, input.product_id, randomUUID(), journalId,
       JSON.stringify({
         journal_id: journalId,
         source_event_id: input.source_event_id,
         effect_type: input.effect_type,
         effect_key: input.effect_key
       })]
    );

    await client.query("COMMIT");
    open = false;
    return { status: "created", journal_id: journalId };
  } catch (error) {
    if (open) {
      try { await client.query("ROLLBACK"); } catch {}
    }
    throw error;
  } finally {
    client.release();
  }
}

export async function reverseJournal(pool, { tenant_id, product_id, journal_id, idempotency_key }) {
  const reversalId = randomUUID();
  const client = await pool.connect();
  let open = false;
  try {
    await client.query("BEGIN");
    open = true;
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id]);
    await client.query("SELECT set_config('app.product_id', $1, true)", [product_id]);

    const original = await client.query(
      `SELECT source_event_id, effect_type, effect_key, status
         FROM public.journal_transactions
        WHERE tenant_id = $1 AND product_id = $2 AND journal_id = $3
        FOR UPDATE`,
      [tenant_id, product_id, journal_id]
    );
    if (original.rowCount !== 1 || original.rows[0].status !== "posted") {
      throw Object.assign(new Error("only an existing posted journal can be reversed"), { code: "P02_NOT_REVERSIBLE" });
    }

    await client.query(
      `INSERT INTO public.journal_transactions
        (tenant_id, product_id, journal_id, source_event_id, effect_type,
         effect_key, idempotency_key, request_fingerprint, status, reversal_of_journal_id)
       VALUES ($1, $2, $3, $4, 'reversal', $5, $6, $7, 'draft', $8)`,
      [tenant_id, product_id, reversalId, original.rows[0].source_event_id,
       original.rows[0].effect_key, idempotency_key,
       createHash("sha256").update(journal_id + "|" + idempotency_key).digest("hex"),
       journal_id]
    );

    await client.query(
      `INSERT INTO public.ledger_entries
        (tenant_id, product_id, journal_id, line_no, account_id, currency_code, side, amount)
       SELECT tenant_id, product_id, $4, line_no, account_id, currency_code,
              CASE side WHEN 'debit' THEN 'credit' ELSE 'debit' END, amount
         FROM public.ledger_entries
        WHERE tenant_id = $1 AND product_id = $2 AND journal_id = $3
        ORDER BY line_no`,
      [tenant_id, product_id, journal_id, reversalId]
    );

    await client.query(
      "UPDATE public.journal_transactions SET status = 'posted' WHERE tenant_id = $1 AND product_id = $2 AND journal_id = $3",
      [tenant_id, product_id, reversalId]
    );
    await client.query(
      `INSERT INTO public.outbox_events
        (tenant_id, product_id, event_id, journal_id, event_type, payload)
       VALUES ($1, $2, $3, $4, 'ledger.journal.reversed', $5::jsonb)`,
      [tenant_id, product_id, randomUUID(), reversalId,
       JSON.stringify({ journal_id: reversalId, reverses_journal_id: journal_id })]
    );

    await client.query("COMMIT");
    open = false;
    return { status: "reversed", journal_id: reversalId, reverses_journal_id: journal_id };
  } catch (error) {
    if (open) {
      try { await client.query("ROLLBACK"); } catch {}
    }
    throw error;
  } finally {
    client.release();
  }
}

export async function listReconciliationExceptions(pool, tenantId, productId) {
  return withLedgerTransaction(pool, tenantId, productId, async (client) => {
    const result = await client.query(
      `SELECT source_event_id, effect_key, currency_code,
              expected_amount::text, posted_payable_amount::text
         FROM public.ledger_reconciliation
        ORDER BY source_event_id, effect_key`
    );
    return result.rows;
  });
}
