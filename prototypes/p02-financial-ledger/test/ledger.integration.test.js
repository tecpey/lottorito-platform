import assert from "node:assert/strict";
import { after, test } from "node:test";
import { randomUUID } from "node:crypto";
import { Pool } from "pg";
import {
  listReconciliationExceptions,
  postLedgerEffect,
  reverseJournal,
  withLedgerTransaction
} from "../src/ledger.js";
import {
  ACCOUNTS, PRODUCT_AFFILIATE, PRODUCT_OTHER, TENANT_A, TENANT_B
} from "./fixtures.js";

const adminPool = new Pool({ connectionString: process.env.ADMIN_DATABASE_URL, max: 4 });
const runtimePool = new Pool({ connectionString: process.env.RUNTIME_DATABASE_URL, max: 1 });
const runtimePool2 = new Pool({ connectionString: process.env.RUNTIME_DATABASE_URL, max: 1 });

after(async () => {
  await runtimePool.end();
  await runtimePool2.end();
  await adminPool.end();
});

function normalizeDecimal(value) {
  return String(value).replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
}

async function createSourceEvent({
  tenantId = TENANT_A,
  productId = PRODUCT_AFFILIATE,
  currency = "USD",
  amount = "125.37",
  effectKey = "agent-" + randomUUID()
} = {}) {
  const sourceEventId = "source-" + randomUUID();
  await adminPool.query(
    `INSERT INTO public.source_events
      (tenant_id, product_id, source_event_id, effect_key, currency_code, expected_amount)
     VALUES ($1, $2, $3, $4, $5, $6::numeric)`,
    [tenantId, productId, sourceEventId, effectKey, currency, amount]
  );
  return { tenantId, productId, sourceEventId, effectKey, currency, amount };
}

function buildInput(source, {
  amount = source.amount,
  idempotencyKey = "idem-" + randomUUID(),
  entries,
  effectType = "affiliate_commission_accrual"
} = {}) {
  const accounts = source.tenantId === TENANT_B
    ? ACCOUNTS.tenantB.affiliate
    : source.productId === PRODUCT_OTHER
      ? ACCOUNTS.tenantA.other
      : ACCOUNTS.tenantA.affiliate;
  const currencyAccounts = source.currency === "USDT"
    ? { expense: accounts.usdtExpense, payable: accounts.usdtPayable }
    : { expense: accounts.usdExpense, payable: accounts.usdPayable };

  return {
    tenant_id: source.tenantId,
    product_id: source.productId,
    source_event_id: source.sourceEventId,
    effect_type: effectType,
    effect_key: source.effectKey,
    idempotency_key: idempotencyKey,
    entries: entries ?? [
      { account_id: currencyAccounts.expense, currency_code: source.currency, side: "debit", amount },
      { account_id: currencyAccounts.payable, currency_code: source.currency, side: "credit", amount }
    ]
  };
}

async function readJournal(pool, tenantId, productId, journalId) {
  return withLedgerTransaction(pool, tenantId, productId, async (client) => {
    const header = await client.query(
      "SELECT journal_id, status, reversal_of_journal_id, posted_at FROM public.journal_transactions WHERE journal_id = $1",
      [journalId]
    );
    const entries = await client.query(
      "SELECT account_id, currency_code, side, amount::text FROM public.ledger_entries WHERE journal_id = $1 ORDER BY line_no",
      [journalId]
    );
    return { header: header.rows[0], entries: entries.rows };
  });
}

test("tenant and product contexts isolate accounts and source events", async () => {
  const affiliateA = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query("SELECT account_code, currency_code FROM public.ledger_accounts ORDER BY account_code, currency_code")
  );
  const otherA = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_OTHER, (client) =>
    client.query("SELECT account_code, currency_code FROM public.ledger_accounts ORDER BY account_code")
  );
  const affiliateB = await withLedgerTransaction(runtimePool, TENANT_B, PRODUCT_AFFILIATE, (client) =>
    client.query("SELECT account_code, currency_code FROM public.ledger_accounts ORDER BY account_code")
  );
  assert.equal(affiliateA.rowCount, 4);
  assert.equal(otherA.rowCount, 2);
  assert.equal(affiliateB.rowCount, 2);
  assert.equal(affiliateA.rows.every((row) => row.currency_code === "USD" || row.currency_code === "USDT"), true);
});

test("posts exact balanced double-entry and writes the outbox in the same transaction", async () => {
  const source = await createSourceEvent();
  const input = buildInput(source);
  const posted = await postLedgerEffect(runtimePool, input);
  assert.equal(posted.status, "created");

  const stored = await readJournal(runtimePool, TENANT_A, PRODUCT_AFFILIATE, posted.journal_id);
  assert.equal(stored.header.status, "posted");
  assert.equal(stored.entries.length, 2);
  assert.deepEqual(stored.entries.map((entry) => entry.side), ["debit", "credit"]);
  assert.equal(normalizeDecimal(stored.entries[0].amount), "125.37");
  assert.equal(normalizeDecimal(stored.entries[1].amount), "125.37");

  const totals = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query(
      "SELECT side, sum(amount)::text AS total FROM public.ledger_entries WHERE journal_id = $1 GROUP BY side ORDER BY side",
      [posted.journal_id]
    )
  );
  assert.deepEqual(totals.rows.map((row) => [row.side, normalizeDecimal(row.total)]), [
    ["credit", "125.37"], ["debit", "125.37"]
  ]);

  const outbox = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query("SELECT event_type, payload->>'journal_id' AS journal_id FROM public.outbox_events WHERE journal_id = $1", [posted.journal_id])
  );
  assert.equal(outbox.rowCount, 1);
  assert.equal(outbox.rows[0].event_type, "ledger.journal.posted");
  assert.equal(outbox.rows[0].journal_id, posted.journal_id);
});

test("exact numeric arithmetic and token precision are preserved without JavaScript floats", async () => {
  const arithmetic = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query("SELECT ('0.1'::numeric + '0.2'::numeric)::text AS exact_sum")
  );
  assert.equal(normalizeDecimal(arithmetic.rows[0].exact_sum), "0.3");

  const source = await createSourceEvent({ currency: "USDT", amount: "5.123456" });
  const posted = await postLedgerEffect(runtimePool, buildInput(source));
  const stored = await readJournal(runtimePool, TENANT_A, PRODUCT_AFFILIATE, posted.journal_id);
  assert.equal(normalizeDecimal(stored.entries[0].amount), "5.123456");
  assert.equal(normalizeDecimal(stored.entries[1].amount), "5.123456");
  await assert.rejects(
    postLedgerEffect(runtimePool, buildInput(source, { amount: 5.123456 })),
    TypeError
  );
});

test("replaying the same economic effect returns the original journal", async () => {
  const source = await createSourceEvent();
  const input = buildInput(source);
  const first = await postLedgerEffect(runtimePool, input);
  const second = await postLedgerEffect(runtimePool, input);
  assert.equal(first.status, "created");
  assert.equal(second.status, "duplicate");
  assert.equal(second.journal_id, first.journal_id);

  const counts = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query(
      `SELECT
         (SELECT count(*) FROM public.journal_transactions WHERE source_event_id = $1) AS journals,
         (SELECT count(*) FROM public.economic_effects WHERE source_event_id = $1) AS effects,
         (SELECT count(*) FROM public.outbox_events WHERE journal_id = $2) AS outbox`,
      [source.sourceEventId, first.journal_id]
    )
  );
  assert.deepEqual(
    [Number(counts.rows[0].journals), Number(counts.rows[0].effects), Number(counts.rows[0].outbox)],
    [1, 1, 1]
  );
});

test("concurrent duplicate delivery creates exactly one journal and one economic effect", async () => {
  const source = await createSourceEvent();
  const input = buildInput(source);
  const [first, second] = await Promise.all([
    postLedgerEffect(runtimePool, input),
    postLedgerEffect(runtimePool2, input)
  ]);
  assert.deepEqual([first.status, second.status].sort(), ["created", "duplicate"]);
  assert.equal(first.journal_id, second.journal_id);

  const count = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query(
      "SELECT count(*) AS count FROM public.journal_transactions WHERE source_event_id = $1 AND status = 'posted'",
      [source.sourceEventId]
    )
  );
  assert.equal(Number(count.rows[0].count), 1);
});

test("reusing an economic effect or idempotency key with a different fingerprint is rejected", async () => {
  const source = await createSourceEvent();
  const input = buildInput(source);
  await postLedgerEffect(runtimePool, input);

  await assert.rejects(
    postLedgerEffect(runtimePool, buildInput(source, { amount: "124.00", idempotencyKey: input.idempotency_key })),
    (error) => error.code === "P02_IDEMPOTENCY_CONFLICT"
  );
});

test("unbalanced journals roll back header, effect, entries and outbox", async () => {
  const source = await createSourceEvent();
  const input = buildInput(source, {
    entries: [
      { account_id: ACCOUNTS.tenantA.affiliate.usdExpense, currency_code: "USD", side: "debit", amount: "125.37" },
      { account_id: ACCOUNTS.tenantA.affiliate.usdPayable, currency_code: "USD", side: "credit", amount: "100.00" }
    ]
  });
  await assert.rejects(postLedgerEffect(runtimePool, input), (error) => error.code === "23514");

  const persisted = await adminPool.query(
    `SELECT
       (SELECT count(*) FROM public.journal_transactions WHERE source_event_id = $1) AS journals,
       (SELECT count(*) FROM public.economic_effects WHERE source_event_id = $1) AS effects,
       (SELECT count(*) FROM public.ledger_entries WHERE journal_id IN
          (SELECT journal_id FROM public.journal_transactions WHERE source_event_id = $1)) AS entries,
       (SELECT count(*) FROM public.outbox_events WHERE journal_id IN
          (SELECT journal_id FROM public.journal_transactions WHERE source_event_id = $1)) AS outbox`,
    [source.sourceEventId]
  );
  assert.deepEqual(
    [Number(persisted.rows[0].journals), Number(persisted.rows[0].effects), Number(persisted.rows[0].entries), Number(persisted.rows[0].outbox)],
    [0, 0, 0, 0]
  );
});

test("currency decimal scale is enforced at the database boundary", async () => {
  const source = await createSourceEvent({ amount: "1.00" });
  const input = buildInput(source, { amount: "1.001" });
  await assert.rejects(postLedgerEffect(runtimePool, input), (error) => error.code === "22003");
});

test("each currency must balance independently; unlike currencies cannot net", async () => {
  const source = await createSourceEvent({ amount: "100.00" });
  const input = buildInput(source, {
    entries: [
      { account_id: ACCOUNTS.tenantA.affiliate.usdExpense, currency_code: "USD", side: "debit", amount: "100.00" },
      { account_id: ACCOUNTS.tenantA.affiliate.usdtPayable, currency_code: "USDT", side: "credit", amount: "100.00" }
    ]
  });
  await assert.rejects(postLedgerEffect(runtimePool, input), (error) => error.code === "23514");
});

test("posted journals and entries cannot be edited or deleted", async () => {
  const source = await createSourceEvent();
  const posted = await postLedgerEffect(runtimePool, buildInput(source));

  await assert.rejects(
    adminPool.query("UPDATE public.ledger_entries SET amount = 1 WHERE journal_id = $1", [posted.journal_id]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("DELETE FROM public.ledger_entries WHERE journal_id = $1", [posted.journal_id]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("UPDATE public.journal_transactions SET status = 'draft' WHERE journal_id = $1", [posted.journal_id]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("DELETE FROM public.journal_transactions WHERE journal_id = $1", [posted.journal_id]),
    (error) => error.code === "55000"
  );
});

test("a posted journal can only be reversed by a new exact inverse journal", async () => {
  const source = await createSourceEvent();
  const accountIds = [ACCOUNTS.tenantA.affiliate.usdExpense, ACCOUNTS.tenantA.affiliate.usdPayable];
  const balanceBefore = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query(
      "SELECT account_id, balance::text FROM public.ledger_account_balances WHERE account_id = ANY($1::uuid[]) ORDER BY account_id",
      [accountIds]
    )
  );
  const original = await postLedgerEffect(runtimePool, buildInput(source));
  const reversed = await reverseJournal(runtimePool, {
    tenant_id: TENANT_A,
    product_id: PRODUCT_AFFILIATE,
    journal_id: original.journal_id,
    idempotency_key: "reverse-" + randomUUID()
  });
  assert.equal(reversed.status, "reversed");

  const originalAfter = await readJournal(runtimePool, TENANT_A, PRODUCT_AFFILIATE, original.journal_id);
  const reversal = await readJournal(runtimePool, TENANT_A, PRODUCT_AFFILIATE, reversed.journal_id);
  assert.equal(originalAfter.header.status, "posted");
  assert.equal(reversal.header.status, "posted");
  assert.equal(reversal.header.reversal_of_journal_id, original.journal_id);
  assert.equal(reversal.entries[0].side, "credit");
  assert.equal(reversal.entries[1].side, "debit");

  const balances = await withLedgerTransaction(runtimePool, TENANT_A, PRODUCT_AFFILIATE, (client) =>
    client.query(
      "SELECT account_id, balance::text FROM public.ledger_account_balances WHERE account_id = ANY($1::uuid[]) ORDER BY account_id",
      [accountIds]
    )
  );
  assert.deepEqual(
    balances.rows.map((row) => [row.account_id, normalizeDecimal(row.balance)]),
    balanceBefore.rows.map((row) => [row.account_id, normalizeDecimal(row.balance)])
  );

  await assert.rejects(
    reverseJournal(runtimePool, {
      tenant_id: TENANT_A,
      product_id: PRODUCT_AFFILIATE,
      journal_id: original.journal_id,
      idempotency_key: "reverse-again-" + randomUUID()
    }),
    (error) => error.code === "23505"
  );
});

test("reconciliation detects missing and duplicated financial postings", async () => {
  const source = await createSourceEvent();
  const before = await listReconciliationExceptions(runtimePool, TENANT_A, PRODUCT_AFFILIATE);
  assert.ok(before.some((row) => row.source_event_id === source.sourceEventId));

  const posted = await postLedgerEffect(runtimePool, buildInput(source));
  const after = await listReconciliationExceptions(runtimePool, TENANT_A, PRODUCT_AFFILIATE);
  assert.equal(after.some((row) => row.source_event_id === source.sourceEventId), false);

  const rogueJournalId = randomUUID();
  await adminPool.query(
    `INSERT INTO public.journal_transactions
      (tenant_id, product_id, journal_id, source_event_id, effect_type, effect_key,
       idempotency_key, request_fingerprint, status)
     VALUES ($1, $2, $3, $4, 'affiliate_commission_accrual', $5, $6, 'synthetic-admin-injection', 'draft')`,
    [TENANT_A, PRODUCT_AFFILIATE, rogueJournalId, source.sourceEventId, source.effectKey, "rogue-" + randomUUID()]
  );
  await adminPool.query(
    `INSERT INTO public.ledger_entries
      (tenant_id, product_id, journal_id, line_no, account_id, currency_code, side, amount)
     VALUES
      ($1, $2, $3, 1, $4, 'USD', 'debit', 1.00),
      ($1, $2, $3, 2, $5, 'USD', 'credit', 1.00)`,
    [TENANT_A, PRODUCT_AFFILIATE, rogueJournalId,
     ACCOUNTS.tenantA.affiliate.usdExpense, ACCOUNTS.tenantA.affiliate.usdPayable]
  );
  await adminPool.query(
    "UPDATE public.journal_transactions SET status = 'posted' WHERE journal_id = $1",
    [rogueJournalId]
  );

  const exception = await listReconciliationExceptions(runtimePool, TENANT_A, PRODUCT_AFFILIATE);
  const mismatch = exception.find((row) => row.source_event_id === source.sourceEventId);
  assert.ok(mismatch);
  assert.equal(normalizeDecimal(mismatch.expected_amount), "125.37");
  assert.equal(normalizeDecimal(mismatch.posted_payable_amount), "126.37");
  assert.notEqual(posted.journal_id, rogueJournalId);
});

test("source events and economic effects are append-only", async () => {
  const source = await createSourceEvent();
  const posted = await postLedgerEffect(runtimePool, buildInput(source));
  await assert.rejects(
    adminPool.query("UPDATE public.source_events SET expected_amount = 1 WHERE source_event_id = $1", [source.sourceEventId]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("DELETE FROM public.source_events WHERE source_event_id = $1", [source.sourceEventId]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("UPDATE public.economic_effects SET effect_key = 'tampered' WHERE journal_id = $1", [posted.journal_id]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("DELETE FROM public.economic_effects WHERE journal_id = $1", [posted.journal_id]),
    (error) => error.code === "55000"
  );
});

test("journal headers cannot be inserted directly as posted", async () => {
  const source = await createSourceEvent();
  await assert.rejects(
    adminPool.query(
      `INSERT INTO public.journal_transactions
        (tenant_id, product_id, journal_id, source_event_id, effect_type,
         effect_key, idempotency_key, request_fingerprint, status, posted_at)
       VALUES ($1, $2, $3, $4, 'affiliate_commission_accrual', $5, $6, 'direct-post', 'posted', clock_timestamp())`,
      [TENANT_A, PRODUCT_AFFILIATE, randomUUID(), source.sourceEventId, source.effectKey, "direct-" + randomUUID()]
    ),
    (error) => error.code === "55000"
  );
});
