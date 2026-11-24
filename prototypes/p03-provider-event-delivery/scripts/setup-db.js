import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { Client } from "pg";

const connectionString = process.env.ADMIN_DATABASE_URL;
if (!connectionString) throw new Error("ADMIN_DATABASE_URL is required for a disposable PostgreSQL database");
const schema = await readFile(fileURLToPath(new URL("../db/schema.sql", import.meta.url)), "utf8");
const client = new Client({ connectionString });
try {
  await client.connect();
  await client.query(schema);
  process.stdout.write("P-03 synthetic provider-event schema prepared.\n");
} finally {
  await client.end();
}
