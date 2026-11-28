# G09-A19 — Deployment Constraints & Candidate Qualification Matrix

**Dossier:** `LOT-AFFILIATE-G09-A19-001`  
**Date:** 2026-11-28  
**Status:** RESEARCH / CONSTRAINT DISCOVERY — NO DEPLOYMENT OR TECHNOLOGY DECISION  
**Parent:** G09-A18 — Persistence & Authority Candidate Architecture Evaluation  
**Scope:** Affiliate financial-event acceptance, idempotency, ledger posting, outbox/inbox, evidence and recovery boundary.

## 1. Executive disposition

G09-A19 converts the candidate families in G09-A18 into a constraint-first qualification process. It does **not** select a cloud, region, database, topology, managed service, legal jurisdiction, numeric RPO/RTO, retention period, or budget.

**Current decision: NO CANDIDATE IS QUALIFIED.** Candidate scoring is intentionally withheld until mandatory constraints and evidence are supplied. A weighted score must never compensate for failure of a legal, residency, security, correctness, or recovery hard gate.

The first decision is not “which database is best?” It is “which deployment footprints are legally, contractually, operationally and technically admissible for the exact data classes and failure guarantees?” Only then can database products be compared fairly.

## 2. Scope and explicit non-goals

In scope:
- authoritative acceptance of an external partner event;
- event identity, idempotency, Receipt/WorkItem cardinality;
- financial journal and commission state;
- Inbox/Outbox, replay, quarantine and audit evidence;
- backups, restore, failover, fencing and credential/key dependencies;
- data and metadata locations across the full service chain.

Out of scope:
- selecting a production hosting country or provider;
- legal conclusions about any customer, operator, country or gaming license;
- choosing numeric availability, RPO, RTO, retention or latency targets;
- approving a vendor, commercial contract, data-processing agreement or cross-border transfer;
- runtime proof, production migration, real partner integration, financial operations, merge or deployment authorization.

## 3. Governing principles

1. **Constraint-first, not score-first.** Hard constraints are pass/fail. A weighted model is used only among candidates that pass every applicable hard gate.
2. **Data-location is a system property.** Database rows are only one part of the footprint. Include application compute, queues, caches, object storage, backups, snapshots, logs, traces, metrics, support bundles, control-plane metadata, identity systems, KMS/HSM, CDN/WAF, email/SMS providers, analytics, fraud tooling, CI artifacts and vendor support access.
3. **At-rest location is not the whole legal question.** Distinguish storage location, processing location, remote access, onward transfer, support access, telemetry, subprocessors, encryption-key control and deletion obligations. Obtain jurisdiction-specific legal review; provider marketing pages are not legal advice.
4. **Residency and resilience can conflict.** Cross-region synchronous replication may improve fault tolerance while violating a single-country storage boundary. A read replica, witness, backup or telemetry stream may create a separate location question.
5. **A provider claim is not a deployment proof.** Require service-specific terms, region/service availability, topology configuration, control evidence, test results and contractual commitments.
6. **Unknown is not pass.** Mark unknowns as OPEN / NOT EVIDENCED, never as assumed compliant.
7. **Financial correctness precedes availability.** During uncertainty, fail closed for new authoritative acceptance rather than acknowledge an event that may later disappear or be double-posted.

## 4. Constraint register — owner inputs required

Each row must be completed with a value, source, accountable owner, date, scope and evidence link. No inferred values.

| ID | Constraint domain | Required question / evidence | Gate treatment |
|---|---|---|---|
| C-01 | Contracting entity | Which legal entity operates Lottorito and which entity contracts with each customer/provider? | Hard gate |
| C-02 | Customer/operator jurisdiction | What legal entities, operating countries, licenses and contractual obligations actually apply to the first tenant? Do not infer from a proposed pilot. | Hard gate |
| C-03 | Data subjects & categories | Which data subjects and data classes are processed: partner identity, player identifiers, financial/commission records, credentials, support content, telemetry? Classification and minimization required. | Hard gate |
| C-04 | Residency boundary | For each data class, which countries/regions are permitted, required, prohibited, or subject to transfer conditions? | Hard gate |
| C-05 | Processing/access boundary | Are remote support, administrator access, subprocessors, control-plane processing or telemetry outside the storage region allowed? Under what controls? | Hard gate |
| C-06 | Retention/deletion | Applicable retention, legal hold, deletion, erasure, backup expiry and immutable-ledger constraints. Reconcile conflicting obligations. | Hard gate |
| C-07 | Key custody | Who controls encryption keys, key location, rotation, revocation, recovery and break-glass? Are provider-managed keys acceptable? | Hard gate |
| C-08 | Availability objective | Which user-visible and internal services require availability, and what failure scope must be survived? | Business approval |
| C-09 | RPO/RTO | Business Impact Analysis must set tolerated data loss and recovery time per capability, not one blanket number. | Business approval |
| C-10 | Latency | Required p50/p95/p99 for event acceptance, ledger commit, reads and operator workflows; source workload and geography. | Measured target |
| C-11 | Load envelope | Expected and peak event rate, burst duration, tenant count, event size, retention growth, concurrent writers and replay backlog. | Measured target |
| C-12 | Operations | Who can operate, patch, fail over, restore and investigate? Coverage hours, escalation, skills, runbooks and separation of duties. | Hard operational gate |
| C-13 | Provider constraints | Allowed providers, account ownership, region availability, service exclusions, sanctions/export restrictions and procurement limits. | Hard gate |
| C-14 | Cost envelope | Budget range and cost ownership for compute, storage, replicas, network egress, backups, observability, support and DR drills. | Owner approval |
| C-15 | Exit/portability | Required export format, restore portability, migration window, vendor exit, key/data deletion evidence and dependency inventory. | Hard gate |
| C-16 | Audit/evidence | Required log classes, immutability, access review, retention, evidence export and independent assurance. | Hard gate |

**Required artifact before scoring:** a signed/approved Constraint Decision Record containing C-01..C-16, with explicit `NOT APPLICABLE` justifications where appropriate. The owner may delegate factual research, but legal and commercial approvals remain with accountable humans.

## 5. Data-flow and location inventory

Build one row per data flow and service. Do not collapse all data into “database”.

| Plane / component | Data to inventory | Location questions | Evidence required |
|---|---|---|---|
| API / application compute | request bodies, auth context, memory, temporary files | execution region, failover region, debug dumps | deployment topology, service terms, config export |
| Primary database | canonical event, receipt, work item, ledger, tenant metadata | primary, replicas, quorum/witness placement | exact topology, replication config, service terms |
| Queue / broker | event payloads, offsets, delivery metadata | brokers, replicas, DLQ, control plane | region map, retention and replication config |
| Cache / Redis | tokens, locks, dedupe hints, ephemeral state | node, replica, snapshots, persistence | config and data classification; must not be sole financial authority |
| Object storage | backups, exports, evidence, attachments | bucket region, replication, versioning, object lock | bucket policy, replication rules, lifecycle |
| Backup / DR | base backups, WAL, snapshots, replicas | copy destination, vault, restore environment | restore tests, immutability, expiry, access logs |
| KMS / HSM | key material, metadata, wrapping keys | key region, replica, control plane, recovery | key policy, audit log, recovery procedure |
| Observability | logs, traces, metrics, exception payloads | collector, vendor SaaS, support exports | redaction rules, data-location terms, retention |
| Identity / secrets | user/admin identity, API keys, secrets | IdP region, support access, backup | DPA/terms, MFA, RBAC, break-glass logs |
| Edge / CDN / WAF | IPs, request metadata, cached content | edge processing, log export, origin | vendor data map, cache and logging policy |
| CI/CD / artifacts | schema, fixtures, test data, secrets, build artifacts | runner region, artifact retention | sanitized fixtures, secret scanning, retention |
| Support / subprocessors | tickets, screen shares, diagnostic bundles | human access locations, subprocessors | contractual access model and audit trail |

A data-flow row is incomplete unless it names: source, destination, purpose, data class, tenant boundary, storage/processing/access locations, encryption boundary, retention, deletion path, subprocessor, owner and evidence.

## 6. Candidate families — conditional qualification, not ranking

| Candidate family | Potential strengths | Critical constraints / failure modes | Minimum evidence before consideration |
|---|---|---|---|
| Engineered PostgreSQL HA (self-managed) | Familiar relational semantics; explicit WAL/replication/failover design; deployment flexibility | Operator owns fencing, failover orchestration, backup/restore, patching, monitoring, quorum semantics and DR; asynchronous promotion can lose acknowledged data if incorrectly designed | Reproducible topology; sync settings and standby quorum; STONITH/fencing proof; split-brain test; PITR/restore drill; measured latency; on-call and patch plan |
| Managed PostgreSQL HA | Reduced infrastructure operations; provider-managed patching/failover options | “HA” may be zone-level only; service-specific failover, replication acknowledgement, backup region, read replica and control-plane semantics differ; limited access to fencing internals | Exact SKU/region/service docs; contract/SLA; sync commit semantics; failover behavior; backup copy locations; restore proof; support-access/data-location terms |
| CockroachDB (specific edition and topology) | Distributed SQL, serializable transactions, automatic replication; locality/survival controls | Cross-region quorum can raise write latency; retries are part of application contract; region survivability requires a supported topology and explicit configuration; product/edition/region support varies | Exact release/edition; topology and locality; survival goal; transaction retry tests; failure-domain test; region/metadata placement; service terms and cost |
| YugabyteDB (specific product/deployment) | PostgreSQL-compatible API; Raft replication; self-managed and managed footprints; geo-partitioning options | Default synchronous replication across regions can copy all data across regions; geo-partitioning and xCluster have different semantics; operations and compatibility require validation | Exact product/version; RF and region topology; geo-partition map; xCluster direction/consistency; failure test; restore; PostgreSQL compatibility tests; operations model |
| Google Cloud Spanner (specific configuration) | Managed distributed SQL; serializable/external consistency; regional and multi-region topologies | Location configurations are constrained; multi-region voting quorum can span countries/regions; geo-partitioning has documented metadata/statistics exceptions; vendor lock-in and cost | Exact instance configuration; allowed location fit; data-residency terms; geo-partition caveats; transaction/unknown-commit recovery tests; export/exit test; region failure and cost evidence |
| Authority + durable transactional store + outbox separation | Makes the authoritative acceptance boundary explicit; can isolate event identity/fencing from downstream work | More moving parts; must not create two independent authorities or non-atomic financial acceptance; cross-store atomicity/reconciliation becomes difficult | Formal authority model; one linearizable source of truth for identity; transactional commit boundary; reconciliation proof; no dual-write gap; recovery and restore consistency tests |

No product family passes by category name. Qualification is per exact product, edition, version, region, topology, contract and configuration.

## 7. Hard qualification gates

All applicable gates are binary. Failure or missing evidence blocks the candidate; weighted advantages cannot offset it.

| Gate | Pass condition | Required adversarial evidence |
|---|---|---|
| G1 — Legal and residency admissibility | All storage, processing, remote-access, telemetry, backup, key and subprocessor flows fit approved constraints | Data-flow/location inventory plus legal/contract review; test region restrictions and service exceptions |
| G2 — Tenant and security boundary | Tenant isolation, least privilege, encryption, key control, support access and audit requirements are enforceable | Cross-tenant adversarial tests; privileged access review; key rotation/revocation and break-glass evidence |
| G3 — Single authoritative acceptance | Exactly one authoritative identity/acceptance decision; no split brain or stale writer can commit | Network partition, stale primary, delayed process, lease expiry, fencing-token and failover tests |
| G4 — Durability semantics | API success is issued only after the precise documented durable-commit condition; acknowledged event cannot vanish under in-scope failures | Kill primary/standby, network cut, storage crash, forced promotion, commit-ack boundary and WAL/quorum inspection |
| G5 — Atomic financial correctness | Receipt, work item and balanced journal effects satisfy invariant and uniqueness under concurrency, retries and ambiguous commit | Concurrent duplicate submissions, same key/different payload, crash at every commit boundary, UNKNOWN outcome recovery |
| G6 — Recovery and lifecycle | Backup/restore preserves identity, tombstones, journal, revocations and authority epoch consistently; retention/deletion rules are enforceable | Restore into isolated environment; replay old event after restore; PITR, backup expiry, tenant offboarding, key loss/recovery drills |
| G7 — Operational survivability | Named operator capability, patch/upgrade plan, monitoring, paging, documented failover/failback and support escalation exist | Game day with operator not author; restore/failover timed against owner-approved targets; upgrade/rollback drill |
| G8 — Portability and exit | Data, schema, evidence and key dependencies can be exported/recovered; exit obligations are feasible | Full export/restore proof, dependency inventory, deletion certificate path, migration and rollback rehearsal |
| G9 — Performance and economics | Workload-specific SLOs pass under normal, degraded and recovery load; full lifecycle cost fits approved envelope | Reproducible load/soak/failure tests; p50/p95/p99; egress, backup, support, DR and storage-growth cost model |

**Gate ordering:** G1 and G2 are pre-screen gates. G3–G6 are correctness gates. G7–G8 are operational/exit gates. G9 is evaluated only after the others pass. A gate may be marked NOT APPLICABLE only with a written rationale approved by its accountable owner.

## 8. Business Impact Analysis — do not invent RPO/RTO

RPO and RTO must be derived from impact analysis per capability. NIST SP 800-34 frames contingency planning as a process tied to business impact, recovery strategies, plans and exercises; ISO 22301 provides a business-continuity management framework. These are methods, not ready-made numeric targets.

Create separate objectives for:
- authoritative event acceptance;
- commission/ledger availability and read access;
- partner portal/reporting;
- non-authoritative analytics;
- support/chat and notification systems;
- evidence archive and audit export.

For each, document maximum tolerable downtime, maximum tolerable data loss, dependencies, manual workaround, backlog growth, reconciliation window, recovery order, and business owner approval. For the authoritative ledger, “restore service” is insufficient: the business must also approve how accepted events and financial statements are reconciled after recovery.

## 9. Measurement protocol

Do not compare vendor benchmark marketing. Run the same application-level workload and failure schedule against each exact candidate:
- identical event/tenant distributions and payload sizes;
- realistic duplicate/retry rates and hot-key contention;
- same transaction boundary and balanced journal invariant;
- steady, burst, soak and replay-backlog profiles;
- node, zone, region, network, disk and credential failures;
- commit-response loss and UNKNOWN outcome;
- backup restore and failover/failback;
- observed p50/p95/p99 latency, throughput, error rate, backlog age, recovery duration and operator actions;
- full cost model including replicas, network egress, backups, observability, support and DR drills.

Record raw run artifacts, configuration hashes, software versions, topology, seeds, test scripts, clock assumptions, result parser and independent oracle. Repeat runs; publish variance and confidence intervals. Do not collapse correctness and performance into one average score.

## 10. Decision method after constraints are known

1. Complete C-01..C-16 and the data-flow inventory.
2. Obtain legal/contractual approval for each permitted deployment footprint.
3. Remove candidates that cannot be deployed in an admissible region or cannot meet required data-flow restrictions.
4. For remaining candidates, pin exact product, edition, release, topology and configuration.
5. Execute G1–G8 evidence plan; any failed/unknown gate blocks qualification.
6. Run G9 performance/economic comparison only for candidates that pass.
7. Publish a decision record with evidence links, dissent, residual risks, expiry/revalidation trigger and accountable approvals.
8. Requalify after material changes: provider terms, region, service edition, topology, key model, subprocessor, data classes, traffic profile or legal regime.

No numerical weighted score is defined in this dossier. If later used, weights and thresholds must be approved before seeing benchmark results, and hard-gate failures remain disqualifying.

## 11. R1 evidence plan and exit criteria

R1 remains research-only until:
- C-01..C-16 have approved values or justified N/A;
- a complete data-flow/location inventory exists;
- candidate shortlist is limited to products/regions with current official documentation and contractual availability;
- G1–G9 evidence owners and test plans are named;
- unresolved assumptions are visible and have owners/deadlines.

**R1 exit does not authorize R2 runtime harness or R3 production proof.** Separate authorization and A4 gate approvals remain mandatory.

## 12. Current project disposition

- G09-A19: RESEARCH DOSSIER; no deployment decision.
- Candidate families: UNSELECTED / NOT QUALIFIED.
- C-01..C-16: OPEN / OWNER INPUT REQUIRED.
- G1..G9: NOT TESTED / NOT PASSED.
- ADR-002: PROPOSED.
- OD-01..OD-12: OPEN.
- A11-F01..F08: OPEN.
- A12 independent review: NOT PERFORMED.
- R0: BLOCKED; R1: research-only; R2: NOT STARTED; R3: NOT AUTHORIZED.
- A4 gates: NOT APPROVED.
- No provider, country, region, topology, database, numeric RPO/RTO, retention or budget selected.
- No runtime, partner, financial, merge or deployment action authorized.

## 13. References

**Primary product / platform documentation**
- PostgreSQL, High Availability, Load Balancing and Replication: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL, Synchronous Replication and failover: https://www.postgresql.org/docs/current/warm-standby.html
- AWS, Data Privacy FAQ — customer-selected Regions and exceptions: https://aws.amazon.com/compliance/data-privacy-faq/
- Google Cloud, Spanner instance configurations and replica/quorum placement: https://docs.cloud.google.com/spanner/docs/instance-configurations
- Google Cloud, Spanner data residency and geo-partition caveats: https://docs.cloud.google.com/spanner/docs/data-residency
- Google Cloud, Assured Workloads data residency and service-data distinction: https://docs.cloud.google.com/assured-workloads/docs/data-residency
- YugabyteDB, replication and fault tolerance: https://docs.yugabyte.com/stable/architecture/docdb-replication/replication/
- YugabyteDB, multi-region deployment and residency modes: https://docs.yugabyte.com/stable/explore/multi-region-deployments/
- YugabyteDB, production universe planning and topology: https://docs.yugabyte.com/stable/yugabyte-platform/create-deployments/create-universes-overview/
- CockroachDB, developer transaction and retry basics: https://www.cockroachlabs.com/docs/stable/developer-basics.html

**Continuity and assurance methods**
- NIST SP 800-34 Rev. 1, Contingency Planning Guide: https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final
- ISO 22301:2019, Business Continuity Management Systems: https://www.iso.org/standard/75106.html
- Jepsen, distributed-systems correctness analyses: https://jepsen.io/analyses

**Evidence limitation:** provider documentation describes product behavior and stated commitments, not independent qualification of Lottorito's intended deployment. Legal interpretation, contract review, region availability, exact SKU behavior and reproducible tests remain necessary.

**Final disposition:** G09-A19 defines the constraint and qualification process only. No candidate has been selected or qualified.