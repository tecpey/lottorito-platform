import { createHash, createHmac, timingSafeEqual, randomUUID } from "node:crypto";

function digest(value) {
  return createHash("sha256").update(value).digest("hex");
}

function secretBuffer(secret) {
  if (Buffer.isBuffer(secret)) return secret;
  if (typeof secret !== "string" || secret.length === 0) throw new TypeError("webhook secret is required");
  return Buffer.from(secret, "utf8");
}

function safeEqual(left, right) {
  const a = Buffer.isBuffer(left) ? left : Buffer.from(left);
  const b = Buffer.isBuffer(right) ? right : Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function signStandardWebhook({ eventId, rawBody, secret, timestamp }) {
  if (typeof eventId !== "string" || eventId.length === 0 || eventId.includes(".")) {
    throw new TypeError("webhook event ID must be non-empty and cannot contain a dot");
  }
  if (typeof rawBody !== "string" && !Buffer.isBuffer(rawBody)) {
    throw new TypeError("rawBody must be the exact request bytes");
  }
  if (!Number.isSafeInteger(timestamp) || timestamp < 1) throw new TypeError("timestamp must be Unix seconds");
  const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody, "utf8");
  const signed = Buffer.concat([
    Buffer.from(eventId + "." + timestamp + ".", "utf8"),
    body
  ]);
  const signature = createHmac("sha256", secretBuffer(secret)).update(signed).digest("base64");
  return {
    "webhook-id": eventId,
    "webhook-timestamp": String(timestamp),
    "webhook-signature": "v1," + signature
  };
}

export function verifyStandardWebhook({ headers, rawBody, keys, now = Date.now(), maxAgeSeconds = 300 }) {
  const id = headers?.["webhook-id"];
  const timestampText = headers?.["webhook-timestamp"];
  const signatureHeader = headers?.["webhook-signature"];
  if (typeof id !== "string" || id.length === 0 || id.includes(".")) return { valid: false, reason: "invalid_event_id" };
  if (typeof timestampText !== "string" || !/^[0-9]+$/.test(timestampText)) return { valid: false, reason: "invalid_timestamp" };
  if (typeof signatureHeader !== "string" || signatureHeader.length === 0) return { valid: false, reason: "missing_signature" };
  const timestamp = Number(timestampText);
  if (!Number.isSafeInteger(timestamp) || Math.abs(Math.floor(now / 1000) - timestamp) > maxAgeSeconds) {
    return { valid: false, reason: "stale_signature" };
  }
  if (!Array.isArray(keys) || keys.length === 0) return { valid: false, reason: "no_verification_keys" };

  const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody);
  const signed = Buffer.concat([
    Buffer.from(id + "." + timestampText + ".", "utf8"),
    body
  ]);
  const supplied = signatureHeader.split(/\s+/).map((part) => {
    const comma = part.indexOf(",");
    return comma > 0 ? { version: part.slice(0, comma), value: part.slice(comma + 1) } : null;
  }).filter((item) => item && item.version === "v1" && item.value.length > 0);

  for (const key of keys) {
    const expected = createHmac("sha256", secretBuffer(key.secret)).update(signed).digest();
    for (const candidate of supplied) {
      let received;
      try { received = Buffer.from(candidate.value, "base64"); } catch { continue; }
      if (safeEqual(expected, received)) return { valid: true, eventId: id, timestamp, keyId: key.id };
    }
  }
  return { valid: false, reason: "signature_mismatch" };
}

export function adaptToCloudEvent(payload, installation, providerEventId) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw Object.assign(new Error("provider payload must be a JSON object"), { code: "P03_INVALID_PAYLOAD" });
  }
  if (payload.event_id !== undefined && payload.event_id !== providerEventId) {
    throw Object.assign(new Error("signed webhook ID does not match payload event_id"), { code: "P03_EVENT_ID_MISMATCH" });
  }
  if (typeof payload.type !== "string" || payload.type.length === 0) {
    throw Object.assign(new Error("provider event type is required"), { code: "P03_INVALID_EVENT_TYPE" });
  }
  const occurredAt = payload.occurred_at ?? payload.time ?? null;
  const parsedTime = occurredAt === null ? null : new Date(occurredAt);
  if (parsedTime && Number.isNaN(parsedTime.getTime())) {
    throw Object.assign(new Error("provider event time is invalid"), { code: "P03_INVALID_EVENT_TIME" });
  }
  const data = payload.data ?? {};
  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    throw Object.assign(new Error("provider event data must be an object"), { code: "P03_INVALID_EVENT_DATA" });
  }

  return {
    specversion: "1.0",
    id: providerEventId,
    source: installation.provider_source ?? "urn:lottorito:provider:" + installation.provider_id,
    type: payload.type,
    ...(typeof payload.subject === "string" && payload.subject.length > 0 ? { subject: payload.subject } : {}),
    ...(parsedTime ? { time: parsedTime.toISOString() } : {}),
    datacontenttype: "application/json",
    data
  };
}

export async function withEventTransaction(pool, tenantId, productId, callback) {
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

export async function ingestProviderWebhook(pool, {
  installation, keys, headers, rawBody, now = Date.now(),
  maxAgeSeconds = 300, maxBodyBytes = 256 * 1024
}) {
  if (!installation || installation.active !== true ||
      !installation.tenant_id || !installation.product_id || !installation.provider_id) {
    return { http_status: 404, outcome: "unknown_installation" };
  }
  const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody ?? "", "utf8");
  if (body.length > maxBodyBytes) return { http_status: 413, outcome: "payload_too_large" };

  const verification = verifyStandardWebhook({ headers, rawBody: body, keys, now, maxAgeSeconds });
  if (!verification.valid) return { http_status: 401, outcome: "signature_rejected", reason: verification.reason };

  let payload;
  try {
    payload = JSON.parse(body.toString("utf8"));
  } catch {
    return { http_status: 400, outcome: "invalid_json" };
  }

  let canonicalEvent;
  try {
    canonicalEvent = adaptToCloudEvent(payload, installation, verification.eventId);
  } catch (error) {
    return { http_status: 400, outcome: "invalid_event", reason: error.code ?? "invalid_event" };
  }

  const payloadHash = digest(body);
  return withEventTransaction(pool, installation.tenant_id, installation.product_id, async (client) => {
    const inserted = await client.query(
      `INSERT INTO public.provider_event_inbox
        (tenant_id, product_id, provider_id, provider_event_id, event_type,
         event_source, event_subject, event_time, provider_sequence,
         payload_hash, signature_key_id, canonical_event)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb)
       ON CONFLICT DO NOTHING
       RETURNING provider_event_id`,
      [
        installation.tenant_id, installation.product_id, installation.provider_id,
        verification.eventId, canonicalEvent.type, canonicalEvent.source,
        canonicalEvent.subject ?? null, canonicalEvent.time ?? null,
        Number.isSafeInteger(payload.sequence) ? payload.sequence : null,
        payloadHash, verification.keyId, JSON.stringify(canonicalEvent)
      ]
    );
    if (inserted.rowCount === 1) {
      return { http_status: 202, outcome: "accepted", provider_event_id: verification.eventId };
    }

    const existing = await client.query(
      `SELECT payload_hash, status
         FROM public.provider_event_inbox
        WHERE tenant_id = $1 AND product_id = $2
          AND provider_id = $3 AND provider_event_id = $4`,
      [installation.tenant_id, installation.product_id, installation.provider_id, verification.eventId]
    );
    if (existing.rowCount !== 1) {
      throw new Error("inbox conflict row was not visible in the installation scope");
    }
    if (existing.rows[0].payload_hash === payloadHash) {
      return {
        http_status: 200,
        outcome: "duplicate",
        provider_event_id: verification.eventId,
        existing_status: existing.rows[0].status
      };
    }

    await client.query(
      `INSERT INTO public.provider_event_conflicts
        (tenant_id, product_id, provider_id, provider_event_id,
         accepted_payload_hash, conflicting_payload_hash)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT DO NOTHING`,
      [installation.tenant_id, installation.product_id, installation.provider_id,
       verification.eventId, existing.rows[0].payload_hash, payloadHash]
    );
    return { http_status: 409, outcome: "event_id_payload_conflict", provider_event_id: verification.eventId };
  });
}

export async function claimNextInboxEvent(pool, {
  tenantId, productId, workerId, now = new Date(), leaseSeconds = 30
}) {
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const selected = await client.query(
      `SELECT provider_id, provider_event_id
         FROM public.provider_event_inbox
        WHERE (status IN ('accepted', 'retry') AND available_at <= $1)
           OR (status = 'processing' AND lease_until <= $1)
        ORDER BY received_at, provider_event_id
        LIMIT 1
        FOR UPDATE SKIP LOCKED`,
      [now]
    );
    if (selected.rowCount === 0) return null;
    const row = selected.rows[0];
    const claimed = await client.query(
      `UPDATE public.provider_event_inbox
          SET status = 'processing',
              attempt_count = attempt_count + 1,
              claimed_by = $3,
              lease_until = $4::timestamptz + ($5::int * interval '1 second')
        WHERE tenant_id = $1 AND product_id = $2
          AND provider_id = $6 AND provider_event_id = $7
        RETURNING provider_id, provider_event_id, event_type,
                  canonical_event, attempt_count, lease_until`,
      [tenantId, productId, workerId, now, leaseSeconds, row.provider_id, row.provider_event_id]
    );
    return claimed.rows[0];
  });
}

export async function completeInboxEvent(pool, {
  tenantId, productId, providerId, eventId, workerId, attemptCount, now = new Date()
}) {
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const result = await client.query(
      `UPDATE public.provider_event_inbox
          SET status = 'processed', processed_at = $7,
              lease_until = NULL, claimed_by = NULL, last_error_code = NULL
        WHERE tenant_id = $1 AND product_id = $2
          AND provider_id = $3 AND provider_event_id = $4
          AND status = 'processing' AND claimed_by = $5 AND attempt_count = $6`,
      [tenantId, productId, providerId, eventId, workerId, attemptCount, now]
    );
    return result.rowCount === 1;
  });
}

export async function failInboxEvent(pool, {
  tenantId, productId, providerId, eventId, workerId, attemptCount,
  errorCode, now = new Date(), baseDelaySeconds = 5, maxDelaySeconds = 3600,
  maxAttempts = 5, jitter = 0
}) {
  if (!Number.isFinite(jitter) || jitter < 0 || jitter > 1) throw new RangeError("jitter must be between 0 and 1");
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const current = await client.query(
      `SELECT attempt_count FROM public.provider_event_inbox
        WHERE tenant_id = $1 AND product_id = $2
          AND provider_id = $3 AND provider_event_id = $4
          AND status = 'processing' AND claimed_by = $5 AND attempt_count = $6
        FOR UPDATE`,
      [tenantId, productId, providerId, eventId, workerId, attemptCount]
    );
    if (current.rowCount !== 1) return { accepted: false, status: "stale_attempt" };
    const dead = attemptCount >= maxAttempts;
    const delay = Math.min(maxDelaySeconds, baseDelaySeconds * (2 ** Math.max(0, attemptCount - 1))) * (1 + jitter);
    const result = await client.query(
      `UPDATE public.provider_event_inbox
          SET status = $7, available_at = $8::timestamptz + ($9::double precision * interval '1 second'),
              lease_until = NULL, claimed_by = NULL, last_error_code = $10
        WHERE tenant_id = $1 AND product_id = $2
          AND provider_id = $3 AND provider_event_id = $4
          AND claimed_by = $5 AND attempt_count = $6
        RETURNING status, available_at`,
      [tenantId, productId, providerId, eventId, workerId, attemptCount,
       dead ? "dead_letter" : "retry", now, delay, errorCode]
    );
    return { accepted: result.rowCount === 1, ...result.rows[0] };
  });
}

export async function createOutboundDelivery(pool, {
  tenantId, productId, endpointId, eventId, payload
}) {
  const serialized = JSON.stringify(payload);
  const payloadHash = digest(serialized);
  const deliveryId = randomUUID();
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const inserted = await client.query(
      `INSERT INTO public.outbound_webhook_deliveries
        (tenant_id, product_id, delivery_id, endpoint_id, event_id, payload_hash, payload)
       VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb)
       ON CONFLICT DO NOTHING
       RETURNING delivery_id`,
      [tenantId, productId, deliveryId, endpointId, eventId, payloadHash, serialized]
    );
    if (inserted.rowCount === 1) return { status: "created", delivery_id: deliveryId };
    const existing = await client.query(
      `SELECT delivery_id, payload_hash
         FROM public.outbound_webhook_deliveries
        WHERE tenant_id = $1 AND product_id = $2 AND endpoint_id = $3 AND event_id = $4`,
      [tenantId, productId, endpointId, eventId]
    );
    if (existing.rowCount !== 1 || existing.rows[0].payload_hash !== payloadHash) {
      throw Object.assign(new Error("outbound event/endpoint identity was reused with a different payload"), {
        code: "P03_OUTBOUND_IDEMPOTENCY_CONFLICT"
      });
    }
    return { status: "duplicate", delivery_id: existing.rows[0].delivery_id };
  });
}

export async function claimNextOutboundDelivery(pool, {
  tenantId, productId, workerId, now = new Date(), leaseSeconds = 30
}) {
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const selected = await client.query(
      `SELECT delivery_id
         FROM public.outbound_webhook_deliveries
        WHERE (status IN ('pending', 'retry') AND available_at <= $1)
           OR (status = 'processing' AND lease_until <= $1)
        ORDER BY created_at, delivery_id
        LIMIT 1
        FOR UPDATE SKIP LOCKED`,
      [now]
    );
    if (selected.rowCount === 0) return null;
    const deliveryId = selected.rows[0].delivery_id;
    const claimed = await client.query(
      `UPDATE public.outbound_webhook_deliveries
          SET status = 'processing', attempt_count = attempt_count + 1,
              claimed_by = $3,
              lease_until = $4::timestamptz + ($5::int * interval '1 second')
        WHERE tenant_id = $1 AND product_id = $2 AND delivery_id = $6
        RETURNING delivery_id, endpoint_id, event_id, payload,
                  attempt_count, lease_until`,
      [tenantId, productId, workerId, now, leaseSeconds, deliveryId]
    );
    const row = claimed.rows[0];
    await client.query(
      `INSERT INTO public.webhook_delivery_attempts
        (tenant_id, product_id, delivery_id, attempt_no, outcome)
       VALUES ($1, $2, $3, $4, 'in_flight')`,
      [tenantId, productId, row.delivery_id, row.attempt_count]
    );
    return row;
  });
}

export async function recordOutboundResult(pool, {
  tenantId, productId, deliveryId, workerId, attemptCount,
  httpStatus = null, errorCode = null, now = new Date(),
  baseDelaySeconds = 5, maxDelaySeconds = 3600, maxAttempts = 5, jitter = 0
}) {
  if (!Number.isFinite(jitter) || jitter < 0 || jitter > 1) throw new RangeError("jitter must be between 0 and 1");
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const current = await client.query(
      `SELECT attempt_count
         FROM public.outbound_webhook_deliveries
        WHERE tenant_id = $1 AND product_id = $2 AND delivery_id = $3
          AND status = 'processing' AND claimed_by = $4 AND attempt_count = $5
        FOR UPDATE`,
      [tenantId, productId, deliveryId, workerId, attemptCount]
    );
    if (current.rowCount !== 1) return { accepted: false, status: "stale_attempt" };

    const delivered = httpStatus !== null && httpStatus >= 200 && httpStatus < 300;
    const retryable = httpStatus === null || httpStatus === 408 || httpStatus === 425 ||
      httpStatus === 429 || httpStatus >= 500;
    const dead = retryable && attemptCount >= maxAttempts;
    const nextStatus = delivered ? "delivered" : retryable ? (dead ? "dead_letter" : "retry") : "failed";
    const delay = Math.min(maxDelaySeconds, baseDelaySeconds * (2 ** Math.max(0, attemptCount - 1))) * (1 + jitter);

    await client.query(
      `UPDATE public.webhook_delivery_attempts
          SET finished_at = $5, outcome = $6, http_status = $7, error_code = $8
        WHERE tenant_id = $1 AND product_id = $2
          AND delivery_id = $3 AND attempt_no = $4`,
      [tenantId, productId, deliveryId, attemptCount, now,
       delivered ? "delivered" : retryable ? "retryable_failure" : "permanent_failure",
       httpStatus, errorCode]
    );
    const updated = await client.query(
      `UPDATE public.outbound_webhook_deliveries
          SET status = $4,
              available_at = CASE WHEN $4 = 'retry' OR $4 = 'dead_letter'
                THEN $5::timestamptz + ($6::double precision * interval '1 second')
                ELSE available_at END,
              delivered_at = CASE WHEN $4 = 'delivered' THEN $5 ELSE delivered_at END,
              lease_until = NULL, claimed_by = NULL,
              last_http_status = $7, last_error_code = $8
        WHERE tenant_id = $1 AND product_id = $2 AND delivery_id = $3
        RETURNING status, available_at, delivered_at`,
      [tenantId, productId, deliveryId, nextStatus, now, delay, httpStatus, errorCode]
    );
    return { accepted: updated.rowCount === 1, ...updated.rows[0] };
  });
}

export async function listProviderEventReconciliation(pool, tenantId, productId) {
  return withEventTransaction(pool, tenantId, productId, async (client) => {
    const result = await client.query(
      `SELECT provider_id, provider_event_id, inbox_status
         FROM public.provider_event_reconciliation
        ORDER BY provider_id, provider_event_id`
    );
    return result.rows;
  });
}
