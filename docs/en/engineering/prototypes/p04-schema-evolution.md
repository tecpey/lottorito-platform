# P-04 Schema Evolution and Compatibility

**Document ID:** LOT-PROT-P04-001 | **Version:** 0.2.0 | **Status:** Synthetic prototype; 7 CI tests passed; no production migration approved

## Purpose

A disposable PostgreSQL experiment tests schema evolution while v1/v2 application roles coexist. PostgreSQL 18.7, Node.js 26.13.0 and pg 8.23.1 are candidate inputs only, not approved platform choices.

## Scope

- Tenant-scoped partner events with old payload and additive canonical_payload.
- Two synthetic tenants with distinct v1/v2 LOGIN roles mapped to one tenant identity; RLS derives tenant from session_user.
- Bidirectional trigger compatibility for old/new writers; conflicting dual-write is rejected.
- Transactional migration runner with SHA-256 checksum, advisory lock, idempotent replay and fail-closed checksum drift.
- Bounded resumable backfill using row locks and SKIP LOCKED.
- Lock-timeout failure test and recovery from invalid concurrent index.
- Staged NOT VALID constraint and separate validation.
- Representative ledger and reporting invariants checked before/after.
- Non-destructive contract rehearsal only; legacy column is retained.

## Acceptance

P04-COMPAT: old/new writer-reader coexistence and conflicting-write rejection.
P04-BACKFILL: interruption/reconnect and tenant-scoped resumability.
P04-TENANT: RLS denies cross-tenant access and spoofed ownership.
P04-MIGRATION: idempotent replay, checksum drift rejection and failed-migration rollback.
P04-LOCK: lock_timeout aborts blocked DDL without partial schema change.
P04-INDEX: failed concurrent unique-index build is detected and repaired.
P04-FINANCE: journal/line counts, debit-credit equality and reporting totals remain unchanged.
P04-CONTRACT: projection parity is checked; legacy column is not dropped.

## Limits

No zero-downtime, production-scale lock/backfill, CDC, partitioned-table, multi-region or production migration claim. Trigger is transitional and requires workload-specific review. Migration runner is not a complete framework. Contract does not drop/rename columns; destructive migration requires explicit owner approval after old clients/workers retire and data parity is independently verified. P-02/P-03 fixtures are not modified or connected. Synthetic data/credentials only.

## Evidence

Integration run [45471750215](https://github.com/tecpey/lottorito-platform/actions/runs/45471750215) passed 7 tests (0 failed, 0 skipped) on code head 15c536e5be2f61b1805191f5977a46b17eaf1971; duplicate push run [45471737779](https://github.com/tecpey/lottorito-platform/actions/runs/45471737779) also passed. Documentation Governance run [45471750133](https://github.com/tecpey/lottorito-platform/actions/runs/45471750133) passed on the same head. PostgreSQL 18.7, Node.js 26.13.0, npm ci and pg 8.23.1 were used. Synthetic test success is not production readiness or technology approval.


## Rebased-stack validation — 2026-11-25

The original PR #51 code head passed its seven-test P-04 suite, but that branch was a sibling of P-03C/P-03D. This prototype has been copied onto `spike/p04-schema-evolution-p03d`, whose parent is P-03D PR #61. Re-run P-04 plus P-02/P-03C/P-03D regression and bilingual Documentation Governance on the new PR head. Until then, the original seven-test run is historical evidence only; the rebased P-04 status is pending verification.
