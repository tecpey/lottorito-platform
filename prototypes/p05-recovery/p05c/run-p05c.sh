#!/usr/bin/env bash
set -euo pipefail
ROOT=/tmp/lottorito-p05c
PRIMARY="$ROOT/primary"
STANDBY="$ROOT/standby"
mkdir -p "$ROOT"
chown postgres:postgres "$ROOT"
as_pg(){ runuser -u postgres -- "$@"; }
psql_primary(){ as_pg env PGHOST=127.0.0.1 PGPORT=55441 PGUSER=postgres psql -X -d postgres -At -v ON_ERROR_STOP=1 "$@"; }
psql_standby(){ as_pg env PGHOST=127.0.0.1 PGPORT=55442 PGUSER=postgres psql -X -d postgres -At -v ON_ERROR_STOP=1 "$@"; }
running(){ as_pg pg_ctl -D "$1" status >/dev/null 2>&1; }
stop_if_running(){ if running "$1"; then as_pg pg_ctl -D "$1" -m fast -w -t 15 stop; fi; }
cleanup(){
  stop_if_running "$STANDBY" || true
  stop_if_running "$PRIMARY" || true
}
trap cleanup EXIT
rm -rf "$ROOT"
install -d -o postgres -g postgres "$ROOT"
echo "[P05C] Initialize two isolated PostgreSQL 18 clusters with checksums and rewind prerequisites"
as_pg initdb -D "$PRIMARY" --data-checksums --auth-local=trust --auth-host=trust >/tmp/p05c-init-primary.log
as_pg bash -c "cat >> '$PRIMARY/postgresql.conf' <<'EOF'
listen_addresses = '127.0.0.1'
port = 55441
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = '128MB'
hot_standby = on
wal_log_hints = on
full_page_writes = on
EOF"
as_pg bash -c "cat >> '$PRIMARY/pg_hba.conf' <<'EOF'
host all all 127.0.0.1/32 trust
host replication repl 127.0.0.1/32 trust
EOF"
as_pg pg_ctl -D "$PRIMARY" -l "$ROOT/primary.log" -o "-p 55441 -h 127.0.0.1" -w -t 30 start
psql_primary -c "CREATE ROLE repl WITH REPLICATION LOGIN" >/dev/null
psql_primary -c "CREATE TABLE public.p05c_events(event_id text PRIMARY KEY, writer_id text NOT NULL, epoch bigint NOT NULL, payload text NOT NULL)" >/dev/null
psql_primary -c "CREATE TABLE public.p05c_fence_state(singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton), current_epoch bigint NOT NULL, active_writer text NOT NULL, lease_until timestamptz NOT NULL)" >/dev/null
psql_primary -c "INSERT INTO public.p05c_fence_state VALUES(true,1,'node-a',clock_timestamp()+interval '1 hour')" >/dev/null
psql_primary -c "CREATE FUNCTION public.p05c_post_effect(p_writer text,p_epoch bigint,p_event_id text,p_payload text) RETURNS void LANGUAGE plpgsql AS \$\$ DECLARE s record; BEGIN SELECT current_epoch,active_writer,lease_until INTO s FROM public.p05c_fence_state WHERE singleton FOR UPDATE; IF NOT FOUND OR s.current_epoch<>p_epoch OR s.active_writer<>p_writer OR s.lease_until<=clock_timestamp() THEN RAISE EXCEPTION 'P05C_WRITER_FENCED'; END IF; INSERT INTO public.p05c_events VALUES(p_event_id,p_writer,p_epoch,p_payload); END \$\$" >/dev/null
psql_primary -c "CREATE FUNCTION public.p05c_claim_epoch(p_expected bigint,p_writer text) RETURNS bigint LANGUAGE plpgsql AS \$\$ DECLARE v_epoch bigint; BEGIN UPDATE public.p05c_fence_state SET current_epoch=current_epoch+1,active_writer=p_writer WHERE singleton AND current_epoch=p_expected AND lease_until>clock_timestamp() RETURNING current_epoch INTO v_epoch; RETURN v_epoch; END \$\$" >/dev/null
psql_primary -c "SELECT public.p05c_post_effect('node-a',1,'baseline','replicated baseline')" >/dev/null

echo "[P05C] Take physical base backup and start standby"
as_pg pg_basebackup -h 127.0.0.1 -p 55441 -U repl -D "$STANDBY" -Fp -Xs -P -R
as_pg bash -c "cat >> '$STANDBY/postgresql.conf' <<'EOF'
listen_addresses = '127.0.0.1'
port = 55442
hot_standby = on
EOF"
as_pg pg_ctl -D "$STANDBY" -l "$ROOT/standby.log" -o "-p 55442 -h 127.0.0.1" -w -t 30 start
for attempt in $(seq 1 60); do
  if test "$(psql_standby -c "SELECT count(*) FROM public.p05c_events WHERE event_id='baseline'")" = "1"; then break; fi
  sleep 0.25
done
test "$(psql_standby -c "SELECT count(*) FROM public.p05c_events WHERE event_id='baseline'")" = "1"
test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "t"
echo "physical_standby_streaming=PASS"

promote_only_if_fenced(){
  if running "$PRIMARY"; then
    echo "refusing promotion while former primary process is still running" >&2
    return 1
  fi
  as_pg pg_ctl -D "$STANDBY" promote -w -t 30
}
echo "[P05C] Promotion gate must refuse while old primary is still alive"
if promote_only_if_fenced >/tmp/p05c-premature-promotion.log 2>&1; then
  echo "promotion was allowed while old primary was alive" >&2; exit 1
fi
grep -q "refusing promotion" /tmp/p05c-premature-promotion.log
echo "promotion_refused_while_old_writer_alive=PASS"

echo "[P05C] Create an explicitly unreplicated old-primary tail, then fence old process"
as_pg pg_ctl -D "$STANDBY" -m fast -w -t 15 stop
psql_primary -c "SELECT public.p05c_post_effect('node-a',1,'old-primary-unreplicated','synthetic tail not present on standby')" >/dev/null
as_pg pg_ctl -D "$PRIMARY" -m fast -w -t 15 stop
if running "$PRIMARY"; then echo "old primary process remained active after fence" >&2; exit 1; fi
echo "old_primary_process_fenced=PASS"

echo "[P05C] Start stale standby without old primary and promote it"
as_pg pg_ctl -D "$STANDBY" -l "$ROOT/standby-failover.log" -o "-p 55442 -h 127.0.0.1" -w -t 30 start
for attempt in $(seq 1 60); do
  if test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "t"; then break; fi
  sleep 0.25
done
test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "t"
promote_only_if_fenced
for attempt in $(seq 1 60); do
  if test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "f"; then break; fi
  sleep 0.25
done
test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "f"
test "$(psql_standby -c "SELECT public.p05c_claim_epoch(1,'node-b')")" = "2"
psql_standby -c "SELECT public.p05c_post_effect('node-b',2,'new-primary-after-failover','accepted on promoted node')" >/dev/null
echo "standby_promoted_and_epoch_advanced=PASS"

echo "[P05C] Reject stale writer and expired lease"
if psql_standby -c "SELECT public.p05c_post_effect('node-a',1,'stale-writer-attempt','must be rejected')" >/tmp/p05c-stale-writer.log 2>&1; then
  echo "stale writer was accepted" >&2; exit 1
fi
grep -q "P05C_WRITER_FENCED" /tmp/p05c-stale-writer.log
psql_standby -c "UPDATE public.p05c_fence_state SET lease_until=clock_timestamp()-interval '1 second' WHERE singleton" >/dev/null
if psql_standby -c "SELECT public.p05c_post_effect('node-b',2,'expired-lease-attempt','must be rejected')" >/tmp/p05c-expired-lease.log 2>&1; then
  echo "expired lease writer was accepted" >&2; exit 1
fi
grep -q "P05C_WRITER_FENCED" /tmp/p05c-expired-lease.log
psql_standby -c "UPDATE public.p05c_fence_state SET lease_until=clock_timestamp()+interval '1 hour' WHERE singleton" >/dev/null
echo "stale_writer_rejected=PASS"
echo "expired_lease_rejected=PASS"

echo "[P05C] Race two promotion claimants against one epoch with atomic compare-and-swap"
(psql_standby -c "SELECT public.p05c_claim_epoch(2,'node-c')" >"$ROOT/cas-c.out") &
PID_C=$!
(psql_standby -c "SELECT public.p05c_claim_epoch(2,'node-d')" >"$ROOT/cas-d.out") &
PID_D=$!
wait "$PID_C"
wait "$PID_D"
WIN_C="$(tr -d '[:space:]' <"$ROOT/cas-c.out")"
WIN_D="$(tr -d '[:space:]' <"$ROOT/cas-d.out")"
WINNERS=0
test -n "$WIN_C" && WINNERS=$((WINNERS+1))
test -n "$WIN_D" && WINNERS=$((WINNERS+1))
test "$WINNERS" = "1"
CURRENT_EPOCH="$(psql_standby -c "SELECT current_epoch FROM public.p05c_fence_state WHERE singleton")"
CURRENT_WRITER="$(psql_standby -c "SELECT active_writer FROM public.p05c_fence_state WHERE singleton")"
test "$CURRENT_EPOCH" = "3"
psql_standby -c "SELECT public.p05c_post_effect('$CURRENT_WRITER',3,'single-cas-winner','only one claimant obtained epoch three')" >/dev/null
echo "concurrent_epoch_claim_single_winner=PASS"

echo "[P05C] Rewind old primary to promoted timeline and rejoin it as standby"
as_pg pg_rewind --target-pgdata="$PRIMARY" --source-server="host=127.0.0.1 port=55442 user=postgres dbname=postgres" --write-recovery-conf --progress
as_pg bash -c "printf '\nport = 55441\n' >> '$PRIMARY/postgresql.auto.conf'"
as_pg pg_ctl -D "$PRIMARY" -l "$ROOT/primary-rejoined.log" -o "-p 55441 -h 127.0.0.1" -w -t 30 start
for attempt in $(seq 1 120); do
  if test "$(psql_primary -c "SELECT pg_is_in_recovery()")" = "t" && test "$(psql_primary -c "SELECT count(*) FROM public.p05c_events WHERE event_id='new-primary-after-failover'")" = "1"; then break; fi
  sleep 0.25
done
test "$(psql_primary -c "SELECT pg_is_in_recovery()")" = "t"
test "$(psql_primary -c "SELECT count(*) FROM public.p05c_events WHERE event_id='new-primary-after-failover'")" = "1"
test "$(psql_primary -c "SELECT count(*) FROM public.p05c_events WHERE event_id='old-primary-unreplicated'")" = "0"
if psql_primary -c "INSERT INTO public.p05c_events VALUES('write-to-rejoined-standby','node-a',1,'must remain read only')" >/tmp/p05c-standby-write.log 2>&1; then
  echo "rewound standby accepted a write" >&2; exit 1
fi
grep -Eqi "read-only transaction|recovery" /tmp/p05c-standby-write.log
echo "pg_rewind_failback_rejoin=PASS"
echo "divergent_unreplicated_tail_discarded=PASS"
echo "rewound_node_read_only=PASS"

echo "[P05C] Controlled switchover back to original node and rewind former primary"
TARGET_LSN="$(psql_standby -c "SELECT pg_current_wal_lsn()")"
for attempt in $(seq 1 120); do
  REPLAY_LSN="$(psql_primary -c "SELECT pg_last_wal_replay_lsn()")"
  if as_pg psql -X -h 127.0.0.1 -p 55441 -U postgres -d postgres -At -c "SELECT '$REPLAY_LSN'::pg_lsn >= '$TARGET_LSN'::pg_lsn" | grep -qx t; then break; fi
  sleep 0.25
done
as_pg pg_ctl -D "$STANDBY" -m fast -w -t 15 stop
as_pg pg_ctl -D "$PRIMARY" promote -w -t 30
for attempt in $(seq 1 60); do
  if test "$(psql_primary -c "SELECT pg_is_in_recovery()")" = "f"; then break; fi
  sleep 0.25
done
test "$(psql_primary -c "SELECT pg_is_in_recovery()")" = "f"
test "$(psql_primary -c "SELECT public.p05c_claim_epoch(3,'node-a')")" = "4"
psql_primary -c "SELECT public.p05c_post_effect('node-a',4,'controlled-failback','original node resumed primary after rewind')" >/dev/null
as_pg pg_rewind --target-pgdata="$STANDBY" --source-server="host=127.0.0.1 port=55441 user=postgres dbname=postgres" --write-recovery-conf --progress
as_pg bash -c "printf '\nport = 55442\n' >> '$STANDBY/postgresql.auto.conf'"
as_pg pg_ctl -D "$STANDBY" -l "$ROOT/standby-failback.log" -o "-p 55442 -h 127.0.0.1" -w -t 30 start
for attempt in $(seq 1 120); do
  if test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "t" && test "$(psql_standby -c "SELECT count(*) FROM public.p05c_events WHERE event_id='controlled-failback'")" = "1"; then break; fi
  sleep 0.25
done
test "$(psql_standby -c "SELECT pg_is_in_recovery()")" = "t"
test "$(psql_standby -c "SELECT count(*) FROM public.p05c_events WHERE event_id='controlled-failback'")" = "1"
test "$(psql_standby -c "SELECT current_epoch FROM public.p05c_fence_state WHERE singleton")" = "4"
test "$(psql_standby -c "SELECT active_writer FROM public.p05c_fence_state WHERE singleton")" = "node-a"
test "$(psql_primary -c "SELECT current_epoch FROM public.p05c_fence_state WHERE singleton")" = "4"
echo "controlled_switchover_back=PASS"
echo "former_primary_rewound_as_standby=PASS"
echo "epoch_four_active_writer_node_a=PASS"
echo "P05C_RESULT=PASS"
