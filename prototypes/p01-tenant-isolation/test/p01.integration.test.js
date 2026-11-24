import test, { before, after } from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { generateKeyPairSync } from "node:crypto";
import { setTimeout as delay } from "node:timers/promises";
import { Pool } from "pg";
import { createTenantServer } from "../src/app.js";
import { withTenantTransaction } from "../src/tenant-db.js";
import { acknowledgeJob, claimNextJob } from "../src/job-dispatch.js";
import { processTenantJob } from "../src/job-worker.js";
import {
  authenticateSyntheticRequest,
  TENANT_A,
  TENANT_B,
  SHARED_RECORD_ID,
  TENANT_B_ONLY_RECORD_ID
} from "./fixtures.js";

const databaseUrl = process.env.DATABASE_URL;
const adminDatabaseUrl = process.env.ADMIN_DATABASE_URL;
const dispatcherDatabaseUrl = process.env.DISPATCHER_DATABASE_URL;
const supportDatabaseUrl = process.env.SUPPORT_DATABASE_URL;
assert.ok(databaseUrl, "DATABASE_URL must point to the least-privilege app_runtime role");
assert.ok(adminDatabaseUrl, "ADMIN_DATABASE_URL must point to the disposable fixture administrator");
assert.ok(dispatcherDatabaseUrl, "DISPATCHER_DATABASE_URL must point to the metadata-only dispatcher role");
assert.ok(supportDatabaseUrl, "SUPPORT_DATABASE_URL must point to the support-authorizer role");

const SUPPORT_GRANT_ACTIVE = "33333333-3333-4333-8333-333333333333";
const SUPPORT_GRANT_EXPIRED = "44444444-4444-4444-8444-444444444444";
const SUPPORT_GRANT_REVOKED = "55555555-5555-4555-8555-555555555555";
const SUPPORT_GRANT_OTHER_TENANT = "66666666-6666-4666-8666-666666666666";

const { privateKey: jobSigningPrivateKeyObject, publicKey: jobVerifyPublicKeyObject } =
  generateKeyPairSync("ed25519");
const jobSigningPrivateKey = jobSigningPrivateKeyObject.export({ type: "pkcs8", format: "pem" });
const jobVerifyPublicKey = jobVerifyPublicKeyObject.export({ type: "spki", format: "pem" });

const adminPool = new Pool({ connectionString: adminDatabaseUrl, max: 2 });
const adminObserverPool = new Pool({ connectionString: adminDatabaseUrl, max: 1 });
const dispatcherPool = new Pool({ connectionString: dispatcherDatabaseUrl, max: 1 });
const dispatcherPool2 = new Pool({ connectionString: dispatcherDatabaseUrl, max: 1 });
const supportPool = new Pool({ connectionString: supportDatabaseUrl, max: 2 });
const tenantAPool = new Pool({ connectionString: process.env.TENANT_A_DATABASE_URL, max: 1 });
const tenantBPool = new Pool({ connectionString: process.env.TENANT_B_DATABASE_URL, max: 1 });
const pool = new Pool({
  connectionString: databaseUrl,
  max: 1,
  idleTimeoutMillis: 1000,
  connectionTimeoutMillis: 3000
});
const server = createTenantServer({ pool, supportPool, authenticate: authenticateSyntheticRequest });
let origin;

async function request(path, options = {}) {
  const headers = { ...(options.token ? { authorization: "Bearer " + options.token } : {}), ...(options.headers ?? {}) };
  const response = await fetch(new URL(path, origin), {
    method: options.method ?? "GET",
    headers,
    body: options.body
  });
  return { status: response.status, body: await response.json() };
}

before(async () => {
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  origin = "http://127.0.0.1:" + server.address().port;
  await adminPool.query(
    "INSERT INTO public.support_grants (grant_id, support_subject_id, tenant_id, resource_scope, reason, expires_at, revoked_at) VALUES ($1, 'synthetic-support-a', $2, 'records:read', 'Customer requested investigation of record visibility', clock_timestamp() + interval '1 hour', NULL), ($3, 'synthetic-support-a', $2, 'records:read', 'Expired synthetic support investigation reason', clock_timestamp() - interval '1 hour', NULL), ($4, 'synthetic-support-a', $2, 'records:read', 'Revoked synthetic support investigation reason', clock_timestamp() + interval '1 hour', clock_timestamp()), ($5, 'synthetic-support-a', $6, 'records:read', 'Wrong tenant synthetic investigation reason', clock_timestamp() + interval '1 hour', NULL)",
    [SUPPORT_GRANT_ACTIVE, TENANT_A, SUPPORT_GRANT_EXPIRED, SUPPORT_GRANT_REVOKED, SUPPORT_GRANT_OTHER_TENANT, TENANT_B]
  );
});

after(async () => {
  server.close();
  await once(server, "close");
  await pool.end();
  await adminPool.end();
  await adminObserverPool.end();
  await dispatcherPool.end();
  await dispatcherPool2.end();
  await tenantAPool.end();
  await tenantBPool.end();
  await supportPool.end();
});

test("missing and invalid synthetic credentials cannot access tenant data", async () => {
  const missing = await request("/records");
  const invalid = await request("/records", { token: "not-a-valid-token" });
  assert.equal(missing.status, 401);
  assert.equal(invalid.status, 401);
});

test("async jobs preserve signed tenant context, retry safely and expose no payload to dispatcher", async () => {
  const createA = await request("/jobs", {
    token: "p01-synthetic-token-a",
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ payload: "tenant A background task" })
  });
  const createB = await request("/jobs", {
    token: "p01-synthetic-token-b",
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ payload: "tenant B background task" })
  });
  const forged = await request("/jobs", {
    token: "p01-synthetic-token-a",
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ tenant_id: TENANT_B, payload: "forged task" })
  });
  assert.equal(createA.status, 202);
  assert.equal(createB.status, 202);
  assert.equal(forged.status, 403);

  const jobA = createA.body.data.job_id;
  const jobB = createB.body.data.job_id;
  const metadata = await dispatcherPool.query(
    "SELECT tenant_id, job_id, status FROM public.job_dispatch ORDER BY tenant_id, job_id"
  );
  assert.equal(metadata.rowCount, 2);
  assert.equal(metadata.rows.every((row) => row.status === "pending"), true);
  await assert.rejects(
    dispatcherPool.query("SELECT payload FROM public.tenant_jobs"),
    (error) => error.code === "42501"
  );
  const dispatcherRole = await dispatcherPool.query(
    "SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user"
  );
  assert.equal(dispatcherRole.rows[0].rolsuper, false);
  assert.equal(dispatcherRole.rows[0].rolbypassrls, false);

  const [claimOne, claimTwo] = await Promise.all([
    claimNextJob(dispatcherPool, jobSigningPrivateKey, { leaseSeconds: 30 }),
    claimNextJob(dispatcherPool2, jobSigningPrivateKey, { leaseSeconds: 30 })
  ]);
  assert.notEqual(claimOne.job_id, claimTwo.job_id);
  const firstAttempt = [claimOne, claimTwo].find((item) => item.tenant_id === TENANT_A);
  const bAttempt = [claimOne, claimTwo].find((item) => item.tenant_id === TENANT_B);
  assert.equal(firstAttempt.job_id, jobA);
  assert.equal(bAttempt.job_id, jobB);

  const retryAttempt = await claimNextJob(dispatcherPool, jobSigningPrivateKey, { leaseSeconds: 0 });
  assert.equal(retryAttempt.job_id, jobA);
  assert.equal(retryAttempt.attempt, 2);

  const tampered = { ...retryAttempt, tenant_id: TENANT_B };
  assert.equal((await processTenantJob(pool, tampered, jobVerifyPublicKey)).status, "invalid_envelope");

  const completed = await processTenantJob(pool, firstAttempt, jobVerifyPublicKey);
  assert.deepEqual(completed, { status: "completed", payload: "tenant A background task" });
  assert.equal((await processTenantJob(pool, retryAttempt, jobVerifyPublicKey)).status, "already_processed");
  assert.equal(await acknowledgeJob(dispatcherPool, firstAttempt, jobVerifyPublicKey), false);
  assert.equal(await acknowledgeJob(dispatcherPool, retryAttempt, jobVerifyPublicKey), true);

  assert.equal((await processTenantJob(pool, bAttempt, jobVerifyPublicKey)).status, "completed");
  assert.equal(await acknowledgeJob(dispatcherPool, bAttempt, jobVerifyPublicKey), true);
  assert.equal(await claimNextJob(dispatcherPool, jobSigningPrivateKey), null);

  const aCannotReadB = await withTenantTransaction(pool, TENANT_A, (client) =>
    client.query("SELECT job_id FROM public.tenant_jobs WHERE job_id = $1", [jobB])
  );
  assert.equal(aCannotReadB.rowCount, 0);
});

test("job and dispatch outbox writes roll back atomically", async () => {
  const orphanJobId = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
  await assert.rejects(
    withTenantTransaction(pool, TENANT_A, async (client) => {
      await client.query(
        "INSERT INTO public.tenant_jobs (tenant_id, job_id, subject_id, payload) VALUES ($1, $2, $3, $4)",
        [TENANT_A, orphanJobId, "synthetic-user-a", "must roll back with dispatch"]
      );
      await client.query(
        "INSERT INTO public.job_dispatch (tenant_id, job_id) VALUES ($1, $2)",
        [TENANT_A, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"]
      );
    }),
    (error) => error.code === "23503"
  );

  const orphan = await withTenantTransaction(pool, TENANT_A, (client) =>
    client.query("SELECT job_id FROM public.tenant_jobs WHERE job_id = $1", [orphanJobId])
  );
  assert.equal(orphan.rowCount, 0);
});

test("an async job is rejected when its originating membership is revoked before execution", async () => {
  const created = await request("/jobs", {
    token: "p01-synthetic-token-a",
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ payload: "must not execute after revocation" })
  });
  assert.equal(created.status, 202);

  await adminPool.query(
    "UPDATE public.tenant_memberships SET active = false WHERE tenant_id = $1 AND subject_id = $2",
    [TENANT_A, "synthetic-user-a"]
  );
  try {
    const envelope = await claimNextJob(dispatcherPool, jobSigningPrivateKey);
    assert.equal(envelope.job_id, created.body.data.job_id);
    const result = await processTenantJob(pool, envelope, jobVerifyPublicKey);
    assert.equal(result.status, "membership_revoked");

    const stored = await withTenantTransaction(pool, TENANT_A, (client) =>
      client.query("SELECT status FROM public.tenant_jobs WHERE job_id = $1", [envelope.job_id])
    );
    assert.equal(stored.rows[0].status, "rejected");
    assert.equal(await acknowledgeJob(dispatcherPool, envelope, jobVerifyPublicKey), true);
  } finally {
    await adminPool.query(
      "UPDATE public.tenant_memberships SET active = true WHERE tenant_id = $1 AND subject_id = $2",
      [TENANT_A, "synthetic-user-a"]
    );
  }
});

test("membership revocation blocks the next request without affecting another tenant", async () => {
  const revoked = await adminPool.query(
    "UPDATE public.tenant_memberships SET active = false WHERE tenant_id = $1 AND subject_id = $2",
    [TENANT_A, "synthetic-user-a"]
  );
  assert.equal(revoked.rowCount, 1);

  try {
    const a = await request("/records", { token: "p01-synthetic-token-a" });
    const b = await request("/records", { token: "p01-synthetic-token-b" });
    assert.equal(a.status, 403);
    assert.equal(a.body.error, "forbidden");
    assert.equal(b.status, 200);
  } finally {
    await adminPool.query(
      "UPDATE public.tenant_memberships SET active = true WHERE tenant_id = $1 AND subject_id = $2",
      [TENANT_A, "synthetic-user-a"]
    );
  }
});

test("RLS returns only rows for the authenticated tenant", async () => {
  const a = await request("/records", { token: "p01-synthetic-token-a" });
  const b = await request("/records", { token: "p01-synthetic-token-b" });
  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.equal(a.body.data.length, 2);
  assert.equal(b.body.data.length, 2);
  assert.ok(a.body.data.some((row) => row.payload === "synthetic tenant A fixture"));
  assert.ok(a.body.data.some((row) => row.payload === "tenant A private fixture"));
  assert.ok(b.body.data.some((row) => row.payload === "synthetic tenant B fixture"));
  assert.ok(b.body.data.some((row) => row.payload === "tenant B private fixture"));

  const membershipsA = await withTenantTransaction(pool, TENANT_A, (client) =>
    client.query("SELECT subject_id FROM public.tenant_memberships ORDER BY subject_id")
  );
  const membershipsB = await withTenantTransaction(pool, TENANT_B, (client) =>
    client.query("SELECT subject_id FROM public.tenant_memberships ORDER BY subject_id")
  );
  assert.deepEqual(membershipsA.rows.map((row) => row.subject_id), ["synthetic-user-a"]);
  assert.deepEqual(membershipsB.rows.map((row) => row.subject_id), ["synthetic-user-b"]);
});

test("a forged tenant header cannot switch the authenticated tenant", async () => {
  const result = await request("/records", {
    token: "p01-synthetic-token-a",
    headers: { "x-tenant-id": TENANT_B }
  });
  assert.equal(result.status, 200);
  assert.equal(result.body.data.length, 2);
  assert.ok(result.body.data.some((row) => row.payload === "synthetic tenant A fixture"));
  assert.ok(result.body.data.some((row) => row.payload === "tenant A private fixture"));
  assert.equal(result.body.data.some((row) => row.payload.includes("tenant B")), false);
});

test("the same object UUID resolves only inside the authenticated tenant", async () => {
  const a = await request("/records/" + SHARED_RECORD_ID, { token: "p01-synthetic-token-a" });
  const b = await request("/records/" + SHARED_RECORD_ID, { token: "p01-synthetic-token-b" });
  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.equal(a.body.data.payload, "synthetic tenant A fixture");
  assert.equal(b.body.data.payload, "synthetic tenant B fixture");
});

test("tenant A cannot read a tenant-B-only object even when it knows the identifier", async () => {
  const denied = await request("/records/" + TENANT_B_ONLY_RECORD_ID, {
    token: "p01-synthetic-token-a"
  });
  const allowed = await request("/records/" + TENANT_B_ONLY_RECORD_ID, {
    token: "p01-synthetic-token-b"
  });
  assert.equal(denied.status, 404);
  assert.equal(allowed.status, 200);
  assert.equal(allowed.body.data.payload, "tenant B private fixture");
});

test("a forged tenant_id in a write body is rejected without a side effect", async () => {
  const write = await request("/records", {
    token: "p01-synthetic-token-a",
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ tenant_id: TENANT_B, natural_key: "forged-write", payload: "must not be stored" })
  });
  assert.equal(write.status, 403);
  const a = await request("/records", { token: "p01-synthetic-token-a" });
  const b = await request("/records", { token: "p01-synthetic-token-b" });
  assert.equal(a.body.data.some((row) => row.natural_key === "forged-write"), false);
  assert.equal(b.body.data.some((row) => row.natural_key === "forged-write"), false);
});

test("writes derive tenant_id from the authenticated principal", async () => {
  const write = await request("/records", {
    token: "p01-synthetic-token-a",
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ natural_key: "created-by-a", payload: "tenant A only" })
  });
  assert.equal(write.status, 201);
  const a = await request("/records", { token: "p01-synthetic-token-a" });
  const b = await request("/records", { token: "p01-synthetic-token-b" });
  assert.equal(a.body.data.some((row) => row.natural_key === "created-by-a"), true);
  assert.equal(b.body.data.some((row) => row.natural_key === "created-by-a"), false);
});

test("pooled connections do not leak tenant context between alternating tenants", async () => {
  for (const item of [
    ["p01-synthetic-token-a", "synthetic tenant A fixture"],
    ["p01-synthetic-token-b", "synthetic tenant B fixture"],
    ["p01-synthetic-token-a", "synthetic tenant A fixture"]
  ]) {
    const result = await request("/records", { token: item[0] });
    assert.equal(result.status, 200);
    assert.ok(result.body.data.some((row) => row.payload === item[1]));
    const other = item[0] === "p01-synthetic-token-a" ? "synthetic tenant B fixture" : "synthetic tenant A fixture";
    assert.equal(result.body.data.some((row) => row.payload === other), false);
  }

  const client = await pool.connect();
  try {
    const result = await client.query("SELECT current_setting('app.tenant_id', true) AS tenant_id");
    assert.ok(result.rows[0].tenant_id === null || result.rows[0].tenant_id === "");
  } finally {
    client.release();
  }
});

test("runtime role is not superuser, table owner or BYPASSRLS and FORCE RLS is enabled", async () => {
  const result = await pool.query(
    "SELECT r.rolsuper, r.rolbypassrls, r.rolcreatedb, r.rolcreaterole, c.relrowsecurity, c.relforcerowsecurity, pg_get_userbyid(c.relowner) AS table_owner, current_user AS runtime_role FROM pg_roles r JOIN pg_class c ON c.oid = 'public.tenant_records'::regclass WHERE r.rolname = current_user"
  );
  assert.equal(result.rows.length, 1);
  const role = result.rows[0];
  assert.equal(role.rolsuper, false);
  assert.equal(role.rolbypassrls, false);
  assert.equal(role.rolcreatedb, false);
  assert.equal(role.rolcreaterole, false);
  assert.equal(role.relrowsecurity, true);
  assert.equal(role.relforcerowsecurity, true);
  assert.notEqual(role.table_owner, role.runtime_role);

  const membershipPrivileges = await pool.query(
    "SELECT has_column_privilege(current_user, 'public.tenant_memberships', 'lock_version', 'UPDATE') AS can_update_lock_version, has_column_privilege(current_user, 'public.tenant_memberships', 'active', 'UPDATE') AS can_update_active"
  );
  assert.equal(membershipPrivileges.rows[0].can_update_lock_version, true);
  assert.equal(membershipPrivileges.rows[0].can_update_active, false);

  const policies = await pool.query(
    "SELECT policyname, permissive FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tenant_records' ORDER BY policyname"
  );
  assert.deepEqual(
    policies.rows.map((policy) => [policy.policyname, policy.permissive]),
    [
      ["tenant_records_app_access", "PERMISSIVE"],
      ["tenant_records_identity_guard", "PERMISSIVE"],
      ["tenant_records_tenant_guard", "RESTRICTIVE"]
    ]
  );
});

test("RLS blocks cross-tenant UPDATE and DELETE even when the object ID is known", async () => {
  const update = await withTenantTransaction(pool, TENANT_A, (client) =>
    client.query(
      "UPDATE public.tenant_records SET payload = 'tampered' WHERE record_id = $1 RETURNING record_id",
      [TENANT_B_ONLY_RECORD_ID]
    )
  );
  const remove = await withTenantTransaction(pool, TENANT_A, (client) =>
    client.query(
      "DELETE FROM public.tenant_records WHERE record_id = $1 RETURNING record_id",
      [TENANT_B_ONLY_RECORD_ID]
    )
  );
  assert.equal(update.rowCount, 0);
  assert.equal(remove.rowCount, 0);

  const stillThere = await request("/records/" + TENANT_B_ONLY_RECORD_ID, {
    token: "p01-synthetic-token-b"
  });
  assert.equal(stillThere.status, 200);
  assert.equal(stillThere.body.data.payload, "tenant B private fixture");
});

test("RLS WITH CHECK rejects a cross-tenant insert even if application code is bypassed", async () => {
  await assert.rejects(
    withTenantTransaction(pool, TENANT_A, (client) =>
      client.query(
        "INSERT INTO public.tenant_records (tenant_id, record_id, natural_key, payload) VALUES ($1, $2, $3, $4)",
        [TENANT_B, "cccccccc-cccc-4ccc-8ccc-cccccccccccc", "direct-forged", "must be rejected"]
      )
    ),
    (error) => error.code === "42501"
  );

  // The failed transaction must be rolled back before the pooled connection is reused.
  const a = await request("/records", { token: "p01-synthetic-token-a" });
  const b = await request("/records", { token: "p01-synthetic-token-b" });
  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.equal(b.body.data.some((row) => row.natural_key === "direct-forged"), false);
});

test("red-team boundary: a compromised shared runtime role can assert another tenant GUC", async () => {
  // This is an intentional threat-boundary demonstration, not a security pass.
  // The shared DB role is trusted application infrastructure. RLS GUC context
  // prevents accidental query omissions; it does not authenticate the app to DB.
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [TENANT_B]);
    const result = await client.query(
      "SELECT payload FROM public.tenant_records ORDER BY payload"
    );
    assert.ok(result.rows.some((row) => row.payload === "synthetic tenant B fixture"));
    assert.ok(result.rows.some((row) => row.payload === "tenant B private fixture"));
  } finally {
    await client.query("ROLLBACK");
    client.release();
  }
});


test("identity-bound per-tenant database roles resist GUC spoofing and role switching", async () => {
  for (const [poolForTenant, ownTenant, otherTenant, ownRecordId, ownPayload, otherRecordId] of [
    [tenantAPool, TENANT_A, TENANT_B, SHARED_RECORD_ID, "synthetic tenant A fixture", TENANT_B_ONLY_RECORD_ID],
    [tenantBPool, TENANT_B, TENANT_A, TENANT_B_ONLY_RECORD_ID, "tenant B private fixture", "dddddddd-dddd-4ddd-8ddd-dddddddddddd"]
  ]) {
    const identity = await poolForTenant.query(
      "SELECT session_user::text AS session_user, current_user::text AS current_user, private.current_tenant_id()::text AS tenant_id"
    );
    const expectedRole = ownTenant === TENANT_A ? "tenant_a_runtime" : "tenant_b_runtime";
    assert.equal(identity.rows[0].session_user, expectedRole);
    assert.equal(identity.rows[0].current_user, expectedRole);
    assert.equal(identity.rows[0].tenant_id, ownTenant);

    const functionSecurity = await poolForTenant.query(
      "SELECT p.prosecdef, p.proconfig, pg_get_userbyid(p.proowner) AS function_owner, r.rolcanlogin, r.rolsuper, r.rolbypassrls, has_schema_privilege(current_user, 'private', 'CREATE') AS can_create_in_private FROM pg_proc p JOIN pg_roles r ON r.rolname = pg_get_userbyid(p.proowner) WHERE p.oid = 'private.current_tenant_id()'::regprocedure"
    );
    assert.equal(functionSecurity.rows.length, 1);
    assert.equal(functionSecurity.rows[0].prosecdef, true);
    assert.equal(functionSecurity.rows[0].function_owner, "tenant_identity_owner");
    assert.equal(functionSecurity.rows[0].rolcanlogin, false);
    assert.equal(functionSecurity.rows[0].rolsuper, false);
    assert.equal(functionSecurity.rows[0].rolbypassrls, false);
    assert.equal(functionSecurity.rows[0].can_create_in_private, false);
    assert.ok(functionSecurity.rows[0].proconfig.includes("search_path=pg_catalog, private, pg_temp"));

    // Try to shadow the private identity map from a caller-controlled temp schema.
    await poolForTenant.query("CREATE TEMP TABLE tenant_role_map (database_role name, tenant_id uuid)");
    await poolForTenant.query(
      "INSERT INTO pg_temp.tenant_role_map (database_role, tenant_id) VALUES ($1, $2)",
      [expectedRole, otherTenant]
    );
    const afterTempShadow = await poolForTenant.query("SELECT private.current_tenant_id()::text AS tenant_id");
    assert.equal(afterTempShadow.rows[0].tenant_id, ownTenant);

    const roleState = await poolForTenant.query(
      "SELECT r.rolsuper, r.rolbypassrls, pg_has_role(session_user, $1, 'SET') AS can_set_other_role FROM pg_roles r WHERE r.rolname = session_user",
      [ownTenant === TENANT_A ? "tenant_b_runtime" : "tenant_a_runtime"]
    );
    assert.equal(roleState.rows[0].rolsuper, false);
    assert.equal(roleState.rows[0].rolbypassrls, false);
    assert.equal(roleState.rows[0].can_set_other_role, false);

    const expectedSubject = ownTenant === TENANT_A ? "synthetic-user-a" : "synthetic-user-b";
    const memberships = await poolForTenant.query(
      "SELECT subject_id FROM public.tenant_memberships ORDER BY subject_id"
    );
    assert.deepEqual(memberships.rows.map((row) => row.subject_id), [expectedSubject]);

    const jobs = await poolForTenant.query(
      "SELECT subject_id, payload FROM public.tenant_jobs ORDER BY job_id"
    );
    assert.ok(jobs.rowCount > 0);
    assert.equal(jobs.rows.every((row) => row.subject_id === expectedSubject), true);

    const ownRow = await poolForTenant.query(
      "SELECT payload FROM public.tenant_records WHERE record_id = $1",
      [ownRecordId]
    );
    assert.equal(ownRow.rowCount, 1);
    assert.equal(ownRow.rows[0].payload, ownPayload);

    const otherRow = await poolForTenant.query(
      "SELECT payload FROM public.tenant_records WHERE record_id = $1",
      [otherRecordId]
    );
    assert.equal(otherRow.rowCount, 0);

    // This role can set arbitrary custom GUCs, but the identity policy never reads them.
    await poolForTenant.query("SELECT set_config('app.tenant_id', $1, false)", [otherTenant]);
    const stillIsolated = await poolForTenant.query(
      "SELECT payload FROM public.tenant_records WHERE record_id = $1",
      [otherRecordId]
    );
    assert.equal(stillIsolated.rowCount, 0);

    await assert.rejects(
      poolForTenant.query("SET ROLE " + (ownTenant === TENANT_A ? "tenant_b_runtime" : "tenant_a_runtime")),
      (error) => error.code === "42501"
    );
    await assert.rejects(
      poolForTenant.query("SET SESSION AUTHORIZATION " + (ownTenant === TENANT_A ? "tenant_b_runtime" : "tenant_a_runtime")),
      (error) => error.code === "42501"
    );
    await assert.rejects(
      poolForTenant.query("SELECT * FROM private.tenant_role_map"),
      (error) => error.code === "42501"
    );
    await assert.rejects(
      poolForTenant.query(
        "INSERT INTO public.tenant_records (tenant_id, record_id, natural_key, payload) VALUES ($1, $2, $3, $4)",
        [otherTenant, "cccccccc-cccc-4ccc-8ccc-cccccccccccc", "identity-forged", "must be rejected"]
      ),
      (error) => error.code === "42501"
    );
  }
});


test("membership revocation waits for an in-flight tenant transaction holding FOR SHARE", async () => {
  let requestClient = await pool.connect();
  const revokeClient = await adminPool.connect();
  let releaseRequest;
  const releaseGate = new Promise((resolve) => { releaseRequest = resolve; });
  let lockedResolve;
  const lockAcquired = new Promise((resolve) => { lockedResolve = resolve; });
  let requestTransactionOpen = false;
  let revokeTransactionOpen = false;

  const inFlightRequest = (async () => {
    await requestClient.query("BEGIN");
    requestTransactionOpen = true;
    await requestClient.query("SELECT set_config('app.tenant_id', $1, true)", [TENANT_A]);
    const membership = await requestClient.query(
      "SELECT active FROM public.tenant_memberships WHERE subject_id = $1 FOR SHARE",
      ["synthetic-user-a"]
    );
    assert.equal(membership.rows[0]?.active, true);
    lockedResolve();
    await releaseGate;
    await requestClient.query("COMMIT");
    requestTransactionOpen = false;
  })();

  try {
    await lockAcquired;
    await revokeClient.query("BEGIN");
    revokeTransactionOpen = true;
    const pidResult = await revokeClient.query("SELECT pg_backend_pid() AS pid");
    const revokePid = pidResult.rows[0].pid;
    let updateError;
    let updateFinished = false;
    const update = revokeClient.query(
      "UPDATE public.tenant_memberships SET active = false WHERE tenant_id = $1 AND subject_id = $2",
      [TENANT_A, "synthetic-user-a"]
    ).then(
      () => { updateFinished = true; },
      (error) => { updateError = error; updateFinished = true; }
    );

    let waitingOnLock = false;
    for (let attempt = 0; attempt < 100; attempt += 1) {
      const observed = await adminObserverPool.query(
        "SELECT wait_event_type FROM pg_stat_activity WHERE pid = $1",
        [revokePid]
      );
      if (observed.rows[0]?.wait_event_type === "Lock") {
        waitingOnLock = true;
        break;
      }
      await delay(20);
    }
    assert.equal(waitingOnLock, true, "revocation UPDATE should wait on the in-flight membership row lock");
    assert.equal(updateFinished, false, "revocation must not pass the active request's FOR SHARE lock");

    releaseRequest();
    await inFlightRequest;
    requestClient.release();
    requestClient = null;
    await update;
    if (updateError) throw updateError;
    assert.equal(updateFinished, true);
    await revokeClient.query("COMMIT");
    revokeTransactionOpen = false;

    const subsequentRequest = await request("/records", { token: "p01-synthetic-token-a" });
    assert.equal(subsequentRequest.status, 403);
  } finally {
    releaseRequest();
    await inFlightRequest.catch(() => {});
    if (requestClient) {
      if (requestTransactionOpen) {
        try { await requestClient.query("ROLLBACK"); } catch {}
      }
      requestClient.release();
    }
    if (revokeTransactionOpen) {
      try { await revokeClient.query("ROLLBACK"); } catch {}
    }
    try {
      await revokeClient.query(
        "UPDATE public.tenant_memberships SET active = true WHERE tenant_id = $1 AND subject_id = $2",
        [TENANT_A, "synthetic-user-a"]
      );
    } finally {
      revokeClient.release();
    }
  }
});

test("database access without transaction-local tenant context is default-deny", async () => {
  const visible = await pool.query("SELECT count(*)::int AS count FROM public.tenant_records");
  assert.equal(visible.rows[0].count, 0);
  await assert.rejects(
    pool.query(
      "INSERT INTO public.tenant_records (tenant_id, record_id, natural_key, payload) VALUES ($1, $2, $3, $4)",
      [TENANT_A, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", "no-context", "must fail"]
    ),
    (error) => error.code === "42501"
  );
});



test("support principal can read only a tenant record covered by its active grant and emits an audit event", async () => {
  const result = await request("/support/tenants/" + TENANT_A + "/records/" + SHARED_RECORD_ID, {
    token: "p01-synthetic-support-token", headers: { "x-support-grant-id": SUPPORT_GRANT_ACTIVE }
  });
  assert.equal(result.status, 200);
  assert.equal(result.body.data.payload, "synthetic tenant A fixture");
  const audit = await adminPool.query("SELECT support_subject_id, grant_id, tenant_id, resource_id, action, outcome, reason FROM public.support_audit WHERE grant_id = $1", [SUPPORT_GRANT_ACTIVE]);
  assert.equal(audit.rowCount, 1);
  assert.equal(audit.rows[0].support_subject_id, "synthetic-support-a");
  assert.equal(audit.rows[0].tenant_id, TENANT_A);
  assert.equal(audit.rows[0].resource_id, SHARED_RECORD_ID);
  assert.equal(audit.rows[0].action, "records:read");
  assert.equal(audit.rows[0].outcome, "allowed");
  assert.match(audit.rows[0].reason, /Customer requested investigation/);
});

test("support grant rejects expired, revoked, wrong-subject, wrong-tenant and unknown grants with denial audit", async () => {
  const cases = [
    ["p01-synthetic-support-token", TENANT_A, SUPPORT_GRANT_EXPIRED],
    ["p01-synthetic-support-token", TENANT_A, SUPPORT_GRANT_REVOKED],
    ["p01-synthetic-support-other-token", TENANT_A, SUPPORT_GRANT_ACTIVE],
    ["p01-synthetic-support-token", TENANT_B, SUPPORT_GRANT_ACTIVE],
    ["p01-synthetic-support-token", TENANT_A, "77777777-7777-4777-8777-777777777777"],
    ["p01-synthetic-support-token", TENANT_A, SUPPORT_GRANT_OTHER_TENANT]
  ];
  for (const [token, tenantId, grantId] of cases) {
    const result = await request("/support/tenants/" + tenantId + "/records/" + SHARED_RECORD_ID, {
      token, headers: { "x-support-grant-id": grantId }
    });
    assert.equal(result.status, 403);
    assert.equal(result.body.error, "support_access_denied");
  }
  const denied = await adminPool.query("SELECT count(*)::int AS count FROM public.support_audit WHERE outcome = 'denied'");
  assert.equal(denied.rows[0].count, cases.length);
});

test("support principals cannot use tenant routes or mutate records, and tenant principals cannot use support routes", async () => {
  const list = await request("/records", { token: "p01-synthetic-support-token" });
  assert.equal(list.status, 403);
  const mutation = await request("/records", {
    token: "p01-synthetic-support-token", method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ natural_key: "support-write", payload: "must not write" })
  });
  assert.equal(mutation.status, 403);
  const tenantToSupport = await request("/support/tenants/" + TENANT_A + "/records/" + SHARED_RECORD_ID, {
    token: "p01-synthetic-token-a", headers: { "x-support-grant-id": SUPPORT_GRANT_ACTIVE }
  });
  assert.equal(tenantToSupport.status, 403);
});

test("support-authorizer role has only intended metadata and audit privileges", async () => {
  const role = await adminPool.query("SELECT rolsuper, rolbypassrls, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname = 'support_authorizer'");
  assert.equal(role.rowCount, 1);
  assert.deepEqual(role.rows[0], { rolsuper: false, rolbypassrls: false, rolcreatedb: false, rolcreaterole: false });
  const grants = await adminPool.query("SELECT has_table_privilege('support_authorizer', 'public.support_grants', 'SELECT') AS can_read_grants, has_table_privilege('support_authorizer', 'public.support_audit', 'INSERT') AS can_append_audit, has_table_privilege('support_authorizer', 'public.support_audit', 'SELECT') AS can_read_audit, has_table_privilege('support_authorizer', 'public.tenant_records', 'SELECT') AS can_read_records, has_table_privilege('support_authorizer', 'public.tenant_jobs', 'SELECT') AS can_read_jobs, has_column_privilege('support_authorizer', 'public.support_grants', 'revoked_at', 'UPDATE') AS can_revoke_grants");
  assert.deepEqual(grants.rows[0], { can_read_grants: true, can_append_audit: true, can_read_audit: false, can_read_records: false, can_read_jobs: false, can_revoke_grants: false });
});

test("support-authorizer cannot read tenant payloads, job payloads or audit history and cannot mutate audit rows", async () => {
  await assert.rejects(supportPool.query("SELECT payload FROM public.tenant_records"), (error) => error.code === "42501");
  await assert.rejects(supportPool.query("SELECT payload FROM public.tenant_jobs"), (error) => error.code === "42501");
  await assert.rejects(supportPool.query("SELECT * FROM public.support_audit"), (error) => error.code === "42501");
  await assert.rejects(supportPool.query("UPDATE public.support_audit SET reason = 'tampered'"), (error) => error.code === "42501");
  await assert.rejects(supportPool.query("UPDATE public.support_grants SET revoked_at = clock_timestamp()"), (error) => error.code === "42501");
  await assert.rejects(supportPool.query("DELETE FROM public.support_grants"), (error) => error.code === "42501");
  await assert.rejects(supportPool.query("DELETE FROM public.support_audit"), (error) => error.code === "42501");
});

test("grant revocation blocks behind an in-flight authorized support read lock", async () => {
  const lockClient = await supportPool.connect();
  let locked = false;
  try {
    await lockClient.query("BEGIN");
    const grant = await lockClient.query("SELECT grant_id FROM public.support_grants WHERE grant_id = $1 AND revoked_at IS NULL FOR SHARE", [SUPPORT_GRANT_ACTIVE]);
    assert.equal(grant.rowCount, 1);
    locked = true;
    let updateFinished = false;
    const revokePromise = adminPool.query("UPDATE public.support_grants SET revoked_at = clock_timestamp() WHERE grant_id = $1", [SUPPORT_GRANT_ACTIVE]).then((result) => {
      updateFinished = true; return result;
    });
    let observedLockWait = false;
    const deadline = Date.now() + 2000;
    while (Date.now() < deadline && !observedLockWait) {
      const waiting = await adminPool.query("SELECT EXISTS (SELECT 1 FROM pg_stat_activity WHERE wait_event_type = 'Lock' AND query LIKE 'UPDATE public.support_grants%') AS blocked");
      observedLockWait = waiting.rows[0].blocked;
      if (!observedLockWait) await delay(10);
    }
    assert.equal(observedLockWait, true, "revocation UPDATE should wait on support grant row lock");
    assert.equal(updateFinished, false);
    await lockClient.query("COMMIT");
    locked = false;
    await revokePromise;
  } finally {
    if (locked) await lockClient.query("ROLLBACK");
    lockClient.release();
  }
  const denied = await request("/support/tenants/" + TENANT_A + "/records/" + SHARED_RECORD_ID, {
    token: "p01-synthetic-support-token", headers: { "x-support-grant-id": SUPPORT_GRANT_ACTIVE }
  });
  assert.equal(denied.status, 403);
});
