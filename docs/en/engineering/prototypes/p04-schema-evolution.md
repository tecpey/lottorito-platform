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
