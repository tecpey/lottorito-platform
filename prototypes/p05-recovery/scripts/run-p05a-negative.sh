#!/usr/bin/env bash
set -euo pipefail
ROOT=/tmp/lottorito-p05
NEG=/tmp/lottorito-p05-negative
ARCHIVE=/var/lib/postgresql/wal-archive
as_pg(){ runuser -u postgres -- "$@"; }
rm -rf "$NEG"
install -d -o postgres -g postgres "$NEG"
# Values are written by the successful P-05A positive PITR drill.
source "$ROOT/restore.env"
test -s "$ROOT/base/backup_manifest"
test -s "$ARCHIVE/$RESTORE_WAL"
echo "[P05A-NEG] Verify an incomplete restore staging directory is rejected"
as_pg cp -a "$ROOT/base" "$NEG/incomplete-restore"
as_pg rm -f "$NEG/incomplete-restore/global/pg_control"
if as_pg pg_verifybackup "$NEG/incomplete-restore" >"$NEG/incomplete-verify.log" 2>&1; then
  echo "incomplete restore staging directory unexpectedly verified" >&2; exit 1
fi
grep -q "global/pg_control" "$NEG/incomplete-verify.log"
if as_pg pg_ctl -D "$NEG/incomplete-restore" -l "$NEG/incomplete-start.log" -o "-p 55434 -h 127.0.0.1 -c archive_mode=off" -w -t 8 start >"$NEG/incomplete-pgctl.log" 2>&1; then
  echo "incomplete restore staging directory unexpectedly started" >&2
  as_pg pg_ctl -D "$NEG/incomplete-restore" -m immediate -w -t 5 stop || true
  exit 1
fi
if as_pg pg_ctl -D "$NEG/incomplete-restore" status >/dev/null 2>&1; then
  as_pg pg_ctl -D "$NEG/incomplete-restore" -m immediate -w -t 5 stop
  echo "incomplete restore left a running server" >&2; exit 1
fi
echo "incomplete_restore_manifest_rejected=PASS"
echo "incomplete_restore_server_start_rejected=PASS"

echo "[P05A-NEG] Remove the exact WAL segment containing the named recovery target"
as_pg cp -a "$ROOT/base" "$NEG/missing-wal-restore"
as_pg cp -a "$ARCHIVE" "$NEG/archive-with-gap"
as_pg rm -f "$NEG/archive-with-gap/$RESTORE_WAL" "$NEG/missing-wal-restore/pg_wal/$RESTORE_WAL"
test ! -e "$NEG/archive-with-gap/$RESTORE_WAL"
test ! -e "$NEG/missing-wal-restore/pg_wal/$RESTORE_WAL"
as_pg touch "$NEG/missing-wal-restore/recovery.signal"
as_pg bash -c "cat >> '$NEG/missing-wal-restore/postgresql.auto.conf' <<'EOF'
restore_command = 'cp $NEG/archive-with-gap/%f %p'
recovery_target_name = 'p05_before_incident'
recovery_target_action = 'promote'
recovery_target_timeline = 'latest'
EOF"
# A missing archive object may cause startup to fail, or may leave a server
# recoverable only to an earlier point. Both outcomes are rejected unless the
# named target marker is present and verified.
if as_pg pg_ctl -D "$NEG/missing-wal-restore" -l "$NEG/missing-wal.log" -o "-p 55433 -h 127.0.0.1 -c archive_mode=off" -w -t 15 start >"$NEG/missing-wal-pgctl.log" 2>&1; then
  if pg_isready -h 127.0.0.1 -p 55433 >/dev/null 2>&1; then
    recovery_state="$(as_pg psql -X -h 127.0.0.1 -p 55433 -U postgres -d lottorito_p05 -At -c "SELECT pg_is_in_recovery()")"
    if test "$recovery_state" = "t"; then
      as_pg pg_ctl -D "$NEG/missing-wal-restore" -m immediate -w -t 5 stop
      echo "missing_wal_server_remains_read_only_in_recovery=PASS"
    else
      echo "missing WAL unexpectedly produced a writable server before the requested target" >&2
      as_pg pg_ctl -D "$NEG/missing-wal-restore" -m immediate -w -t 5 stop || true
      exit 1
    fi
  else
    as_pg pg_ctl -D "$NEG/missing-wal-restore" -m immediate -w -t 5 stop || true
    echo "missing_wal_startup_not_ready=PASS"
  fi
else
  if as_pg pg_ctl -D "$NEG/missing-wal-restore" status >/dev/null 2>&1; then
    as_pg pg_ctl -D "$NEG/missing-wal-restore" -m immediate -w -t 5 stop
  fi
  echo "missing_wal_startup_failed_closed=PASS"
fi
grep -q "$RESTORE_WAL" "$NEG/missing-wal.log"
echo "missing_wal_target_segment_absence_detected=PASS"
echo "P05A_NEGATIVE_RESULT=PASS"
