import test, { after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { Pool } from "pg";
import {
  claimNextProviderEvent, ingestProviderWebhook, makeWebhook, signWebhook, verifyWebhook,
  processProviderEvent, reconcileProviderEvents
} from "../src/provider.js";
import { claimOutboxEvents } from "../../p03-ledger-outbox-integration/src/relay.js";

const urls = {
  admin: process.env.ADMIN_DATABASE_URL,
  affiliateA: process.env.TENANT_A_AFFILIATE_DATABASE_URL,
  affiliateB: process.env.TENANT_B_AFFILIATE_DATABASE_URL,
  lotteryA: process.env.TENANT_A_LOTTERY_DATABASE_URL
};
for (const [name, value] of Object.entries(urls)) assert.ok(value, `missing ${name} database URL`);

const admin = new Pool({ connectionString: urls.admin, max: 4 });
const affiliateA = new Pool({ connectionString: urls.affiliateA, max: 4 });
const affiliateB = new Pool({ connectionString: urls.affiliateB, max: 3 });
const lotteryA = new Pool({ connectionString: urls.lotteryA, max: 3 });

const TENANT_A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const TENANT_B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const PRODUCT_AFFILIATE = "affiliate_agent";
const PRODUCT_LOTTERY = "lottery";
const A_CASH = "11111111-1111-4111-8111-111111111101";
const A_CLEARING = "11111111-1111-4111-8111-111111111102";
const B_CASH = "22222222-2222-4222-8222-222222222201";
const B_CLEARING = "22222222-2222-4222-8222-222222222202";
const LOTTERY_CASH = "33333333-3333-4333-8333-333333333301";
const LOTTERY_CLEARING = "33333333-3333-4333-8333-333333333302";
const EVENT_TYPE = "com.synthetic.settlement.posted.v1";
const currentSecret = "synthetic-current-webhook-secret-32-bytes";
const previousSecret = "synthetic-previous-webhook-secret-32-bytes";
const keys = [{ id: "current-v1", secret: currentSecret }, { id: "previous-v1", secret: previousSecret }];

const affiliateInstallation = {
  active: true, tenant_id: TENANT_A, product_id: PRODUCT_AFFILIATE,
  provider_id: "synthetic-provider", provider_source: "urn:synthetic:provider:affiliate",
  event_mappings: {
    [EVENT_TYPE]: { currency_code: "USD", debit_account_id: A_CASH, credit_account_id: A_CLEARING }
  }
};
const lotteryInstallation = {
  active: true, tenant_id: TENANT_A, product_id: PRODUCT_LOTTERY,
  provider_id: "synthetic-provider", provider_source: "urn:synthetic:provider:lottery",
  event_mappings: {
    [EVENT_TYPE]: { currency_code: "USD", debit_account_id: LOTTERY_CASH, credit_account_id: LOTTERY_CLEARING }
  }
};
const tenantBInstallation = {
  active: true, tenant_id: TENANT_B, product_id: PRODUCT_AFFILIATE,
  provider_id: "synthetic-provider", provider_source: "urn:synthetic:provider:tenant-b",
  event_mappings: {
    [EVENT_TYPE]: { currency_code: "USD", debit_account_id: B_CASH, credit_account_id: B_CLEARING }
  }
};

function webhook(installation, options = {}) {
  const eventId = options.eventId ?? "evt-" + randomUUID();
  const payload = {
    type: EVENT_TYPE,
    occurred_at: new Date().toISOString(),
    data: { amount_minor: options.amount ?? "12500", currency_code: options.currency ?? "USD" },
    ...(options.payloadScope ?? {})
  };
  const secret = options.secret ?? currentSecret;
  const built = makeWebhook({ eventId, payload, secret, timestamp: options.timestamp });
  return { ...built, installation };
}

async function ingest(pool, fixture, extra = {}) {
  return ingestProviderWebhook(pool, {
    installation: fixture.installation, keys,
    headers: fixture.headers, rawBody: fixture.rawBody,
    ...extra
  });
}

async function inboxRow(pool, providerId, eventId) {
  const result = await pool.query(
    "SELECT * FROM public.provider_event_inbox WHERE provider_id=$1 AND provider_event_id=$2",
    [providerId, eventId]
  );
  return result.rows[0] ?? null;
}

async function processOne(pool, installation, fixture, options = {}) {
  const claim = await claimNextProviderEvent(pool, {
    workerId: options.workerId ?? "p03d-worker-" + randomUUID(),
    leaseSeconds: options.leaseSeconds ?? 30,
    now: options.now ?? null,
    providerId: fixture.installation.provider_id,
    eventId: fixture.eventId
  });
  assert.ok(claim, "expected a provider inbox event to be claimable");
  assert.equal(claim.provider_event_id, fixture.eventId);
  return { claim, result: await processProviderEvent(pool, { claim, installation, ...options }) };
}

async function journalCounts(tenantId, productId, sourceEventId) {
  const result = await admin.query(
    `SELECT
       (SELECT count(*)::int FROM public.ledger_journals WHERE tenant_id=$1 AND product_id=$2 AND source_event_id=$3) AS journals,
       (SELECT count(*)::int FROM public.ledger_outbox WHERE tenant_id=$1 AND product_id=$2 AND payload->>'source_event_id'=$3::text) AS outbox_events,
       (SELECT count(*)::int FROM public.outbox_delivery_state d JOIN public.ledger_outbox o
          ON o.tenant_id=d.tenant_id AND o.product_id=d.product_id AND o.event_id=d.event_id
         WHERE o.tenant_id=$1 AND o.product_id=$2 AND o.payload->>'source_event_id'=$3::text) AS delivery_rows`,
    [tenantId, productId, sourceEventId]
  );
  return result.rows[0];
}

after(async () => {
  await Promise.all([admin.end(), affiliateA.end(), affiliateB.end(), lotteryA.end()]);
});

test("valid raw-body signature is durably accepted before the simulated HTTP 202", async () => {
  const fixture = webhook(affiliateInstallation);
  const result = await ingest(affiliateA, fixture);
  assert.equal(result.http_status, 202);
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.ok(stored);
  assert.equal(stored.status, "accepted");
  assert.equal(stored.product_id, PRODUCT_AFFILIATE);
  assert.equal(stored.payload_hash.length, 64);
  assert.ok(stored.effect_id && stored.source_event_id);
});

test("raw-body tampering is rejected before inbox persistence", async () => {
  const fixture = webhook(affiliateInstallation);
  const tampered = Buffer.from(fixture.rawBody.toString("utf8") + " ");
  const result = await ingestProviderWebhook(affiliateA, {
    installation: affiliateInstallation, keys, headers: fixture.headers, rawBody: tampered
  });
  assert.equal(result.http_status, 401);
  assert.equal(await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId), null);
});

test("webhook signing rejects secrets shorter than 128 bits", () => {
  assert.throws(
    () => signWebhook({
      eventId: "evt-short-secret",
      rawBody: Buffer.from("{}"),
      secret: "too-short",
      timestamp: Math.floor(Date.now() / 1000)
    }),
    /at least 128 bits/
  );
});

test("non-canonical base64 signature bytes are rejected", () => {
  const fixture = webhook(affiliateInstallation);
  const headers = {
    ...fixture.headers,
    "webhook-signature": fixture.headers["webhook-signature"] + "!"
  };
  const result = verifyWebhook({ headers, rawBody: fixture.rawBody, keys });
  assert.equal(result.valid, false);
  assert.equal(result.reason, "signature_mismatch");
});

test("invalid replay-window and body-size configuration fails closed", async () => {
  const fixture = webhook(affiliateInstallation);
  assert.throws(
    () => verifyWebhook({ headers: fixture.headers, rawBody: fixture.rawBody, keys, maxAgeSeconds: Number.NaN }),
    RangeError
  );
  assert.throws(
    () => verifyWebhook({ headers: fixture.headers, rawBody: fixture.rawBody, keys, now: Number.NaN }),
    RangeError
  );
  await assert.rejects(
    ingestProviderWebhook(affiliateA, {
      installation: affiliateInstallation, keys, headers: fixture.headers,
      rawBody: fixture.rawBody, maxBodyBytes: Number.NaN
    }),
    RangeError
  );
});

test("stale and future signature timestamps are rejected", async () => {
  const stale = webhook(affiliateInstallation, { timestamp: Math.floor(Date.now() / 1000) - 900 });
  const future = webhook(affiliateInstallation, { timestamp: Math.floor(Date.now() / 1000) + 900 });
  assert.equal((await ingest(affiliateA, stale)).http_status, 401);
  assert.equal((await ingest(affiliateA, future)).http_status, 401);
});

test("previous signing key remains accepted only while explicitly configured", async () => {
  const fixture = webhook(affiliateInstallation, { secret: previousSecret });
  const result = await ingest(affiliateA, fixture);
  assert.equal(result.http_status, 202);
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.signature_key_id, "previous-v1");
});

test("same event ID and same raw payload is an idempotent duplicate", async () => {
  const fixture = webhook(affiliateInstallation);
  assert.equal((await ingest(affiliateA, fixture)).http_status, 202);
  const duplicate = await ingest(affiliateA, fixture);
  assert.equal(duplicate.http_status, 200);
  assert.equal(duplicate.outcome, "duplicate");
  const count = await affiliateA.query(
    "SELECT count(*)::int AS n FROM public.provider_event_inbox WHERE provider_id=$1 AND provider_event_id=$2",
    [affiliateInstallation.provider_id, fixture.eventId]
  );
  assert.equal(count.rows[0].n, 1);
});

test("same event ID with a changed payload is quarantined as immutable conflict evidence", async () => {
  const eventId = "evt-conflict-" + randomUUID();
  const first = webhook(affiliateInstallation, { eventId, amount: "1000" });
  const second = webhook(affiliateInstallation, { eventId, amount: "2000" });
  assert.equal((await ingest(affiliateA, first)).http_status, 202);
  const conflict = await ingest(affiliateA, second);
  assert.equal(conflict.http_status, 409);
  const rows = await affiliateA.query(
    "SELECT count(*)::int AS n FROM public.provider_event_conflicts WHERE provider_id=$1 AND provider_event_id=$2",
    [affiliateInstallation.provider_id, eventId]
  );
  assert.equal(rows.rows[0].n, 1);
  assert.equal((await inboxRow(affiliateA, affiliateInstallation.provider_id, eventId)).payload_hash.length, 64);
});

test("caller-controlled tenant/product fields cannot override database and installation scope", async () => {
  const fixture = webhook(affiliateInstallation, {
    payloadScope: { tenant_id: TENANT_B, product_id: PRODUCT_LOTTERY }
  });
  assert.equal((await ingest(affiliateA, fixture)).http_status, 202);
  assert.equal((await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId)).tenant_id, TENANT_A);
  assert.equal(await inboxRow(affiliateB, affiliateInstallation.provider_id, fixture.eventId), null);
  assert.equal(await inboxRow(lotteryA, affiliateInstallation.provider_id, fixture.eventId), null);
});

test("tenant and product identities cannot read each other's provider inbox", async () => {
  const affiliate = webhook(affiliateInstallation);
  const lottery = webhook(lotteryInstallation);
  const tenantB = webhook(tenantBInstallation);
  await ingest(affiliateA, affiliate);
  await ingest(lotteryA, lottery);
  await ingest(affiliateB, tenantB);
  assert.equal((await affiliateA.query("SELECT * FROM provider_event_inbox WHERE provider_event_id=$1", [affiliate.eventId])).rowCount, 1);
  assert.equal((await lotteryA.query("SELECT * FROM provider_event_inbox WHERE provider_event_id=$1", [affiliate.eventId])).rowCount, 0);
  assert.equal((await affiliateB.query("SELECT * FROM provider_event_inbox WHERE provider_event_id=$1", [affiliate.eventId])).rowCount, 0);
});

test("processing atomically creates product-scoped journal, immutable outbox and P-03C delivery state", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  const { result } = await processOne(affiliateA, affiliateInstallation, fixture);
  assert.equal(result.outcome, "processed");
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.status, "processed");
  assert.equal(stored.product_id, PRODUCT_AFFILIATE);
  assert.ok(stored.journal_id);
  const counts = await journalCounts(TENANT_A, PRODUCT_AFFILIATE, stored.source_event_id);
  assert.deepEqual(counts, { journals: 1, outbox_events: 1, delivery_rows: 1 });
  const rows = await admin.query(
    `SELECT j.product_id AS journal_product, o.product_id AS outbox_product, d.product_id AS delivery_product,
            d.status AS delivery_status
       FROM public.ledger_journals j
       JOIN public.ledger_outbox o USING (tenant_id, product_id, journal_id)
       JOIN public.outbox_delivery_state d USING (tenant_id, product_id, event_id)
      WHERE j.tenant_id=$1 AND j.product_id=$2 AND j.journal_id=$3`,
    [TENANT_A, PRODUCT_AFFILIATE, stored.journal_id]
  );
  assert.deepEqual(rows.rows[0], {
    journal_product: PRODUCT_AFFILIATE,
    outbox_product: PRODUCT_AFFILIATE,
    delivery_product: PRODUCT_AFFILIATE,
    delivery_status: "pending"
  });
});

test("pre-commit worker failure rolls back journal, outbox and delivery state but keeps inbox retryable", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  const { claim, result } = await processOne(affiliateA, affiliateInstallation, fixture, { simulateBeforeCommit: true });
  assert.equal(result.outcome, "retry");
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.status, "retry");
  const counts = await journalCounts(TENANT_A, PRODUCT_AFFILIATE, stored.source_event_id);
  assert.deepEqual(counts, { journals: 0, outbox_events: 0, delivery_rows: 0 });
  assert.equal(stored.lease_token, null);
  assert.ok(claim.lease_token);
});

test("duplicate webhook after processing returns the original result without another economic effect", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  const { result } = await processOne(affiliateA, affiliateInstallation, fixture);
  assert.equal(result.outcome, "processed");
  const duplicate = await ingest(affiliateA, fixture);
  assert.equal(duplicate.outcome, "duplicate");
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  const counts = await journalCounts(TENANT_A, PRODUCT_AFFILIATE, stored.source_event_id);
  assert.deepEqual(counts, { journals: 1, outbox_events: 1, delivery_rows: 1 });
});

test("expired provider inbox lease is reclaimed and stale worker cannot process", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  const future = new Date(Date.now() + 1000);
  const first = await claimNextProviderEvent(affiliateA, { workerId: "old-worker", leaseSeconds: 1, now: future, providerId: affiliateInstallation.provider_id, eventId: fixture.eventId });
  const second = await claimNextProviderEvent(affiliateA, {
    workerId: "new-worker", leaseSeconds: 30, now: new Date(future.getTime() + 2000), providerId: affiliateInstallation.provider_id, eventId: fixture.eventId
  });
  assert.equal(second.provider_event_id, fixture.eventId);
  assert.notEqual(second.lease_token, first.lease_token);
  const stale = await processProviderEvent(affiliateA, { claim: first, installation: affiliateInstallation });
  assert.equal(stale.outcome, "stale");
  const processed = await processProviderEvent(affiliateA, { claim: second, installation: affiliateInstallation });
  assert.equal(processed.outcome, "processed");
});

test("maximum attempts transition an expired or failed claim to dead letter", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  await admin.query(
    "UPDATE public.provider_event_inbox SET max_attempts=1 WHERE tenant_id=$1 AND product_id=$2 AND provider_id=$3 AND provider_event_id=$4",
    [TENANT_A, PRODUCT_AFFILIATE, affiliateInstallation.provider_id, fixture.eventId]
  );
  const { result } = await processOne(affiliateA, affiliateInstallation, fixture, { simulateBeforeCommit: true });
  assert.equal(result.outcome, "dead_letter");
  assert.equal((await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId)).status, "dead_letter");
});

test("unknown event type is quarantined without financial posting", async () => {
  const fixture = webhook(affiliateInstallation);
  const body = JSON.parse(fixture.rawBody.toString("utf8"));
  body.type = "com.synthetic.unknown.v9";
  const rawBody = Buffer.from(JSON.stringify(body));
  const headers = (await import("../src/provider.js")).signWebhook({
    eventId: fixture.eventId, rawBody, secret: currentSecret, timestamp: Math.floor(Date.now() / 1000)
  });
  const altered = { ...fixture, rawBody, headers };
  await ingest(affiliateA, altered);
  const { result } = await processOne(affiliateA, affiliateInstallation, altered);
  assert.equal(result.outcome, "quarantined");
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.journal_id, null);
  assert.equal(stored.last_error_code, "P03D_UNMAPPED_EVENT");
});

test("lottery posting is isolated from affiliate accounts and its outbox", async () => {
  const fixture = webhook(lotteryInstallation);
  await ingest(lotteryA, fixture);
  const { result } = await processOne(lotteryA, lotteryInstallation, fixture);
  assert.equal(result.outcome, "processed");
  const stored = await inboxRow(lotteryA, lotteryInstallation.provider_id, fixture.eventId);
  assert.equal(stored.product_id, PRODUCT_LOTTERY);
  const counts = await journalCounts(TENANT_A, PRODUCT_LOTTERY, stored.source_event_id);
  assert.deepEqual(counts, { journals: 1, outbox_events: 1, delivery_rows: 1 });
  const affiliateClaims = await claimOutboxEvents(affiliateA, { workerId: "affiliate-relay", batchSize: 100, leaseSeconds: 30 });
  assert.equal(affiliateClaims.some((row) => row.aggregate_id === stored.journal_id), false);
  const lotteryClaims = await claimOutboxEvents(lotteryA, { workerId: "lottery-relay", batchSize: 100, leaseSeconds: 30 });
  assert.equal(lotteryClaims.some((row) => row.aggregate_id === stored.journal_id), true);
});

test("inbox constraints reject partial processed state and attempt overflow", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  const where = "WHERE tenant_id=$1 AND product_id=$2 AND provider_id=$3 AND provider_event_id=$4";
  const args = [TENANT_A, PRODUCT_AFFILIATE, affiliateInstallation.provider_id, fixture.eventId];
  await assert.rejects(
    affiliateA.query("UPDATE public.provider_event_inbox SET processed_at=clock_timestamp() " + where, args),
    (error) => error.code === "23514"
  );
  await assert.rejects(
    affiliateA.query("UPDATE public.provider_event_inbox SET status='processed' " + where, args),
    (error) => error.code === "23514"
  );
  await assert.rejects(
    affiliateA.query("UPDATE public.provider_event_inbox SET status='retry', processed_at=clock_timestamp() " + where, args),
    (error) => error.code === "23514"
  );
  await assert.rejects(
    affiliateA.query("UPDATE public.provider_event_inbox SET attempt_count=max_attempts+1 " + where, args),
    (error) => error.code === "23514"
  );
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.status, "accepted");
  assert.equal(stored.processed_at, null);
  assert.equal(stored.journal_id, null);
  assert.equal(stored.attempt_count, 0);
});

test("provider worker cannot write ledger tables directly and product spoof is denied", async () => {
  await assert.rejects(
    affiliateA.query("INSERT INTO public.ledger_outbox(tenant_id,product_id,event_id,journal_id,event_type,payload) VALUES($1,$2,gen_random_uuid(),gen_random_uuid(),'ledger.journal.posted','{}'::jsonb)", [TENANT_A, PRODUCT_LOTTERY]),
    (error) => error.code === "42501" || error.code === "23503"
  );
  await assert.rejects(
    affiliateA.query("INSERT INTO public.provider_event_inbox(tenant_id,product_id,provider_id,provider_event_id,event_type,event_source,payload_hash,signature_key_id,canonical_event) VALUES($1,$2,'synthetic-provider','spoof','type','source',$3,'key','{}'::jsonb)", [TENANT_A, PRODUCT_LOTTERY, "a".repeat(64)]),
    (error) => error.code === "42501"
  );
});

test("reconciliation identifies missing events and closes after journal/outbox/delivery commit", async () => {
  const fixture = webhook(affiliateInstallation);
  await admin.query(
    "INSERT INTO public.provider_event_expectations(tenant_id,product_id,provider_id,provider_event_id) VALUES($1,$2,$3,$4)",
    [TENANT_A, PRODUCT_AFFILIATE, affiliateInstallation.provider_id, fixture.eventId]
  );
  const before = await reconcileProviderEvents(admin, {
    tenantId: TENANT_A, productId: PRODUCT_AFFILIATE, providerId: affiliateInstallation.provider_id
  });
  assert.equal(before.length, 1);
  assert.equal(before[0].inbox_status, null);
  await ingest(affiliateA, fixture);
  await processOne(affiliateA, affiliateInstallation, fixture);
  const afterRows = await reconcileProviderEvents(admin, {
    tenantId: TENANT_A, productId: PRODUCT_AFFILIATE, providerId: affiliateInstallation.provider_id
  });
  assert.equal(afterRows.length, 0);
});

test("unmapped database identity fails closed for product-scoped posting", async () => {
  await assert.rejects(
    admin.query("SELECT * FROM public.post_journal($1,$2,$3,$4::jsonb)", [
      "p03d-unmapped", randomUUID(), randomUUID(), JSON.stringify([
        { line_no: 1, account_id: A_CASH, currency_code: "USD", direction: "debit", amount_minor: "1" },
        { line_no: 2, account_id: A_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "1" }
      ])
    ]),
    (error) => error.code === "42501" && error.message.includes("not mapped to a tenant")
  );
});

test("P-09F concurrent workers claim and process one provider event exactly once", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);

  const claims = await Promise.all([
    claimNextProviderEvent(affiliateA, {
      workerId: "p09f-worker-alpha", providerId: affiliateInstallation.provider_id, eventId: fixture.eventId
    }),
    claimNextProviderEvent(affiliateA, {
      workerId: "p09f-worker-beta", providerId: affiliateInstallation.provider_id, eventId: fixture.eventId
    })
  ]);
  const winners = claims.filter(Boolean);
  assert.equal(winners.length, 1, "exactly one concurrent worker must acquire the inbox lease");

  const outcomes = await Promise.all([
    processProviderEvent(affiliateA, { claim: winners[0], installation: affiliateInstallation }),
    processProviderEvent(affiliateA, { claim: winners[0], installation: affiliateInstallation })
  ]);
  assert.deepEqual(outcomes.map((item) => item.outcome).sort(), ["processed", "stale"]);
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.status, "processed");
  assert.equal(stored.attempt_count, 1);
  const counts = await journalCounts(TENANT_A, PRODUCT_AFFILIATE, stored.source_event_id);
  assert.deepEqual(counts, { journals: 1, outbox_events: 1, delivery_rows: 1 });
});

test("P-09F concurrent stale and current lease holders cannot double-post", async () => {
  const fixture = webhook(affiliateInstallation);
  await ingest(affiliateA, fixture);
  const leaseStart = new Date(Date.now() + 1000);
  const staleClaim = await claimNextProviderEvent(affiliateA, {
    workerId: "p09f-expired-worker", leaseSeconds: 1, now: leaseStart,
    providerId: affiliateInstallation.provider_id, eventId: fixture.eventId
  });
  const currentClaim = await claimNextProviderEvent(affiliateA, {
    workerId: "p09f-current-worker", leaseSeconds: 30,
    now: new Date(leaseStart.getTime() + 2000),
    providerId: affiliateInstallation.provider_id, eventId: fixture.eventId
  });
  assert.ok(staleClaim);
  assert.ok(currentClaim);
  assert.notEqual(staleClaim.lease_token, currentClaim.lease_token);

  const [stale, current] = await Promise.all([
    processProviderEvent(affiliateA, { claim: staleClaim, installation: affiliateInstallation }),
    processProviderEvent(affiliateA, { claim: currentClaim, installation: affiliateInstallation })
  ]);
  assert.equal(stale.outcome, "stale");
  assert.equal(current.outcome, "processed");
  const stored = await inboxRow(affiliateA, affiliateInstallation.provider_id, fixture.eventId);
  assert.equal(stored.status, "processed");
  assert.equal(stored.attempt_count, 2);
  const counts = await journalCounts(TENANT_A, PRODUCT_AFFILIATE, stored.source_event_id);
  assert.deepEqual(counts, { journals: 1, outbox_events: 1, delivery_rows: 1 });
});

test("P-09F same provider event and source UUID remain isolated across Affiliate, Lottery and tenants", async () => {
  const eventId = "evt-p09f-cross-scope-" + randomUUID();
  const sourceEventId = randomUUID();
  const scopes = [
    { tenantId: TENANT_A, productId: PRODUCT_AFFILIATE, installation: affiliateInstallation, pool: affiliateA, effectId: randomUUID(), hash: "a".repeat(64), worker: "p09f-affiliate-a" },
    { tenantId: TENANT_A, productId: PRODUCT_LOTTERY, installation: lotteryInstallation, pool: lotteryA, effectId: randomUUID(), hash: "b".repeat(64), worker: "p09f-lottery-a" },
    { tenantId: TENANT_B, productId: PRODUCT_AFFILIATE, installation: tenantBInstallation, pool: affiliateB, effectId: randomUUID(), hash: "c".repeat(64), worker: "p09f-affiliate-b" }
  ];

  const values = [];
  const placeholders = [];
  for (const scope of scopes) {
    const offset = values.length;
    const canonical = {
      specversion: "1.0",
      id: eventId,
      source: scope.installation.provider_source,
      type: EVENT_TYPE,
      datacontenttype: "application/json",
      data: { amount_minor: "12500", currency_code: "USD" }
    };
    values.push(
      scope.tenantId, scope.productId, scope.installation.provider_id, eventId,
      EVENT_TYPE, scope.installation.provider_source, scope.hash, "p09f-synthetic-key",
      JSON.stringify(canonical), scope.effectId, sourceEventId
    );
    const p = Array.from({ length: 11 }, (_, i) => "$" + (offset + i + 1));
    p[8] += "::jsonb";
    placeholders.push("(" + p.join(",") + ")");
  }

  await admin.query(
    `INSERT INTO public.provider_event_inbox
      (tenant_id,product_id,provider_id,provider_event_id,event_type,event_source,
       payload_hash,signature_key_id,canonical_event,effect_id,source_event_id)
     VALUES ${placeholders.join(",")}`,
    values
  );
  await admin.query(
    `INSERT INTO public.provider_event_expectations(tenant_id,product_id,provider_id,provider_event_id)
     VALUES ($1,$2,$3,$4),($5,$6,$7,$8),($9,$10,$11,$12)`,
    [
      TENANT_A, PRODUCT_AFFILIATE, affiliateInstallation.provider_id, eventId,
      TENANT_A, PRODUCT_LOTTERY, lotteryInstallation.provider_id, eventId,
      TENANT_B, PRODUCT_AFFILIATE, tenantBInstallation.provider_id, eventId
    ]
  );

  const claims = await Promise.all(scopes.map((scope) => claimNextProviderEvent(scope.pool, {
    workerId: scope.worker, providerId: scope.installation.provider_id, eventId
  })));
  assert.ok(claims.every(Boolean), "each tenant/product scope must claim its own matching inbox row");
  const results = await Promise.all(scopes.map((scope, index) =>
    processProviderEvent(scope.pool, { claim: claims[index], installation: scope.installation })
  ));
  assert.deepEqual(results.map((item) => item.outcome), ["processed", "processed", "processed"]);

  for (const scope of scopes) {
    const stored = await inboxRow(scope.pool, scope.installation.provider_id, eventId);
    assert.equal(stored.tenant_id, scope.tenantId);
    assert.equal(stored.product_id, scope.productId);
    assert.equal(stored.source_event_id, sourceEventId);
    assert.equal(stored.status, "processed");
    assert.ok(stored.journal_id);
    assert.deepEqual(
      await journalCounts(scope.tenantId, scope.productId, sourceEventId),
      { journals: 1, outbox_events: 1, delivery_rows: 1 }
    );
    assert.deepEqual(await reconcileProviderEvents(admin, {
      tenantId: scope.tenantId, productId: scope.productId, providerId: scope.installation.provider_id
    }), []);
  }

  const identityRows = await admin.query(
    `SELECT count(*)::int AS rows, count(DISTINCT product_id)::int AS products,
            count(DISTINCT tenant_id)::int AS tenants
       FROM public.ledger_journals WHERE source_event_id=$1`,
    [sourceEventId]
  );
  assert.deepEqual(identityRows.rows[0], { rows: 3, products: 2, tenants: 2 });
  assert.equal((await affiliateA.query(
    "SELECT count(*)::int AS n FROM public.provider_event_inbox WHERE provider_event_id=$1", [eventId]
  )).rows[0].n, 1);
  assert.equal((await lotteryA.query(
    "SELECT count(*)::int AS n FROM public.provider_event_inbox WHERE provider_event_id=$1", [eventId]
  )).rows[0].n, 1);
  assert.equal((await affiliateB.query(
    "SELECT count(*)::int AS n FROM public.provider_event_inbox WHERE provider_event_id=$1", [eventId]
  )).rows[0].n, 1);
});
