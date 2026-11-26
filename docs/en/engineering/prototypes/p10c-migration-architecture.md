# P-10C — Staged Migration Architecture and Coexistence Decision Framework

**Document ID:** LOT-PROT-P10C-001 | **Version:** 0.1.0 | **Status:** Source-neutral architecture proposal; no source or target approved | **Reviewed:** 2026-11-26

## 1. Purpose and authorization boundary

P-10C defines how a safe, staged migration should be designed after an owner-approved P-10B inventory. It is intentionally source-neutral: no production schema, volume, engine topology, traffic profile, consistency model, RPO/RTO, legal entity, accounting policy or target deployment has been verified. This document does not select a migration technology, set a cutover date, approve dual-write, or authorize source access, DDL, DML, backfill, replication, financial posting, merge or deployment.

A source-specific plan requires: (1) reviewed P-10B source register, metadata snapshot and lineage; (2) owner-adjudicated tenant, product and legal-entity ownership; (3) source/target engine versions, schema, roles, RLS, writers, readers, jobs and dependencies; (4) data classification, jurisdiction, retention and transfer approvals; (5) measured volume, write rate, peak load and capacity; (6) business-approved consistency, downtime, RPO/RTO and financial-close requirements; and (7) named source owner, DBA, domain owner, security/privacy reviewer, finance approver and cutover authority. Missing inputs are blockers, never defaults.

## 2. Non-negotiable invariants

- **One authoritative writer per aggregate at a time.** Never create two independently writable authorities for the same financial or business aggregate.
- **No blind dual-write.** A database write and an independent broker/API write are not atomic. Prefer a transactional outbox in the same database transaction or source-supported CDC with a documented offset/replay model. Dual-write is admissible only when atomicity and failure recovery are proven for the actual systems.
- **Expand before contract.** Add compatible structures; deploy readers/writers that tolerate both representations; backfill and validate; switch authority only after gates; remove old structures only after rollback and retention dependencies expire.
- **Backfill must be deterministic, idempotent, resumable, bounded and observable.** Each chunk needs stable scope/cursor, checkpoint, retry-safe writes, rate limits, metrics and stop/resume procedure.
- **Tenant, product and legal-entity identity are explicit.** Never infer or default missing attribution. The legacy value shared is not a canonical product or tenant.
- **Financial history is immutable.** Do not rewrite posted journals or fabricate transaction history from aggregates. Corrections require approved compensating/reversal entries. Never silently convert currencies.
- **Reconciliation precedes authority transfer.** Counts alone are insufficient; validate identities, relationships, states, exact monetary totals per currency and source-to-ledger lineage.
- **Rollback is state-dependent.** Before target writes, returning to source may be safe. After target becomes authoritative and accepts writes, a pointer flip can lose/fork data. Rehearse forward-fix, reverse-delta/CDC or restore/replay; never promise rollback without proof.
- **Evidence is reproducible and minimized.** Retain query/code versions, manifests, counts, checksums and approval references. Keep raw PII, credentials and customer/player/payment payloads out of Git, CI and chat.

## 3. Candidate migration patterns (not technology selections)

| Pattern | Fit | Risks / proof required |
|---|---|---|
| Offline snapshot + maintenance cutover | Small/low-change source; downtime acceptable | Consistent snapshot, complete delta or write freeze, restore rehearsal, measured outage |
| Expand + bounded application backfill | Compatible old/new app versions can coexist in one transactional database | Mixed-version compatibility, chunk locks, idempotency, retirement of old clients |
| Snapshot + CDC/logical replication | Large dataset or low downtime requirement; source supports reliable log capture | DDL coordination, replica identity, sequence state, WAL/slot retention, lag, conflicts, failover and exact cutover LSN |
| Domain-by-domain incremental migration | Bounded contexts have clear ownership and can move independently | Cross-domain references, API/event contracts, temporary coexistence and reconciliation |
| ETL/batch import | Historical transformation or non-operational analytics | Transformation lineage, late changes, deduplication, privacy and repeatability |

Do not choose PostgreSQL logical replication merely because both endpoints use PostgreSQL. It does not replicate DDL; sequence state needs separate handling; large objects and some relation types have restrictions. Schema coordination and sequence synchronization must be explicit. Verify the exact source/target major versions and current official limitations before adoption.

**Default planning posture:** prefer a bounded domain-by-domain expand/backfill/validate/cutover/contract plan. Use CDC only when measured volume and downtime requirements justify its operational complexity and the source topology supports it. If no safe incremental path exists, choose a controlled maintenance-window migration; do not call it zero-downtime.

## 4. Source-to-target mapping and coexistence

For each object family, specify: source/target object and bounded-context owner; authoritative writer by phase; stable source key, target key, natural key and uniqueness scope; tenant/product/legal-entity/currency derivation with evidence; field transformations, null semantics, precision/scale, timezone and enum mapping; parent/child ordering and deletion behavior; event/economic-effect/idempotency identities and trace link; PII classification, purpose, retention, masking and deletion propagation; rejected/ambiguous cases, quarantine reason and human adjudication owner.

Mapping must be total for admitted records and explicitly partial for excluded/quarantined records. Never silently map unknown enums, absent currency, null tenant/product or ambiguous shared rows. No default may turn missing identity into affiliate_agent, lottery or platform scope.

For every domain and phase, define one write authority and the permitted read authority. A routing facade must enforce idempotency and preserve source identity. Document read-after-write behavior and stale-read tolerance. Cache, search, analytics, exports, scheduled jobs, webhooks, workers and manual operations are part of the migration surface, not just the primary database.

## 5. Backfill engineering contract

A source-specific plan must define:

1. **Eligibility:** only in-scope, owner-adjudicated records with complete required identity and valid parent relationships.
2. **Deterministic partitioning:** stable primary-key ranges or immutable cursors; avoid offset pagination over changing datasets.
3. **Chunk sizing:** based on measured lock duration, transaction size, WAL/replication impact, I/O and replica lag—not arbitrary row counts.
4. **Idempotency:** deterministic key such as (migration_id, source_id, source_pk), protected by target uniqueness. Same key/same canonical payload is a safe retry; same key/different payload is a hard conflict.
5. **Checkpointing:** persist completed ranges and source snapshot/LSN boundary; checkpoint only after target commit.
6. **Concurrency:** bounded workers, partition by tenant/product only where safe, no unbounded fan-out, respect FK dependency order and avoid hot-key contention.
7. **Rate control:** pause/throttle on DBA-defined lock-wait, transaction-age, WAL-growth, replication-lag, CPU/I/O, error-rate or application-SLO thresholds.
8. **Failure handling:** quarantine malformed records with opaque references; never silently skip; use bounded retries with exponential backoff and jitter.
9. **Repeatability:** rerunning a completed chunk creates no duplicate business identity, new financial effect or mutation of immutable history.
10. **Audit:** migration ID, code/config digest, source snapshot/LSN, range, counts, checksum, timestamps, actor, result and exception totals.

A high-water mark alone is insufficient if updates/deletes can occur behind it. Use a consistent snapshot plus captured change stream, or a documented write-freeze/delta window. Include deletion/tombstone semantics to prevent deleted source records from being resurrected.

## 6. Financial and identity reconciliation

Financial migration is a separate controlled workstream, not an ordinary table copy.

- Preserve original journal IDs where safe, source references, currency, approved integer minor-unit precision, posting time, accounting period, account mapping and immutable audit lineage.
- Validate debit and credit independently for every currency, legal entity, tenant, product, account class and accounting period. Never net unlike currencies.
- Reconcile source events to economic effects and posted journals. Delivery ID, webhook ID, request idempotency key and economic-effect identity are distinct.
- Compare posted, pending, held, reversed, disputed, voided and quarantined states separately. Validate reversal chains and prevent pending effects from being posted twice.
- Do not infer NGR, eligible revenue, commission, agent entitlement, tax, FX or payout obligations from field names. Require approved domain/accounting rules and source evidence.
- If history is incomplete, do not manufacture historical journals. An opening balance or migration adjustment is permissible only with Finance approval, source evidence, balancing entries, period treatment and traceable migration reference.
- Freeze or explicitly account for concurrent financial activity during final reconciliation. Any unexplained difference blocks cutover.

Minimum evidence: per-scope counts; exact debit/credit totals per currency; source-to-effect and effect-to-journal coverage; duplicate/missing identity counts; orphan/quarantine counts; state distribution; reversal linkage; before/after control totals; independently reviewed exception dispositions. A matching count or aggregate does not prove correct ownership or accounting treatment.

## 7. Cutover state machine

| Phase | Source authority | Target authority | Exit gate |
|---|---|---|---|
| C0 Prepare | Source | None | Approved mapping, controls, backups, rehearsals, abort/forward-fix plan |
| C1 Expand | Source | None | Additive schema compatible with all active source app versions |
| C2 Snapshot/backfill | Source | None | Snapshot boundary fixed; backfill complete or within defined delta window |
| C3 Catch up | Source | None | Lag within approved threshold; no unresolved apply errors |
| C4 Validate | Source | Read-only shadow | Reconciliation, security, performance and business sign-offs pass |
| C5 Freeze/fence | Temporarily frozen | Read-only | Writers/jobs/webhooks fenced; final delta drained; no stale source writer |
| C6 Promote | Target | Target | Atomic authority switch, sequence/identity readiness, health gates, smoke and ledger checks |
| C7 Observe | Target | Target | Monitoring and business reconciliation pass; source retained read-only |
| C8 Contract | Target | Target | Rollback/retention window expired; old clients/jobs retired; destructive cleanup explicitly approved |

A feature flag or DNS change alone is not fencing. Use a verifiable writer epoch/lease or equivalent so stale workers and old application instances cannot write after promotion. Record cutover checkpoint (LSN or equivalent), source/target high-water marks, active writer identity and operator approvals.

## 8. Rollback, forward-fix and recovery

- Before target writes: return to source only after proving it remained complete and authoritative.
- During shadow reads: disable shadow reads; source remains writer.
- During final freeze: abort promotion; re-enable source only after proving no target-only committed effects exist.
- After target writes: never flip back blindly. Prefer forward-fix on target; otherwise use rehearsed reverse-delta/CDC with conflict handling, or restore/replay from a verified recovery point.
- If both systems accepted writes, stop both writers, preserve logs/snapshots, fence stale workers and reconcile before resuming. Never use last-write-wins for financial or ownership data.
- Contract/destructive changes occur only after the rollback window and verification of retained artifacts/dependencies.

A backup is not a rollback plan until restore, integrity checks, application/worker recovery and replay have been rehearsed. Set RPO/RTO from approved business impact analysis; do not invent numeric targets here.

## 9. Security, privacy and operational controls

Use a dedicated least-privilege, time-bound migration identity, separate from application identity. Analyze role ownership and RLS bypass explicitly. Enforce tenant/product scope at extraction and target-write boundaries; RLS is defense in depth, not a substitute for correct scope. Encrypt transfers/storage using approved mechanisms; never copy secrets or credential verifiers. Minimize columns and retention; keep restricted manifests outside repository and CI logs.

Monitor lock waits, long transactions, dead tuples/bloat, WAL/archive growth, replication slots, replica lag, disk headroom, CPU/I/O, error/quarantine rate, API latency and worker backlog. Define abort thresholds and named operator authority before execution. Stop on unexplained financial differences, identity ambiguity, privilege/RLS surprises, replication errors, data loss, unexpected load or missing evidence.

Before a real migration, test tenant isolation, authorization, replay, duplicates, partial failure, interrupted chunks, schema skew, stale workers, restore and failover in disposable environments.

## 10. Decision record and deliverables

Source-specific approval requires: a Migration Architecture ADR comparing viable patterns; source-to-target mapping and compatibility matrix; writer/reader authority matrix; backfill runbook with chunk/checkpoint/idempotency and capacity budget; financial reconciliation specification and approved exception register; cutover/fencing/abort/forward-fix/rollback/restore runbooks; security/privacy/legal review; measured rehearsal on representative synthetic or properly authorized masked data; and named approvals from source owner/DBA, domain owner, Security/Privacy, Finance and release authority.

## 11. Acceptance criteria

P-10C is ready for source-specific implementation planning only when P-10B inventory is authorized, executed and independently reviewed; all migrated tenant/product/legal-entity identities are evidence-backed; unresolved cases are excluded/quarantined; one write authority is defined per domain; backfill is deterministic, bounded, resumable, idempotent and observable, including updates/deletes/replay; financial reconciliation is exact per currency/period with zero unexplained differences; fencing and promotion/abort/forward-fix are rehearsed; restore meets owner-approved RPO/RTO and integrity requirements; and Security, Privacy, Legal, DBA, Finance and business owners approve the specific plan.

Until then P-10C remains a design framework. It is not production-readiness certification or migration authorization.

## 12. Research references

- AWS Prescriptive Guidance, relational database migration strategy: https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-database-migration/
- AWS Prescriptive Guidance, transactional outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- PostgreSQL logical replication: https://www.postgresql.org/docs/current/logical-replication.html
- PostgreSQL logical replication restrictions: https://www.postgresql.org/docs/current/logical-replication-restrictions.html
- PostgreSQL explicit locking: https://www.postgresql.org/docs/current/explicit-locking.html
- PostgreSQL CREATE INDEX: https://www.postgresql.org/docs/current/sql-createindex.html
- Google Cloud recovery testing: https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-failures
- NIST SP 800-207 Zero Trust Architecture: https://csrc.nist.gov/pubs/sp/800/207/final

These references inform design; they do not imply vendor adoption, compliance certification or validation of an actual Lottorito environment.
