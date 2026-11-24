import test from "node:test";
import assert from "node:assert/strict";
import { Pool } from "pg";
import { normalizeJournalRequest, postJournal } from "../src/posting.js";

const adminUrl = process.env.ADMIN_DATABASE_URL;
const tenantAUrl = process.env.TENANT_A_DATABASE_URL;
const tenantBUrl = process.env.TENANT_B_DATABASE_URL;
assert.ok(adminUrl, "ADMIN_DATABASE_URL must target the disposable P-02 database");
assert.ok(tenantAUrl, "TENANT_A_DATABASE_URL must authenticate as tenant_a_ledger_runtime");
assert.ok(tenantBUrl, "TENANT_B_DATABASE_URL must authenticate as tenant_b_ledger_runtime");

const TENANT_A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const TENANT_B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const EVENT_1 = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee";
const EVENT_2 = "ffffffff-ffff-4fff-8fff-ffffffffffff";
const A_USD_CASH = "11111111-1111-4111-8111-111111111101";
const A_USD_CLEARING = "11111111-1111-4111-8111-111111111102";
const A_JPY_CASH = "11111111-1111-4111-8111-111111111103";
const A_JPY_CLEARING = "11111111-1111-4111-8111-111111111104";
const B_USD_CASH = "22222222-2222-4222-8222-222222222201";
const B_USD_CLEARING = "22222222-2222-4222-8222-222222222202";

const adminPool = new Pool({ connectionString: adminUrl, max: 2 });
const tenantAPool = new Pool({ connectionString: tenantAUrl, max: 2 });
const tenantASecondPool = new Pool({ connectionString: tenantAUrl, max: 1 });
const tenantBPool = new Pool({ connectionString: tenantBUrl, max: 2 });

function request(idempotencyKey, lines, sourceEventId = EVENT_1) {
  return { idempotency_key: idempotencyKey, source_event_id: sourceEventId, lines };
}

function balancedUsd(amount = "12500", accountDebit = A_USD_CASH, accountCredit = A_USD_CLEARING) {
  return [
    { line_no: 1, account_id: accountDebit, currency_code: "USD", direction: "debit", amount_minor: amount },
    { line_no: 2, account_id: accountCredit, currency_code: "USD", direction: "credit", amount_minor: amount }
  ];
}

async function journalCount(tenantId, idempotencyKey) {
  const result = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.posting_requests WHERE tenant_id = $1 AND idempotency_key = $2",
    [tenantId, idempotencyKey]
  );
  return result.rows[0].count;
}

test.after(async () => {
  await tenantAPool.end();
  await tenantASecondPool.end();
  await tenantBPool.end();
  await adminPool.end();
});

test("a valid balanced journal posts atomically with exact integer minor units", async () => {
  const result = await postJournal(tenantAPool, request("p02-basic-001", balancedUsd("12500")));
  assert.equal(result.duplicate, false);

  const journal = await adminPool.query(
    "SELECT status, source_event_id FROM public.ledger_journals WHERE tenant_id = $1 AND journal_id = $2",
    [TENANT_A, result.journal_id]
  );
  assert.deepEqual(journal.rows, [{ status: "posted", source_event_id: EVENT_1 }]);

  const lines = await adminPool.query(
    "SELECT line_no, direction, amount_minor::text AS amount_minor FROM public.ledger_lines WHERE tenant_id = $1 AND journal_id = $2 ORDER BY line_no",
    [TENANT_A, result.journal_id]
  );
  assert.deepEqual(lines.rows, [
    { line_no: 1, direction: "debit", amount_minor: "12500" },
    { line_no: 2, direction: "credit", amount_minor: "12500" }
  ]);

  const outbox = await adminPool.query(
    "SELECT event_type, payload->>'journal_id' AS journal_id FROM public.ledger_outbox WHERE tenant_id = $1 AND journal_id = $2",
    [TENANT_A, result.journal_id]
  );
  assert.deepEqual(outbox.rows, [{ event_type: "ledger.journal.posted", journal_id: result.journal_id }]);
});

test("a repeated idempotency key returns the original journal without a second outbox event", async () => {
  const first = await postJournal(tenantAPool, request("p02-repeat-001", balancedUsd("700")));
  const second = await postJournal(tenantAPool, request("p02-repeat-001", balancedUsd("700")));
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(second.journal_id, first.journal_id);
  assert.equal(await journalCount(TENANT_A, "p02-repeat-001"), 1);

  const events = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.ledger_outbox WHERE tenant_id = $1 AND journal_id = $2",
    [TENANT_A, first.journal_id]
  );
  assert.equal(events.rows[0].count, 1);
});

test("concurrent duplicate requests serialize to one journal and one outbox event", async () => {
  const input = request("p02-concurrent-001", balancedUsd("9100"));
  const [left, right] = await Promise.all([
    postJournal(tenantAPool, input),
    postJournal(tenantASecondPool, input)
  ]);
  assert.equal(left.journal_id, right.journal_id);
  assert.deepEqual([left.duplicate, right.duplicate].sort(), [false, true]);
  assert.equal(await journalCount(TENANT_A, "p02-concurrent-001"), 1);

  const outbox = await adminPool.query(
    "SELECT count(*)::int AS count FROM public.ledger_outbox WHERE tenant_id = $1 AND journal_id = $2",
    [TENANT_A, left.journal_id]
  );
  assert.equal(outbox.rows[0].count, 1);
});

test("the same idempotency key with different intent is rejected", async () => {
  await postJournal(tenantAPool, request("p02-mismatch-001", balancedUsd("1000")));
  await assert.rejects(
    postJournal(tenantAPool, request("p02-mismatch-001", balancedUsd("1001"))),
    (error) => error.code === "22023" && error.message.includes("different request content")
  );
  assert.equal(await journalCount(TENANT_A, "p02-mismatch-001"), 1);
});

test("unbalanced postings are rejected without leaving request journal line or outbox rows", async () => {
  const lines = [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "100" },
    { line_no: 2, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "99" }
  ];
  await assert.rejects(
    postJournal(tenantAPool, request("p02-unbalanced-001", lines)),
    (error) => error.code === "22023" && error.message.includes("not balanced")
  );
  assert.equal(await journalCount(TENANT_A, "p02-unbalanced-001"), 0);
  const orphan = await adminPool.query(
    "SELECT count(*)::int AS journals FROM public.ledger_journals WHERE tenant_id = $1 AND source_event_id = $2",
    [TENANT_A, EVENT_1]
  );
  assert.equal(orphan.rows[0].journals, 0);
});

test("currency groups must balance independently; cross-currency netting is rejected", async () => {
  const lines = [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "100" },
    { line_no: 2, account_id: A_JPY_CLEARING, currency_code: "JPY", direction: "credit", amount_minor: "100" }
  ];
  await assert.rejects(
    postJournal(tenantAPool, request("p02-cross-currency-net-001", lines)),
    (error) => error.code === "22023" && error.message.includes("not balanced per currency")
  );
  assert.equal(await journalCount(TENANT_A, "p02-cross-currency-net-001"), 0);
});

test("multi-currency journals balance each currency independently", async () => {
  const lines = [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "12345" },
    { line_no: 2, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "12345" },
    { line_no: 3, account_id: A_JPY_CASH, currency_code: "JPY", direction: "debit", amount_minor: "987" },
    { line_no: 4, account_id: A_JPY_CLEARING, currency_code: "JPY", direction: "credit", amount_minor: "987" }
  ];
  const posted = await postJournal(tenantAPool, request("p02-multicurrency-001", lines, EVENT_2));
  assert.equal(posted.duplicate, false);
  const balances = await adminPool.query(
    "SELECT currency_code, sum(CASE WHEN direction = 'debit' THEN amount_minor ELSE -amount_minor END)::text AS net FROM public.ledger_lines WHERE tenant_id = $1 AND journal_id = $2 GROUP BY currency_code ORDER BY currency_code",
    [TENANT_A, posted.journal_id]
  );
  assert.deepEqual(balances.rows, [
    { currency_code: "JPY", net: "0" },
    { currency_code: "USD", net: "0" }
  ]);
});

test("exact 38-digit integer amounts are stored without floating-point conversion", async () => {
  const amount = "99999999999999999999999999999999999999";
  const posted = await postJournal(tenantAPool, request("p02-max-precision-001", balancedUsd(amount)));
  const lines = await adminPool.query(
    "SELECT amount_minor::text AS amount_minor FROM public.ledger_lines WHERE tenant_id = $1 AND journal_id = $2 ORDER BY line_no",
    [TENANT_A, posted.journal_id]
  );
  assert.deepEqual(lines.rows.map((row) => row.amount_minor), [amount, amount]);
});

test("tenant A cannot post against tenant B accounts and receives no cross-tenant account details", async () => {
  const lines = balancedUsd("10", B_USD_CASH, B_USD_CLEARING);
  await assert.rejects(
    postJournal(tenantAPool, request("p02-cross-tenant-account-001", lines)),
    (error) => error.code === "22023" && error.message === "ledger account or currency is unavailable"
  );
  assert.equal(await journalCount(TENANT_A, "p02-cross-tenant-account-001"), 0);
});

test("idempotency keys are scoped by tenant rather than globally", async () => {
  const a = await postJournal(tenantAPool, request("same-token", balancedUsd("500")));
  const bLines = [
    { line_no: 1, account_id: B_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "500" },
    { line_no: 2, account_id: B_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "500" }
  ];
  const b = await postJournal(tenantBPool, request("same-token", bLines));
  assert.notEqual(a.journal_id, b.journal_id);
  assert.equal(a.duplicate, false);
  assert.equal(b.duplicate, false);
  assert.equal(await journalCount(TENANT_A, "same-token"), 1);
  assert.equal(await journalCount(TENANT_B, "same-token"), 1);
});

test("tenant runtime roles cannot directly read or mutate ledger tables", async () => {
  await assert.rejects(
    tenantAPool.query("SELECT * FROM public.ledger_journals"),
    (error) => error.code === "42501"
  );
  await assert.rejects(
    tenantAPool.query("DELETE FROM public.ledger_lines"),
    (error) => error.code === "42501"
  );
  const role = await tenantAPool.query(
    "SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user"
  );
  assert.deepEqual(role.rows[0], { rolsuper: false, rolbypassrls: false });
});

test("posted journals lines requests and outbox are immutable even to the fixture administrator", async () => {
  const posted = await postJournal(tenantAPool, request("p02-immutable-001", balancedUsd("25")));
  await assert.rejects(
    adminPool.query("UPDATE public.ledger_journals SET status = 'posted' WHERE tenant_id = $1 AND journal_id = $2", [TENANT_A, posted.journal_id]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("DELETE FROM public.ledger_lines WHERE tenant_id = $1 AND journal_id = $2", [TENANT_A, posted.journal_id]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("UPDATE public.posting_requests SET idempotency_key = 'rewritten' WHERE tenant_id = $1 AND idempotency_key = 'p02-immutable-001'", [TENANT_A]),
    (error) => error.code === "55000"
  );
  await assert.rejects(
    adminPool.query("DELETE FROM public.ledger_outbox WHERE tenant_id = $1 AND journal_id = $2", [TENANT_A, posted.journal_id]),
    (error) => error.code === "55000"
  );
});

test("database identity must map to a tenant before posting", async () => {
  await assert.rejects(
    adminPool.query(
      "SELECT * FROM public.post_journal($1, $2, $3::jsonb)",
      ["p02-unmapped-001", EVENT_1, JSON.stringify(balancedUsd("10"))]
    ),
    (error) => error.code === "42501" && error.message.includes("not mapped to a tenant")
  );
});

test("the API rejects unsafe amounts and malformed requests before database access", async () => {
  assert.throws(() => normalizeJournalRequest(request("p02-invalid-amount", [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: 1.5 },
    { line_no: 2, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "1" }
  ])), TypeError);
  assert.throws(() => normalizeJournalRequest(request("p02-float", [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "01" },
    { line_no: 2, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "1" }
  ])), TypeError);
  assert.throws(() => normalizeJournalRequest(request("p02-duplicate-line", [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "1" },
    { line_no: 1, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "1" }
  ])), TypeError);
  assert.throws(() => normalizeJournalRequest({ ...request("p02-extra-field", balancedUsd()), tenant_id: TENANT_B }), TypeError);
});

test("database-side validation rejects extra fields and fractional amount strings", async () => {
  const extra = [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "10", tenant_id: TENANT_B },
    { line_no: 2, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "10", tenant_id: TENANT_B }
  ];
  await assert.rejects(
    tenantAPool.query("SELECT * FROM public.post_journal($1, $2, $3::jsonb)", ["p02-db-extra-001", EVENT_1, JSON.stringify(extra)]),
    (error) => error.code === "22023" && error.message.includes("fields are invalid")
  );
  const fractional = [
    { line_no: 1, account_id: A_USD_CASH, currency_code: "USD", direction: "debit", amount_minor: "10.5" },
    { line_no: 2, account_id: A_USD_CLEARING, currency_code: "USD", direction: "credit", amount_minor: "10.5" }
  ];
  await assert.rejects(
    tenantAPool.query("SELECT * FROM public.post_journal($1, $2, $3::jsonb)", ["p02-db-fraction-001", EVENT_1, JSON.stringify(fractional)]),
    (error) => error.code === "22023" && error.message.includes("values are invalid")
  );
});

test("RLS policies bind the privileged posting function to the database session tenant", async () => {
  const policies = await adminPool.query(
    "SELECT tablename, policyname, roles FROM pg_policies WHERE schemaname = 'public' AND tablename LIKE 'ledger_%' ORDER BY tablename, policyname"
  );
  assert.equal(policies.rowCount, 5);
  assert.equal(policies.rows.every((row) => row.roles.includes("ledger_executor")), true);
  const map = await tenantAPool.query(
    "SELECT session_user::text AS role_name, private.current_tenant_id()::text AS tenant_id"
  ).catch((error) => ({ error }));
  assert.ok(map.error, "tenant runtime roles must not have direct access to the private identity map");
});
