import test, { before, after } from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { Pool } from "pg";
import { createTenantServer } from "../src/app.js";
import {
  authenticateSyntheticRequest,
  TENANT_A,
  TENANT_B,
  SHARED_RECORD_ID,
  TENANT_B_ONLY_RECORD_ID
} from "./fixtures.js";

const databaseUrl = process.env.DATABASE_URL;
assert.ok(databaseUrl, "DATABASE_URL must point to the least-privilege app_runtime role");

const pool = new Pool({
  connectionString: databaseUrl,
  max: 1,
  idleTimeoutMillis: 1000,
  connectionTimeoutMillis: 3000
});
const server = createTenantServer({ pool, authenticate: authenticateSyntheticRequest });
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
});

after(async () => {
  server.close();
  await once(server, "close");
  await pool.end();
});

test("missing and invalid synthetic credentials cannot access tenant data", async () => {
  const missing = await request("/records");
  const invalid = await request("/records", { token: "not-a-valid-token" });
  assert.equal(missing.status, 401);
  assert.equal(invalid.status, 401);
});

test("RLS returns only rows for the authenticated tenant", async () => {
  const a = await request("/records", { token: "p01-synthetic-token-a" });
  const b = await request("/records", { token: "p01-synthetic-token-b" });
  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.equal(a.body.data.length, 1);
  assert.equal(b.body.data.length, 2);
  assert.equal(a.body.data[0].payload, "synthetic tenant A fixture");
  assert.ok(b.body.data.some((row) => row.payload === "synthetic tenant B fixture"));
  assert.ok(b.body.data.some((row) => row.payload === "tenant B private fixture"));
});

test("a forged tenant header cannot switch the authenticated tenant", async () => {
  const result = await request("/records", {
    token: "p01-synthetic-token-a",
    headers: { "x-tenant-id": TENANT_B }
  });
  assert.equal(result.status, 200);
  assert.equal(result.body.data.length, 1);
  assert.equal(result.body.data[0].payload, "synthetic tenant A fixture");
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
