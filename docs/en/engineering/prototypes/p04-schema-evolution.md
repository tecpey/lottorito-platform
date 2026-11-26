# P-04 Schema Evolution and Compatibility

**Document ID:** LOT-PROT-P04-001 | **Version:** 0.3.0 | **Status:** Synthetic migration experiment; product-qualified tenant isolation; P-09L CI passed (8/8)

## Purpose

A disposable PostgreSQL experiment tests expand/backfill/validate/contract rehearsal while v1/v2 application roles coexist. P-04 is an independent migration lab; it does not alter P-02/P-03 production schemas.

## P-09L product identity

- The role map binds each database role to both `tenant_id` and canonical `product_id`.
- The same Tenant A has Affiliate & Agent v1/v2 roles and separate Lottery v1/v2 roles. Tenant B remains Affiliate & Agent.
- Partner event identity is `(tenant_id, product_id, event_id)`; RLS and the resumable backfill use the same tuple.
- Journal identity is `(tenant_id, product_id, journal_id)`; line identity and the journal FK include product.
- Reporting identity is `(tenant_id, product_id, report_day)`; RLS also enforces product.
- Synthetic fixtures deliberately reuse the same event UUID and journal UUID across Affiliate & Agent and Lottery within Tenant A.
- Old/new writers coexist independently in each product. A role cannot read or write another product's rows even when UUIDs are identical.

## Existing migration experiment

- Bidirectional trigger compatibility for old/new payload columns; conflicting dual-write is rejected.
- Transactional migration runner with SHA-256 checksum, advisory lock, idempotent replay and fail-closed checksum drift.
- Bounded resumable backfill using row locks and SKIP LOCKED, with explicit tenant/product predicates.
- Lock-timeout failure test and recovery from invalid concurrent index.
- Staged NOT VALID constraint and separate validation.
- Representative ledger and reporting invariants checked before/after.
- Non-destructive contract rehearsal only; legacy column is retained.

## Acceptance

P04-COMPAT: old/new writer-reader coexistence in Affiliate and Lottery.
P04-BACKFILL: interruption/reconnect and resumability independently per tenant/product.
P04-TENANT-PRODUCT: RLS denies cross-tenant and cross-product access and spoofed ownership.
P04-IDENTITY: same event/journal UUIDs are accepted across products but remain distinct composite identities.
P04-MIGRATION: idempotent replay, checksum drift rejection and failed-migration rollback.
P04-LOCK: lock_timeout aborts blocked DDL without partial schema change.
P04-INDEX: failed concurrent index build is detected and repaired with a tenant/product-aware index.
P04-FINANCE: journal/line counts, debit-credit equality and product reporting totals remain unchanged.
P04-CONTRACT: projection parity is checked; legacy column is not dropped.

## Limits

No zero-downtime, production-scale lock/backfill, CDC, partitioned-table, multi-region or production migration claim. Trigger is transitional and requires workload-specific review. Migration runner is not a complete framework. Contract does not drop/rename columns; destructive migration requires explicit owner approval after old clients/workers retire and data parity is independently verified. No production data, credentials or schema are changed. Synthetic test success is not production readiness.

**P-09L CI evidence:** [Run 45863086577](https://github.com/tecpey/lottorito-platform/actions/runs/45863086577) — PASS, 8/8 tests on PostgreSQL 18.7. This includes same-UUID journal/event separation by product, composite journal-line FK rejection, cross-product RLS and rejection of the legacy `shared` token. Exact source head: `a3c06e62a0a83d8ff73e81797d991242d9d5e489`.

## P-09K exact-head validation (2026-11-26)

P-04 schema-evolution compatibility passed on exact head `75fd23701d4e28f047f8ebb73ea0b684bb144c7a`: [workflow 45863298488](https://github.com/tecpey/lottorito-platform/actions/runs/45863298488), 8/8 integration tests. This remains an isolated migration laboratory and is not evidence of a production migration.

## P-09L — Concurrent index recovery serialization and definition verification (2026-11-26)

The P-04 recovery path now pins one PostgreSQL client for the full operation, uses `pg_try_advisory_lock` for the named index and keeps the acquired session-level lock across catalog inspection, optional invalid-index removal, `CREATE INDEX CONCURRENTLY`, and post-build verification. A competing caller does not wait on the advisory lock: it immediately returns `busy` and releases its connection, avoiding a waiting query snapshot that could block the concurrent index build. This is deliberate: session-level locks survive transaction boundaries, while `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block. The lock is explicitly released in `finally`; a connection with uncertain lock-release state is destroyed rather than returned to the pool.

The recovery routine checks both `pg_index.indisvalid` and `indisready`, then verifies the exact `pg_get_indexdef` string. A valid index with the expected name but a different definition fails closed; it is never silently accepted as the desired index. The test starts two recoveries concurrently after a failed unique concurrent build and requires exactly one repair and one nonblocking `busy` or post-repair `valid` result; it then creates a valid wrong-definition index and asserts rejection before restoring the expected definition. The initial blocking-lock implementation exposed a real deadlock between the lock waiter and `CREATE INDEX CONCURRENTLY`; the nonblocking try-lock design removes that wait edge.

**Validation:** [P-04 workflow 45864404159](https://github.com/tecpey/lottorito-platform/actions/runs/45864404159) — 8/8 tests passed on commit `6528003dd867bb19a289fab0bdf0943a537ecd7d`. This remains a disposable PostgreSQL 18.7 migration experiment, not production DDL approval.

Research basis: [PostgreSQL 18 advisory lock functions](https://www.postgresql.org/docs/18/functions-admin.html), [explicit locking](https://www.postgresql.org/docs/18/explicit-locking.html), and [CREATE INDEX CONCURRENTLY failure/recovery behavior](https://www.postgresql.org/docs/18/sql-createindex.html). PostgreSQL documents that a failed concurrent build can leave an invalid index, while session-level advisory lock waiters can retain snapshots; therefore the recovery contender uses try-lock rather than waiting.

## Final P-09L validation update (2026-11-26)

The corrected nonblocking advisory try-lock implementation passed [P-04 workflow 45864974941](https://github.com/tecpey/lottorito-platform/actions/runs/45864974941): 8/8 tests, zero failures, on exact code head `7cb0598a163f40e53a4412a44b476b0404685b75`. The test suite now covers the deadlock regression, concurrent repair convergence, valid-index definition drift rejection, and final catalog verification.
