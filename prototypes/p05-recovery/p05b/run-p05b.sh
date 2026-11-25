#!/usr/bin/env bash
set -euo pipefail
ROOT=/tmp/lottorito-p05
P05B=/workspace/p05b
admin_psql(){ runuser -u postgres -- env PGPASSWORD=p05-admin-only-not-production psql -X -h 127.0.0.1 -p 55432 -U postgres -d lottorito_p05 -v ON_ERROR_STOP=1 "$@"; }
echo "[P05B] Restore object bytes and envelope keys from independent recovery sets"
runuser -u postgres -- env PGPASSWORD=p05-admin-only-not-production python3 "$P05B/object-key-recovery.py"
echo "[P05B] Create tenant-scoped inbox and replay fixtures"
admin_psql -f "$P05B/events-schema-and-fixtures.sql"
admin_psql -f "$P05B/process-events.sql"
echo "[P05B] Inject interruption inside atomic inbox-to-ledger transaction"
if admin_psql -c "BEGIN; SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','50000000-0000-4000-8000-000000000001'); SELECT 1/0; COMMIT;" >/tmp/p05b-interrupt.log 2>&1; then
 echo "interrupted replay unexpectedly committed" >&2; exit 1
fi
test "$(admin_psql -At -c "SELECT count(*) FROM public.ledger_journals WHERE economic_effect_id IN ('20000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000102')")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM public.p05_inbox WHERE status<>'pending'")" = "0"
test "$(admin_psql -At -c "SELECT last_sequence FROM public.p05_replay_cursor WHERE consumer_name='ledger-projection'")" = "0"
echo "[P05B] Retry pending events after transaction rollback"
test "$(admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','50000000-0000-4000-8000-000000000001')")" = "2"
test "$(admin_psql -At -c "SELECT count(*) FROM public.p05_inbox WHERE status='processed'")" = "2"
test "$(admin_psql -At -c "SELECT last_sequence FROM public.p05_replay_cursor WHERE consumer_name='ledger-projection'")" = "2"
test "$(admin_psql -At -c "SELECT count(*) FROM public.ledger_journals WHERE economic_effect_id IN ('20000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000102')")" = "2"
test "$(admin_psql -At -c "SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','50000000-0000-4000-8000-000000000001')")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM (SELECT tenant_id,journal_id FROM public.ledger_lines GROUP BY tenant_id,journal_id HAVING sum(CASE WHEN direction='debit' THEN amount_minor ELSE -amount_minor END)<>0) q")" = "0"
test "$(admin_psql -At -c "WITH cash AS (SELECT tenant_id,sum(amount_minor) n FROM public.ledger_lines WHERE account_code='cash' AND direction='debit' GROUP BY tenant_id), src AS (SELECT tenant_id,sum(amount_minor) n FROM public.source_events GROUP BY tenant_id) SELECT count(*) FROM src FULL JOIN cash USING(tenant_id) WHERE coalesce(src.n,0)<>coalesce(cash.n,0)")" = "0"
test "$(admin_psql -At -c "SELECT count(*) FROM (SELECT tenant_id,economic_effect_id FROM public.ledger_journals GROUP BY tenant_id,economic_effect_id HAVING count(*)>1) q")" = "0"
echo "[P05B] Verify tenant isolation and reject cross-tenant writes"
test "$(runuser -u postgres -- env PGPASSWORD=p05-tenant-a-not-production psql -X -h 127.0.0.1 -p 55432 -U p05_tenant_a -d lottorito_p05 -At -c "SELECT count(*) FROM public.p05_inbox")" = "2"
if runuser -u postgres -- env PGPASSWORD=p05-tenant-a-not-production psql -X -h 127.0.0.1 -p 55432 -U p05_tenant_a -d lottorito_p05 -v ON_ERROR_STOP=1 -c "INSERT INTO public.p05_inbox VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','ledger-projection','30000000-0000-4000-8000-000000000199','20000000-0000-4000-8000-000000000199','50000000-0000-4000-8000-000000000001',1,'pending')" >/tmp/p05b-cross-tenant.log 2>&1; then
 echo "cross-tenant inbox insert unexpectedly succeeded" >&2; exit 1
fi
grep -qi "row-level security" /tmp/p05b-cross-tenant.log
echo "event_delivery_order=2,1,duplicate-2"
echo "event_inbox_deduplication=PASS"
echo "sequence_gap_blocked=PASS"
echo "interrupted_replay_rollback=PASS"
echo "replay_retry_exactly_two_effects=PASS"
echo "ledger_reconciliation=PASS"
echo "tenant_inbox_isolation=PASS"
echo "P05B_EVENT_RESULT=PASS"
runuser -u postgres -- pg_ctl -D "$ROOT/restore" -m fast -w stop
echo "P05B_RESULT=PASS"
