# P-10E — Reliability, Resilience and Disaster Recovery Architecture

**Document ID:** LOT-PROT-P10E-001 | **Version:** 0.1.0 | **Status:** Source-neutral design proposal; not operational approval | **Reviewed:** 2026-11-26

## 1. Purpose and assurance boundary

This document defines a source-neutral reliability and disaster-recovery (DR) framework for the future Lottorito multi-tenant platform: business continuity, data durability, backup/restore, point-in-time recovery, failover, tenant-scoped recovery, queue/event recovery, cryptographic dependency recovery, operational readiness and evidence.

This is not an implementation audit, production runbook, service-level commitment or approval to access/modify a live environment. No production topology, backup catalog, PostgreSQL/Redis configuration, queue broker, object store, KMS, monitoring system, provider contract, region or operating agreement was inspected. No live backup, restore, failover, DR exercise, migration or production data was accessed. All objectives remain unapproved pending business-impact analysis (BIA), source inventory and owner review.

Read this with P-10C (source-neutral migration architecture) and P-10D (security, tenant isolation and governance). It does not supersede financial posting invariants or authorize rewriting ledger history.

## 2. Business-owned recovery objectives

### 2.1 RTO and RPO definitions

RTO is the maximum approved elapsed time to restore a specified service to its agreed minimum operating state. RPO is the maximum approved age of recoverable data at the declared recovery point. Each objective must state its measurement boundary, start/stop events, clock source, included dependencies and scope (tenant, product, region or platform).

For each capability, accountable product, finance, security, privacy/legal and operations owners must assess maximum tolerable disruption, maximum tolerable data loss, non-reconstructible records, external dependencies, recovery order, minimum viable mode, manual fallback, recovery authority and acceptance evidence.

RTO/RPO are business decisions constrained by demonstrated technical capability and cost. Do not copy provider defaults or invent targets. Distinguish service restoration from backlog clearance, reconciliation completion and return to normal operations.

### 2.2 Domain objective register

All values below are **TBD / not approved**. This table is a decision template, not a target proposal.

| Domain | Integrity priority | RPO | RTO | Acceptance evidence |
|---|---|---|---|---|
| Financial ledger and journal | Critical; no silent loss or rewrite | TBD | TBD | Consistent DB recovery, balanced journals, unique effect identities and reconciliation |
| Wallet/payment orchestration and payout instructions | Critical; state transitions must reconcile | TBD | TBD | Ledger + provider evidence + idempotency; no duplicate movement |
| Affiliate attribution and commission | High; explainable recomputation | TBD | TBD | Source events, policy versions, immutable postings and period reconciliation |
| Identity, tenant and authorization control plane | Critical security dependency | TBD | TBD | Membership, roles, key access, revocation and tenant-boundary tests |
| Provider/webhook inbox and outbox | High; replay without duplicate effects | TBD | TBD | Event identity, ordering, signature provenance and inbox/outbox consistency |
| Live chat and notifications | Product-dependent; message-loss tolerance TBD | TBD | TBD | Message durability, provider delivery state and tenant-scoped replay |
| Analytics, search and derived reports | Rebuildable only if source lineage is proven | TBD | TBD | Rebuild from authoritative sources; freshness and tenant-filter validation |
| Static content and documentation | Lower operational criticality; integrity still required | TBD | TBD | Versioned source, artifact checksums and publish validation |

A domain may need separate objectives for read-only availability, write availability, settlement cutoffs, backlog drain and full recovery.

## 3. Data authority and recoverability classification

Classify every store, dataset, keyspace, queue and bucket as one of:
1. **System of record:** authoritative business state; loss requires formal recovery and reconciliation.
2. **Durable event/evidence:** source event, inbox/outbox, provider evidence or audit record needed to reconstruct or explain state.
3. **Rebuildable projection:** cache, search index, analytics aggregate or materialized view; rebuildability must be demonstrated from retained authoritative inputs.
4. **Ephemeral state:** transient session, presence, rate-limit or coordination state; policy may be reset/re-authentication rather than restore.
5. **External authority:** provider, bank, payment or identity evidence whose recovery depends on external exports, APIs and contractual access.

Do not classify Redis, BullMQ, object storage, chat messages or a database as disposable merely because of the technology name. A queue containing the only copy of an event is not disposable. A cache containing the only copy of a business decision indicates an architectural defect.

For every dataset record owner, tenant/product scope, source of truth, classification, retention, encryption/key dependency, backup method, consistency group, restore order, integrity check, rebuild source and approved RPO/RTO.

## 4. Backup protection

Define a policy per data class and store: backup type and schedule; retention and legal hold; encryption in transit/at rest; key custody and historical key retention; independent failure domain/account/credentials; immutable or object-locked copies where justified; catalog/manifest, source identity, timestamp, version, checksum, size and completion status; alerting for missed, late, incomplete, corrupted or inaccessible backups; and restore dependencies.

Use a 3-2-1-style objective as a design prompt, not proof of independence. Verify administrative, credential, region, network and key independence. Replicas and snapshots under one compromised account are not independent protection. Ordinary application, tenant and routine operator identities must not be able to delete backups. Separate backup creation, retention administration, restore approval and evidence review where feasible. Do not expose backup credentials to application workloads or untrusted CI.

### 4.1 PostgreSQL candidate

If PostgreSQL is confirmed as the authoritative store, evaluate base backups plus continuous WAL archiving and PITR for the selected version and hosting model. Maintain a complete, ordered and monitored WAL chain from the selected base backup; verify archive completion and required timeline/history files. Monitor archive lag, oldest recoverable point, backup age, archive failures, storage capacity and restore duration.

A base backup without all required WAL is not a complete PITR set. A successful backup command is not proof of restorability. Preserve multiple known-good sets. Restore into a new isolated instance/data directory, never over the only surviving source. Select recovery target and timeline deliberately; PITR creates a new history. Validate roles, extensions, locale/collation, tablespaces, configuration, replication slots, secrets, encryption and application compatibility separately. Database recovery does not automatically restore external objects, queues, KMS state or provider transactions.

### 4.2 Redis and queues

If Redis is used, classify each logical database/keyspace as authoritative, durable coordination, queue backing store or rebuildable cache. Evaluate RDB, AOF, fsync policy, replication and independent backups against actual loss tolerance. A replica improves availability but is not a backup against logical deletion, corruption, malicious writes or compromised credentials. Restore persistence files on an isolated target and validate them.

For BullMQ or another queue, document broker persistence, queue/consumer topology, delayed/scheduled/repeatable jobs, active/locked jobs, stalled recovery, retry/backoff, dead-letter handling, retention and graceful shutdown. Preserve event identity and idempotency keys. Queue backups do not replace an authoritative event journal or transactional outbox. Re-enqueue only from a proven source with bounded replay and duplicate-effect protection.

### 4.3 Object storage and keys

Version and protect object data, metadata, lifecycle rules and deletion markers. Verify checksums after transfer and restore. Preserve application references and tenant ownership metadata. Back up access policies separately; a restored object with incorrect authorization metadata can expose another tenant's data.

Record KMS/HSM dependencies and historical key-version recovery. Ciphertext is unusable if its decryption key, wrapping key, policy, identity or region is unavailable. Key recovery is a separate tested control with dual control and audit. Never store plaintext keys beside backups.

## 5. Cross-system consistency and financial recovery

Independent snapshots taken at different times do not necessarily represent one coherent business point. Define consistency groups and a recovery protocol across authoritative database/WAL, event inbox/outbox and provider evidence, Redis/queue and worker leases, object storage and metadata, identity/authorization/secrets/key versions, and external provider/payment evidence.

Prefer rebuilding transient/derived components from durable authoritative records only when proven. Otherwise include them in a protected consistency group. Maintain a tamper-evident recovery manifest containing snapshot IDs, source/target identity, timestamps/time zones, database LSN/timeline where applicable, object versions, queue offsets/IDs, key versions, software/configuration version and checksums.

For financial workflows:
1. Stop or isolate writers and external side effects.
2. Identify the last accepted durable event/ledger boundary.
3. Restore to a new isolated environment.
4. Verify journal balancing, unique effect identities, source-to-ledger traceability and period totals.
5. Reconcile provider/bank evidence and pending/unknown outcomes.
6. Replay only authorized events with stable idempotency keys and explicit ordering.
7. Fence stale workers and former regions from writing.
8. Obtain independent finance and operations approval before resuming writes.

A missing local acknowledgement does not prove a payment failed. Query/reconcile with the provider before retrying a potentially completed external side effect. Do not claim exactly-once delivery; use at-least-once processing with idempotent effects and auditable reconciliation.

## 6. Failover, split-brain and fencing

Define failure detection, decision authority, promotion criteria, quorum, replication-lag thresholds and safe failback. Automatic failover is not automatically safe for financial writes. Before promoting a new writer, fence the former writer from clients, workers, schedulers and provider callbacks. Use epoch/term/lease fencing or an equivalent mechanism tied to authoritative state so stale processes cannot commit or publish effects after promotion.

Document behavior for database-primary loss, Redis/cluster loss, worker crash and duplicate delivery, stalled lock recovery, region/network partition, identity/secrets/KMS outage, provider timeout with unknown payment outcome, storage/account compromise and ransomware.

A safe degraded mode may restore read-only service first, but must never bypass ledger, authorization, tenant isolation, audit or approval. If quorum or writer ownership is uncertain, fail closed for irreversible financial actions. Failback is a controlled migration: reconcile divergent writes, establish one authoritative writer, re-seed replicas, verify lag/consistency and retire the former writer.

## 7. Tenant-scoped restore and blast-radius control

Tenant-specific recovery in a shared database is a high-risk extraction workflow, not a direct restore over production. Restore the required point into an isolated temporary environment, then extract into a clean target using reviewed, versioned, tenant-aware procedures.

Confirm tenant identity/ownership from authoritative evidence; never infer it from shared, null or ambiguous legacy values. Identify cross-tenant references, shared/global records and product/legal-entity dependencies. Preserve referential integrity, event lineage, ledger invariants and audit evidence. Prevent copying another tenant's data, secrets, tokens, keys or personal data. Use deterministic reviewed ID mappings and collision checks. Reapply current authorization and retention policies. Reconcile extracted totals/references with the source restore. Obtain independent data-owner, security/privacy and finance approval where applicable. Preserve a manifest of recovery point, extraction code/version, scope, checksums and approvers.

If safe extraction cannot be demonstrated, restore the full environment in isolation and quarantine it. Never restore a shared snapshot over live production as a tenant-level repair.

## 8. Runbooks and recovery sequence

Maintain versioned runbooks with prerequisites, decision authority, source-validated commands, expected outputs, stop conditions, abort/rollback criteria and evidence locations. This architecture contains no generic production command or execution authorization.

Suggested sequence:
1. Declare incident, severity, incident commander and recovery objective.
2. Preserve evidence; isolate compromised/conflicting writers.
3. Establish clean recovery environment, network boundary and trusted identities.
4. Recover secret/KMS access under dual control.
5. Restore authoritative database and required WAL to approved point.
6. Restore/verify durable objects and external evidence.
7. Restore or rebuild queue/Redis according to classification.
8. Validate identity, tenant scope, RLS, grants and audit.
9. Run financial, event, referential and cross-tenant integrity checks.
10. Reconcile provider/payment outcomes; quarantine unknown states.
11. Approve limited read-only or controlled write reopening.
12. Drain/replay backlog with bounded concurrency and idempotency.
13. Monitor SLOs, lag, errors, duplicate/rejected events and reconciliation deltas.
14. Close incident only after owner acceptance and evidence capture.

Keep separate playbooks for incident response, cyber recovery, database PITR, region failover, tenant restore and routine backup restore. Ransomware recovery requires a clean-room strategy, known-good pre-compromise recovery point, credential rotation, forensic evidence preservation and artifact validation before reconnection.

## 9. SLO, observability and capacity

Define SLIs from user-visible outcomes, not only process health. Candidate indicators: authorized critical read/write success; ledger posting success and invariant violations; provider callback acceptance, duplicate/replay rejection and reconciliation age; queue oldest-message age, backlog, retry/DLQ and stalled jobs; DB availability, connection saturation, replication/WAL lag and storage headroom; backup freshness and last verified restore age; KMS/secret retrieval and authorization denials; chat persistence/delivery state where applicable.

For each SLI define numerator, denominator, exclusions, aggregation window, tenant segmentation, alert threshold, owner and data source. Approve SLOs only after baseline measurement and product-owner review. Error budgets may guide release policy but never justify weakening financial correctness, security, privacy or legal controls.

Capacity planning must include restore throughput, WAL replay, object transfer bandwidth, queue replay rate, index rebuild, connection storms, cache warm-up and provider rate limits. A plan exceeding available bandwidth, storage, quotas or provider limits is not viable. Load-test recovery in isolated environments and protect production from replay storms.

## 10. DR exercises and acceptance evidence

Recovery tests must be scheduled, scoped, authorized and recorded. Start with tabletop and isolated restore tests; progress to component failure, regional simulation and controlled failover only after prerequisites and approvals. This document does not authorize destructive or production failover exercises.

Record scenario/assumptions, scope, exact recovery point, approvals, participants, measured RTO/RPO and method, integrity/financial/tenant/security results, missing dependencies, key availability, restore logs, deviations, residual risks, remediation owner/due date, retest evidence and formal acceptance.

A successful test requires correct data integrity, no unauthorized cross-tenant exposure, no duplicate/omitted financial effects, objectives met or formally exceptioned, complete evidence and owner sign-off. "Service started" or "backup job green" alone is not acceptance.

Exercise cadence is risk-based and owner-approved. Planning prompts: continuous backup/lag monitoring; recurring restore sampling; full recovery-path exercise at least annually and after material architecture changes; more frequent tests for critical financial paths where justified. These are not adopted commitments.

## 11. Governance and change control

Name accountable owners for service, data, tenant, finance, security, privacy/legal, platform/DBA, backup, KMS, provider relationship, incident command and release. Define who may declare disaster, select recovery point, authorize writer promotion, accept data loss, resume payments, approve tenant extraction and close incidents. Apply dual control to high-impact financial, key and cross-tenant actions.

Each exception requires scope, rationale, compensating control, risk owner, expiry, review date and evidence. Review recovery plans after schema/store/provider/key/tenant/region changes and material incidents or workload changes.

## 12. Acceptance criteria and required deliverables

P-10E is ready for source-specific implementation planning only when:
1. BIA and domain-level RTO/RPO register have named owner approvals.
2. Every dataset/store has an authority and recoverability classification.
3. Backup, retention, isolation, encryption, key and integrity policies are defined.
4. Database PITR and WAL completeness are measurable where applicable.
5. Queue, Redis, object and external-provider recovery semantics are documented.
6. Consistency groups and recovery manifests are defined.
7. Writer fencing, failover/failback and unknown payment outcome handling are specified.
8. Tenant-scoped restore has isolated extraction design and negative tests.
9. Runbooks, decision rights, communications and clean-room strategy have owners.
10. Restore/DR exercises demonstrate integrity, tenant isolation and measured objectives.
11. SLI/SLO, alerting, capacity and error-budget policy are approved.
12. Finance, Security, Privacy/Legal, Product and Operations sign off.

Deliverables: BIA; RTO/RPO register; data authority/recoverability inventory; backup/retention matrix; key recovery plan; consistency-group map; recovery-manifest schema; PostgreSQL/Redis/queue/object restore procedures; failover/fencing ADR; tenant-restore procedure; incident/DR runbooks; SLI/SLO catalogue; exercise calendar; evidence and exception registers; approvals.

## 13. Non-goals and current status

This document does not select hosting, region, backup vendor, topology, PostgreSQL/Redis version, queue provider, KMS/HSM or SLO target. It does not assert that backups exist, are complete, immutable or restorable. It does not certify RTO/RPO, perform restore/failover, inspect production, approve financial recovery or authorize migration/tenant extraction.

P-10B remains an unexecuted source-inventory protocol; P-10C remains a source-neutral migration framework; P-10D remains a source-neutral security/governance design. P-10E is a source-neutral reliability/DR design baseline only.

## 14. Research references

- PostgreSQL 18, Continuous Archiving and PITR: https://www.postgresql.org/docs/current/continuous-archiving.html
- PostgreSQL Backup and Restore: https://www.postgresql.org/docs/current/backup.html
- Redis Open Source Persistence: https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/
- BullMQ Idempotent Jobs: https://docs.bullmq.io/patterns/idempotent-jobs
- BullMQ Going to Production: https://docs.bullmq.io/guide/going-to-production
- BullMQ Graceful Shutdown: https://docs.bullmq.io/guide/workers/graceful-shutdown
- Google Cloud Well-Architected, Recovery Testing for Data Loss (reviewed 2026-10-27): https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-data-loss
- AWS Well-Architected Reliability Pillar: https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/
- Google SRE Workbook, Error Budget Policy: https://sre.google/workbook/error-budget-policy/
- NIST SP 800-34 Rev. 1, Contingency Planning Guide: https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final

These sources inform design only. They do not establish Lottorito implementation, legal applicability, production readiness or vendor selection.
