import assert from "node:assert/strict";
import { after, test } from "node:test";
import { randomUUID } from "node:crypto";
import { Pool } from "pg";
import {
  adaptToCloudEvent,
  claimNextInboxEvent,
  claimNextOutboundDelivery,
  completeInboxEvent,
  createOutboundDelivery,
  failInboxEvent,
  ingestProviderWebhook,
  listProviderEventReconciliation,
  recordOutboundResult,
  signStandardWebhook,
  verifyStandardWebhook,
  withEventTransaction
} from "../src/events.js";

const TENANT_A = "11111111-1111-4111-8111-111111111111";
const TENANT_B = "22222222-2222-4222-8222-222222222222";
const PRODUCT_A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const PRODUCT_B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const installation = {
  installation_id: "synthetic-installation-a",
  tenant_id: TENANT_A,
  product_id: PRODUCT_A,
  provider_id: "synthetic-partner",
  provider_source: "urn:lottorito:provider:synthetic-partner",
  active: true
};
const keys = [
  { id: "current-v2", secret: "p03-current-synthetic-secret-not-production" },
  { id: "previous-v1", secret: "p03-previous-synthetic-secret-not-production" }
];
const adminPool = new Pool({ connectionString: process.env.ADMIN_DATABASE_URL, max: 4 });
const runtimePool = new Pool({ connectionString: process.env.RUNTIME_DATABASE_URL, max: 1 });
const runtimePool2 = new Pool({ connectionString: process.env.RUNTIME_DATABASE_URL, max: 1 });

after(async () => {
  await runtimePool.end();
  await runtimePool2.end();
  await adminPool.end();
});

function buildWebhook({
  eventId = "evt-" + randomUUID(),
  data = { external_user_id: "synthetic-user-1", amount: "12.34", currency: "USD" },
  secret = keys[0].secret,
  timestamp = Math.floor(Date.now() / 1000),
  topLevel = {}
} = {}) {
  const payload = {
    event_id: eventId,
    type: "com.synthetic.partner.transaction.settled.v1",
    occurred_at: new Date(timestamp * 1000).toISOString(),
    subject: "transaction-" + eventId,
    data,
    ...topLevel
  };
  const rawBody = JSON.stringify(payload);
  return {
    eventId,
    payload,
    rawBody,
    headers: signStandardWebhook({ eventId, rawBody, secret, timestamp }),
    timestamp
  };
}

async function ingest(fixture, options = {}) {
  return ingestProviderWebhook(runtimePool, {
    installation,
    keys,
    headers: fixture.headers,
    rawBody: fixture.rawBody,
    ...options
  });
}

async function inboxRow(eventId) {
  return withEventTransaction(runtimePool, TENANT_A, PRODUCT_A, async (client) => {
    const result = await client.query(
      "SELECT provider_event_id, status, attempt_count, signature_key_id, canonical_event FROM public.provider_event_inbox WHERE provider_id = $1 AND provider_event_id = $2",
      [installation.provider_id, eventId]
    );
    return result.rows[0] ?? null;
  });
}

test("valid signed provider event is durably accepted as a canonical CloudEvent", async () => {
  const fixture = buildWebhook();
  const result = await ingest(fixture);
  assert.equal(result.http_status, 202);
  assert.equal(result.outcome, "accepted");
  const stored = await inboxRow(fixture.eventId);
  assert.equal(stored.status, "accepted");
  assert.equal(stored.signature_key_id, "current-v2");
  assert.equal(stored.canonical_event.specversion, "1.0");
  assert.equal(stored.canonical_event.id, fixture.eventId);
  assert.equal(stored.canonical_event.source, installation.provider_source);
  assert.equal(stored.canonical_event.type, fixture.payload.type);
  assert.equal(stored.canonical_event.data.amount, "12.34");
});

test("raw-body tampering invalidates the signature", async () => {
  const fixture = buildWebhook();
  const tampered = fixture.rawBody.replace("12.34", "99.99");
  const result = await ingestProviderWebhook(runtimePool, {
    installation, keys, headers: fixture.headers, rawBody: tampered
  });
  assert.equal(result.http_status, 401);
  assert.equal(result.reason, "signature_mismatch");
  assert.equal(await inboxRow(fixture.eventId), null);
});

test("stale and future timestamps are rejected before persistence", async () => {
  const stale = buildWebhook({ timestamp: Math.floor(Date.now() / 1000) - 900 });
  const staleResult = await ingest(stale, { maxAgeSeconds: 300 });
  assert.equal(staleResult.http_status, 401);
  assert.equal(staleResult.reason, "stale_signature");

  const future = buildWebhook({ timestamp: Math.floor(Date.now() / 1000) + 900 });
  const futureResult = await ingest(future, { maxAgeSeconds: 300 });
  assert.equal(futureResult.http_status, 401);
  assert.equal(futureResult.reason, "stale_signature");
});

test("signature verification rejects missing and unsupported signature headers", async () => {
  const fixture = buildWebhook();
  const missing = { ...fixture.headers };
  delete missing["webhook-signature"];
  assert.equal((await ingestProviderWebhook(runtimePool, {
    installation, keys, headers: missing, rawBody: fixture.rawBody
  })).http_status, 401);

  const unsupported = { ...fixture.headers, "webhook-signature": "v9,not-supported" };
  assert.equal((await ingestProviderWebhook(runtimePool, {
    installation, keys, headers: unsupported, rawBody: fixture.rawBody
  })).http_status, 401);
});

test("rotated previous signing key remains accepted while configured", async () => {
  const fixture = buildWebhook({ secret: keys[1].secret });
  const result = await ingest(fixture);
  assert.equal(result.http_status, 202);
  const stored = await inboxRow(fixture.eventId);
  assert.equal(stored.signature_key_id, "previous-v1");
});

test("same provider event ID and exact payload is acknowledged as an idempotent duplicate", async () => {
  const fixture = buildWebhook();
  assert.equal((await ingest(fixture)).http_status, 202);
  const retry = {
    ...fixture,
    headers: signStandardWebhook({
      eventId: fixture.eventId,
      rawBody: fixture.rawBody,
      secret: keys[0].secret,
      timestamp: Math.floor(Date.now() / 1000)
    })
  };
  const duplicate = await ingest(retry);
  assert.equal(duplicate.http_status, 200);
  assert.equal(duplicate.outcome, "duplicate");
  const count = await withEventTransaction(runtimePool, TENANT_A, PRODUCT_A, (client) =>
    client.query("SELECT count(*)::int AS count FROM public.provider_event_inbox WHERE provider_id = $1 AND provider_event_id = $2",
      [installation.provider_id, fixture.eventId])
  );
  assert.equal(count.rows[0].count, 1);
});

test("same provider event ID with a different payload is recorded as a conflict", async () => {
  const eventId = "evt-conflict-" + randomUUID();
  const first = buildWebhook({ eventId, data: { amount: "10.00" } });
  const second = buildWebhook({ eventId, data: { amount: "11.00" } });
  assert.equal((await ingest(first)).http_status, 202);
  const conflict = await ingest(second);
  assert.equal(conflict.http_status, 409);
  assert.equal(conflict.outcome, "event_id_payload_conflict");

  const rows = await withEventTransaction(runtimePool, TENANT_A, PRODUCT_A, (client) =>
    client.query("SELECT count(*)::int AS count FROM public.provider_event_conflicts WHERE provider_id = $1 AND provider_event_id = $2",
      [installation.provider_id, eventId])
  );
  assert.equal(rows.rows[0].count, 1);
});

test("tenant and product identifiers in caller payload cannot override installation scope", async () => {
  const fixture = buildWebhook({
    topLevel: { tenant_id: TENANT_B, product_id: PRODUCT_B }
  });
  assert.equal((await ingest(fixture)).http_status, 202);

  const inA = await inboxRow(fixture.eventId);
  assert.ok(inA);
  const inB = await withEventTransaction(runtimePool, TENANT_B, PRODUCT_B, (client) =>
    client.query("SELECT count(*)::int AS count FROM public.provider_event_inbox WHERE provider_event_id = $1",
      [fixture.eventId])
  );
  assert.equal(inB.rows[0].count, 0);
});

test("payload size, invalid JSON and mismatched event ID fail closed", async () => {
  const oversized = buildWebhook();
  assert.equal((await ingestProviderWebhook(runtimePool, {
    installation, keys, headers: oversized.headers, rawBody: "x".repeat(2048), maxBodyBytes: 128
  })).http_status, 413);

  const rawBody = "{not-json";
  const headers = signStandardWebhook({
    eventId: "evt-invalid-json-" + randomUUID(),
    rawBody, secret: keys[0].secret, timestamp: Math.floor(Date.now() / 1000)
  });
  assert.equal((await ingestProviderWebhook(runtimePool, { installation, keys, headers, rawBody })).http_status, 400);

  const mismatch = buildWebhook();
  const mismatchPayload = JSON.stringify({ ...mismatch.payload, event_id: "different-id" });
  const mismatchHeaders = signStandardWebhook({
    eventId: mismatch.eventId, rawBody: mismatchPayload, secret: keys[0].secret,
    timestamp: Math.floor(Date.now() / 1000)
  });
  const mismatchResult = await ingestProviderWebhook(runtimePool, {
    installation, keys, headers: mismatchHeaders, rawBody: mismatchPayload
  });
  assert.equal(mismatchResult.http_status, 400);
  assert.equal(mismatchResult.reason, "P03_EVENT_ID_MISMATCH");
});

test("unknown or inactive installation is rejected without trusting payload scope", async () => {
  const fixture = buildWebhook();
  const result = await ingestProviderWebhook(runtimePool, {
    installation: { ...installation, active: false },
    keys, headers: fixture.headers, rawBody: fixture.rawBody
  });
  assert.equal(result.http_status, 404);
});

test("adapter creates a provider-neutral CloudEvent without copying tenant identity", async () => {
  const event = adaptToCloudEvent(
    { type: "com.synthetic.example.v1", event_id: "event-1", subject: "account-1", data: { ok: true } },
    installation,
    "event-1"
  );
  assert.equal(event.specversion, "1.0");
  assert.equal(event.id, "event-1");
  assert.equal(event.source, installation.provider_source);
  assert.equal("tenant_id" in event, false);
  assert.deepEqual(event.data, { ok: true });
});

test("inbox worker claims and acknowledges a durable event", async () => {
  const fixture = buildWebhook();
  await ingest(fixture);
  const claimed = await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-a"
  });
  assert.equal(claimed.provider_event_id, fixture.eventId);
  assert.equal(claimed.attempt_count, 1);
  assert.equal(await completeInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, providerId: installation.provider_id,
    eventId: fixture.eventId, workerId: "worker-a", attemptCount: 1
  }), true);
  assert.equal((await inboxRow(fixture.eventId)).status, "processed");
});

test("concurrent inbox workers claim distinct events using SKIP LOCKED", async () => {
  const first = buildWebhook();
  const second = buildWebhook();
  await ingest(first);
  await ingest(second);
  const [claimA, claimB] = await Promise.all([
    claimNextInboxEvent(runtimePool, { tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-a" }),
    claimNextInboxEvent(runtimePool2, { tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-b" })
  ]);
  assert.ok(claimA && claimB);
  assert.notEqual(claimA.provider_event_id, claimB.provider_event_id);
});

test("expired inbox lease is reclaimed and stale worker acknowledgement is rejected", async () => {
  const fixture = buildWebhook();
  await ingest(fixture);
  const now = new Date();
  const first = await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-old", now, leaseSeconds: 1
  });
  const second = await claimNextInboxEvent(runtimePool2, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-new",
    now: new Date(now.getTime() + 2000), leaseSeconds: 30
  });
  assert.equal(second.provider_event_id, fixture.eventId);
  assert.equal(second.attempt_count, 2);
  assert.equal(await completeInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, providerId: installation.provider_id,
    eventId: fixture.eventId, workerId: "worker-old", attemptCount: first.attempt_count
  }), false);
  assert.equal(await completeInboxEvent(runtimePool2, {
    tenantId: TENANT_A, productId: PRODUCT_A, providerId: installation.provider_id,
    eventId: fixture.eventId, workerId: "worker-new", attemptCount: second.attempt_count
  }), true);
});

test("retry uses bounded exponential backoff and event becomes claimable at available_at", async () => {
  const fixture = buildWebhook();
  await ingest(fixture);
  const now = new Date();
  const claimed = await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-retry", now
  });
  const failed = await failInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, providerId: installation.provider_id,
    eventId: fixture.eventId, workerId: "worker-retry", attemptCount: claimed.attempt_count,
    errorCode: "synthetic_timeout", now, baseDelaySeconds: 5, maxDelaySeconds: 60, jitter: 0.2
  });
  assert.equal(failed.status, "retry");
  assert.equal(new Date(failed.available_at).getTime() - now.getTime(), 6000);
  assert.equal(await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "too-early", now: new Date(now.getTime() + 1000)
  }), null);
  const retry = await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "retry-ready",
    now: new Date(now.getTime() + 7000)
  });
  assert.equal(retry.provider_event_id, fixture.eventId);
  assert.equal(retry.attempt_count, 2);
});

test("inbox reaches dead-letter after the configured maximum attempts", async () => {
  const fixture = buildWebhook();
  await ingest(fixture);
  const claimed = await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-dlq"
  });
  const failed = await failInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, providerId: installation.provider_id,
    eventId: fixture.eventId, workerId: "worker-dlq", attemptCount: claimed.attempt_count,
    errorCode: "permanent_processor_failure", maxAttempts: 1
  });
  assert.equal(failed.status, "dead_letter");
  assert.equal(await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "worker-after-dlq"
  }), null);
});

test("provider reconciliation surfaces missing events until they are processed", async () => {
  const fixture = buildWebhook();
  await adminPool.query(
    `INSERT INTO public.provider_event_expectations
      (tenant_id, product_id, provider_id, provider_event_id)
     VALUES ($1, $2, $3, $4)`,
    [TENANT_A, PRODUCT_A, installation.provider_id, fixture.eventId]
  );
  assert.equal((await listProviderEventReconciliation(runtimePool, TENANT_A, PRODUCT_A)).length, 1);
  await ingest(fixture);
  assert.equal((await listProviderEventReconciliation(runtimePool, TENANT_A, PRODUCT_A)).length, 1);
  const claimed = await claimNextInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "reconciliation-worker"
  });
  await completeInboxEvent(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, providerId: installation.provider_id,
    eventId: fixture.eventId, workerId: "reconciliation-worker", attemptCount: claimed.attempt_count
  });
  assert.equal((await listProviderEventReconciliation(runtimePool, TENANT_A, PRODUCT_A)).length, 0);
});

test("outbound event and endpoint identity is idempotent and detects payload drift", async () => {
  const eventId = "out-" + randomUUID();
  const payload = { specversion: "1.0", id: eventId, source: "urn:lottorito:test", type: "com.test.created.v1", data: { amount: "1.00" } };
  const first = await createOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_B, endpointId: "endpoint-a", eventId, payload
  });
  const duplicate = await createOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_B, endpointId: "endpoint-a", eventId, payload
  });
  assert.equal(first.status, "created");
  assert.equal(duplicate.status, "duplicate");
  assert.equal(duplicate.delivery_id, first.delivery_id);
  await assert.rejects(
    createOutboundDelivery(runtimePool, {
      tenantId: TENANT_A, productId: PRODUCT_B, endpointId: "endpoint-a", eventId,
      payload: { ...payload, data: { amount: "2.00" } }
    }),
    (error) => error.code === "P03_OUTBOUND_IDEMPOTENCY_CONFLICT"
  );
});

test("outbound webhook signatures can be verified during key rotation", async () => {
  const eventId = "out-signature-" + randomUUID();
  const rawBody = JSON.stringify({ id: eventId, type: "com.lottorito.example.v1" });
  const headers = signStandardWebhook({
    eventId, rawBody, secret: keys[1].secret, timestamp: Math.floor(Date.now() / 1000)
  });
  const verified = verifyStandardWebhook({ headers, rawBody, keys });
  assert.equal(verified.valid, true);
  assert.equal(verified.keyId, "previous-v1");
});

test("outbound delivery retries transient failures and stops on permanent failures", async () => {
  const eventId = "delivery-" + randomUUID();
  const created = await createOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, endpointId: "endpoint-retry",
    eventId, payload: { id: eventId, type: "com.test.retry.v1" }
  });
  const now = new Date();
  const first = await claimNextOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "sender-a", now
  });
  assert.equal(first.delivery_id, created.delivery_id);
  const retry = await recordOutboundResult(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, deliveryId: first.delivery_id,
    workerId: "sender-a", attemptCount: first.attempt_count, httpStatus: 503,
    errorCode: "upstream_5xx", now, baseDelaySeconds: 5, jitter: 0
  });
  assert.equal(retry.status, "retry");

  const second = await claimNextOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "sender-b",
    now: new Date(now.getTime() + 6000)
  });
  assert.equal(second.attempt_count, 2);
  const failed = await recordOutboundResult(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, deliveryId: second.delivery_id,
    workerId: "sender-b", attemptCount: second.attempt_count, httpStatus: 400,
    errorCode: "invalid_endpoint_request"
  });
  assert.equal(failed.status, "failed");
});

test("outbound delivery lease prevents stale sender acknowledgement", async () => {
  const eventId = "delivery-lease-" + randomUUID();
  const created = await createOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, endpointId: "endpoint-lease",
    eventId, payload: { id: eventId, type: "com.test.lease.v1" }
  });
  const now = new Date();
  const first = await claimNextOutboundDelivery(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "sender-old", now, leaseSeconds: 1
  });
  const second = await claimNextOutboundDelivery(runtimePool2, {
    tenantId: TENANT_A, productId: PRODUCT_A, workerId: "sender-new",
    now: new Date(now.getTime() + 2000), leaseSeconds: 30
  });
  assert.equal(second.delivery_id, created.delivery_id);
  assert.equal(second.attempt_count, 2);
  const stale = await recordOutboundResult(runtimePool, {
    tenantId: TENANT_A, productId: PRODUCT_A, deliveryId: first.delivery_id,
    workerId: "sender-old", attemptCount: first.attempt_count, httpStatus: 200
  });
  assert.equal(stale.accepted, false);
  assert.equal(stale.status, "stale_attempt");
  const delivered = await recordOutboundResult(runtimePool2, {
    tenantId: TENANT_A, productId: PRODUCT_A, deliveryId: second.delivery_id,
    workerId: "sender-new", attemptCount: second.attempt_count, httpStatus: 204
  });
  assert.equal(delivered.status, "delivered");
});

test("missing tenant/product context defaults to no visible inbox rows", async () => {
  const result = await runtimePool.query("SELECT count(*)::int AS count FROM public.provider_event_inbox");
  assert.equal(result.rows[0].count, 0);
});
