import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { Client } from "pg";

const connectionString = process.env.ADMIN_DATABASE_URL;
if (!connectionString) throw new Error("ADMIN_DATABASE_URL must target a disposable P-03 database");

const client = new Client({ connectionString });
const files = [
  new URL("../../p02-ledger-posting/db/schema.sql", import.meta.url),
  new URL("../db/provider-schema.sql", import.meta.url)
];

try {
  await client.connect();
  for (const url of files) {
    const sql = await readFile(fileURLToPath(url), "utf8");
    await client.query(sql);
  }
  process.stdout.write("P-03 synthetic provider-event schema prepared.\n");
} finally {
  await client.end();
}
