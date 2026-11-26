#!/usr/bin/env bash
set -euo pipefail

ROOT=/tmp/lottorito-p09e
ADMIN_PASSWORD=p05-admin-only-not-production
SOURCE_PORT=55432
RESTORE_PORT=55433
DB=lottorito_p09e
TENANT_A=aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa
TENANT_B=bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb
EVENT_ID=evt-cross-scope-identity
SOURCE_EVENT_ID=30000000-0000-4000-8000-000000000001
AFFILIATE_EFFECT=20000000-0000-4000-8000-000000000101
LOTTERY_EFFECT=20000000-0000-4000-8000-000000000102
TENANT_B_EFFECT=20000000-0000-4000-8000-000000000103
AFFILIATE_CASH=11111111-1111-4111-8111-111111111101
AFFILIATE_CLEARING=11111111-1111-4111-8111-111111111102
LOTTERY_CASH=11111111-1111-4111-8111-111111111101
LOTTERY_CLEARING=11111111-1111-4111-8111-111111111102
TENANT_B_CASH=22222222-2222-4222-8222-222222222201
TENANT_B_CLEARING=22222222-2222-4222-8222-222222222202
AMOUNT=12500

as_pg(){ runuser -u postgres -- "$@"; }
admin_psql(){
  as_pg env PGPASSWORD="$ADMIN_PASSWORD" psql -X -h 127.0.0.1 -p "$1" -U postgres -d "$2" -v ON_ERROR_STOP=1 "${@:3}"
}
tenant_psql(){
  local port="$1" user="$2" password="$3"
  shift 3
  as_pg env PGPASSWORD="$password" psql -X -h 127.0.0.1 -p "$port" -U "$user" -d "$DB" -v ON_ERROR_STOP=1 "$@"
}
assert_eq(){
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "P-09E assertion failed: $label expected=$expected actual=$actual" >&2
    exit 1
  fi
}

echo "[P-09E] Create a separate disposable database using the exact P-02/P-03C/P-03D schema chain"
admin_psql "$SOURCE_PORT" postgres -c "CREATE DATABASE $DB"
admin_psql "$SOURCE_PORT" "$DB" -f /workspace-p02/db/schema.sql
admin_psql "$SOURCE_PORT" "$DB" -f /workspace-p03c/db/integration.sql
admin_psql "$SOURCE_PORT" "$DB" -f /workspace-p03d/db/integration.sql
admin_psql "$SOURCE_PORT" "$DB" -f /workspace/p09e/process-event.sql

assert_eq "$(admin_psql "$SOURCE_PORT" "$DB" -At -c "SELECT count(*) FROM public.ledger_accounts")" "8" "P-02 accounts"
assert_eq "$(admin_psql "$SOURCE_PORT" "$DB" -At -c "SELECT count(*) FROM private.tenant_role_map")" "3" "P-02 tenant/product role map"

echo "[P-09E] Seed the same source-event UUID and provider event ID in three distinct tenant/product scopes"
tenant_psql "$SOURCE_PORT" tenant_a_ledger_runtime p02-tenant-a-not-for-production -c "
INSERT INTO public.provider_event_inbox
 (tenant_id,product_id,provider_id,provider_event_id,event_type,event_source,payload_hash,signature_key_id,canonical_event,effect_id,source_event_id)
VALUES
 ('$TENANT_A','affiliate_agent','synthetic-provider','$EVENT_ID','com.synthetic.settlement.posted.v1','urn:synthetic:p09e:affiliate',repeat('a',64),'synthetic-key-v1',
  jsonb_build_object('specversion','1.0','id','$EVENT_ID','source','urn:synthetic:p09e:affiliate','type','com.synthetic.settlement.posted.v1','time','2026-11-25T12:00:00Z','dataschema','urn:lottorito:schema:synthetic-settlement:1','tenantid','$TENANT_A','scope',jsonb_build_object('kind','product','id','affiliate_agent'),'sourceeventid','$SOURCE_EVENT_ID','schemaversion',1,'traceparent','00-0123456789abcdef0123456789abcdef-0123456789abcdef-00','data',jsonb_build_object('amount_minor','$AMOUNT','currency_code','USD')),
  '$AFFILIATE_EFFECT','$SOURCE_EVENT_ID')"
tenant_psql "$SOURCE_PORT" tenant_a_lottery_runtime p02-tenant-a-lottery-not-for-production -c "
INSERT INTO public.provider_event_inbox
 (tenant_id,product_id,provider_id,provider_event_id,event_type,event_source,payload_hash,signature_key_id,canonical_event,effect_id,source_event_id)
VALUES
 ('$TENANT_A','lottery','synthetic-provider','$EVENT_ID','com.synthetic.settlement.posted.v1','urn:synthetic:p09e:lottery',repeat('b',64),'synthetic-key-v1',
  jsonb_build_object('specversion','1.0','id','$EVENT_ID','source','urn:synthetic:p09e:lottery','type','com.synthetic.settlement.posted.v1','time','2026-11-25T12:00:00Z','dataschema','urn:lottorito:schema:synthetic-settlement:1','tenantid','$TENANT_A','scope',jsonb_build_object('kind','product','id','lottery'),'sourceeventid','$SOURCE_EVENT_ID','schemaversion',1,'traceparent','00-0123456789abcdef0123456789abcdef-0123456789abcdef-00','data',jsonb_build_object('amount_minor','$AMOUNT','currency_code','USD')),
  '$LOTTERY_EFFECT','$SOURCE_EVENT_ID')"
tenant_psql "$SOURCE_PORT" tenant_b_ledger_runtime p02-tenant-b-not-for-production -c "
INSERT INTO public.provider_event_inbox
 (tenant_id,product_id,provider_id,provider_event_id,event_type,event_source,payload_hash,signature_key_id,canonical_event,effect_id,source_event_id)
VALUES
 ('$TENANT_B','affiliate_agent','synthetic-provider','$EVENT_ID','com.synthetic.settlement.posted.v1','urn:synthetic:p09e:tenant-b',repeat('c',64),'synthetic-key-v1',
  jsonb_build_object('specversion','1.0','id','$EVENT_ID','source','urn:synthetic:p09e:tenant-b','type','com.synthetic.settlement.posted.v1','time','2026-11-25T12:00:00Z','dataschema','urn:lottorito:schema:synthetic-settlement:1','tenantid','$TENANT_B','scope',jsonb_build_object('kind','product','id','affiliate_agent'),'sourceeventid','$SOURCE_EVENT_ID','schemaversion',1,'traceparent','00-0123456789abcdef0123456789abcdef-0123456789abcdef-00','data',jsonb_build_object('amount_minor','$AMOUNT','currency_code','USD')),
  '$TENANT_B_EFFECT','$SOURCE_EVENT_ID')"

admin_psql "$SOURCE_PORT" "$DB" -c "
INSERT INTO public.provider_event_expectations(tenant_id,product_id,provider_id,provider_event_id)
VALUES
 ('$TENANT_A','affiliate_agent','synthetic-provider','$EVENT_ID'),
 ('$TENANT_A','lottery','synthetic-provider','$EVENT_ID'),
 ('$TENANT_B','affiliate_agent','synthetic-provider','$EVENT_ID')"
assert_eq "$(admin_psql "$SOURCE_PORT" "$DB" -At -c "SELECT count(*) FROM public.provider_event_inbox")" "3" "pre-backup provider inbox"
assert_eq "$(admin_psql "$SOURCE_PORT" "$DB" -At -c "SELECT count(*) FROM public.financial_effects")" "0" "pre-backup financial effects"

echo "[P-09E] Take and verify a physical PostgreSQL base backup containing the exact P-02/P-03D schema and accepted inbox records"
rm -rf "$ROOT"
install -d -o postgres -g postgres "$ROOT"
as_pg env PGPASSWORD="$ADMIN_PASSWORD" pg_basebackup \
  -h 127.0.0.1 -p "$SOURCE_PORT" -U postgres -D "$ROOT/base" \
  -Fp -Xs -P --checkpoint=fast
as_pg pg_verifybackup "$ROOT/base"

echo "[P-09E] Restore the physical backup into an isolated second PostgreSQL cluster"
as_pg pg_ctl -D "$ROOT/base" -l "$ROOT/restore.log" \
  -o "-p $RESTORE_PORT -h 127.0.0.1 -c archive_mode=off" -w start
cleanup(){
  as_pg pg_ctl -D "$ROOT/base" -m fast -w stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

restore_admin(){ admin_psql "$RESTORE_PORT" "$DB" "$@"; }
restore_tenant_a(){ tenant_psql "$RESTORE_PORT" tenant_a_ledger_runtime p02-tenant-a-not-for-production "$@"; }
restore_tenant_lottery(){ tenant_psql "$RESTORE_PORT" tenant_a_lottery_runtime p02-tenant-a-lottery-not-for-production "$@"; }
restore_tenant_b(){ tenant_psql "$RESTORE_PORT" tenant_b_ledger_runtime p02-tenant-b-not-for-production "$@"; }

assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.provider_event_inbox")" "3" "restored provider inbox"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.financial_effects")" "0" "restored financial effects before replay"

echo "[P-09E] Corrupt a restored event scope and prove replay fails closed before any financial effect"
restore_admin -c "UPDATE public.provider_event_inbox
  SET canonical_event=jsonb_set(canonical_event,'{scope,id}',to_jsonb('lottery'::text))
  WHERE tenant_id='$TENANT_B' AND product_id='affiliate_agent' AND provider_id='synthetic-provider' AND provider_event_id='$EVENT_ID'"
if restore_tenant_b -c "SELECT public.p09e_process_provider_event('$EVENT_ID','$TENANT_B_CASH','$TENANT_B_CLEARING','$AMOUNT','provider:p09e:tenant-b:$EVENT_ID')" >"$ROOT/corrupt-replay.log" 2>&1; then
  echo "P-09E corrupted canonical event unexpectedly replayed" >&2
  exit 1
fi
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.financial_effects")" "0" "corrupt replay creates no financial effect"
assert_eq "$(restore_admin -At -c "SELECT status FROM public.provider_event_inbox WHERE tenant_id='$TENANT_B' AND product_id='affiliate_agent' AND provider_id='synthetic-provider' AND provider_event_id='$EVENT_ID'")" "accepted" "corrupt replay transaction rolls back claim"
restore_admin -c "UPDATE public.provider_event_inbox
  SET canonical_event=jsonb_set(canonical_event,'{scope,id}',to_jsonb('affiliate_agent'::text))
  WHERE tenant_id='$TENANT_B' AND product_id='affiliate_agent' AND provider_id='synthetic-provider' AND provider_event_id='$EVENT_ID'"
echo "replay_contract_corruption_blocked=PASS"

echo "[P-09E] Inject a failure after P-02 journal/outbox writes but before P-03D inbox commit"
if restore_tenant_a -c "BEGIN; SELECT public.p09e_process_provider_event('$EVENT_ID','$AFFILIATE_CASH','$AFFILIATE_CLEARING','$AMOUNT','provider:p09e:affiliate:$EVENT_ID'); SELECT 1/0; COMMIT" >"$ROOT/interrupted-transaction.log" 2>&1; then
  echo "P-09E injected failure unexpectedly committed" >&2
  exit 1
fi
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.financial_effects")" "0" "failed transaction financial effects rollback"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.ledger_journals")" "0" "failed transaction journals rollback"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.ledger_outbox")" "0" "failed transaction outbox rollback"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.outbox_delivery_state")" "0" "failed transaction delivery state rollback"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.provider_event_inbox WHERE status<>'accepted' OR lease_token IS NOT NULL")" "0" "failed transaction inbox remains retryable"

echo "[P-09E] Replay accepted provider events through the actual P-02 post_journal function and P-03D inbox"
restore_tenant_a -c "SELECT public.p09e_process_provider_event('$EVENT_ID','$AFFILIATE_CASH','$AFFILIATE_CLEARING','$AMOUNT','provider:p09e:affiliate:$EVENT_ID')"
restore_tenant_lottery -c "SELECT public.p09e_process_provider_event('$EVENT_ID','$LOTTERY_CASH','$LOTTERY_CLEARING','$AMOUNT','provider:p09e:lottery:$EVENT_ID')"
restore_tenant_b -c "SELECT public.p09e_process_provider_event('$EVENT_ID','$TENANT_B_CASH','$TENANT_B_CLEARING','$AMOUNT','provider:p09e:tenant-b:$EVENT_ID')"

echo "[P-09E] Prove exact retry and alternate transport-key idempotency without duplicate financial effects"
for scope in affiliate lottery tenant-b; do
  case "$scope" in
    affiliate) run_tenant=restore_tenant_a; debit="$AFFILIATE_CASH"; credit="$AFFILIATE_CLEARING"; key="provider:p09e:affiliate:$EVENT_ID" ;;
    lottery) run_tenant=restore_tenant_lottery; debit="$LOTTERY_CASH"; credit="$LOTTERY_CLEARING"; key="provider:p09e:lottery:$EVENT_ID" ;;
    tenant-b) run_tenant=restore_tenant_b; debit="$TENANT_B_CASH"; credit="$TENANT_B_CLEARING"; key="provider:p09e:tenant-b:$EVENT_ID" ;;
  esac
  "$run_tenant" -At -c "SELECT p.duplicate AND p.journal_id=i.journal_id FROM public.provider_event_inbox i CROSS JOIN LATERAL public.post_journal('$key',i.effect_id,i.source_event_id,jsonb_build_array(jsonb_build_object('line_no',1,'account_id','$debit','currency_code','USD','direction','debit','amount_minor','$AMOUNT'),jsonb_build_object('line_no',2,'account_id','$credit','currency_code','USD','direction','credit','amount_minor','$AMOUNT'))) p WHERE i.provider_id='synthetic-provider' AND i.provider_event_id='$EVENT_ID' AND i.status='processed'" | grep -qx t
done
restore_tenant_a -At -c "SELECT p.duplicate FROM public.provider_event_inbox i CROSS JOIN LATERAL public.post_journal('provider:p09e:affiliate:alternate-retry:$EVENT_ID',i.effect_id,i.source_event_id,jsonb_build_array(jsonb_build_object('line_no',1,'account_id','$AFFILIATE_CASH','currency_code','USD','direction','debit','amount_minor','$AMOUNT'),jsonb_build_object('line_no',2,'account_id','$AFFILIATE_CLEARING','currency_code','USD','direction','credit','amount_minor','$AMOUNT'))) p WHERE i.provider_id='synthetic-provider' AND i.provider_event_id='$EVENT_ID' AND i.status='processed'" | grep -qx t

echo "[P-09E] Reconcile restored and replayed provider inbox, journals, immutable outbox and delivery state"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.provider_event_inbox WHERE status='processed' AND journal_id IS NOT NULL")" "3" "processed inbox rows"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.financial_effects")" "3" "unique financial effects"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.posting_requests")" "4" "request identities including one alternate retry token"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.ledger_journals")" "3" "one journal per economic effect"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.ledger_lines")" "6" "two balanced lines per journal"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.ledger_outbox")" "3" "one immutable outbox event per journal"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.outbox_delivery_state")" "3" "one delivery state per outbox event"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.provider_event_reconciliation")" "0" "provider-to-ledger-to-outbox reconciliation exceptions"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM (SELECT tenant_id,product_id,journal_id FROM public.ledger_lines GROUP BY tenant_id,product_id,journal_id HAVING sum(CASE WHEN direction='debit' THEN amount_minor ELSE -amount_minor END)<>0) q")" "0" "balanced journals"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM (SELECT tenant_id,product_id,effect_id FROM public.financial_effects GROUP BY tenant_id,product_id,effect_id HAVING count(*)>1) q")" "0" "no repeated economic effects"
assert_eq "$(restore_admin -At -c "SELECT count(*) FROM public.ledger_journals WHERE source_event_id='$SOURCE_EVENT_ID'")" "3" "same source UUID preserved in all three composite scopes"
assert_eq "$(restore_admin -At -c "SELECT count(DISTINCT product_id) FROM public.ledger_journals WHERE tenant_id='$TENANT_A' AND source_event_id='$SOURCE_EVENT_ID'")" "2" "same-tenant product collision remains distinct"

echo "[P-09E] Prove tenant and product RLS boundaries survived physical backup and restore"
assert_eq "$(restore_tenant_a -At -c "SELECT count(*) FROM public.provider_event_inbox")" "1" "affiliate tenant A inbox visibility"
assert_eq "$(restore_tenant_lottery -At -c "SELECT count(*) FROM public.provider_event_inbox")" "1" "lottery tenant A inbox visibility"
assert_eq "$(restore_tenant_b -At -c "SELECT count(*) FROM public.provider_event_inbox")" "1" "affiliate tenant B inbox visibility"
assert_eq "$(restore_tenant_a -At -c "SELECT count(*) FROM public.provider_event_inbox WHERE product_id='lottery'")" "0" "affiliate cannot read lottery inbox"
assert_eq "$(restore_tenant_lottery -At -c "SELECT count(*) FROM public.provider_event_inbox WHERE product_id='affiliate_agent'")" "0" "lottery cannot read affiliate inbox"

if restore_tenant_a -c "INSERT INTO public.provider_event_inbox(tenant_id,product_id,provider_id,provider_event_id,event_type,event_source,payload_hash,signature_key_id,canonical_event,effect_id,source_event_id) VALUES ('$TENANT_A','lottery','synthetic-provider','evt-cross-product-write-denied','com.synthetic.settlement.posted.v1','urn:synthetic:p09e:forbidden',repeat('d',64),'synthetic-key-v1','{}'::jsonb,gen_random_uuid(),gen_random_uuid())" >"$ROOT/cross-product-write.log" 2>&1; then
  echo "P-09E cross-product inbox write unexpectedly succeeded" >&2
  exit 1
fi
grep -qi "row-level security" "$ROOT/cross-product-write.log"

echo "physical_backup=PASS"
echo "pg_verifybackup=PASS"
echo "physical_restore=PASS"
echo "same_p02_p03d_schema_and_records=PASS"
echo "failed_posting_transaction_rolled_back=PASS"
echo "provider_inbox_replay=PASS"
echo "financial_effect_idempotency=PASS"
echo "outbox_delivery_state_atomicity=PASS"
echo "tenant_product_rls_after_restore=PASS"
echo "source_event_uuid_cross_scope_collision=PASS"
echo "provider_ledger_outbox_reconciliation=PASS"
echo "P09E_RESULT=PASS"
