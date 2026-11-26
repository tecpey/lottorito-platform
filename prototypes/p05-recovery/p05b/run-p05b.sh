#!/usr/bin/env bash
set -euo pipefail
ROOT=/tmp/lottorito-p05
P05B=/workspace/p05b
admin_psql(){ runuser -u postgres -- env PGPASSWORD=p05-admin-only-not-production psql -X -h 127.0.0.1 -p 55432 -U postgres -d lottorito_p05 -v ON_ERROR_STOP=1 "$@"; }
tenant_psql(){ local user="$1" password="$2"; shift 2; runuser -u postgres -- env PGPASSWORD="$password" psql -X -h 127.0.0.1 -p 55432 -U "$user" -d lottorito_p05 -v ON_ERROR_STOP=1 "$@"; }
echo "[P05B] Restore objects and envelope keys"
runuser -u postgres -- env PGPASSWORD=p05-admin-only-not-production python3 "$P05B/object-key-recovery.py"
admin_psql -f "$P05B/events-schema-and-fixtures.sql"
admin_psql -f "$P05B/process-events.sql"
echo "[P05B] Inject interruption and prove transaction rollback"
if admin_psql -c "BEGIN; SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','50000000-0000-4000-8000-000000000001'); SELECT 1/0; COMMIT;" >/tmp/p05b-interrupt.log 2>&1; then exit 1; fi
test "$(admin_psql -At -c "SELECT count(*) FROM public.ledger_journals WHERE economic_effect_id IN ('20000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000102')")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM public.p05_inbox WHERE status<>'pending'")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM public.p05_replay_cursor WHERE last_sequence<>0")" = "0"
echo "[P05B] Run concurrent same-product and cross-product workers"
admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','50000000-0000-4000-8000-000000000001')" >/tmp/p05b-affiliate-1.out & W1=$!
admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','50000000-0000-4000-8000-000000000001')" >/tmp/p05b-affiliate-2.out & W2=$!
admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','50000000-0000-4000-8000-000000000001')" >/tmp/p05b-lottery.out & W3=$!
wait "$W1"; wait "$W2"; wait "$W3"
A1=$(tr -d '\r\n' </tmp/p05b-affiliate-1.out); A2=$(tr -d '\r\n' </tmp/p05b-affiliate-2.out); L1=$(tr -d '\r\n' </tmp/p05b-lottery.out)
test "$((A1+A2))" = "2"; test "$L1" = "2"
test "$(admin_psql -At -c "SELECT count(*) FROM public.p05_inbox WHERE status='processed'")" = "4"
test "$(admin_psql -At -c "SELECT count(*) FROM public.p05_replay_cursor WHERE last_sequence=2")" = "2"
test "$(admin_psql -At -c "SELECT count(*) FROM public.ledger_journals WHERE economic_effect_id IN ('20000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000102')")" = "4"
test "$(admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','50000000-0000-4000-8000-000000000001')")" = "0"
test "$(admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','50000000-0000-4000-8000-000000000001')")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM (SELECT tenant_id,product_id,journal_id FROM public.ledger_lines GROUP BY tenant_id,product_id,journal_id HAVING sum(CASE WHEN direction='debit' THEN amount_minor ELSE -amount_minor END)<>0) q")" = "0"
test "$(admin_psql -At -c "WITH cash AS (SELECT tenant_id,product_id,sum(amount_minor) n FROM public.ledger_lines WHERE account_code='cash' AND direction='debit' GROUP BY tenant_id,product_id), src AS (SELECT tenant_id,product_id,sum(amount_minor) n FROM public.source_events GROUP BY tenant_id,product_id) SELECT count(*) FROM src FULL JOIN cash USING(tenant_id,product_id) WHERE coalesce(src.n,0)<>coalesce(cash.n,0)")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM (SELECT tenant_id,product_id,economic_effect_id FROM public.ledger_journals GROUP BY tenant_id,product_id,economic_effect_id HAVING count(*)>1) q")" = "0"
echo "[P05B] Verify tenant/product RLS"
test "$(tenant_psql p05_tenant_a p05-tenant-a-not-production -At -c "SELECT count(*) FROM public.p05_inbox")" = "2"
test "$(tenant_psql p05_tenant_a_lottery p05-tenant-a-lottery-not-for-production -At -c "SELECT count(*) FROM public.p05_inbox")" = "2"
test "$(tenant_psql p05_tenant_a p05-tenant-a-not-production -At -c "SELECT count(*) FROM public.p05_inbox WHERE product_id='lottery'")" = "0"
test "$(tenant_psql p05_tenant_a p05-tenant-a-not-production -At -c "SELECT count(*) FROM public.source_events WHERE product_id='lottery'")" = "0"
test "$(tenant_psql p05_tenant_a p05-tenant-a-not-production -At -c "SELECT count(*) FROM public.ledger_journals WHERE product_id='lottery'")" = "0"
test "$(tenant_psql p05_tenant_a_lottery p05-tenant-a-lottery-not-for-production -At -c "SELECT count(*) FROM public.source_events WHERE product_id='lottery'")" = "2"
test "$(tenant_psql p05_tenant_a_lottery p05-tenant-a-lottery-not-for-production -At -c "SELECT count(*) FROM public.ledger_journals WHERE product_id='lottery'")" = "2"
test "$(tenant_psql p05_tenant_a_lottery p05-tenant-a-lottery-not-for-production -At -c "SELECT count(*) FROM public.ledger_lines WHERE product_id='lottery'")" = "4"
if tenant_psql p05_tenant_a p05-tenant-a-not-production -c "INSERT INTO public.p05_inbox(tenant_id,product_id,consumer_name,source_event_id,economic_effect_id,aggregate_id,aggregate_seq) VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','affiliate_agent','ledger-projection',gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),1)" >/tmp/p05b-cross-tenant.log 2>&1; then exit 1; fi
grep -qi "row-level security" /tmp/p05b-cross-tenant.log
if tenant_psql p05_tenant_a p05-tenant-a-not-production -c "INSERT INTO public.p05_inbox(tenant_id,product_id,consumer_name,source_event_id,economic_effect_id,aggregate_id,aggregate_seq) VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection',gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),1)" >/tmp/p05b-cross-product.log 2>&1; then exit 1; fi
grep -qi "row-level security" /tmp/p05b-cross-product.log
echo "product_scope_event_identity=PASS"
echo "product_scope_replay_cursor_isolation=PASS"
echo "concurrent_replay_cursor_serialization=PASS"
echo "interrupted_replay_rollback=PASS"
echo "ledger_reconciliation=PASS"
echo "P05B_EVENT_RESULT=PASS"
runuser -u postgres -- pg_ctl -D "$ROOT/restore" -m fast -w stop
echo "P05B_RESULT=PASS"
