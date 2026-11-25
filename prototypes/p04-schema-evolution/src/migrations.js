import {createHash} from "node:crypto";
export async function applyMigration(pool,id,sql){
 if(!/^[a-z0-9][a-z0-9._-]{2,100}$/.test(id))throw new TypeError("invalid migration id");
 const checksum=createHash("sha256").update(sql).digest("hex"),c=await pool.connect();
 try{
  await c.query("BEGIN");await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))",[id]);
  const old=await c.query("SELECT checksum FROM schema_migrations WHERE migration_id=$1",[id]);
  if(old.rowCount){if(old.rows[0].checksum!==checksum)throw new Error("migration checksum mismatch");await c.query("COMMIT");return false;}
  await c.query(sql);await c.query("INSERT INTO schema_migrations(migration_id,checksum) VALUES($1,$2)",[id,checksum]);await c.query("COMMIT");return true;
 }catch(e){await c.query("ROLLBACK");throw e;}finally{c.release();}
}
export async function backfillBatch(pool,size=100){
 if(!Number.isInteger(size)||size<1||size>500)throw new RangeError("batch size must be 1..500");
 const c=await pool.connect();
 try{
  await c.query("BEGIN");await c.query("SET LOCAL lock_timeout='2s'");
  const picked=await c.query("SELECT event_id FROM partner_events WHERE canonical_payload IS NULL ORDER BY created_at,event_id LIMIT $1 FOR UPDATE SKIP LOCKED",[size]);
  const ids=picked.rows.map(row=>row.event_id);
  if(ids.length===0){await c.query("COMMIT");return 0;}
  const updated=await c.query("UPDATE partner_events SET canonical_payload=payload WHERE event_id=ANY($1::uuid[]) AND canonical_payload IS NULL RETURNING event_id",[ids]);
  await c.query("COMMIT");return updated.rowCount;
 }catch(e){await c.query("ROLLBACK");throw e;}finally{c.release();}
}
export async function recoverConcurrentIndex(pool){
 const name="public.p04_events_tenant_created_idx";
 const r=await pool.query("SELECT i.indisvalid FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass($1)",[name]);
 if(r.rowCount&&r.rows[0].indisvalid)return false;
 if(r.rowCount)await pool.query("DROP INDEX CONCURRENTLY public.p04_events_tenant_created_idx");
 await pool.query("CREATE INDEX CONCURRENTLY p04_events_tenant_created_idx ON public.partner_events(tenant_id,created_at,event_id)");return true;
}
