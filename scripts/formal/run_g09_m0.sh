#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

: "${TLA2TOOLS_JAR:?TLA2TOOLS_JAR must point to the pinned tla2tools.jar}"
OUT_DIR="${TLC_OUT_DIR:-$ROOT/build/formal/g09-m0}"
EXPECTED_SHA256="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"

mkdir -p "$OUT_DIR"
actual_sha256="$(sha256sum "$TLA2TOOLS_JAR" | awk '{print $1}')"
if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
  printf 'TLA2TOOLS SHA-256 mismatch: expected %s, got %s\n' "$EXPECTED_SHA256" "$actual_sha256" >&2
  exit 1
fi

printf 'TLA2TOOLS_SHA256=%s\n' "$actual_sha256"
java -version

run_case() {
  local name="$1"
  local config="$2"
  local expected="$3"
  local log="$OUT_DIR/$name.log"
  local meta="$OUT_DIR/meta-$name"
  local status=0

  mkdir -p "$meta"
  printf '\n===== TLC case: %s (expected: %s) =====\n' "$name" "$expected"

  java -XX:+UseParallelGC -Xmx1g -cp "$TLA2TOOLS_JAR" \
    tlc2.TLC -workers 1 -seed 1 -fp 0 \
    -metadir "$meta" -config "$config" \
    formal/G09M0AtomicAcceptance.tla >"$log" 2>&1 || status=$?

  cat "$log"

  if [[ "$expected" == "PASS" ]]; then
    if [[ "$status" -ne 0 ]] || ! grep -Fq 'Model checking completed. No error has been found.' "$log"; then
      printf 'Baseline case %s did not complete cleanly (exit=%s).\n' "$name" "$status" >&2
      return 1
    fi
  else
    if [[ "$status" -ne 12 ]] || ! grep -Fq "Error: Invariant $expected is violated." "$log"; then
      printf 'Mutant %s did not produce the expected invariant violation (exit=%s).\n' "$name" "$status" >&2
      return 1
    fi
  fi
}

run_case baseline formal/G09M0AtomicAcceptance.cfg PASS
run_case mutant_partial_commit formal/G09M0MutantPartialCommit.cfg PairAtomicity
run_case mutant_duplicate_pair formal/G09M0MutantDuplicatePair.cfg AtMostOneReceipt
run_case mutant_early_ack formal/G09M0MutantEarlyAck.cfg AcceptedAckSoundness

printf '\nAll G09 M0 baseline and negative-control expectations matched.\n'
