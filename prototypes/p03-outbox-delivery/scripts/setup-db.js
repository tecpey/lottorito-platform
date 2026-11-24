import { readFile } from "node:fs/promises";
import { Pool } from "pg";

const adminUrl = process.env.ADMIN_DATABASE_URL;
if (!adminUrl) throw new Error("ADMIN_DATABASE_URL must target the disposable P-03 database");
const pool = new Pool({ connectionString: adminUrl, max: 1 });
try {
  const schema = await readFile(new URL("../db/schema.sql", import.meta.url), "utf8");
  const functions = await readFile(new URL("../db/functions.sql", import.meta.url), "utf8");
  await pool.query(schema);
  await pool.query(functions);
  await pool.query(
    "INSERT INTO private.tenant_role_map(database_role,tenant_id) VALUES ($1,$2),($3,$4)",
    [
      "tenant_a_outbox_runtime", "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "tenant_b_outbox_runtime", "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
    ]
  );
  console.log("P-03 disposable schema and tenant identities initialized");
} finally {
  await pool.end();
}
