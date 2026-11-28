# G09-A20 — Constraint Evidence Acquisition & Adversarial Qualification Design

**Document ID:** LOT-AFFILIATE-G09-A20-001  
**Version:** 1.0.0 | **Status:** Proposed research/test-design only  
**Date:** 2026-11-28

## 1. Purpose and authority

This dossier turns G09-A19's C-01..C-16 constraints and G1..G9 hard gates into (a) an auditable evidence-acquisition register and (b) a candidate-neutral adversarial test design.

It does not select a provider, jurisdiction, region, database, edition, topology, key service, retention period, RPO/RTO, budget or operating model. It does not approve ADR-002, close A11 findings, satisfy A12 independent review, authorize R2 harness execution or authorize R3 production proof. A model-authored analysis is not independent human assurance.

## 2. Baseline and evidence states

Inputs: G09-A17 (OD-01..OD-12 research), G09-A18 (candidate-family evaluation), G09-A19 (C-01..C-16, data-flow inventory and G1..G9), ADR-002 (proposed atomic InboxReceipt + WorkItem and UNKNOWN-commit reconciliation), A11 (eight open findings), A12 (independent review not performed/assessable).

Use these states precisely:
- MISSING: no evidence supplied.
- UNVERIFIED: evidence exists but has not been validated.
- CONTRADICTED: conflicts with another authoritative source or observed behavior.
- EXPIRED: validity window elapsed or a revalidation trigger occurred.
- ACCEPTED: named accountable authority explicitly accepted it for a stated scope/date.
- NOT APPLICABLE: justified in writing and accepted by the accountable authority.
- PASS / FAIL / INCONCLUSIVE: result of a specific reproducible test; absence of failure is not PASS.

Vendor statements, marketing benchmarks, sales emails, architecture diagrams, SOC reports, certification badges and successful CI jobs do not alone prove Lottorito's end-to-end behavior.

## 3. Evidence acquisition register

For every item record: evidence ID; exact question; authoritative issuer; artifact/version/date; scope (legal entity, product, edition, region, service, data class); controlled source reference; integrity hash; classification; reviewer; accountable approver; expiry/revalidation trigger; disposition; linked gates; exceptions.

| ID | Required evidence | Issuer / verifier | Hard stop |
|---|---|---|---|
| C-01 | Incorporation/registry extract, contracting entity, service order, governing terms, subcontracting chain | Owner + qualified counsel | Contracting entity or chain ambiguous |
| C-02 | Customer/operator identity and establishment; licence/authorization where applicable; written jurisdiction map | Customer/operator + counsel | Responsible operator or jurisdiction unknown |
| C-03 | Data inventory/classification; controller/processor roles; special-category and financial-record determination | Privacy owner + counsel | Data classes or roles incomplete |
| C-04 | Exact region/SKU availability; binding residency terms; transfer and onward-transfer map | Provider contract + counsel | Required location/transfer unsupported |
| C-05 | Storage, replica, support, telemetry, control-plane and subprocessor locations; privileged-access paths | Provider + security | Unapproved location/access path |
| C-06 | Retention by record class; backup/log expiry; deletion propagation; legal-hold/restore interaction | Privacy/legal + records owner | Deletion or hold semantics unknown/conflicting |
| C-07 | KMS/HSM product/region; key owner, rotation, revocation, recovery, separation of duties and provider access | Security/crypto owner + provider | Key authority or recovery cannot be evidenced |
| C-08 | Business service map, dependency SLOs, maintenance/support terms and failure-domain assumptions | Service owner + operations | No business owner or dependency model |
| C-09 | Approved BIA, impact over time, tolerable data loss/interruption, recovery tier and measurement boundary | Business owner + continuity lead | RPO/RTO guessed, unapproved or undefined |
| C-10 | User/partner geography, critical path, consistency requirement, measured network topology and latency budget | Product/engineering + operations | Approved critical-path budget cannot be met |
| C-11 | Event rates, tenant skew, payload sizes, concurrency, burst/replay, retention growth and headroom | Product/engineering + data owner | Workload profile materially incomplete |
| C-12 | Named on-call roles, skills, runbooks, incident authority, support coverage and recovery drills | Operations owner | No team can operate/recover the design |
| C-13 | Exact service/SKU/edition/region feature matrix, quotas, SLA, maintenance, support, subprocessors and exclusions | Provider + procurement/security | Required behavior assumed or sales-promised |
| C-14 | Lifecycle cost: compute, replicas, storage, backup, egress, KMS, observability, support, DR, taxes and exit | Finance/procurement | Cost incomplete or above approved ceiling |
| C-15 | Export format/completeness/consistency, restore elsewhere, key access, migration time, deletion proof and exit fees | Architecture + provider + legal | Data/keys unrecoverable or exit impractical |
| C-16 | Audit catalogue, immutable export, retention, trusted timestamps, actor attribution, independent inspection and incident cooperation | Security/audit + provider | Required evidence cannot be collected/inspected |

### 3.1 Evidence quality controls

1. Prefer binding contract terms, exact-SKU official documentation, independently issued assurance reports and reproducible customer-controlled tests—only for questions each source is authoritative to answer.
2. Separate provider-wide claims from exact product, edition, release, region, topology and configuration behavior.
3. Record service exclusions; region existence does not prove every dependent service is available there.
4. Preserve controlled source snapshots and hashes; URLs are mutable.
5. Treat certifications/reports as scoped evidence, not application-specific proof or legal compliance.
6. Revalidate on renewal, product/edition/region/subprocessor/control-plane change, material incident, new data class, legal change or expiry.
7. If evidence is confidential, seek qualified independent inspection. Otherwise mark UNVERIFIED, never PASS.

## 4. Complete data-flow and location inventory

Follow data, metadata, credentials and control signals, not only the primary database. For every component record data classes, tenant scope, read/write paths, source/destination locations, jurisdiction, encryption, key owner, replicas/caches, backup/retention/deletion, support access, subprocessors, audit evidence and recovery dependencies.

Mandatory components:
- Edge: DNS, CDN, WAF, gateway, ingress and edge logs.
- Application/API workers, background workers, schedulers and admin/control plane.
- Primary database, replicas, WAL/transaction logs, CDC and schema registry.
- InboxReceipt, WorkItem, DeliveryOutbox and broker/queue.
- Cache, locks, leases, coordination and authority/fencing service.
- Object storage, backups, snapshots, PITR/WAL archives and restore staging.
- KMS/HSM, secrets manager, certificates and identity provider.
- Metrics, traces, logs, crash dumps, profiling and alert payloads.
- CI/CD, build artifacts, package registries, IaC state and deployment metadata.
- Support tickets/attachments, provider support bundles and break-glass access.
- Analytics, exports, warehouse, search indexes and downstream consumers.

**Completeness test:** trace one synthetic event ID and tenant ID through every component, including logs, backups, support and restore. Any unexplained copy, location, principal or retention path blocks qualification.

## 5. Candidate-neutral invariants and independent oracles

All candidate adapters must prove the same invariants using product-specific mechanisms.

- I-01: success acknowledgement only after the required durable InboxReceipt + WorkItem pair commits under the approved durability policy.
- I-02: exactly one pair per approved source identity; uniqueness/cardinality enforced by persistence authority, not application code alone.
- I-03: same identity + same semantic payload cannot create a second accepted work item or economic effect.
- I-04: same identity + different semantic fingerprint is rejected/quarantined, never silently treated as duplicate.
- I-05: UNKNOWN commit is neither presumed success nor failure; authoritative reconciliation safely arbitrates with any in-flight original transaction.
- I-06: stale primary, worker, lease holder, authority epoch or restored environment cannot mutate protected state after losing authority.
- I-07: tenant comes from trusted installation context; payload-controlled fields cannot cross tenant boundaries.
- I-08: restore/PITR cannot silently resurrect expired dedupe tombstones, revoked credentials/authority or consumed economic identities.
- I-09: ingress/worker identities cannot reach financial posting capabilities; ingress tests assert zero financial side effects.
- I-10: audit/evidence is attributable, time-qualified, integrity-protected and sufficient to reconstruct decisions without prohibited data.

Independent oracle families:
- Database: authoritative reads, uniqueness/cardinality constraints, transaction history and consistency metadata.
- Protocol: captured request/response and event identity/fingerprint, independently parsed.
- Authority: epoch/term/fencing state and rejection of stale actors at mutation time.
- Financial non-effect: independent ledger/journal query and privilege inspection; zero balance/journal delta.
- Tenant: cross-tenant negative queries and authorization traces.
- Recovery: restored data, source/target checkpoints, WAL/CDC/replication positions and reconciliation report.
- Evidence: raw artifact hashes, trusted time, runner identity and immutable run manifest.

The application code under test must not be its sole correctness oracle.

## 6. Adversarial qualification catalogue

These are designed cases, NOT RUN. Pin exact product, version, edition, region, topology, configuration and client/driver before adapting. If fault occurrence is unproven or the oracle cannot distinguish histories, outcome is INCONCLUSIVE.

| ID | Scenario and stimulus | Required pass condition |
|---|---|---|
| A20-01 | Partition old primary from quorum/authority while selected clients remain connected | At most one authority commits; old primary fenced |
| A20-02 | Restore network to isolated old primary with stale state | Former primary cannot accept writes/rejoin as authority without safe reconciliation |
| A20-03 | Remove enough voters/fault domains to lose quorum | Protected writes fail closed; no unsafe local acceptance |
| A20-04 | Acknowledge pair then immediately fail active node/domain | Acknowledged pair survives within approved RPO |
| A20-05 | Drop client response after server commit | Client sees UNKNOWN; authoritative reconciliation finds one pair; retry creates no duplicate |
| A20-06 | Pause original commit and race a retry/negative reconciliation read | Absence is not concluded while original commit may linearize; exactly one terminal pair |
| A20-07 | Barrier-release concurrent same-identity requests across nodes | Exactly one pair; losers receive documented duplicate/in-progress result |
| A20-08 | Concurrent same identity with different semantic payloads | Conflict rejected/quarantined; no silent overwrite |
| A20-09 | Inject stale/rolled-back authority epoch or replay old token | Mutation-time fencing rejects stale authority; epoch never rolls back/reuses |
| A20-10 | Expire worker lease, reclaim with new generation, resume stale worker | Stale generation cannot commit protected state or external side effects |
| A20-11 | Duplicate, delay, reorder and redeliver outbox messages | Consumer idempotency holds; ordering contract explicit; source atomicity preserved |
| A20-12 | Disable broker, accumulate backlog, restore with replay storm | No durable work loss/duplication; bounded resources and fair tenant scheduling |
| A20-13 | Corrupt backup, omit required log segment or alter manifest | Integrity/recovery fails closed; no false healthy-restore declaration |
| A20-14 | PITR before/after a synthetic accepted event | Recovery point explicit; no duplicate replay or tombstone resurrection |
| A20-15 | Restore across schema/config/registry/key/credential change | Compatibility proven or restore blocked pending controlled migration/reconciliation |
| A20-16 | Isolate primary region and invoke pre-authorized DR | Approved RPO/RTO measured; single writer; residency/key constraints preserved |
| A20-17 | Fail back after writes occurred in DR | No dual writer; divergence reconciled explicitly; acknowledged work not lost |
| A20-18 | Rotate/revoke/deny/recover keys under controlled test | Approved availability/confidentiality behavior; unauthorized decrypt denied |
| A20-19 | Use cross-tenant IDs and compromised low-privilege operator principal | No cross-tenant read/write/disclosure; break-glass bounded and attributable |
| A20-20 | Trace synthetic markers through logs/traces/backups/support/analytics | All copies/locations match accepted inventory; unknown destination fails |
| A20-21 | Expire records, restore old backup, replay old event beyond retention boundary | Approved lifecycle honored; no duplicate economic effect or silent identity resurrection |
| A20-22 | Rolling upgrade, client mismatch, downgrade or interrupted migration | Invariants hold; unsupported downgrade blocked; recovery documented |
| A20-23 | Oversized payload, hot tenant, retry amplification and storage pressure | Explicit quotas/backpressure; no starvation beyond approved limits |
| A20-24 | Skew node clocks, stop time sync and delay lock acquisition | Authority/lease correctness does not rely on unproven wall-clock assumptions |
| A20-25 | Attempt audit deletion, policy change, backup deletion or evidence tampering | Separation of duties and immutable/external evidence prevent or detect action |
| A20-26 | Restore into isolated environment with stale production-like secrets | Restored environment cannot reach production/partner/payment/authority/ledger |
| A20-27 | Inject failures around a synthetic separately-authorized posting boundary | Balanced immutable journal or no posting; never partial economic effect |
| A20-28 | Steady/burst/soak load while repeating selected failures | Correctness remains PASS; performance separately measured against approved SLO |

### 6.1 Candidate-specific adapter cautions

- PostgreSQL HA: prove actual synchronous-standby configuration, commit mode, quorum membership, failover controller/fencing, WAL archive continuity, timeline handling and restore. synchronous_commit=on without configured synchronous standbys is not proof of remote acknowledgement. pg_verifybackup is not a substitute for isolated restore and domain assertions.
- CockroachDB: pin release, locality/lease/replication configuration, retry handling and ambiguous-commit semantics. Test serializable retries and backup/recovery with exact driver. Generic SQLSTATE retry guidance does not prove application side-effect idempotency.
- YugabyteDB: distinguish synchronous Raft replication inside a universe from asynchronous xCluster between universes. Pin RF, placement, consistency mode, conflict/DDL behavior, backup source and supported restore. Do not infer zero-loss regional DR from an asynchronous target.
- Spanner: pin instance configuration, replica placement, dialect, backup/PITR, key model and client API. UNKNOWN commit requires reconciliation, not automatic retry. Verify backup copy/restore region behavior and residency implications.

These are test obligations, not a comparative verdict. Product documentation does not replace exact-candidate testing.

## 7. Safety and authorization gates

Before execution:
1. Owner authorizes named stage, environment, budget and time window in writing.
2. Legal/privacy/security approve synthetic data and every test location.
3. Relevant A4 gates are explicitly approved.
4. R2 harness scope, exact candidate and test plan are reviewed; real customer/player/partner data and production credentials are prohibited.
5. Test environment has no route or credentials to production, partner, payment, wallet, payout or live ledger.
6. Fault injection has kill switch, blast-radius limit, rollback and named operator.
7. Evidence collection is enabled before stimulus; clocks/time sources recorded.
8. Independent reviewer approves oracle and expected outcome before the run.

Immediate stop: real data/credentials; unexpected external side effect; cross-tenant exposure; financial mutation; two active authorities; unreconciled acknowledged-write loss; evidence tampering; uncontrolled resource exhaustion; or boundary breach.

Synthetic isolated success does not authorize production. R3 requires separate owner decision and operational/legal/security approvals.

## 8. Reproducibility manifest

Each run must preserve:
- run/case IDs, sequence, UTC start/end and trusted time-source evidence;
- owner authorization, approved stage, named operator and independent reviewer;
- exact product/edition/release/region/topology and configuration export/hash;
- IaC, application, schema, driver, client and harness commit digests;
- synthetic fixture generator/version/seed, tenant/event IDs and payload hashes;
- fault mechanism, schedule, target, timing and proof the fault occurred;
- expected history, assertions, independent oracle queries and raw outputs;
- logs/traces/metrics, replication positions, backup IDs and recovery checkpoints;
- PASS/FAIL/INCONCLUSIVE, deviations, parser version and variance/confidence where relevant;
- cleanup/deletion proof and residual artifacts;
- reviewer disposition, exceptions, signatures and revalidation date.

Do not place secrets or raw personal data in evidence bundles. Redaction must preserve forensic meaning; protected originals require approved access and retention.

## 9. Non-compensatory decision method

Qualification is sequential:
1. Admissibility: legal, residency, data-flow, contract and security constraints accepted.
2. Correctness: I-01..I-10 proven on exact candidate.
3. Recovery: backup, PITR, failover, failback and key recovery demonstrated within approved objectives.
4. Operability: staffed runbooks, monitoring, escalation and repeated drills demonstrated.
5. Performance/economics: only after hard gates pass; equivalent workloads; report distributions, tail latency, error rate, backlog, recovery time, cost and uncertainty separately.

FAIL or INCONCLUSIVE on a mandatory gate blocks qualification. Weighted scoring cannot compensate for legal, security, durability, atomicity or recovery failure. Do not rank candidates before C-01..C-16 are accepted and the exact comparison set is frozen.

Decision record: candidate identity; scope/exclusions; evidence index and hashes; gate results; accepted risks/dissent; cost/exit analysis; approvers; validity; revalidation triggers; explicit selected/rejected/deferred/not-admissible outcome.

## 10. Research basis and limitations

- NIST SP 800-34 Rev. 1: https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final
- PostgreSQL backup and restore: https://www.postgresql.org/docs/current/backup.html
- PostgreSQL continuous archiving/PITR and timelines: https://www.postgresql.org/docs/current/continuous-archiving.html
- PostgreSQL pg_verifybackup limitations: https://www.postgresql.org/docs/current/app-pgverifybackup.html
- PostgreSQL synchronous replication/standby: https://www.postgresql.org/docs/current/warm-standby.html
- CockroachDB transaction/retry: https://www.cockroachlabs.com/docs/stable/developer-basics.html
- YugabyteDB backup/restore/PITR: https://docs.yugabyte.com/stable/manage/backup-restore/
- YugabyteDB asynchronous xCluster: https://docs.yugabyte.com/stable/explore/going-beyond-sql/asynchronous-replication-ysql/
- YugabyteDB replication: https://docs.yugabyte.com/stable/architecture/docdb-replication/
- Spanner UNKNOWN commit: https://docs.cloud.google.com/spanner/docs/reference/rest/v1/projects.instances.databases.sessions/commit
- Spanner backup copy/restore: https://docs.cloud.google.com/spanner/docs/backup
- Spanner PITR: https://docs.cloud.google.com/spanner/docs/pitr

NIST supports a lifecycle including BIA, recovery strategy, exercises and maintenance; it does not set Lottorito objectives. PostgreSQL distinguishes backup integrity checks from successful restore and correct application data. Distributed products differ in synchronous/asynchronous, retry, UNKNOWN and backup semantics. Official documentation describes capabilities under stated conditions; it does not prove Lottorito's exact configuration, legal admissibility, operator competence or application invariants.

## 11. Current disposition

- G09-A20: PROPOSED research/test-design only.
- C-01..C-16: OPEN; no owner evidence acquired/accepted here.
- Data-flow inventory: required; completeness not demonstrated.
- A20-01..A20-28: DESIGNED / NOT RUN.
- Candidate families: UNSELECTED / NOT QUALIFIED.
- G1..G9: NOT TESTED / NOT PASSED.
- ADR-002: PROPOSED; OD-01..OD-12 OPEN.
- A11-F01..F08 OPEN; A12 independent review NOT PERFORMED / NOT ASSESSABLE.
- R0 BLOCKED; R1 research-only; R2 NOT STARTED; R3 NOT AUTHORIZED.
- A4 gates NOT APPROVED.
- No runtime/harness, provider selection, partner integration, financial operation, merge or deployment authorized.

**Conclusion:** this dossier defines how evidence is acquired and how candidate claims are safely falsified. It does not claim any candidate passed.
