import { createHash, createHmac, timingSafeEqual } from "node:crypto";

const MAX_BODY_BYTES = 64 * 1024;
const DEFAULT_TOLERANCE_SECONDS = 300;
const UUID_NAMESPACE = "4c4f5454-4f52-4954-4f2d-503033303031";

function fail(message, code, status = 400) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  throw error;
}

function uuidBytes(value) {
  const hex = value.replaceAll("-", "");
  if (!/^[0-9a-f]{32}$/i.test(hex)) throw new TypeError("namespace must be a UUID");
  return Buffer.from(hex, "hex");
}

export function uuidV5(namespace, name) {
  const digest = createHash("sha1")
    .update(uuidBytes(namespace))
    .update(Buffer.from(String(name), "utf8"))
    .digest();
  const bytes = Buffer.from(digest.subarray(0, 16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString("hex");
  return \`\${hex.slice(0, 8)}-\${hex.slice(8, 12)}-\${hex.slice(12, 16)}-\${hex.slice(16, 20)}-\${hex.slice(20)}\`;
}

export function parseSignatureHeader(header) {
  if (typeof header !== "string" || header.length > 512) {
    fail("signature header is missing or invalid", "P03_SIGNATURE_HEADER", 400);
  }
  const fields = new Map();
  for (const part of header.split(",")) {
    const separator = part.indexOf("=");
    if (separator < 1) fail("signature header is malformed", "P03_SIGNATURE_HEADER", 400);
    const key = part.slice(0, separator).trim();
    const value = part.slice(separator + 1).trim();
    if (!key || !value || fields.has(key)) {
      fail("signature header contains duplicate or empty fields", "P03_SIGNATURE_HEADER", 400);
    }
    fields.set(key, value);
  }
  const timestampText = fields.get("t");
  const signature = fields.get("v1");
  if (!timestampText || !/^[0-9]{1,12}$/.test(timestampText)
      || !signature || !/^[0-9a-f]{64}$/i.test(signature)) {
    fail("signature header fields are invalid", "P03_SIGNATURE_HEADER", 400);
  }
  return { timestamp: Number(timestampText), signature: signature.toLowerCase() };
}

export function verifyProviderSignature(rawBody, header, secret, nowSeconds = Math.floor(Date.now() / 1000), toleranceSeconds = DEFAULT_TOLERANCE_SECONDS) {
  if (!Buffer.isBuffer(rawBody)) throw new TypeError("rawBody must be a Buffer");
  if (rawBody.length > MAX_BODY_BYTES) fail("provider request body is too large", "P03_BODY_TOO_LARGE", 413);
  if (typeof secret !== "string" || Buffer.byteLength(secret, "utf8") < 32) {
    throw new TypeError("provider signing secret must contain at least 32 bytes");
  }
  const { timestamp, signature } = parseSignatureHeader(header);
  if (!Number.isInteger(nowSeconds) || Math.abs(nowSeconds - timestamp) > toleranceSeconds) {
    fail("provider signature timestamp is outside the accepted tolerance", "P03_STALE_SIGNATURE", 400);
  }
  const expected = createHmac("sha256", secret)
    .update(String(timestamp))
    .update(".")
    .update(rawBody)
    .digest();
  const supplied = Buffer.from(signature, "hex");
  if (supplied.length !== expected.length || !timingSafeEqual(expected, supplied)) {
    fail("provider signature verification failed", "P03_BAD_SIGNATURE", 401);
  }
  return { timestamp };
}

export function signProviderPayload(rawBody, secret, timestamp) {
  const signature = createHmac("sha256", secret)
    .update(String(timestamp))
    .update(".")
    .update(rawBody)
    .digest("hex");
  return \`t=\${timestamp},v1=\${signature}\`;
}

function requireText(value, field, maxLength) {
  if (typeof value !== "string" || value.length < 1 || value.length > maxLength) {
    fail(\`provider event field \${field} is invalid\`, "P03_INVALID_EVENT", 400);
  }
  return value;
}

export async function ingestProviderWebhook(pool, endpoint, rawBody, signatureHeader, nowSeconds = Math.floor(Date.now() / 1000)) {
  if (!endpoint || typeof endpoint !== "object") throw new TypeError("trusted endpoint configuration is required");
  if (!Buffer.isBuffer(rawBody)) throw new TypeError("rawBody must be a Buffer");
  if (rawBody.length > MAX_BODY_BYTES) fail("provider request body is too large", "P03_BODY_TOO_LARGE", 413);

  const verified = verifyProviderSignature(rawBody, signatureHeader, endpoint.secret, nowSeconds);
  let payload;
  try {
    payload = JSON.parse(rawBody.toString("utf8"));
  } catch {
    fail("provider payload is not valid JSON", "P03_INVALID_JSON", 400);
  }
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    fail("provider payload must be a JSON object", "P03_INVALID_EVENT", 400);
  }

  const providerId = requireText(endpoint.providerId, "endpoint.providerId", 64);
  const providerAccountId = requireText(endpoint.providerAccountId, "endpoint.providerAccountId", 128);
  const providerEventId = requireText(payload.event_id, "event_id", 128);
  const eventType = requireText(payload.event_type, "event_type", 96);
  const bodyAccount = requireText(payload.provider_account_id, "provider_account_id", 128);
  if (bodyAccount !== providerAccountId) {
    fail("provider account does not match the trusted webhook endpoint", "P03_ACCOUNT_MISMATCH", 403);
  }
  if (typeof endpoint.keyId !== "string" || endpoint.keyId.length < 1 || endpoint.keyId.length > 64) {
    throw new TypeError("trusted endpoint keyId is required");
  }

  let occurredAt = null;
  if (payload.occurred_at !== undefined && payload.occurred_at !== null) {
    const parsed = Date.parse(payload.occurred_at);
    if (!Number.isFinite(parsed)) fail("provider occurred_at is invalid", "P03_INVALID_EVENT", 400);
    occurredAt = new Date(parsed).toISOString();
  }

  const amountMinor = typeof payload.amount_minor === "string" ? payload.amount_minor : null;
  const currencyCode = typeof payload.currency_code === "string" ? payload.currency_code : null;
  const identity = \`\${providerId}|\${providerAccountId}|\${providerEventId}\`;
  const sourceEventId = uuidV5(UUID_NAMESPACE, \`source|\${identity}\`);
  const effectId = uuidV5(UUID_NAMESPACE, \`effect|\${identity}|\${eventType}\`);
  const idempotencyKey = \`pvd:\${createHash("sha256").update(\`\${identity}|\${eventType}\`).digest("hex")}\`;
  const payloadHash = createHash("sha256").update(rawBody).digest("hex");

  const result = await pool.query(
    "SELECT inbox_id, duplicate FROM public.receive_provider_event($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13,$14)",
    [
      providerId,
      providerAccountId,
      providerEventId,
      eventType,
      sourceEventId,
      effectId,
      idempotencyKey,
      occurredAt,
      amountMinor,
      currencyCode,
      JSON.stringify(payload),
      payloadHash,
      endpoint.keyId,
      new Date(verified.timestamp * 1000).toISOString()
    ]
  );
  return result.rows[0];
}

export async function processProviderEvent(pool, inboxId) {
  const result = await pool.query(
    "SELECT journal_id, processing_status, duplicate FROM public.process_provider_event($1)",
    [inboxId]
  );
  return result.rows[0];
}

export async function reconcileProviderEvents(pool) {
  const result = await pool.query("SELECT * FROM public.reconcile_provider_events()");
  return result.rows[0];
}
