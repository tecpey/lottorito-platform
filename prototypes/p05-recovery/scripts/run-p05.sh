#!/usr/bin/env bash
set -euo pipefail
ROOT=/tmp/lottorito-p05
ARCHIVE=/var/lib/postgresql/wal-archive
ADMIN_PASSWORD=p05-admin-only-not-production
rm -rf "$ROOT"
install -d -o postgres -g postgres "$ROOT"
as_pg(){ runuser -u postgres -- "$@"; }
admin_psql(){ as_pg env PGPASSWORD="$ADMIN_PASSWORD" psql -X -h 127.0.0.1 -U postgres -d lottorito_p05 -p "${PGPORT:-5432}" -v ON_ERROR_STOP=1 "$@"; }
restore_psql(){ as_pg env PGPASSWORD="$ADMIN_PASSWORD" psql -X -h 127.0.0.1 -U postgres -d lottorito_p05 -p 55432 -v ON_ERROR_STOP=1 "$@"; }
tenant_count(){ as_pg env PGPASSWORD="$2" psql -X -h 127.0.0.1 -p "$3" -U "$1" -d lottorito_p05 -At -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM public.ledger_journals"; }
echo "[P05] Create synthetic schema"
as_pg psql -X -v ON_ERROR_STOP=1 -d lottorito_p05 -f /workspace/db/setup.sql
echo "[P05] Create physical base backup"
BACKUP_START=$(date +%s)
as_pg env PGPASSWORD="$ADMIN_PASSWORD" pg_basebackup -h 127.0.0.1 -U postgres -D "$ROOT/base" -Fp -Xs -P
as_pg pg_verifybackup "$ROOT/base"
BACKUP_SECONDS=$(( $(date +%s) - BACKUP_START ))
echo "[P05] Create pre-target marker, named restore point and post-target marker"
admin_psql -c "INSERT INTO public.recovery_markers(marker) VALUES('before-p05-restore-point')"
RESTORE_LSN="$(admin_psql -At -c "SELECT pg_create_restore_point('p05_before_incident')")"
RESTORE_WAL="$(admin_psql -At -c "SELECT pg_walfile_name('$RESTORE_LSN'::pg_lsn)")"
admin_psql -c "INSERT INTO public.recovery_markers(marker) VALUES('after-p05-restore-point')"
admin_psql -c "SELECT pg_switch_wal()" >/dev/null
for attempt in $(seq 1 40); do test -s "$ARCHIVE/$RESTORE_WAL" && break; sleep 1; done
test -s "$ARCHIVE/$RESTORE_WAL" || { echo "required WAL not archived: $RESTORE_WAL" >&2; exit 1; }
echo "[P05] Prove corrupted manifest is rejected"
cp -a "$ROOT/base" "$ROOT/tampered"
printf '\n' >> "$ROOT/tampered/backup_manifest"
if as_pg pg_verifybackup "$ROOT/tampered" >/tmp/p05-tamper.log 2>&1; then echo "tampered manifest accepted" >&2; exit 1; fi
echo "[P05] Restore into second data directory"
cp -a "$ROOT/base" "$ROOT/restore"
as_pg touch "$ROOT/restore/recovery.signal"
as_pg bash -c "cat >> '$ROOT/restore/postgresql.auto.conf' <<'EOF'
restore_command = 'cp $ARCHIVE/%f %p'
recovery_target_name = 'p05_before_incident'
recovery_target_action = 'promote'
recovery_target_timeline = 'latest'
EOF"
RESTORE_START=$(date +%s)
as_pg pg_ctl -D "$ROOT/restore" -l "$ROOT/restore.log" -o "-p 55432 -h 127.0.0.1 -c archive_mode=off" -w start
RESTORE_SECONDS=$(( $(date +%s) - RESTORE_START ))
echo "[P05] Assert PITR and tenant RLS"
test "$(tenant_count p05_tenant_a p05-tenant-a-not-production 55432)" = "1"
test "$(tenant_count p05_tenant_b p05-tenant-b-not-production 55432)" = "1"
test "$(restore_psql -At -c "SELECT count(*) FROM public.recovery_markers WHERE marker='before-p05-restore-point'")" = "1"
test "$(restore_psql -At -c "SELECT count(*) FROM public.recovery_markers WHERE marker='after-p05-restore-point'")" = "0"
grep -q 'recovery stopping at restore point "p05_before_incident"' "$ROOT/restore.log"
test "$(restore_psql -At -c "SELECT count(*) FROM public.ledger_journals")" = "2"
test "$(as_pg env PGPASSWORD=p05-tenant-a-not-production psql -X -h 127.0.0.1 -p 55432 -U p05_tenant_a -d lottorito_p05 -At -c "SELECT count(*) FROM public.ledger_journals WHERE tenant_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'")" = "0"
test "$(as_pg env PGPASSWORD=p05-tenant-b-not-production psql -X -h 127.0.0.1 -p 55432 -U p05_tenant_b -d lottorito_p05 -At -c "SELECT count(*) FROM public.ledger_journals WHERE tenant_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'")" = "0"
echo "[P05] Prove cross-tenant writes are denied"
if as_pg env PGPASSWORD=p05-tenant-a-not-production psql -X -h 127.0.0.1 -p 55432 -U p05_tenant_a -d lottorito_p05 -v ON_ERROR_STOP=1 -c "INSERT INTO public.ledger_journals VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','10000000-0000-4000-8000-000000000099','20000000-0000-4000-8000-000000000099','USD','30000000-0000-4000-8000-000000000099')" >/tmp/p05-cross-tenant.log 2>&1; then echo "cross-tenant insert unexpectedly succeeded" >&2; exit 1; fi
grep -qi "row-level security" /tmp/p05-cross-tenant.log
echo "[P05] Reconcile journals and source totals"
test "$(restore_psql -At -c "SELECT count(*) FROM (SELECT tenant_id,journal_id FROM public.ledger_lines GROUP BY tenant_id,journal_id HAVING sum(CASE WHEN direction='debit' THEN amount_minor ELSE -amount_minor END)<>0) q")" = "0"
test "$(restore_psql -At -c "WITH cash AS (SELECT tenant_id,sum(amount_minor) n FROM public.ledger_lines WHERE account_code='cash' AND direction='debit' GROUP BY tenant_id), src AS (SELECT tenant_id,sum(amount_minor) n FROM public.source_events GROUP BY tenant_id) SELECT count(*) FROM src FULL JOIN cash USING(tenant_id) WHERE coalesce(src.n,0)<>coalesce(cash.n,0)")" = "0"
test "$(restore_psql -At -c "SELECT count(*) FROM (SELECT tenant_id,economic_effect_id FROM public.ledger_journals GROUP BY tenant_id,economic_effect_id HAVING count(*)>1) q")" = "0"
test "$(restore_psql -At -c "SELECT count(*) FROM public.object_refs WHERE content_sha256 !~ '^[0-9a-f]{64}$'")" = "0"
echo "restore_point_lsn=$RESTORE_LSN"
echo "restore_wal=$RESTORE_WAL"
echo "backup_and_verify_seconds=$BACKUP_SECONDS"
echo "restore_start_seconds=$RESTORE_SECONDS"
echo "P05A_RESULT=PASS"
as_pg pg_ctl -D "$ROOT/restore" -m fast -w stop
