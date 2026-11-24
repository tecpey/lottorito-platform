import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { Pool } from "pg";
import { claimOutboxEvents, acknowledgeOutboxEvent, rejectOutboxEvent, consumeOutboxEvent, deliverOutboxBatch } from "../src/relay.js";

const adminUrl = process.env.ADMIN_DATABASE_URL;
const tenantAUrl = process.env.TENANT_A_DATABASE_URL;
const tenantBUrl = process.env.TENANT_B_DATABASE_URL;
assert.ok(adminUrl, "ADMIN_DATABASE_URL must target the disposable P-03 database");
assert.ok(tenantAUrl, "TENANT_A_DATABASE_URL must authenticate as tenant_a_outbox_runtime");
assert.ok(tenantBUrl, "TENANT_B_DATABASE_URL must authenticate as tenant_b_outbox_runtime");
const TENANT_A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const TENANT_B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const adminPool = new Pool({ connectionString: adminUrl, max: 2 });
const tenantAPool = new Pool({ connectionString: tenantAUrl, max: 2 });
const tenantASecondPool = new Pool({ connectionString: tenantAUrl, max: 1 });
const tenantBPool = new Pool({ connectionString: tenantBUrl, max: 2 });

async function seedEvent(tenantId = TENANT_A, { maxAttempts = 3, payload = { journal_id: randomUUID(), effect_id: randomUUID() } } = {}) {
  const eventId = randomUUID();
  const aggregateId = randomUUID();
  await adminPool.query(
    "INSERT INTO public.outbox_events(tenant_id,event_id,aggregate_id,event_type,payload) VALUES($1,$2,$3,'ledger.journal.posted',$4::jsonb)",
    [tenantId, eventId, aggregateId, JSON.stringify(payload)]
  );
  await adminPool.query(
    "INSERT INTO public.outbox_delivery_state(tenant_id,event_id,max_attempts) VALUES($1,$2,$3)",
    [tenantId, eventId, maxAttempts]
  );
  return { eventId, aggregateId, payload };
}

async function stateFor(tenantId, eventId) {
  const result = await adminPool.query(
    "SELECT status,attempts,lease_owner,lease_token,lease_until,published_at,last_error FROM public.outbox_delivery_state WHERE tenant_id=$1 AND event_id=$2",
    [tenantId, eventId]
  );
  return result.rows[0];
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test.after(async () => {
  await tenantAPool.end();
  await tenantASecondPool.end();
  await tenantBPool.end();
  await adminPool.end();
});

test("claim is tenant-scoped and returns the immutable event envelope", async () => {
  const a = await seedEvent(TENANT_A);
  const b = await seedEvent(TENANT_B);
  const claimed = await claimOutboxEvents(tenantAPool, { workerId: "tenant-a-worker", batchSize: 10, leaseSeconds: 30 });
  assert.equal(claimed.length, 1);
  assert.equal(claimed[0].event_id, a.eventId);
  assert.deepEqual(claimed[0].payload, a.payload);
  assert.equal((await stateFor(TENANT_A, a.eventId)).status, "leased");
  assert.equal((await stateFor(TENANT_B, b.eventId)).status, "pending");
  await assert.rejects(
    consumeOutboxEvent(tenantAPool, "tenant-a-consumer", b.eventId),
    (error) => error.code === "P0002"
  );
});

test("concurrent workers claim disjoint rows using SKIP LOCKED semantics", async () => {
  const first = await seedEvent();
  const second = await seedEvent();
  const [left, right] = await Promise.all([
    claimOutboxEvents(tenantAPool, { workerId: "worker-left", batchSize: 1, leaseSeconds: 30 }),
    claimOutboxEvents(tenantASecondPool, { workerId: "worker-right", batchSize: 1, leaseSeconds: 30 })
  ]);
  assert.equal(left.length, 1);
  assert.equal(right.length, 1);
  assert.notEqual(left[0].event_id, right[0].event_id);
  assert.deepEqual(new Set([left[0].event_id, right[0].event_id]), new Set([first.eventId, second.eventId]));
});

test("only the current unexpired lease token can acknowledge delivery", async () => {
  const event = await seedEvent();
  const [claim] = await claimOutboxEvents(tenantAPool, { workerId: "ack-worker", batchSize: 1, leaseSeconds: 30 });
  assert.equal(claim.event_id, event.eventId);
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, event.eventId, randomUUID()), false);
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, event.eventId, claim.lease_token), true);
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, event.eventId, claim.lease_token), false);
  assert.equal((await stateFor(TENANT_A, event.eventId)).status, "published");
});

test("expired leases can be reclaimed and stale workers are fenced from ack", async () => {
  const event = await seedEvent();
  const [first] = await claimOutboxEvents(tenantAPool, { workerId: "slow-worker", batchSize: 1, leaseSeconds: 1 });
  await sleep(1100);
  const [second] = await claimOutboxEvents(tenantASecondPool, { workerId: "replacement-worker", batchSize: 1, leaseSeconds: 10 });
  assert.equal(second.event_id, event.eventId);
  assert.notEqual(second.lease_token, first.lease_token);
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, event.eventId, first.lease_token), false);
  assert.equal(await acknowledgeOutboxEvent(tenantASecondPool, event.eventId, second.lease_token), true);
});

test("negative acknowledgement retries then dead-letters at the configured attempt limit", async () => {
  const event = await seedEvent(TENANT_A, { maxAttempts: 2 });
  const [first] = await claimOutboxEvents(tenantAPool, { workerId: "retry-worker", batchSize: 1, leaseSeconds: 30 });
  assert.equal(await rejectOutboxEvent(tenantAPool, event.eventId, first.lease_token, new Error("temporary broker outage"), 0), "pending");
  const [second] = await claimOutboxEvents(tenantAPool, { workerId: "retry-worker", batchSize: 1, leaseSeconds: 30 });
  assert.equal(second.attempt, 2);
  assert.equal(await rejectOutboxEvent(tenantAPool, event.eventId, second.lease_token, "permanent test failure", 0), "dead");
  assert.equal((await claimOutboxEvents(tenantAPool, { workerId: "retry-worker", batchSize: 10, leaseSeconds: 30 })).length, 0);
  const state = await stateFor(TENANT_A, event.eventId);
  assert.equal(state.status, "dead");
  assert.equal(state.attempts, 2);
  assert.equal(state.last_error, "permanent test failure");
});

test("consumer inbox deduplicates concurrent deliveries atomically with the effect record", async () => {
  const event = await seedEvent();
  const [left, right] = await Promise.all([
    consumeOutboxEvent(tenantAPool, "affiliate-projection-v1", event.eventId),
    consumeOutboxEvent(tenantASecondPool, "affiliate-projection-v1", event.eventId)
  ]);
  assert.deepEqual([left, right].sort(), [false, true]);
  const rows = await adminPool.query(
    "SELECT (SELECT count(*)::int FROM public.consumer_inbox WHERE tenant_id=$1 AND event_id=$2) AS inbox_count,(SELECT count(*)::int FROM public.consumer_effects WHERE tenant_id=$1 AND event_id=$2) AS effect_count",
    [TENANT_A, event.eventId]
  );
  assert.deepEqual(rows.rows[0], { inbox_count: 1, effect_count: 1 });
  const [claim] = await claimOutboxEvents(tenantAPool, { workerId: "consumer-test-cleanup", batchSize: 1, leaseSeconds: 30 });
  assert.equal(claim.event_id, event.eventId);
  assert.equal(await acknowledgeOutboxEvent(tenantAPool, event.eventId, claim.lease_token), true);
});

test("publish-before-ack crash window produces safe at-least-once redelivery", async () => {
  const event = await seedEvent();
  const broker = [];
  const [first] = await claimOutboxEvents(tenantAPool, { workerId: "crash-worker", batchSize: 1, leaseSeconds: 1 });
  broker.push(first);
  // Simulate process death after broker publish and before database acknowledgement.
  await sleep(1100);
  const [redelivery] = await claimOutboxEvents(tenantASecondPool, { workerId: "recovery-worker", batchSize: 1, leaseSeconds: 10 });
  assert.equal(redelivery.event_id, event.eventId);
  broker.push(redelivery);
  assert.equal(await acknowledgeOutboxEvent(tenantASecondPool, event.eventId, redelivery.lease_token), true);
  assert.equal(broker.length, 2);
  assert.equal(await consumeOutboxEvent(tenantAPool, "financial-reporting-v1", event.eventId), true);
  assert.equal(await consumeOutboxEvent(tenantASecondPool, "financial-reporting-v1", event.eventId), false);
  const count = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.consumer_effects WHERE tenant_id=$1 AND consumer_name='financial-reporting-v1' AND event_id=$2",
    [TENANT_A, event.eventId]
  );
  assert.equal(count.rows[0].count, 1);
});

test("batch relay records publish failures for retry instead of marking them published", async () => {
  const event = await seedEvent();
  const result = await deliverOutboxBatch(
    tenantAPool,
    async () => { throw new Error("simulated broker timeout"); },
    { workerId: "batch-worker", batchSize: 1, leaseSeconds: 30, retrySeconds: 0 }
  );
  assert.deepEqual(result, [{ eventId: event.eventId, outcome: "pending" }]);
  assert.equal((await stateFor(TENANT_A, event.eventId)).status, "pending");
});

test("tenant runtime cannot read delivery tables directly", async () => {
  await assert.rejects(
    tenantAPool.query("SELECT * FROM public.outbox_events"),
    (error) => error.code === "42501"
  );
  await assert.rejects(
    tenantAPool.query("UPDATE public.outbox_delivery_state SET status='published'"),
    (error) => error.code === "42501"
  );
});

test("claim arguments and consumer identity are validated", async () => {
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
