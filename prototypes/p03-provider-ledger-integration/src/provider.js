import { createHash, createHmac, randomUUID, timingSafeEqual } from "node:crypto";
import { postJournal } from "../../p02-ledger-posting/src/posting.js";

const SHA256 = /^[0-9a-f]{64}$/;
const AMOUNT = /^[1-9][0-9]{0,37}$/;
const SAFE_ID = /^[A-Za-z0-9._:-]{1,80}$/;

function digest(value) {
  return createHash("sha256").update(value).digest("hex");
}

function secretBytes(secret) {
  if (Buffer.isBuffer(secret)) {
    if (secret.length < 16) throw new TypeError("webhook secret must contain at least 128 bits");
    return secret;
  }
  if (typeof secret !== "string" || secret.length === 0) throw new TypeError("webhook secret is required");
  if (secret.startsWith("whsec_")) {
    const decoded = Buffer.from(secret.slice(6), "base64");
    if (decoded.length < 16) throw new TypeError("webhook secret must contain at least 128 bits");
    return decoded;
  }
  return Buffer.from(secret, "utf8");
}

function constantTimeEqual(left, right) {
  const a = Buffer.isBuffer(left) ? left : Buffer.from(left);
  const b = Buffer.isBuffer(right) ? right : Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function signWebhook({ eventId, rawBody, secret, timestamp }) {
  if (typeof eventId !== "string" || !SAFE_ID.test(eventId)) throw new TypeError("invalid webhook event ID");
  if (!Buffer.isBuffer(rawBody) && typeof rawBody !== "string") throw new TypeError("rawBody must be exact request bytes");
  if (!Number.isSafeInteger(timestamp) || timestamp < 1) throw new TypeError("timestamp must be Unix seconds");
  const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody, "utf8");
  const signed = Buffer.concat([Buffer.from(eventId + "." + timestamp + ".", "utf8"), body]);
  const signature = createHmac("sha256", secretBytes(secret)).update(signed).digest("base64");
  return {
    "webhook-id": eventId,
    "webhook-timestamp": String(timestamp),
    "webhook-signature": "v1," + signature
  };
}

export function verifyWebhook({ headers, rawBody, keys, now = Date.now(), maxAgeSeconds = 300 }) {
  const eventId = headers?.["webhook-id"];
  const timestampText = headers?.["webhook-timestamp"];
  const signatureHeader = headers?.["webhook-signature"];
  if (typeof eventId !== "string" || !SAFE_ID.test(eventId)) return { valid: false, reason: "invalid_event_id" };
  if (typeof timestampText !== "string" || !/^[0-9]+$/.test(timestampText)) return { valid: false, reason: "invalid_timestamp" };
  if (typeof signatureHeader !== "string" || signatureHeader.length === 0) return { valid: false, reason: "missing_signature" };
  const timestamp = Number(timestampText);
  if (!Number.isSafeInteger(timestamp) || Math.abs(Math.floor(now / 1000) - timestamp) > maxAgeSeconds) {
    return { valid: false, reason: "stale_signature" };
  }
  if (!Array.isArray(keys) || keys.length === 0) return { valid: false, reason: "no_verification_keys" };
  const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody ?? "");
  const signed = Buffer.concat([Buffer.from(eventId + "." + timestampText + ".", "utf8"), body]);
  const candidates = signatureHeader.split(/\s+/).map((part) => {
    const comma = part.indexOf(",");
    return comma > 0 ? { version: part.slice(0, comma), value: part.slice(comma + 1) } : null;
  }).filter((item) => item?.version === "v1" && item.value.length > 0);
  for (const key of keys) {
    const expected = createHmac("sha256", secretBytes(key.secret)).update(signed).digest();
    for (const candidate of candidates) {
      let supplied;
      try { supplied = Buffer.from(candidate.value, "base64"); } catch { continue; }
      if (constantTimeEqual(expected, supplied)) return { valid: true, eventId, timestamp, keyId: key.id };
    }
  }
  return { valid: false, reason: "signature_mismatch" };
}

function canonicalize(payload, installation, eventId) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw Object.assign(new Error("provider payload must be an object"), { code: "P03D_INVALID_PAYLOAD" });
  }
  if (payload.event_id !== undefined && payload.event_id !== eventId) {
    throw Object.assign(new Error("signed event ID differs from payload event_id"), { code: "P03D_EVENT_ID_MISMATCH" });
  }
  if (typeof payload.type !== "string" || payload.type.length < 1 || payload.type.length > 160) {
    throw Object.assign(new Error("provider event type is invalid"), { code: "P03D_INVALID_EVENT_TYPE" });
  }
  const data = payload.data ?? {};
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw Object.assign(new Error("provider event data must be an object"), { code: "P03D_INVALID_DATA" });
  }
  const occurredAt = payload.occurred_at ?? payload.time ?? null;
  const parsed = occurredAt === null ? null : new Date(occurredAt);
  if (parsed && Number.isNaN(parsed.getTime())) {
    throw Object.assign(new Error("provider event time is invalid"), { code: "P03D_INVALID_EVENT_TIME" });
  }
  return {
    specversion: "1.0",
    id: eventId,
    source: installation.provider_source,
    type: payload.type,
    ...(parsed ? { time: parsed.toISOString() } : {}),
    datacontenttype: "application/json",
    data
  };
}

async function assertInstallationScope(pool, installation) {
  const result = await pool.query(
    "SELECT private.current_tenant_id()::text AS tenant_id, private.current_product_id()::text AS product_id"
  );
  if (result.rowCount !== 1 ||
      result.rows[0].tenant_id !== installation.tenant_id ||
      result.rows[0].product_id !== installation.product_id) {
    throw Object.assign(new Error("database identity does not match trusted provider installation"), {
      code: "P03D_INSTALLATION_SCOPE_MISMATCH"
    });
  }
}

export async function ingestProviderWebhook(pool, {
  installation, keys, headers, rawBody, now = Date.now(),
  maxAgeSeconds = 300, maxBodyBytes = 256 * 1024
}) {
  if (!installation || installation.active !== true ||
      !installation.tenant_id || !installation.product_id || !installation.provider_id ||
      !installation.provider_source) {
    return { http_status: 404, outcome: "unknown_installation" };
  }
  const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody ?? "", "utf8");
  if (body.length > maxBodyBytes) return { http_status: 413, outcome: "payload_too_large" };

  let verification = verifyWebhook({ headers, rawBody: body, keys, now, maxAgeSeconds });
  if (!verification.valid) return { http_status: 401, outcome: "signature_rejected", reason: verification.reason };

  let payload;
  try { payload = JSON.parse(body.toString("utf8")); }
  catch { return { http_status: 400, outcome: "invalid_json" }; }

  let canonicalEvent;
  try { canonicalEvent = canonicalize(payload, installation, verification.eventId); }
  catch (error) { return { http_status: 400, outcome: "invalid_event", reason: error.code ?? "invalid_event" }; }

  await assertInstallationScope(pool, installation);
  const payloadHash = digest(body);
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const inserted = await client.query(
      `INSERT INTO public.provider_event_inbox
        (tenant_id, product_id, provider_id, provider_event_id, event_type, event_source,
         payload_hash, signature_key_id, canonical_event)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb)
       ON CONFLICT DO NOTHING
       RETURNING provider_event_id`,
      [installation.tenant_id, installation.product_id, installation.provider_id,
       verification.eventId, canonicalEvent.type, canonicalEvent.source,
       payloadHash, verification.keyId, JSON.stringify(canonicalEvent)]
    );
    if (inserted.rowCount === 1) {
      await client.query("COMMIT");
      return { http_status: 202, outcome: "accepted", provider_event_id: verification.eventId };
    }

    const existing = await client.query(
      `SELECT payload_hash, status FROM public.provider_event_inbox
        WHERE provider_id=$1 AND provider_event_id=$2`,
      [installation.provider_id, verification.eventId]
    );
    if (existing.rowCount !== 1) throw new Error("provider inbox conflict row is not visible in installation scope");
    if (existing.rows[0].payload_hash === payloadHash) {
      await client.query("COMMIT");
      return {
        http_status: 200, outcome: "duplicate",
        provider_event_id: verification.eventId, existing_status: existing.rows[0].status
      };
    }
    await client.query(
      `INSERT INTO public.provider_event_conflicts
        (tenant_id, product_id, provider_id, provider_event_id, accepted_payload_hash, conflicting_payload_hash)
       VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING`,
      [installation.tenant_id, installation.product_id, installation.provider_id,
       verification.eventId, existing.rows[0].payload_hash, payloadHash]
    );
    await client.query("COMMIT");
    return { http_status: 409, outcome: "event_id_payload_conflict", provider_event_id: verification.eventId };
  } catch (error) {
    try { await client.query("ROLLBACK"); } catch {}
    throw error;
  } finally {
    client.release();
  }
}

export async function claimNextProviderEvent(pool, { workerId, leaseSeconds = 30, now = null, providerId = null, eventId = null }) {
  if (typeof workerId !== "string" || !SAFE_ID.test(workerId)) throw new TypeError("workerId is invalid");
  if (!Number.isInteger(leaseSeconds) || leaseSeconds < 1 || leaseSeconds > 300) throw new RangeError("leaseSeconds must be 1..300");
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query(
      `UPDATE public.provider_event_inbox
          SET status='dead_letter', lease_owner=NULL, lease_token=NULL, lease_until=NULL,
              last_error_code='MAX_ATTEMPTS_EXHAUSTED'
        WHERE status='processing' AND lease_until <= COALESCE($1::timestamptz,clock_timestamp())
          AND attempt_count >= max_attempts`,
      [now]
    );
    const selected = await client.query(
      `SELECT provider_id, provider_event_id
         FROM public.provider_event_inbox
        WHERE ((status IN ('accepted','retry') AND available_at <= COALESCE($1::timestamptz, clock_timestamp()))
           OR (status='processing' AND lease_until <= COALESCE($1::timestamptz, clock_timestamp())))
          AND attempt_count < max_attempts
          AND ($2::text IS NULL OR provider_id=$2)
          AND ($3::text IS NULL OR provider_event_id=$3)
        ORDER BY received_at, provider_event_id
        LIMIT 1 FOR UPDATE SKIP LOCKED`,
      [now, providerId, eventId]
    );
    if (selected.rowCount === 0) {
      await client.query("COMMIT");
      return null;
    }
    const claimed = await client.query(
      `UPDATE public.provider_event_inbox
          SET status='processing', attempt_count=attempt_count+1,
              lease_owner=$3, lease_token=gen_random_uuid(),
              lease_until=COALESCE($4::timestamptz,clock_timestamp()) + make_interval(secs=>$5)
        WHERE provider_id=$1 AND provider_event_id=$2
        RETURNING provider_id, provider_event_id, event_type, canonical_event,
                  effect_id, source_event_id, attempt_count, max_attempts, lease_token, lease_until`,
      [selected.rows[0].provider_id, selected.rows[0].provider_event_id, workerId, now, leaseSeconds]
    );
    await client.query("COMMIT");
    return claimed.rows[0] ?? null;
  } catch (error) {
    try { await client.query("ROLLBACK"); } catch {}
    throw error;
  } finally {
    client.release();
  }
}

function journalLines(event, installation) {
  const mapping = installation.event_mappings?.[event.type];
  if (!mapping) throw Object.assign(new Error("provider event type has no approved synthetic mapping"), { code: "P03D_UNMAPPED_EVENT" });
  const amount = event.data?.amount_minor;
  if (typeof amount !== "string" || !AMOUNT.test(amount)) {
    throw Object.assign(new Error("amount_minor must be an exact positive integer string"), { code: "P03D_INVALID_AMOUNT" });
  }
  if (event.data?.currency_code !== mapping.currency_code) {
    throw Object.assign(new Error("event currency differs from trusted mapping"), { code: "P03D_CURRENCY_MISMATCH" });
  }
  return [
    { line_no: 1, account_id: mapping.debit_account_id, currency_code: mapping.currency_code, direction: "debit", amount_minor: amount },
    { line_no: 2, account_id: mapping.credit_account_id, currency_code: mapping.currency_code, direction: "credit", amount_minor: amount }
  ];
}

function idempotencyKey(productId, providerId, eventId) {
  return "provider:" + digest(Buffer.from(productId + "|" + providerId + "|" + eventId, "utf8"));
}

async function failClaim(pool, claim, errorCode, now, retryDelaySeconds = 5) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const permanent = ["P03D_UNMAPPED_EVENT", "P03D_INVALID_AMOUNT", "P03D_CURRENCY_MISMATCH"].includes(errorCode);
    const status = permanent ? "quarantined" :
      claim.attempt_count >= claim.max_attempts ? "dead_letter" : "retry";
    const result = await client.query(
      `UPDATE public.provider_event_inbox
          SET status=$1, available_at=COALESCE($2::timestamptz,clock_timestamp()) + make_interval(secs=>$3),
              lease_owner=NULL, lease_token=NULL, lease_until=NULL, last_error_code=$4
        WHERE provider_id=$5 AND provider_event_id=$6
          AND status='processing' AND lease_token=$7 AND lease_until > COALESCE($2::timestamptz,clock_timestamp())
        RETURNING status`,
      [status, now, retryDelaySeconds, errorCode, claim.provider_id, claim.provider_event_id, claim.lease_token]
    );
    await client.query("COMMIT");
    return result.rows[0]?.status ?? "stale";
  } catch (error) {
    try { await client.query("ROLLBACK"); } catch {}
    throw error;
  } finally {
    client.release();
  }
}

export async function processProviderEvent(pool, {
  claim, installation, now = null, simulateBeforeCommit = false, retryDelaySeconds = 5
}) {
  if (!claim?.provider_event_id || !claim.lease_token || !installation) throw new TypeError("claim and trusted installation are required");
  if (claim.provider_id !== installation.provider_id) throw new TypeError("claim provider does not match trusted installation");
  if (!Number.isInteger(retryDelaySeconds) || retryDelaySeconds < 0 || retryDelaySeconds > 86400) throw new RangeError("retryDelaySeconds must be 0..86400");
  await assertInstallationScope(pool, installation);
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const locked = await client.query(
      `SELECT * FROM public.provider_event_inbox
        WHERE provider_id=$1 AND provider_event_id=$2
          AND status='processing' AND lease_token=$3
          AND lease_until > COALESCE($4::timestamptz,clock_timestamp())
        FOR UPDATE`,
      [claim.provider_id, claim.provider_event_id, claim.lease_token, now]
    );
    if (locked.rowCount !== 1) {
      await client.query("ROLLBACK");
      return { outcome: "stale" };
    }
    const row = locked.rows[0];
    const lines = journalLines(row.canonical_event, installation);
    const posted = await postJournal(client, {
      idempotency_key: idempotencyKey(row.product_id, row.provider_id, row.provider_event_id),
      effect_id: row.effect_id,
      source_event_id: row.source_event_id,
      lines
    });
    if (simulateBeforeCommit) throw Object.assign(new Error("synthetic crash before transaction commit"), { code: "P03D_SIMULATED_CRASH" });
    const updated = await client.query(
      `UPDATE public.provider_event_inbox
          SET status='processed', processed_at=COALESCE($1::timestamptz,clock_timestamp()),
              journal_id=$2, lease_owner=NULL, lease_token=NULL, lease_until=NULL, last_error_code=NULL
        WHERE provider_id=$3 AND provider_event_id=$4
          AND status='processing' AND lease_token=$5
        RETURNING journal_id`,
      [now, posted.journal_id, row.provider_id, row.provider_event_id, claim.lease_token]
    );
    if (updated.rowCount !== 1) throw new Error("provider inbox lease changed during posting");
    await client.query("COMMIT");
    return { outcome: "processed", journal_id: posted.journal_id, duplicate: posted.duplicate };
  } catch (error) {
    try { await client.query("ROLLBACK"); } catch {}
    const code = error.code && /^P03D_[A-Z0-9_]+$/.test(error.code) ? error.code : "POSTING_FAILED";
    const outcome = await failClaim(pool, claim, code, now, retryDelaySeconds);
    return { outcome, error_code: code };
  } finally {
    client.release();
  }
}

export async function reconcileProviderEvents(adminPool, { tenantId, productId, providerId }) {
  const result = await adminPool.query(
    `SELECT tenant_id, product_id, provider_id, provider_event_id, inbox_status,
            journal_id, journal_found, outbox_event_id, delivery_status
       FROM public.provider_event_reconciliation
      WHERE tenant_id=$1 AND product_id=$2 AND provider_id=$3
      ORDER BY provider_event_id`,
    [tenantId, productId, providerId]
  );
  return result.rows;
}

export function makeWebhook({ eventId, payload, secret, timestamp = Math.floor(Date.now() / 1000) }) {
  const rawBody = Buffer.from(JSON.stringify({ event_id: eventId, ...payload }), "utf8");
  return { eventId, rawBody, headers: signWebhook({ eventId, rawBody, secret, timestamp }) };
}
