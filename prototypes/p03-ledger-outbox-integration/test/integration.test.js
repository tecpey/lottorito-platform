import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { Pool } from "pg";
import { postJournal } from "../../p02-ledger-posting/src/posting.js";
import {
  claimOutboxEvents,
  acknowledgeOutboxEvent,
  rejectOutboxEvent,
  consumeOutboxEvent
} from "../src/relay.js";

const adminUrl = process.env.ADMIN_DATABASE_URL;
const tenantAUrl = process.env.TENANT_A_DATABASE_URL;
const tenantBUrl = process.env.TENANT_B_DATABASE_URL;
assert.ok(adminUrl, "ADMIN_DATABASE_URL must target the disposable P-03C database");
assert.ok(tenantAUrl, "TENANT_A_DATABASE_URL must authenticate as tenant_a_ledger_runtime");
assert.ok(tenantBUrl, "TENANT_B_DATABASE_URL must authenticate as tenant_b_ledger_runtime");

const TENANT_A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const TENANT_B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const A_USD_CASH = "11111111-1111-4111-8111-111111111101";
const A_USD_CLEARING = "11111111-1111-4111-8111-111111111102";
const B_USD_CASH = "22222222-2222-4222-8222-222222222201";
const B_USD_CLEARING = "22222222-2222-4222-8222-222222222202";

const adminPool = new Pool({ connectionString: adminUrl, max: 3 });
const tenantAPool = new Pool({ connectionString: tenantAUrl, max: 3 });
const tenantASecondPool = new Pool({ connectionString: tenantAUrl, max: 2 });
const tenantBPool = new Pool({ connectionString: tenantBUrl, max: 2 });

function request(key, tenantId = TENANT_A, amount = "12500", effectId = randomUUID(), sourceEventId = randomUUID()) {
  const debit = tenantId === TENANT_A ? A_USD_CASH : B_USD_CASH;
  const credit = tenantId === TENANT_A ? A_USD_CLEARING : B_USD_CLEARING;
  return {
    idempotency_key: key,
    effect_id: effectId,
    source_event_id: sourceEventId,
    lines: [
      { line_no: 1, account_id: debit, currency_code: "USD", direction: "debit", amount_minor: amount },
      { line_no: 2, account_id: credit, currency_code: "USD", direction: "credit", amount_minor: amount }
    ]
  };
}

async function postAndFetch(pool, tenantId, key, amount = "12500") {
  const input = request(key, tenantId, amount);
  const posted = await postJournal(pool, input);
  const result = await adminPool.query(
    `SELECT e.event_id, e.journal_id, e.event_type, e.payload, d.status, d.attempts
       FROM public.ledger_outbox e
       JOIN public.outbox_delivery_state d
         ON d.tenant_id = e.tenant_id AND d.event_id = e.event_id
      WHERE e.tenant_id = $1 AND e.journal_id = $2`,
    [tenantId, posted.journal_id]
  );
  assert.equal(result.rowCount, 1, "each committed ledger outbox event must have one delivery-state row");
  return { ...posted, event: result.rows[0], input };
}

async function ackEvent(pool, eventId, workerId = "p03c-test-worker") {
  const claims = await claimOutboxEvents(pool, { workerId, batchSize: 100, leaseSeconds: 30 });
  const event = claims.find((item) => item.event_id === eventId);
  assert.ok(event, "expected event must be claimable by its tenant");
  assert.equal(await acknowledgeOutboxEvent(pool, eventId, event.lease_token), true);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test.after(async () => {
  await tenantAPool.end();
  await tenantASecondPool.end();
  await tenantBPool.end();
  await adminPool.end();
});

test("P-02 posting creates one immutable ledger event and one pending P-03 delivery row atomically", async () => {
  const posted = await postAndFetch(tenantAPool, TENANT_A, "p03c-atomic-001");
  assert.equal(posted.duplicate, false);
  assert.equal(posted.event.status, "pending");
  assert.equal(posted.event.attempts, 0);
  assert.equal(posted.event.event_type, "ledger.journal.posted");
  assert.equal(posted.event.payload.journal_id, posted.journal_id);
  assert.equal(posted.event.payload.effect_id, posted.input.effect_id);
  assert.equal(posted.event.payload.source_event_id, posted.input.source_event_id);
  await assert.rejects(
    adminPool.query("UPDATE public.ledger_outbox SET payload='{}'::jsonb WHERE tenant_id=$1 AND event_id=$2", [TENANT_A, posted.event.event_id]),
    (error) => error.code === "55000"
  );
  await ackEvent(tenantAPool, posted.event.event_id);
});

test("idempotent posting retry returns the original journal and does not duplicate delivery state", async () => {
  const input = request("p03c-idempotent-001");
  const first = await postJournal(tenantAPool, input);
  const second = await postJournal(tenantAPool, input);
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(second.journal_id, first.journal_id);
  const counts = await adminPool.query(
    `SELECT
       (SELECT count(*)::int FROM public.ledger_outbox WHERE tenant_id=$1 AND journal_id=$2) AS events,
       (SELECT count(*)::int FROM public.outbox_delivery_state d JOIN public.ledger_outbox e USING(tenant_id,event_id)
         WHERE d.tenant_id=$1 AND e.journal_id=$2) AS delivery_rows`,
    [TENANT_A, first.journal_id]
  );
  assert.deepEqual(counts.rows[0], { events: 1, delivery_rows: 1 });
  const [event] = await adminPool.query(
    "SELECT event_id FROM public.ledger_outbox WHERE tenant_id=$1 AND journal_id=$2",
    [TENANT_A, first.journal_id]
  ).then((r) => r.rows);
  await ackEvent(tenantAPool, event.event_id);
});

test("alternate request keys for one financial effect do not create a second event", async () => {
  const effectId = randomUUID();
  const firstInput = request("p03c-alias-a", TENANT_A, "700", effectId);
  const secondInput = request("p03c-alias-b", TENANT_A, "700", effectId, firstInput.source_event_id);
  const first = await postJournal(tenantAPool, firstInput);
  const second = await postJournal(tenantAPool, secondInput);
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(second.journal_id, first.journal_id);
  const rows = await adminPool.query(
    "SELECT event_id FROM public.ledger_outbox WHERE tenant_id=$1 AND journal_id=$2",
    [TENANT_A, first.journal_id]
  );
  assert.equal(rows.rowCount, 1);
  await ackEvent(tenantAPool, rows.rows[0].event_id);
});

test("transaction rollback removes journal, ledger outbox and delivery state together", async () => {
  const client = await tenantAPool.connect();
  const input = request("p03c-rollback-001");
  let journalId;
  try {
    await client.query("BEGIN");
    const posted = await postJournal(client, input);
    journalId = posted.journal_id;
    await client.query("ROLLBACK");
  } finally {
    client.release();
  }
  const rows = await adminPool.query(
    `SELECT
       (SELECT count(*)::int FROM public.ledger_journals WHERE tenant_id=$1 AND journal_id=$2) AS journals,
       (SELECT count(*)::int FROM public.ledger_outbox WHERE tenant_id=$1 AND journal_id=$2) AS events,
       (SELECT count(*)::int FROM public.outbox_delivery_state d JOIN public.ledger_outbox e USING(tenant_id,event_id)
         WHERE d.tenant_id=$1 AND e.journal_id=$2) AS delivery_rows`,
    [TENANT_A, journalId]
  );
  assert.deepEqual(rows.rows[0], { journals: 0, events: 0, delivery_rows: 0 });
});

test("P-03C uses P-02 ledger_outbox as the only source event table", async () => {
  const result = await adminPool.query(
    "SELECT to_regclass('public.ledger_outbox')::text AS ledger_source,to_regclass('public.outbox_events')::text AS duplicate_source"
  );
  assert.equal(result.rows[0].ledger_source, "ledger_outbox");
  assert.equal(result.rows[0].duplicate_source, null);
});

test("tenant A cannot claim or consume tenant B ledger events", async () => {
  const postedB = await postAndFetch(tenantBPool, TENANT_B, "p03c-tenant-b-001");
  const aClaims = await claimOutboxEvents(tenantAPool, { workerId: "tenant-a-worker", batchSize: 100, leaseSeconds: 30 });
  assert.equal(aClaims.some((event) => event.event_id === postedB.event.event_id), false);
  const bClaims = await claimOutboxEvents(tenantBPool, { workerId: "tenant-b-worker", batchSize: 100, leaseSeconds: 30 });
  const target = bClaims.find((event) => event.event_id === postedB.event.event_id);
  assert.ok(target);
  assert.equal(target.aggregate_id, postedB.journal_id);
  assert.equal(await acknowledgeOutboxEvent(tenantBPool, target.event_id, target.lease_token), true);
  await assert.rejects(
    consumeOutboxEvent(tenantAPool, "tenant-a-consumer", postedB.event.event_id),
    (error) => error.code === "P0002"
  );
});

test("concurrent workers claim disjoint ledger events with SKIP LOCKED semantics", async () => {
  const first = await postAndFetch(tenantAPool, TENANT_A, "p03c-concurrent-a");
  const second = await postAndFetch(tenantAPool, TENANT_A, "p03c-concurrent-b");
  const [left, right] = await Promise.all([
    claimOutboxEvents(tenantAPool, { workerId: "worker-left", batchSize: 1, leaseSeconds: 30 }),
    claimOutboxEvents(tenantASecondPool, { workerId: "worker-right", batchSize: 1, leaseSeconds: 30 })
  ]);
  assert.equal(left.length, 1);
  assert.equal(right.length, 1);
  assert.notEqual(left[0].event_id, right[0].event_id);
  assert.deepEqual(new Set([left[0].event_id, right[0].event_id]), new Set([first.event.event_id, second.event.event_id]));
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, left[0].event_id, left[0].lease_token), true);
  assert.equal(await acknowledgeOutboxEvent(tenantASecondPool, right[0].event_id, right[0].lease_token), true);
});

test("expired lease is reclaimed with a fresh token and stale worker is fenced", async () => {
  const posted = await postAndFetch(tenantAPool, TENANT_A, "p03c-lease-001");
  const [first] = await claimOutboxEvents(tenantAPool, { workerId: "slow-worker", batchSize: 1, leaseSeconds: 1 });
  assert.equal(first.event_id, posted.event.event_id);
  await sleep(1100);
  const [second] = await claimOutboxEvents(tenantASecondPool, { workerId: "replacement-worker", batchSize: 1, leaseSeconds: 10 });
  assert.equal(second.event_id, posted.event.event_id);
  assert.notEqual(second.lease_token, first.lease_token);
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, posted.event.event_id, first.lease_token), false);
  assert.equal(await acknowledgeOutboxEvent(tenantASecondPool, posted.event.event_id, second.lease_token), true);
});

test("retry limit transitions a ledger event to dead-letter state", async () => {
  const posted = await postAndFetch(tenantAPool, TENANT_A, "p03c-dead-001");
  await adminPool.query(
    "UPDATE public.outbox_delivery_state SET max_attempts=2 WHERE tenant_id=$1 AND event_id=$2",
    [TENANT_A, posted.event.event_id]
  );
  const [first] = await claimOutboxEvents(tenantAPool, { workerId: "retry-worker", batchSize: 1, leaseSeconds: 30 });
  assert.equal(await rejectOutboxEvent(tenantAPool, posted.event.event_id, first.lease_token, "temporary outage", 0), "pending");
  const [second] = await claimOutboxEvents(tenantAPool, { workerId: "retry-worker", batchSize: 1, leaseSeconds: 30 });
  assert.equal(second.attempt, 2);
  assert.equal(await rejectOutboxEvent(tenantAPool, posted.event.event_id, second.lease_token, "permanent failure", 0), "dead");
  assert.equal((await claimOutboxEvents(tenantAPool, { workerId: "retry-worker", batchSize: 100, leaseSeconds: 30 }))
    .some((event) => event.event_id === posted.event.event_id), false);
});

test("consumer inbox and synthetic effect are committed once under concurrent redelivery", async () => {
  const posted = await postAndFetch(tenantAPool, TENANT_A, "p03c-consumer-001");
  const [left, right] = await Promise.all([
    consumeOutboxEvent(tenantAPool, "affiliate-projection-v1", posted.event.event_id),
    consumeOutboxEvent(tenantASecondPool, "affiliate-projection-v1", posted.event.event_id)
  ]);
  assert.deepEqual([left, right].sort(), [false, true]);
  const counts = await adminPool.query(
    `SELECT
       (SELECT count(*)::int FROM public.consumer_inbox WHERE tenant_id=$1 AND event_id=$2) AS inbox_count,
       (SELECT count(*)::int FROM public.consumer_effects WHERE tenant_id=$1 AND event_id=$2) AS effect_count`,
    [TENANT_A, posted.event.event_id]
  );
  assert.deepEqual(counts.rows[0], { inbox_count: 1, effect_count: 1 });
  await ackEvent(tenantAPool, posted.event.event_id);
});

test("publish-before-ack crash window redelivers but consumer effect remains idempotent", async () => {
  const posted = await postAndFetch(tenantAPool, TENANT_A, "p03c-crash-001");
  const broker = [];
  const [first] = await claimOutboxEvents(tenantAPool, { workerId: "crash-worker", batchSize: 1, leaseSeconds: 1 });
  broker.push(first);
  await sleep(1100);
  const [replacement] = await claimOutboxEvents(tenantASecondPool, { workerId: "recovery-worker", batchSize: 1, leaseSeconds: 10 });
  assert.equal(replacement.event_id, posted.event.event_id);
  broker.push(replacement);
  assert.equal(await acknowledgeOutboxEvent(tenantASecondPool, replacement.event_id, replacement.lease_token), true);
  assert.equal(broker.length, 2);
  assert.equal(await consumeOutboxEvent(tenantAPool, "financial-reporting-v1", posted.event.event_id), true);
  assert.equal(await consumeOutboxEvent(tenantASecondPool, "financial-reporting-v1", posted.event.event_id), false);
});

test("tenant runtime cannot directly read or mutate ledger and delivery tables", async () => {
  for (const query of [
    "SELECT * FROM public.ledger_outbox",
    "SELECT * FROM public.outbox_delivery_state",
    "SELECT * FROM public.consumer_inbox",
    "SELECT * FROM public.consumer_effects",
    "UPDATE public.outbox_delivery_state SET status='published'"
  ]) {
    await assert.rejects(
      tenantAPool.query(query),
      (error) => error.code === "42501"
    );
  }
});

test("unmapped database identity cannot claim outbox work", async () => {
  await assert.rejects(
    adminPool.query("SELECT * FROM public.claim_outbox_events(1,30,'unmapped-admin')"),
    (error) => error.code === "42501" && error.message.includes("not mapped to a tenant")
  );
});

test("invalid claim and consumer parameters fail closed", async () => {
  await assert.rejects(
    claimOutboxEvents(tenantAPool, { workerId: "bad worker", batchSize: 1, leaseSeconds: 30 }),
    TypeError
  );
  await assert.rejects(
    tenantAPool.query("SELECT * FROM public.claim_outbox_events(101,30,'worker')"),
    (error) => error.code === "22023"
  );
  await assert.rejects(
    tenantAPool.query("SELECT public.consume_outbox_event('bad consumer',gen_random_uuid())"),
    (error) => error.code === "22023"
  );
});

test("the ledger outbox delivery trigger fails closed if tenant context is absent", async () => {
  const input = request("p03c-unmapped-post-001");
  await assert.rejects(
    adminPool.query(
      "SELECT * FROM public.post_journal($1,$2,$3,$4::jsonb)",
      [input.idempotency_key, input.effect_id, input.source_event_id, JSON.stringify(input.lines)]
    ),
    (error) => error.code === "42501"
  );
});
