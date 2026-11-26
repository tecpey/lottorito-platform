import test,{before,after}from"node:test";import assert from"node:assert/strict";import{readFile}from"node:fs/promises";import{Pool}from"pg";import{applyMigration,backfillBatch,recoverConcurrentIndex}from"../src/migrations.js";
const u={admin:process.env.ADMIN_DATABASE_URL,a1:process.env.TENANT_A_V1_DATABASE_URL,a2:process.env.TENANT_A_V2_DATABASE_URL,b1:process.env.TENANT_B_V1_DATABASE_URL,b2:process.env.TENANT_B_V2_DATABASE_URL,l1:process.env.TENANT_A_LOTTERY_V1_DATABASE_URL,l2:process.env.TENANT_A_LOTTERY_V2_DATABASE_URL};for(const[k,v]of Object.entries(u))assert.ok(v,"missing "+k);
const admin=new Pool({connectionString:u.admin});let a1,a2,b1,b2,l1,l2;const A="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",B="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",AFF="affiliate_agent",LOT="lottery";const id=n=>"00000000-0000-4000-8000-"+String(n).padStart(12,"0");
before(async()=>{
 await admin.query(await readFile(new URL("../db/001-baseline.sql",import.meta.url),"utf8"));
 for(let i=1;i<=4;i++)await admin.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'deposit',$4::jsonb)",[A,AFF,id(i),JSON.stringify({legacy:i})]);
 for(let i=1;i<=2;i++)await admin.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'deposit',$4::jsonb)",[A,LOT,id(i),JSON.stringify({lottery_legacy:i})]);
 for(let i=5;i<=6;i++)await admin.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'deposit',$4::jsonb)",[B,AFF,id(i),JSON.stringify({legacy:i})]);
 for(const[t,p,j]of[[A,AFF,id(101)],[A,LOT,id(101)],[B,AFF,id(102)]]){await admin.query("INSERT INTO ledger_journals(tenant_id,product_id,journal_id,currency) VALUES($1,$2,$3,'USD')",[t,p,j]);await admin.query("INSERT INTO ledger_lines(tenant_id,product_id,journal_id,line_no,side,amount_minor) VALUES($1,$2,$3,1,'debit',1000),($1,$2,$3,2,'credit',1000)",[t,p,j]);}
 await admin.query("INSERT INTO reporting_daily(tenant_id,product_id,report_day,event_count) VALUES($1,$2,CURRENT_DATE,4),($1,$3,CURRENT_DATE,2),($4,$2,CURRENT_DATE,2)",[A,AFF,LOT,B]);
 a1=new Pool({connectionString:u.a1});a2=new Pool({connectionString:u.a2});b1=new Pool({connectionString:u.b1});b2=new Pool({connectionString:u.b2});l1=new Pool({connectionString:u.l1});l2=new Pool({connectionString:u.l2});
 await applyMigration(admin,"p04-expand-v1",await readFile(new URL("../db/002-expand.sql",import.meta.url),"utf8"));
});
after(async()=>{await Promise.all([admin.end(),a1?.end(),a2?.end(),b1?.end(),b2?.end(),l1?.end(),l2?.end()]);});
test("v1/v2 writers and readers coexist independently in Affiliate and Lottery",async()=>{
 await a1.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'v1',$4::jsonb)",[A,AFF,id(201),JSON.stringify({v:1})]);
 await a2.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,canonical_payload) VALUES($1,$2,$3,'v2',$4::jsonb)",[A,AFF,id(202),JSON.stringify({v:2})]);
 await l1.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'v1',$4::jsonb)",[A,LOT,id(201),JSON.stringify({lottery_v1:1})]);
 await l2.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,canonical_payload) VALUES($1,$2,$3,'v2',$4::jsonb)",[A,LOT,id(202),JSON.stringify({lottery_v2:2})]);
 await b1.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'worker-v1',$4::jsonb)",[B,AFF,id(203),JSON.stringify({worker:"v1"})]);
 await b2.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,canonical_payload) VALUES($1,$2,$3,'worker-v2',$4::jsonb)",[B,AFF,id(204),JSON.stringify({worker:"v2"})]);
 assert.deepEqual((await a2.query("SELECT canonical_payload FROM partner_events WHERE event_id=$1",[id(201)])).rows[0].canonical_payload,{v:1});
 assert.deepEqual((await a1.query("SELECT payload FROM partner_events WHERE event_id=$1",[id(202)])).rows[0].payload,{v:2});
 assert.deepEqual((await l2.query("SELECT canonical_payload FROM partner_events WHERE event_id=$1",[id(201)])).rows[0].canonical_payload,{lottery_v1:1});
 assert.deepEqual((await l1.query("SELECT payload FROM partner_events WHERE event_id=$1",[id(202)])).rows[0].payload,{lottery_v2:2});
 assert.deepEqual((await b2.query("SELECT canonical_payload FROM partner_events WHERE event_id=$1",[id(203)])).rows[0].canonical_payload,{worker:"v1"});
 assert.deepEqual((await b1.query("SELECT payload FROM partner_events WHERE event_id=$1",[id(204)])).rows[0].payload,{worker:"v2"});
});
test("journal and line identities are product-qualified and legacy shared scope is rejected",async()=>{
 const journals=await admin.query("SELECT product_id,count(*)::int n FROM ledger_journals WHERE tenant_id=$1 AND journal_id=$2 GROUP BY product_id ORDER BY product_id",[A,id(101)]);
 assert.deepEqual(journals.rows,[{product_id:AFF,n:1},{product_id:LOT,n:1}]);
 assert.equal((await a1.query("SELECT * FROM ledger_journals WHERE journal_id=$1",[id(101)])).rowCount,1);
 assert.equal((await l1.query("SELECT * FROM ledger_journals WHERE journal_id=$1",[id(101)])).rowCount,1);
 assert.equal((await a1.query("SELECT * FROM ledger_lines WHERE journal_id=$1",[id(101)])).rowCount,2);
 assert.equal((await l1.query("SELECT * FROM ledger_lines WHERE journal_id=$1",[id(101)])).rowCount,2);
 await assert.rejects(admin.query("INSERT INTO ledger_lines(tenant_id,product_id,journal_id,line_no,side,amount_minor) VALUES($1,$2,$3,99,'debit',1)",[B,LOT,id(102)]),e=>e.code==="23503");
 await assert.rejects(admin.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,'shared',$2,'legacy',$3::jsonb)",[A,id(299),JSON.stringify({legacy:true})]),e=>e.code==="23514");
});
test("conflicting dual-write fails closed",async()=>{await assert.rejects(a2.query("UPDATE partner_events SET payload=$1::jsonb,canonical_payload=$2::jsonb WHERE event_id=$3",[JSON.stringify({v:3}),JSON.stringify({v:2}),id(201)]),e=>e.code==="23514");});
test("backfill stops and resumes within tenant/product RLS boundaries",async()=>{
 const initial=Number((await a1.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n);assert.equal(initial,4);
 const first=await backfillBatch(a1,2);assert.ok(first>0&&first<=2);await a1.end();a1=new Pool({connectionString:u.a1});
 let resumed=0,changed=0;while((changed=await backfillBatch(a1,2))>0)resumed+=changed;assert.equal(first+resumed,initial);
 assert.equal((await a1.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n,0);
 const lotteryInitial=Number((await l2.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n);assert.equal(lotteryInitial,2);
 let lotteryDone=0;while((changed=await backfillBatch(l2,2))>0)lotteryDone+=changed;assert.equal(lotteryDone,lotteryInitial);
 const bInitial=Number((await b2.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n);assert.equal(bInitial,2);
 let bDone=0;while((changed=await backfillBatch(b2,2))>0)bDone+=changed;assert.equal(bDone,bInitial);
 assert.equal((await a1.query("SELECT * FROM partner_events WHERE tenant_id=$1",[B])).rowCount,0);
 assert.equal((await a1.query("SELECT * FROM partner_events WHERE product_id=$1",[LOT])).rowCount,0);
 assert.equal((await l1.query("SELECT * FROM partner_events WHERE product_id=$1",[AFF])).rowCount,0);
 await assert.rejects(a1.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'spoof',$4::jsonb)",[B,AFF,id(299),JSON.stringify({x:1})]),e=>e.code==="42501");
 await assert.rejects(a1.query("INSERT INTO partner_events(tenant_id,product_id,event_id,event_type,payload) VALUES($1,$2,$3,'spoof',$4::jsonb)",[A,LOT,id(298),JSON.stringify({x:1})]),e=>e.code==="42501");
});
test("migration replay is idempotent and checksum drift is rejected",async()=>{
 assert.equal(await applyMigration(admin,"p04-repeat-v1","SELECT 1"),true);assert.equal(await applyMigration(admin,"p04-repeat-v1","SELECT 1"),false);
 await assert.rejects(applyMigration(admin,"p04-repeat-v1","SELECT 2"),/checksum mismatch/);
 await assert.rejects(applyMigration(admin,"p04-fail-v1","THIS IS NOT SQL"));assert.equal((await admin.query("SELECT 1 FROM schema_migrations WHERE migration_id='p04-fail-v1'")).rowCount,0);
});
test("lock timeout aborts blocked DDL without partial schema change",async()=>{
 const lock=await a1.connect(),ddl=await admin.connect();try{await lock.query("BEGIN");await lock.query("SELECT event_id FROM partner_events WHERE event_id=$1 FOR UPDATE",[id(1)]);await ddl.query("SET lock_timeout='150ms'");
 await assert.rejects(ddl.query("ALTER TABLE partner_events ADD COLUMN lock_probe text"),e=>e.code==="55P03");
 assert.equal((await admin.query("SELECT 1 FROM information_schema.columns WHERE table_name='partner_events' AND column_name='lock_probe'")).rowCount,0);
 }finally{await lock.query("ROLLBACK");await ddl.query("RESET lock_timeout");lock.release();ddl.release();}
});
test("concurrent index recovery uses nonblocking serialization and rejects valid definition drift",async()=>{
 await assert.rejects(admin.query("CREATE UNIQUE INDEX CONCURRENTLY p04_events_tenant_created_idx ON partner_events(event_type)"));
 const invalid=await admin.query("SELECT i.indisvalid FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass('public.p04_events_tenant_created_idx')");
 assert.equal(invalid.rowCount,1);assert.equal(invalid.rows[0].indisvalid,false);
 const concurrent=await Promise.all([recoverConcurrentIndex(admin),recoverConcurrentIndex(admin)]);
 assert.equal(concurrent.filter(x=>x==="repaired").length,1);
 assert.equal(concurrent.filter(x=>x==="busy"||x==="valid").length,1);
 const valid=await admin.query("SELECT i.indisvalid,i.indisready,pg_get_indexdef(i.indexrelid) AS definition FROM pg_class c JOIN pg_index i ON i.indexrelid=c.oid WHERE c.oid=to_regclass('public.p04_events_tenant_created_idx')");
 assert.equal(valid.rowCount,1);assert.equal(valid.rows[0].indisvalid,true);assert.equal(valid.rows[0].indisready,true);
 assert.equal(await recoverConcurrentIndex(admin),"valid");
 await admin.query("DROP INDEX CONCURRENTLY public.p04_events_tenant_created_idx");
 await admin.query("CREATE INDEX p04_events_tenant_created_idx ON public.partner_events(event_type)");
 await assert.rejects(recoverConcurrentIndex(admin),/index definition mismatch/);
 await admin.query("DROP INDEX public.p04_events_tenant_created_idx");
 assert.equal(await recoverConcurrentIndex(admin),"repaired");
});
test("ledger/reporting remain unchanged and contract rehearsal is non-destructive",async()=>{
 const r=await admin.query("SELECT count(*)::int j,(SELECT count(*)::int FROM ledger_lines) l,(SELECT sum(amount_minor)::text FROM ledger_lines WHERE side='debit') d,(SELECT sum(amount_minor)::text FROM ledger_lines WHERE side='credit') c FROM ledger_journals");
 assert.equal(r.rows[0].j,3);assert.equal(r.rows[0].l,6);assert.equal(r.rows[0].d,r.rows[0].c);
 assert.equal((await admin.query("SELECT sum(event_count)::int n FROM reporting_daily")).rows[0].n,8);
 assert.equal((await admin.query("SELECT count(*)::int n FROM partner_events WHERE canonical_payload IS NULL")).rows[0].n,0);
 await admin.query("ALTER TABLE partner_events VALIDATE CONSTRAINT p04_payload_object");
 await admin.query("CREATE TEMP TABLE contract_projection AS SELECT tenant_id,product_id,event_id,canonical_payload FROM partner_events");
 assert.equal((await admin.query("SELECT count(*)::int n FROM contract_projection")).rows[0].n,(await admin.query("SELECT count(*)::int n FROM partner_events")).rows[0].n);
 assert.equal((await admin.query("SELECT 1 FROM information_schema.columns WHERE table_name='partner_events' AND column_name='payload'")).rowCount,1);
});
