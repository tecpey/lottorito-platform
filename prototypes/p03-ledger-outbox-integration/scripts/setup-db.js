import { readFile } from "node:fs/promises";
import { Pool } from "pg";

const adminUrl = process.env.ADMIN_DATABASE_URL;
if (!adminUrl) throw new Error("ADMIN_DATABASE_URL must target a disposable P-03C database");
const pool = new Pool({ connectionString: adminUrl, max: 1 });

try {
  await pool.query(`
    DROP TABLE IF EXISTS public.consumer_effects, public.consumer_inbox,
      public.outbox_delivery_state CASCADE;
    DROP FUNCTION IF EXISTS public.claim_outbox_events(integer,integer,text);
    DROP FUNCTION IF EXISTS public.ack_outbox_event(uuid,uuid);
    DROP FUNCTION IF EXISTS public.nack_outbox_event(uuid,uuid,text,integer);
    DROP FUNCTION IF EXISTS public.consume_outbox_event(text,uuid);
  `);
  const p02Schema = await readFile(new URL("../../p02-ledger-posting/db/schema.sql", import.meta.url), "utf8");
  const p03cSchema = await readFile(new URL("../db/integration.sql", import.meta.url), "utf8");
  await pool.query(p02Schema);
  await pool.query(p03cSchema);
  const objects = await pool.query(`
    SELECT
      to_regclass('public.ledger_outbox') IS NOT NULL AS ledger_outbox_exists,
      to_regclass('public.outbox_events') IS NOT NULL AS duplicate_source_exists,
      to_regclass('public.outbox_delivery_state') IS NOT NULL AS delivery_state_exists,
      (SELECT count(*)::int FROM public.ledger_accounts) AS account_count
  `);
  const row = objects.rows[0];
  if (!row.ledger_outbox_exists || row.duplicate_source_exists || !row.delivery_state_exists || row.account_count !== 8) {
    throw new Error("P-03C combined schema invariant failed");
  }
  console.log("P-03C combined P-02/P-03 schema prepared; ledger_outbox is the single immutable source");
} finally {
  await pool.end();
}
