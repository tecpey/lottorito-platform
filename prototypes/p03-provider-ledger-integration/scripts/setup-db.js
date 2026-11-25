import { readFile } from "node:fs/promises";
import { Pool } from "pg";

const adminUrl = process.env.ADMIN_DATABASE_URL;
if (!adminUrl) throw new Error("ADMIN_DATABASE_URL must target the disposable P-03D database");
const pool = new Pool({ connectionString: adminUrl, max: 1 });

try {
  const p02 = await readFile(new URL("../../p02-ledger-posting/db/schema.sql", import.meta.url), "utf8");
  const p03c = await readFile(new URL("../../p03-ledger-outbox-integration/db/integration.sql", import.meta.url), "utf8");
  const p03d = await readFile(new URL("../db/integration.sql", import.meta.url), "utf8");
  await pool.query(p02);
  await pool.query(p03c);
  await pool.query(p03d);

  const result = await pool.query(`
    SELECT
      to_regclass('public.ledger_outbox') IS NOT NULL AS ledger_outbox_exists,
      to_regclass('public.outbox_events') IS NOT NULL AS duplicate_source_exists,
      to_regclass('public.outbox_delivery_state') IS NOT NULL AS delivery_state_exists,
      to_regclass('public.provider_event_inbox') IS NOT NULL AS provider_inbox_exists,
      (SELECT count(*)::int FROM public.ledger_accounts) AS account_count,
      (SELECT count(*)::int FROM private.tenant_role_map) AS role_map_count,
      (SELECT count(*)::int FROM information_schema.columns
        WHERE table_schema='public' AND table_name='ledger_outbox' AND column_name='product_id') AS outbox_product_column
  `);
  const row = result.rows[0];
  if (!row.ledger_outbox_exists || row.duplicate_source_exists || !row.delivery_state_exists ||
      !row.provider_inbox_exists || row.account_count !== 8 || row.role_map_count !== 3 ||
      row.outbox_product_column !== 1) {
    throw new Error("P-03D combined P-02/P-03C/P-03D schema invariant failed");
  }
  console.log("P-03D combined schema prepared: tenant/product identity, immutable ledger source, provider inbox and delivery state");
} finally {
  await pool.end();
}
