import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { Client } from "pg";

const connectionString = process.env.ADMIN_DATABASE_URL;
if (!connectionString) throw new Error("ADMIN_DATABASE_URL must target a disposable P-02 database");

const schemaPath = new URL("../db/schema.sql", import.meta.url);
const schema = await readFile(fileURLToPath(schemaPath), "utf8");
const client = new Client({ connectionString });

try {
  await client.connect();
  await client.query(schema);
  process.stdout.write("P-02 synthetic ledger schema prepared.\n");
} finally {
  await client.end();
}
