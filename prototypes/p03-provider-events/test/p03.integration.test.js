import test from "node:test";
import assert from "node:assert/strict";
import { createHash, randomUUID } from "node:crypto";
import { Pool } from "pg";
import {
  ingestProviderWebhook,
  processProviderEvent,
  reconcileProviderEvents,
  signProviderPayload,
  verifyProviderSignature
} from "../src/provider-events.js";

const adminPool = new Pool({ connectionString: process.env.ADMIN_DATABASE_URL, max: 2 });
const tenantAPool = new Pool({ connectionString: process.env.TENANT_A_DATABASE_URL, max: 3 });
const tenantASecondPool = new Pool({ connectionString: process.env.TENANT_A_DATABASE_URL, max: 2 });
const tenantBPool = new Pool({ connectionString: process.env.TENANT_B_DATABASE_URL, max: 2 });

const SECRET_A = "p03-synthetic-provider-secret-for-tenant-a";
const SECRET_B = "p03-synthetic-provider-secret-for-tenant-b";
const ENDPOINT_A = { providerId: "synthetic_payments", providerAccountId: "acct-a-001", keyId: "synthetic-key-a-v1", secret: SECRET_A };
const ENDPOINT_B = { providerId: "synthetic_payments", providerAccountId: "acct-b-001", keyId: "synthetic-key-b-v1", secret: SECRET_B };
const now = Math.floor(Date.now() / 1000);

function event(overrides = {}) {
  return {
    event_id: "evt-" + randomUUID(),
    event_type: "transaction.settled",
    provider_account_id: "acct-a-001",
    occurred_at: new Date().toISOString(),
    amount_minor: "2500",
    currency_code: "USD",
    reference: "synthetic-reference",
    ...overrides
  };
}

async function deliver(pool, endpoint, payload, options = {}) {
  const raw = Buffer.from(JSON.stringify(payload));
  const timestamp = options.timestamp ?? now;
  const header = options.header ?? signProviderPayload(raw, endpoint.secret, timestamp);
  return ingestProviderWebhook(pool, endpoint, raw, header, options.nowSeconds ?? now);
}

async function inboxCount(tenantId, providerEventId) {
  const result = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.provider_inbox WHERE tenant_id = $1 AND provider_event_id = $2",
    [tenantId, providerEventId]
  );
  return result.rows[0].count;
}

test.after(async () => {
  await tenantAPool.end();
  await tenantASecondPool.end();
  await tenantBPool.end();
  await adminPool.end();
});

test("raw-body HMAC signature verification accepts the signed payload", () => {
  const raw = Buffer.from('{"event_id":"evt-unit","event_type":"transaction.settled"}');
  const header = signProviderPayload(raw, SECRET_A, now);
  assert.deepEqual(verifyProviderSignature(raw, header, SECRET_A, now), { timestamp: now });
});

test("signature verification rejects a modified signature and a stale timestamp", () => {
  const raw = Buffer.from('{"event_id":"evt-invalid","event_type":"transaction.settled"}');
  const header = signProviderPayload(raw, SECRET_A, now);
  const altered = header.slice(0, -1) + (header.endsWith("0") ? "1" : "0");
  assert.throws(() => verifyProviderSignature(raw, altered, SECRET_A, now), (error) => error.code === "P03_BAD_SIGNATURE");
  const stale = signProviderPayload(raw, SECRET_A, now - 301);
  assert.throws(() => verifyProviderSignature(raw, stale, SECRET_A, now), (error) => error.code === "P03_STALE_SIGNATURE");
});

test("signature parser rejects duplicate timestamp fields", () => {
  const raw = Buffer.from("{}");
  const valid = signProviderPayload(raw, SECRET_A, now);
  assert.throws(() => verifyProviderSignature(raw, valid + ",t=" + now, SECRET_A, now),
    (error) => error.code === "P03_SIGNATURE_HEADER");
});

test("oversized raw payload is rejected before JSON parsing or database access", () => {
  const raw = Buffer.alloc(64 * 1024 + 1, 0x61);
  assert.throws(() => verifyProviderSignature(raw, "t=1,v1=" + "0".repeat(64), SECRET_A, now),
    (error) => error.code === "P03_BODY_TOO_LARGE" && error.status === 413);
});

test("a valid signed settled event is stored in the tenant inbox and accepted outbox", async () => {
  const payload = event({ event_id: "evt-p03-valid-001" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  assert.equal(received.duplicate, false);
  const rows = await adminPool.query(
    "SELECT i.provider_event_id, i.event_type, p.status, o.event_type AS outbox_type FROM public.provider_inbox i JOIN public.provider_event_processing p USING (tenant_id, inbox_id) JOIN public.provider_inbox_outbox o USING (tenant_id, inbox_id) WHERE i.tenant_id = $1 AND i.inbox_id = $2",
    ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", received.inbox_id]
  );
  assert.deepEqual(rows.rows, [{
    provider_event_id: payload.event_id,
    event_type: "transaction.settled",
    status: "received",
    outbox_type: "provider.event.accepted"
  }]);
});

test("the same signed provider event is deduplicated without a second inbox or outbox row", async () => {
  const payload = event({ event_id: "evt-p03-duplicate-001" });
  const raw = Buffer.from(JSON.stringify(payload));
  const signature = signProviderPayload(raw, SECRET_A, now);
  const first = await ingestProviderWebhook(tenantAPool, ENDPOINT_A, raw, signature, now);
  const second = await ingestProviderWebhook(tenantAPool, ENDPOINT_A, raw, signature, now);
  assert.equal(first.inbox_id, second.inbox_id);
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(await inboxCount("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", payload.event_id), 1);
  const outbox = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.provider_inbox_outbox WHERE tenant_id = $1 AND inbox_id = $2",
    ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", first.inbox_id]
  );
  assert.equal(outbox.rows[0].count, 1);
});

test("same provider event identity with changed payload hash is rejected", async () => {
  const payload = event({ event_id: "evt-p03-tamper-001" });
  await deliver(tenantAPool, ENDPOINT_A, payload);
  await assert.rejects(
    deliver(tenantAPool, ENDPOINT_A, { ...payload, amount_minor: "2501" }),
    (error) => error.code === "22023" && error.message.includes("different payload content")
  );
  assert.equal(await inboxCount("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", payload.event_id), 1);
});

test("bad signatures are rejected before any inbox persistence", async () => {
  const payload = event({ event_id: "evt-p03-bad-signature" });
  const raw = Buffer.from(JSON.stringify(payload));
  const signature = signProviderPayload(raw, SECRET_A, now);
  const altered = signature.slice(0, -1) + (signature.endsWith("0") ? "1" : "0");
  await assert.rejects(
    ingestProviderWebhook(tenantAPool, ENDPOINT_A, raw, altered, now),
    (error) => error.code === "P03_BAD_SIGNATURE" && error.status === 401
  );
  assert.equal(await inboxCount("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", payload.event_id), 0);
});

test("trusted endpoint account binding rejects a body that names another provider account", async () => {
  const payload = event({ event_id: "evt-p03-account-mismatch", provider_account_id: "acct-b-001" });
  await assert.rejects(
    deliver(tenantAPool, ENDPOINT_A, payload),
    (error) => error.code === "P03_ACCOUNT_MISMATCH" && error.status === 403
  );
});

test("an unmapped provider account cannot create a tenant inbox event", async () => {
  const endpoint = { ...ENDPOINT_A, providerAccountId: "acct-unmapped-001" };
  const payload = event({ event_id: "evt-p03-unmapped", provider_account_id: endpoint.providerAccountId });
  await assert.rejects(deliver(tenantAPool, endpoint, payload), (error) => error.code === "42501");
});

test("processing a settled event posts exactly one P02 journal and marks the inbox processed", async () => {
  const payload = event({ event_id: "evt-p03-process-001", amount_minor: "6789" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  const processed = await processProviderEvent(tenantAPool, received.inbox_id);
  assert.equal(processed.processing_status, "processed");
  assert.equal(processed.duplicate, false);
  assert.ok(processed.journal_id);
  const lines = await adminPool.query(
    "SELECT direction, amount_minor::text AS amount_minor, currency_code FROM public.ledger_lines WHERE tenant_id = $1 AND journal_id = $2 ORDER BY line_no",
    ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", processed.journal_id]
  );
  assert.deepEqual(lines.rows, [
    { direction: "debit", amount_minor: "6789", currency_code: "USD" },
    { direction: "credit", amount_minor: "6789", currency_code: "USD" }
  ]);
});

test("reprocessing a settled event returns the same journal and creates no second ledger outbox event", async () => {
  const payload = event({ event_id: "evt-p03-process-retry-001", amount_minor: "1200" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  const first = await processProviderEvent(tenantAPool, received.inbox_id);
  const second = await processProviderEvent(tenantAPool, received.inbox_id);
  assert.equal(second.journal_id, first.journal_id);
  assert.equal(second.processing_status, "processed");
  assert.equal(second.duplicate, true);
  const events = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.ledger_outbox WHERE tenant_id = $1 AND journal_id = $2",
    ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", first.journal_id]
  );
  assert.equal(events.rows[0].count, 1);
});

test("concurrent processing of one inbox event serializes to one journal", async () => {
  const payload = event({ event_id: "evt-p03-concurrent-001", amount_minor: "3300" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  const [left, right] = await Promise.all([
    processProviderEvent(tenantAPool, received.inbox_id),
    processProviderEvent(tenantASecondPool, received.inbox_id)
  ]);
  assert.equal(left.journal_id, right.journal_id);
  assert.deepEqual([left.duplicate, right.duplicate].sort(), [false, true]);
});

test("unsupported event types are quarantined without posting a ledger journal", async () => {
  const payload = event({ event_id: "evt-p03-unsupported-001", event_type: "account.profile.updated" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  const processed = await processProviderEvent(tenantAPool, received.inbox_id);
  assert.equal(processed.processing_status, "quarantined");
  assert.equal(processed.journal_id, null);
  const state = await adminPool.query(
    "SELECT status, last_error FROM public.provider_event_processing WHERE tenant_id = $1 AND inbox_id = $2",
    ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", received.inbox_id]
  );
  assert.deepEqual(state.rows, [{ status: "quarantined", last_error: "unsupported_event_type" }]);
});

test("invalid amount strings are quarantined and never reach the financial ledger", async () => {
  const payload = event({ event_id: "evt-p03-invalid-amount", amount_minor: "1.5" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  const processed = await processProviderEvent(tenantAPool, received.inbox_id);
  assert.equal(processed.processing_status, "quarantined");
  assert.equal(processed.journal_id, null);
});

test("an unmapped currency is quarantined without a journal", async () => {
  const payload = event({ event_id: "evt-p03-unmapped-currency", currency_code: "JPY" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  const processed = await processProviderEvent(tenantAPool, received.inbox_id);
  assert.equal(processed.processing_status, "quarantined");
  assert.equal(processed.journal_id, null);
});

test("tenant B cannot process tenant A inbox identifiers", async () => {
  const payload = event({ event_id: "evt-p03-cross-tenant-001" });
  const received = await deliver(tenantAPool, ENDPOINT_A, payload);
  await assert.rejects(
    processProviderEvent(tenantBPool, received.inbox_id),
    (error) => error.code === "P0002"
  );
});

test("tenant B can process its own provider account event", async () => {
  const payload = event({ event_id: "evt-p03-tenant-b-001", provider_account_id: ENDPOINT_B.providerAccountId });
  const received = await deliver(tenantBPool, ENDPOINT_B, payload);
  const processed = await processProviderEvent(tenantBPool, received.inbox_id);
  assert.equal(processed.processing_status, "processed");
  assert.ok(processed.journal_id);
});

test("tenant runtime roles cannot read provider inbox or processing tables directly", async () => {
  await assert.rejects(tenantAPool.query("SELECT * FROM public.provider_inbox"), (error) => error.code === "42501");
  await assert.rejects(tenantAPool.query("UPDATE public.provider_event_processing SET status = 'processed'"), (error) => error.code === "42501");
});

test("reconciliation reports processed and quarantined events with no synthetic exceptions", async () => {
  const result = await reconcileProviderEvents(tenantAPool);
  assert.equal(result.pending_count, 0);
  assert.ok(result.processed_count >= 1);
  assert.ok(result.quarantined_count >= 1);
  assert.equal(result.exception_count, 0);
});

test("inbox and accepted-outbox writes roll back together on outbox failure", async () => {
  const payload = event({ event_id: "evt-p03-outbox-failure" });
  const raw = Buffer.from(JSON.stringify(payload));
  const header = signProviderPayload(raw, SECRET_A, now);
  await adminPool.query("CREATE OR REPLACE FUNCTION public.p03_test_fail_provider_outbox() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'synthetic provider outbox failure' USING ERRCODE = 'P0001'; END $$");
  await adminPool.query("CREATE TRIGGER p03_test_fail_provider_outbox BEFORE INSERT ON public.provider_inbox_outbox FOR EACH ROW EXECUTE FUNCTION public.p03_test_fail_provider_outbox()");
  try {
    await assert.rejects(
      ingestProviderWebhook(tenantAPool, ENDPOINT_A, raw, header, now),
      (error) => error.code === "P0001"
    );
  } finally {
    await adminPool.query("DROP TRIGGER IF EXISTS p03_test_fail_provider_outbox ON public.provider_inbox_outbox");
    await adminPool.query("DROP FUNCTION IF EXISTS public.p03_test_fail_provider_outbox()");
  }
  assert.equal(await inboxCount("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", payload.event_id), 0);
});
