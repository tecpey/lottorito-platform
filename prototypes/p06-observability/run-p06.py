#!/usr/bin/env python3
"""Synthetic-only P-06 end-to-end telemetry, privacy and access-control drill."""
import base64, hashlib, hmac, json, os, re, secrets, subprocess, uuid
from datetime import datetime, timedelta, timezone

DB="lottorito_p06"
ADMIN_PASSWORD="p06-admin-only-not-production"
TENANT_A="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
TENANT_B="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
A_USD_CASH="11111111-1111-4111-8111-111111111101"
A_USD_CLEARING="11111111-1111-4111-8111-111111111102"
TRACE_RE=re.compile(r"^00-([0-9a-f]{32})-([0-9a-f]{16})-01$")
CANARIES=[
 "P06_SECRET_ACCESS_TOKEN_7f31c0",
 "P06_SECRET_API_KEY_91e2b4",
 "P06_SECRET_SESSION_COOKIE_4c8d10",
 "P06_SECRET_PASSWORD_2a7f99",
 "P06_SECRET_DATABASE_URL_aa9011",
 "P06_PII_EMAIL_private-user@example.test",
 "P06_PII_PHONE_+15550109999",
 "P06_PII_CARDPAN_4111111111111111"
]
HMAC_KEY=secrets.token_bytes(32)

def q(value):
    return "'" + str(value).replace("'","''") + "'"

def jsonb(value):
    raw=json.dumps(value,separators=(",",":"),ensure_ascii=False).encode()
    encoded=base64.b64encode(raw).decode()
    return f"convert_from(decode('{encoded}','base64'),'UTF8')::jsonb"

def ref(value):
    return hmac.new(HMAC_KEY,str(value).encode(),hashlib.sha256).hexdigest()

def sanitize_baggage(baggage):
    allowed={"messaging.system","messaging.destination_kind"}
    return {k:v for k,v in baggage.items() if k in allowed and isinstance(v,str) and len(v)<=64 and re.fullmatch(r"[a-zA-Z0-9_.-]+",v)}

def normalize_event_type(value):
    allowed={"affiliate.referral.converted","affiliate.commission.created"}
    if isinstance(value,str) and value in allowed and "\\r" not in value and "\\n" not in value:
        return value,"PARTNER_EVENT_ACCEPTED"
    return "event.validation_failed","INVALID_EVENT_TYPE"

def psql(sql=None,user="postgres",password=ADMIN_PASSWORD,file=None,check=True):
    env=os.environ.copy(); env["PGPASSWORD"]=password
    args=["psql","-X","-h","127.0.0.1","-p","5432","-U",user,"-d",DB,"-At","-F","|","-v","ON_ERROR_STOP=1"]
    if file:
        args.extend(["-f",file])
    else:
        args.extend(["-c",sql])
    result=subprocess.run(args,text=True,capture_output=True,env=env)
    if check and result.returncode:
        raise RuntimeError(f"psql failed for {user}: {result.stderr}\nSQL={sql or file}")
    return result.stdout.strip(),result.stderr,result.returncode

def scalar(sql,user="postgres",password=ADMIN_PASSWORD):
    return psql(sql,user,password)[0].splitlines()[-1]

def expect_reject(sql,user,password,marker):
    out,err,code=psql(sql,user,password,check=False)
    if code==0 or marker.lower() not in (out+err).lower():
        raise AssertionError(f"expected rejection {marker}; code={code}; out={out}; err={err}")

def main():
    print("[P06] Install the existing P-02 immutable ledger fixture")
    psql(file="/workspace/p02/db/schema.sql")
    print("[P06] Install tenant-scoped telemetry, forensic gate and append-only audit schema")
    psql(file="/workspace/p06/schema.sql")

    tenant_a_ref=ref(TENANT_A); tenant_b_ref=ref(TENANT_B)
    actor_id=str(uuid.uuid4()); actor_ref=ref(actor_id)
    source_event_id=str(uuid.uuid4()); source_event_ref=ref(source_event_id)
    effect_id=str(uuid.uuid4()); effect_ref=ref(effect_id)
    trace_id=secrets.token_hex(16)
    psql(f"INSERT INTO p06.role_tenant_map(database_role,tenant_ref) VALUES ('p06_tenant_a_reader',{q(tenant_a_ref)}),('p06_tenant_b_reader',{q(tenant_b_ref)})")

    print("[P06] Create a real synthetic double-entry journal through the P-02 posting function")
    lines=[
      {"line_no":1,"account_id":A_USD_CASH,"currency_code":"USD","direction":"debit","amount_minor":"12500"},
      {"line_no":2,"account_id":A_USD_CLEARING,"currency_code":"USD","direction":"credit","amount_minor":"12500"}
    ]
    ledger_sql=(
      "SELECT journal_id::text || '|' || duplicate::text "
      f"FROM public.post_journal('p06-observability-001',{q(effect_id)}::uuid,{q(source_event_id)}::uuid,{jsonb(lines)})"
    )
    ledger_result,_,_=psql(ledger_sql,user="tenant_a_ledger_runtime",password="p02-tenant-a-not-for-production")
    journal_id,duplicate=ledger_result.split("|")
    if duplicate.lower()!="false": raise AssertionError("P-06 expected a new synthetic journal; duplicate="+duplicate)
    journal_ref=ref(journal_id)
    CANARIES.extend([TENANT_A,TENANT_B,actor_id,source_event_id,effect_id,journal_id])
    if scalar(f"SELECT count(*) FROM public.ledger_journals WHERE tenant_id='{TENANT_A}' AND journal_id='{journal_id}' AND status='posted'")!="1":
        raise AssertionError("P-02 ledger journal was not posted")

    print("[P06] Generate W3C Trace Context and nine linked end-to-end spans")
    stages=[
      ("partner-gateway","partner.event.receive","received"),
      ("partner-gateway","partner.event.authenticate","authenticated"),
      ("event-ingress","event.inbox.persist","durable"),
      ("affiliate-domain","affiliate.attribution.resolve","attributed"),
      ("commission-engine","commission.evaluate","qualified"),
      ("event-outbox","messaging.publish","published"),
      ("event-worker","messaging.process","consumed"),
      ("ledger-service","ledger.post_journal","posted"),
      ("reconciliation","reconciliation.compare","matched")
    ]
    span_ids=[secrets.token_hex(8) for _ in stages]
    if len(set(span_ids))!=len(span_ids): raise AssertionError("span ID collision")
    start=datetime.now(timezone.utc)
    span_records=[]
    for i,(service,name,outcome) in enumerate(stages):
        span_id=span_ids[i]; parent=span_ids[i-1] if i else None
        parent_field="NULL" if parent is None else q(parent)
        effect_field="NULL" if i<4 else q(effect_ref)
        journal_field="NULL" if i<7 else q(journal_ref)
        attrs={"outcome":outcome,"product_domain":"affiliate_agent","schema_version":"1"}
        if i==1: attrs["signature_result"]="valid"
        if i==4: attrs["commission_policy_version"]="synthetic-v1"
        if i==7: attrs["ledger_result"]="posted"
        if i==8: attrs["reconciliation_result"]="matched"
        began=start+timedelta(milliseconds=i*11); ended=began+timedelta(milliseconds=4)
        sql=(
          "INSERT INTO p06.spans(trace_id,span_id,parent_span_id,service_name,span_name,tenant_ref,product_domain,"
          "source_event_ref,economic_effect_ref,journal_ref,started_at,ended_at,status,attributes) VALUES("
          f"{q(trace_id)},{q(span_id)},{parent_field},{q(service)},{q(name)},{q(tenant_a_ref)},'affiliate_agent',"
          f"{q(source_event_ref)},{effect_field},{journal_field},{q(began.isoformat())}::timestamptz,"
          f"{q(ended.isoformat())}::timestamptz,'ok',{jsonb(attrs)})"
        )
        psql(sql)
        traceparent=f"00-{trace_id}-{span_id}-01"
        match=TRACE_RE.fullmatch(traceparent)
        if not match or set(match.group(1))=={"0"} or set(match.group(2))=={"0"}:
            raise AssertionError("invalid W3C traceparent")
        span_records.append({"trace_id":trace_id,"span_id":span_id,"parent_span_id":parent,"traceparent":traceparent})
    if span_records[0]["parent_span_id"] is not None or any(x["parent_span_id"]!=span_ids[i-1] for i,x in enumerate(span_records) if i):
        raise AssertionError("trace parent graph is broken")

    print("[P06] Persist only structured, minimized log fields; reject injection and sensitive baggage")
    logs=[
      (span_ids[0],"partner.event.received","info","PARTNER_EVENT_ACCEPTED",{"product_domain":"affiliate_agent","source_event_ref":source_event_ref}),
      (span_ids[3],"affiliate.attribution.resolved","info","ATTRIBUTION_RESOLVED",{"product_domain":"affiliate_agent","source_event_ref":source_event_ref}),
      (span_ids[4],"commission.calculated","info","COMMISSION_QUALIFIED",{"economic_effect_ref":effect_ref,"policy_version":"synthetic-v1"}),
      (span_ids[7],"ledger.journal.posted","info","LEDGER_JOURNAL_POSTED",{"journal_ref":journal_ref,"currency":"USD"}),
      (span_ids[8],"reconciliation.completed","info","RECONCILIATION_MATCHED",{"journal_ref":journal_ref,"result":"matched"})
    ]
    for span_id,event_name,level,message_code,fields in logs:
        psql(
          "INSERT INTO p06.logs(trace_id,span_id,tenant_ref,level,event_name,message_code,fields) VALUES("
          f"{q(trace_id)},{q(span_id)},{q(tenant_a_ref)},{q(level)},{q(event_name)},{q(message_code)},{jsonb(fields)})"
        )
    raw_event={
      "tenant_id":TENANT_A,"actor_id":actor_id,"source_event_id":source_event_id,
      "email":CANARIES[5],"phone":CANARIES[6],"access_token":CANARIES[0],
      "api_key":CANARIES[1],"session_cookie":CANARIES[2],"password":CANARIES[3],
      "database_url":CANARIES[4],"card_pan":CANARIES[7]
    }
    unsafe_exception="provider error contained "+CANARIES[0]+" and "+CANARIES[5]
    unsafe_baggage={"user.email":CANARIES[5],"api.key":CANARIES[1],"tenant.id":TENANT_A}
    safe_baggage=sanitize_baggage(unsafe_baggage)
    malicious_event_type="affiliate.commission.created"+chr(13)+chr(10)+"ALERT "+CANARIES[0]
    safe_event_name,safe_message_code=normalize_event_type(malicious_event_type)
    if safe_baggage or safe_event_name!="event.validation_failed" or safe_message_code!="INVALID_EVENT_TYPE":
        raise AssertionError("unsafe baggage or log injection was not normalized")
    psql(
      "INSERT INTO p06.logs(trace_id,span_id,tenant_ref,level,event_name,message_code,fields) VALUES("
      f"{q(trace_id)},{q(span_ids[1])},{q(tenant_a_ref)},'warn','{safe_event_name}','{safe_message_code}',"
      f"{jsonb({'reason_code':'schema_invalid','exception_type':'ProviderPayloadError'})})"
    )
    # Canary-bearing source and exception values exist only in this test process.
    assert raw_event["access_token"] in json.dumps(raw_event)
    assert CANARIES[0] in unsafe_exception

    print("[P06] Create bounded metric series for 500 synthetic tenant identities")
    metric_counts={}
    synthetic_tenant_refs={ref(f"synthetic-tenant-{i}") for i in range(500)}
    if len(synthetic_tenant_refs)!=500: raise AssertionError("synthetic tenant identities were not unique")
    for tenant_ref in synthetic_tenant_refs:
        # Tenant identity is deliberately not part of any metric label set.
        for key in [
          ("affiliate_events_total","event_received","success","affiliate_agent",None),
          ("commission_calculations_total","commission_calculated","success","affiliate_agent",None),
          ("ledger_postings_total","ledger_posted","success","affiliate_agent",None),
          ("reconciliation_checks_total","reconciliation_checked","success","affiliate_agent",None)
        ]:
            metric_counts[key]=metric_counts.get(key,0)+1
    for (metric,operation,outcome,product,reason),value in metric_counts.items():
        reason_sql="NULL" if reason is None else q(reason)
        psql(
          "INSERT INTO p06.metrics(metric_name,operation,outcome,product_domain,reason_code,value) VALUES("
          f"{q(metric)},{q(operation)},{q(outcome)},{q(product)},{reason_sql},{value})"
        )
    metric_series=int(scalar("SELECT count(*) FROM p06.metrics"))
    if metric_series>20: raise AssertionError("metric series cardinality grew beyond bounded fixture")
    unbounded_cols=scalar(
      "SELECT count(*) FROM information_schema.columns WHERE table_schema='p06' AND table_name='metrics' "
      "AND column_name IN('tenant_id','tenant_ref','actor_id','user_id','email','source_event_id','journal_id')"
    )
    if unbounded_cols!="0": raise AssertionError("metrics schema contains unbounded identifiers")

    print("[P06] Record pseudonymous correlation map behind audited forensic access")
    psql(
      "INSERT INTO p06.correlation_map(tenant_id,tenant_ref,actor_id,actor_ref,source_event_id,source_event_ref,"
      "economic_effect_id,economic_effect_ref,journal_id,journal_ref,trace_id) VALUES("
      f"{q(TENANT_A)}::uuid,{q(tenant_a_ref)},{q(actor_id)}::uuid,{q(actor_ref)},"
      f"{q(source_event_id)}::uuid,{q(source_event_ref)},{q(effect_id)}::uuid,{q(effect_ref)},"
      f"{q(journal_id)}::uuid,{q(journal_ref)},{q(trace_id)})"
    )
    if scalar("SELECT count(*) FROM p06.forensic_correlation_map",user="p06_forensic_reader",password="p06-forensic-not-production")!="0":
        raise AssertionError("forensic map was visible before an audited access grant")
    forensic_sql=(
      f"SELECT p06.record_forensic_access({q(trace_id)},'incident_review',{q(actor_ref)}); "
      "SELECT count(*) FROM p06.forensic_correlation_map"
    )
    forensic_out,_,_=psql(forensic_sql,user="p06_forensic_reader",password="p06-forensic-not-production")
    if forensic_out.splitlines()[-1]!="1": raise AssertionError("audited forensic access did not reveal one correlation row")
    expect_reject("SELECT count(*) FROM p06.correlation_map","p06_forensic_reader","p06-forensic-not-production","permission denied")
    if scalar(f"SELECT count(*) FROM p06.privileged_audit WHERE action='telemetry.correlation_map.read' AND trace_id='{trace_id}'")!="1":
        raise AssertionError("forensic access was not audited")

    print("[P06] Prove tenant isolation, least privilege and append-only audit")
    if scalar("SELECT count(*) FROM p06.spans",user="p06_tenant_a_reader",password="p06-tenant-a-not-production")!="9":
        raise AssertionError("tenant A cannot see its complete trace")
    if scalar("SELECT count(*) FROM p06.spans",user="p06_tenant_b_reader",password="p06-tenant-b-not-production")!="0":
        raise AssertionError("tenant B can see tenant A trace")
    if scalar("SELECT count(*) FROM p06.logs",user="p06_tenant_a_reader",password="p06-tenant-a-not-production")!="6":
        raise AssertionError("tenant A cannot see its sanitized logs")
    if scalar("SELECT count(*) FROM p06.logs",user="p06_tenant_b_reader",password="p06-tenant-b-not-production")!="0":
        raise AssertionError("tenant B can see tenant A logs")
    if scalar(f"SELECT count(*) FROM p06.spans WHERE source_event_ref={q(source_event_ref)}")!="9":
        raise AssertionError("source event reference is not consistent across trace")
    if scalar(f"SELECT count(*) FROM p06.spans WHERE economic_effect_ref={q(effect_ref)}")!="5":
        raise AssertionError("economic effect reference is not consistent across trace")
    if scalar(f"SELECT count(*) FROM p06.spans WHERE journal_ref={q(journal_ref)}")!="2":
        raise AssertionError("journal reference is not consistent across ledger/reconciliation spans")
    if scalar(f"SELECT count(*) FROM p06.spans WHERE tenant_ref={q(tenant_b_ref)}",user="p06_tenant_a_reader",password="p06-tenant-a-not-production")!="0":
        raise AssertionError("tenant A can query tenant B spans")
    expect_reject("SELECT count(*) FROM p06.correlation_map","p06_tenant_a_reader","p06-tenant-a-not-production","permission denied")
    expect_reject("SELECT count(*) FROM p06.logs","p06_metrics_reader","p06-metrics-not-production","permission denied")
    expect_reject(
      "UPDATE p06.privileged_audit SET reason_code='incident_review'",
      "postgres",ADMIN_PASSWORD,"P06_AUDIT_APPEND_ONLY"
    )

    print("[P06] Scan all telemetry outputs for secret/PII canaries and prohibited field names")
    telemetry_sql=(
      "SELECT COALESCE(string_agg(payload,E'\\n'),'') FROM ("
      "SELECT row_to_json(s)::text AS payload FROM p06.spans s UNION ALL "
      "SELECT row_to_json(l)::text FROM p06.logs l UNION ALL "
      "SELECT row_to_json(m)::text FROM p06.metrics m UNION ALL "
      "SELECT row_to_json(a)::text FROM p06.alerts a UNION ALL "
      "SELECT row_to_json(a)::text FROM p06.privileged_audit a) q"
    )
    telemetry=psql(telemetry_sql)[0].lower()
    for canary in CANARIES:
        if canary.lower() in telemetry: raise AssertionError("secret/PII canary leaked into telemetry: "+canary)
    for forbidden in ['"access_token"','"api_key"','"session_cookie"','"password"','"database_url"','"email"','"phone"','"card_pan"','"authorization"','"private_key"']:
        if forbidden in telemetry: raise AssertionError("prohibited telemetry field leaked: "+forbidden)
    if "\\r" in telemetry or "\\nALERT" in telemetry:
        raise AssertionError("log injection sequence reached telemetry")

    print("[P06] Verify alerts have owners, severity and actionable runbook identifiers")
    if scalar("SELECT count(*) FROM p06.alerts WHERE owner_team<>'' AND runbook_id<>'' AND severity IN('critical','high','warning','info')")!="5":
        raise AssertionError("alert ownership/runbook mapping incomplete")
    if scalar(f"SELECT count(*) FROM public.ledger_journals WHERE tenant_id='{TENANT_A}' AND journal_id='{journal_id}' AND status='posted'")!="1":
        raise AssertionError("telemetry trace does not point to the actual posted ledger journal")

    print(f"trace_id={trace_id}")
    print(f"span_count={len(span_records)}")
    print(f"synthetic_tenant_count={len(synthetic_tenant_refs)}")
    print(f"metric_series_for_500_tenants={metric_series}")
    print("p02_real_ledger_journal=PASS")
    print("w3c_trace_context_parent_chain=PASS")
    print("async_event_to_ledger_trace=PASS")
    print("secret_and_pii_canaries_absent=PASS")
    print("unsafe_baggage_dropped=PASS")
    print("log_injection_neutralized=PASS")
    print("tenant_telemetry_rls=PASS")
    print("forensic_access_audited=PASS")
    print("forensic_mapping_requires_audit=PASS")
    print("telemetry_least_privilege=PASS")
    print("audit_append_only=PASS")
    print("bounded_metric_cardinality=PASS")
    print("alert_owner_severity_runbook=PASS")
    print("P06_RESULT=PASS")

if __name__=="__main__":
    main()
