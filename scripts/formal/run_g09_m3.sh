#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
: "${TLA2TOOLS_JAR:?TLA2TOOLS_JAR must point to the pinned tla2tools.jar}"
OUT_DIR="${TLC_OUT_DIR:-$ROOT/build/formal/g09-m3}"
EXPECTED_SHA256="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"
mkdir -p "$OUT_DIR"
actual_sha256="$(sha256sum "$TLA2TOOLS_JAR" | awk '{print $1}')"
if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
  printf 'TLA2TOOLS SHA-256 mismatch: expected %s, got %s\n' "$EXPECTED_SHA256" "$actual_sha256" >&2
  exit 1
fi
printf 'TLA2TOOLS_SHA256=%s\n' "$actual_sha256"
printf 'TLA+ Tools pin: v1.7.4 (TLC 2.19)\n'
java -version
sha256sum formal/G09M3WorkerLeaseGeneration.tla formal/G09M3*.cfg | tee "$OUT_DIR/sha256-manifest.txt"

run_case() {
  local name="$1" config="$2" expected="$3"
  local log="$OUT_DIR/$name.log" meta="$OUT_DIR/meta-$name" status=0
  mkdir -p "$meta"
  printf '\n===== TLC case: %s (expected: %s) =====\n' "$name" "$expected"
  java -XX:+UseParallelGC -Xmx1g -cp "$TLA2TOOLS_JAR" \
    tlc2.TLC -workers 1 -seed 1 -fp 0 \
    -metadir "$meta" -config "$config" \
    formal/G09M3WorkerLeaseGeneration.tla >"$log" 2>&1 || status=$?
  cat "$log"
  if [[ "$expected" == "PASS" ]]; then
    if [[ "$status" -ne 0 ]] || ! grep -Fq 'Model checking completed. No error has been found.' "$log"; then
      printf 'Baseline case %s did not complete cleanly (exit=%s).\n' "$name" "$status" >&2
      return 1
    fi
  else
    if [[ "$status" -ne 12 ]] || ! grep -Fq "Error: Invariant $expected is violated." "$log"; then
      printf 'Mutant %s did not produce expected invariant violation (exit=%s).\n' "$name" "$status" >&2
      return 1
    fi
  fi
}

run_case baseline formal/G09M3WorkerLeaseGeneration.cfg PASS
run_case mutant_prelock_time formal/G09M3MutantPreLockTime.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_worker_clock formal/G09M3MutantWorkerClock.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_stale_generation formal/G09M3MutantStaleGeneration.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_wrong_token formal/G09M3MutantWrongToken.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_wrong_tenant formal/G09M3MutantWrongTenant.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_stale_lifecycle formal/G09M3MutantStaleLifecycle.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_stale_state formal/G09M3MutantStaleState.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_expired_heartbeat formal/G09M3MutantExpiredHeartbeat.cfg EveryAcceptedMutationWasAuthorized
run_case mutant_heartbeat_generation formal/G09M3MutantHeartbeatGeneration.cfg HeartbeatDoesNotAdvanceGeneration
run_case mutant_guard_mutation formal/G09M3MutantGuardMutation.cfg GuardFailureHasZeroMutation

printf '\nAll G09 M3 baseline and negative-control expectations matched.\n'
