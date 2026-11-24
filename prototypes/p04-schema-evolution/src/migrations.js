import {createHash} from "node:crypto";
export async function applyMigration(pool,id,sql){
 if(!/^[a-z0-9][a-z0-9._-]{2,100}$/.test(id))throw new TypeError("invalid migration id");
 const checksum=createHash("sha256").update(sql).digest("hex"),c=await pool.connect();
 try{
  await c.query("BEGIN");await c.query("SELECT pg_advisory_xact_lock(hashtext($1)::bigint)",[id]);
  const old=await c.query("SELECT checksum FROM schema_migrations WHERE migration_id=$1",[id]);
  if(old.rowCount){if(old.rows[0].checksum!==checksum)throw new Error("migration checksum mismatch");await c.query("COMMIT");return false;}
  await c.query(sql);await c.query("INSERT INTO schema_migrations(migration_id,checksum) VALUES($1,$2)",[id,checksum]);await c.query("COMMIT");return true;
 }catch(e){await c.query("ROLLBACK");throw e;}finally{c.release();}
}
export async function backfillBatch(pool,size=100){
 if(!Number.isInteger(size)||size<1||size>500)throw new RangeError("batch size must be 1..500");
 const c=await pool.connect();
 try{await c.query("BEGIN");await c.query("SET LOCAL lock_timeout='2s'");
 const q="WITH b AS (SELECT tenant_id,event_id FROM partner_events WHERE canonical_payload IS NULL ORDER BY created_at,event_id LIMIT $1 FOR UPDATE SKIP LOCKED) UPDATE partner_events e SET canonical_payload=e.payload FROM b WHERE e.tenant_id=b.tenant_id AND e.event_id=b.event_id AND e.canonical_payload IS NULL RETURNING e.event_id";
 const r=await c.query(q,[size]);await c.query("COMMIT");return r.rowCount;
 }catch(e){await c.query("ROLLBACK");throw e;}finally{c.release();}
}
export async function recoverConcurrentIndex(pool){
 const name="public.p04_events_tenant_created_idx";
 const r=await pool.query("SELECT i.indisvalid FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass($1)",[name]);
 if(r.rowCount&&r.rows[0].indisvalid)return false;
 if(r.rowCount)await pool.query("DROP INDEX CONCURRENTLY public.p04_events_tenant_created_idx");
 await pool.query("CREATE INDEX CONCURRENTLY p04_events_tenant_created_idx ON public.partner_events(tenant_id,created_at,event_id)");return true;
}
