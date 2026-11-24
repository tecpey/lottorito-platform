import test,{before,after} from "node:test";import assert from "node:assert/strict";import{readFile}from"node:fs/promises";import{Pool}from"pg";import{applyMigration,backfillBatch,recoverConcurrentIndex}from"../src/migrations.js";
const u={admin:process.env.ADMIN_DATABASE_URL,a1:process.env.TENANT_A_V1_DATABASE_URL,a2:process.env.TENANT_A_V2_DATABASE_URL,b1:process.env.TENANT_B_V1_DATABASE_URL,b2:process.env.TENANT_B_V2_DATABASE_URL};for(const[k,v]of Object.entries(u))assert.ok(v,"missing "+k);
const admin=new Pool({connectionString:u.admin});let a1,a2,b1,b2;const A="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",B="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";const id=n=>"00000000-0000-4000-8000-"+String(n).padStart(12,"0");
before(async()=>{
 await admin.query(await readFile(new URL("../db/001-baseline.sql",import.meta.url),"utf8"));
 for(let i=1;i<=4;i++)await admin.query("INSERT INTO partner_events(tenant_id,event_id,event_type,payload) VALUES($1,$2,'deposit',$3::jsonb)",[A,id(i),JSON.stringify({legacy:i})]);
 for(let i=5;i<=6;i++)await admin.query("INSERT INTO partner_events(tenant_id,event_id,event_type,payload) VALUES($1,$2,'deposit',$3::jsonb)",[B,id(i),JSON.stringify({legacy:i})]);
 for(const[t,j]of[[A,id(101)],[B,id(102)]]){await admin.query("INSERT INTO ledger_journals VALUES($1,$2,'USD')",[t,j]);await admin.query("INSERT INTO ledger_lines VALUES($1,$2,1,'debit',1000),($1,$2,2,'credit',1000)",[t,j]);}
 await admin.query("INSERT INTO reporting_daily VALUES($1,CURRENT_DATE,4),($2,CURRENT_DATE,2)",[A,B]);
 a1=new Pool({connectionString:u.a1});a2=new Pool({connectionString:u.a2});b1=new Pool({connectionString:u.b1});b2=new Pool({connectionString:u.b2});
 await applyMigration(admin,"p04-expand-v1",await readFile(new URL("../db/002-expand.sql",import.meta.url),"utf8"));
});after(async()=>{await Promise.all([admin.end(),a1?.end(),a2?.end(),b1?.end(),b2?.end()]);});
test("v1/v2 writers and readers coexist in both directions",async()=>{
   await a1.query("INSERT INTO partner_events(tenant_id,event_id,event_type,payload) VALUES($1,$2,'v1',$3::jsonb)",[A,id(201),JSON.stringify({v:1})]);
   await a2.query("INSERT INTO partner_events(tenant_id,event_id,event_type,canonical_payload) VALUES($1,$2,'v2',$3::jsonb)",[A,id(202),JSON.stringify({v:2})]);
 assert.deepEqual((await a2.query("SELECT canonical_payload FROM partner_events WHERE event_id=$1",[id(201)])).rows[0].canonical_payload,{v:1});
 assert.deepEqual((await a1.query("SELECT payload FROM partner_events WHERE event_id=$1",[id(202)])).rows[0].payload,{v:2});
 await b1.query("INSERT INTO partner_events(tenant_id,event_id,event_type,payload) VALUES($1,$2,'worker-v1',$3::jsonb)",[B,id(203),JSON.stringify({worker:"v1"})]);
 await b2.query("INSERT INTO partner_events(tenant_id,event_id,event_type,canonical_payload) VALUES($1,$2,'worker-v2',$3::jsonb)",[B,id(204),JSON.stringify({worker:"v2"})]);
 assert.deepEqual((await b2.query("SELECT canonical_payload FROM partner_events WHERE event_id=$1",[id(203)])).rows[0].canonical_payload,{worker:"v1"});
 assert.deepEqual((await b1.query("SELECT payload FROM partner_events WHERE event_id=$1",[id(204)])).rows[0].payload,{worker:"v2"});
});
test("conflicting dual-write fails closed",async()=>{await assert.rejects(a2.query("UPDATE partner_events SET payload=$1::jsonb,canonical_payload=$2::jsonb WHERE event_id=$3",[JSON.stringify({v:1}),JSON.stringify({v:2}),id(201)]),e=>e.code==="23514");});
test("backfill stops and resumes; RLS scopes each tenant",async()=>{
 assert.equal(await backfillBatch(a1,2),2);await a1.end();a1=new Pool({connectionString:u.a1});
 let n=0;while(await backfillBatch(a1,2))n++;assert.equal(n,2);
 assert.equal((await a1.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n,0);
 assert.equal(await backfillBatch(b2,2),2);assert.equal((await a1.query("SELECT * FROM partner_events WHERE tenant_id=$1",[B])).rowCount,0);
   await assert.rejects(a1.query("INSERT INTO partner_events(tenant_id,event_id,event_type,payload) VALUES($1,$2,'spoof',$3::jsonb)",[B,id(299),JSON.stringify({x:1})]),e=>e.code==="42501");
});
test("migration replay is idempotent and checksum drift is rejected",async()=>{
 assert.equal(await applyMigration(admin,"p04-repeat-v1","SELECT 1"),true);assert.equal(await applyMigration(admin,"p04-repeat-v1","SELECT 1"),false);
 await assert.rejects(applyMigration(admin,"p04-repeat-v1","SELECT 2"),/checksum mismatch/);
 await assert.rejects(applyMigration(admin,"p04-fail-v1","THIS IS NOT SQL"));
 assert.equal((await admin.query("SELECT 1 FROM schema_migrations WHERE migration_id='p04-fail-v1'")).rowCount,0);
});
test("lock timeout aborts blocked DDL without partial schema change",async()=>{
 const lock=await a1.connect(),ddl=await admin.connect();try{await lock.query("BEGIN");await lock.query("SELECT event_id FROM partner_events WHERE event_id=$1 FOR UPDATE",[id(1)]);await ddl.query("SET lock_timeout='150ms'");
 await assert.rejects(ddl.query("ALTER TABLE partner_events ADD COLUMN lock_probe text"),e=>e.code==="55P03");
 assert.equal((await admin.query("SELECT 1 FROM information_schema.columns WHERE table_name='partner_events' AND column_name='lock_probe'")).rowCount,0);
 }finally{await lock.query("ROLLBACK");await ddl.query("RESET lock_timeout");lock.release();ddl.release();}
});
test("failed concurrent unique index leaves invalid index and recovery replaces it",async()=>{
 await assert.rejects(admin.query("CREATE UNIQUE INDEX CONCURRENTLY p04_events_tenant_created_idx ON partner_events(event_type)"));
 const invalid=await admin.query("SELECT i.indisvalid FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass('public.p04_events_tenant_created_idx')");
 assert.equal(invalid.rowCount,1);assert.equal(invalid.rows[0].indisvalid,false);assert.equal(await recoverConcurrentIndex(admin),true);
 assert.equal((await admin.query("SELECT i.indisvalid FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass('public.p04_events_tenant_created_idx')")).rows[0].indisvalid,true);
});
test("ledger/reporting remain unchanged and contract rehearsal is non-destructive",async()=>{
 const r=await admin.query("SELECT count(*)::int j,(SELECT count(*)::int FROM ledger_lines) l,(SELECT sum(amount_minor)::text FROM ledger_lines WHERE side='debit') d,(SELECT sum(amount_minor)::text FROM ledger_lines WHERE side='credit') c");
 assert.equal(r.rows[0].j,2);assert.equal(r.rows[0].l,4);assert.equal(r.rows[0].d,r.rows[0].c);
 assert.equal((await admin.query("SELECT sum(event_count)::int n FROM reporting_daily")).rows[0].n,6);
 assert.equal((await admin.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n,0);
 await admin.query("ALTER TABLE partner_events VALIDATE CONSTRAINT p04_payload_object");
 await admin.query("CREATE TEMP TABLE contract_projection AS SELECT tenant_id,event_id,canonical_payload FROM partner_events");
 assert.equal((await admin.query("SELECT count(*)::int n FROM contract_projection")).rows[0].n,(await admin.query("SELECT count(*)::int n FROM partner_events")).rows[0].n);
 assert.equal((await admin.query("SELECT 1 FROM information_schema.columns WHERE table_name='partner_events' AND column_name='payload'")).rowCount,1);
});
