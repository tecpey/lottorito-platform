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
  const picked=await c.query("SELECT event_id FROM partner_events WHERE tenant_id=private.current_tenant_id() AND product_id=private.current_product_id() AND canonical_payload IS NULL ORDER BY created_at,event_id LIMIT $1 FOR UPDATE SKIP LOCKED",[size]);
  const ids=picked.rows.map(row=>row.event_id);
  if(ids.length===0){await c.query("COMMIT");return 0;}
  const updated=await c.query("UPDATE partner_events SET canonical_payload=payload WHERE tenant_id=private.current_tenant_id() AND product_id=private.current_product_id() AND event_id=ANY($1::uuid[]) AND canonical_payload IS NULL RETURNING event_id",[ids]);
  await c.query("COMMIT");return updated.rowCount;
 }catch(e){await c.query("ROLLBACK");throw e;}finally{c.release();}
}
export async function recoverConcurrentIndex(pool){
 const name="public.p04_events_tenant_created_idx";
 const expected="CREATE INDEX p04_events_tenant_created_idx ON public.partner_events USING btree (tenant_id, product_id, created_at, event_id)";
 const c=await pool.connect();let locked=false,destroy=false;
 try{
  await c.query("SELECT pg_advisory_lock(hashtextextended($1,0))",[name]);locked=true;
  const r=await c.query("SELECT i.indisvalid,i.indisready,pg_get_indexdef(i.indexrelid) AS definition FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass($1)",[name]);
  if(r.rowCount&&r.rows[0].indisvalid&&r.rows[0].indisready){
   if(r.rows[0].definition!==expected)throw new Error("concurrent index definition mismatch");
   return false;
  }
  if(r.rowCount)await c.query("DROP INDEX CONCURRENTLY public.p04_events_tenant_created_idx");
  await c.query("CREATE INDEX CONCURRENTLY p04_events_tenant_created_idx ON public.partner_events(tenant_id,product_id,created_at,event_id)");
  const verified=await c.query("SELECT i.indisvalid,i.indisready,pg_get_indexdef(i.indexrelid) AS definition FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass($1)",[name]);
  if(verified.rowCount!==1||!verified.rows[0].indisvalid||!verified.rows[0].indisready||verified.rows[0].definition!==expected)throw new Error("concurrent index recovery verification failed");
  return true;
 }catch(error){destroy=true;throw error;}
 finally{
  if(locked){try{await c.query("SELECT pg_advisory_unlock(hashtextextended($1,0))",[name]);}catch{destroy=true;}}
  c.release(destroy);
 }
}
