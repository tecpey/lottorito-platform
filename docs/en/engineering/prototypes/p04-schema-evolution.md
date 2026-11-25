# P-04 Schema Evolution and Compatibility

**Document ID:** LOT-PROT-P04-001 | **Version:** 0.3.0 | **Status:** Synthetic prototype; 8 CI tests passed; no production migration approved

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
P04-PAYLOAD-INVARIANT: neither legacy nor new writers can clear both payload representations; failed updates preserve prior values.

## Limits

No zero-downtime, production-scale lock/backfill, CDC, partitioned-table, multi-region or production migration claim. Trigger is transitional and requires workload-specific review. Migration runner is not a complete framework. Contract does not drop/rename columns; destructive migration requires explicit owner approval after old clients/workers retire and data parity is independently verified. P-02/P-03 fixtures are not modified or connected. Synthetic data/credentials only.

## Evidence

Integration [45619282469](https://github.com/tecpey/lottorito-platform/actions/runs/45619282469) passed 8 tests (0 failed, 0 skipped) on exact head `27f8dd2b089574c980c25c862e97525b57ff96be`. The new regression test prevents legacy and new writers from clearing both payload representations and confirms failed updates preserve prior values. Documentation Governance [45619282483](https://github.com/tecpey/lottorito-platform/actions/runs/45619282483) passed on the same head. PostgreSQL 18.7, Node.js 26.13.0, npm ci and pg 8.23.1 were used. Synthetic test success is not production readiness or technology approval.
