# Lottorito Architecture Prototype and Evidence Plan

**Document ID:** LOT-PROT-001 | **Version:** 1.14.0 | **Status:** Proposed experiment plan; execution and technology choices not approved

## 1. Purpose and authority

This plan operationalizes the eight experiments required by LOT-TECH-ADR-001 and maps each to measurable scenarios in LOT-QA-001. It defines what to prove before selecting a stack, database topology, runtime, queue/workflow engine, hosting model or deployment pattern.

This is a plan, not evidence that any prototype has run. No candidate technology is selected or approved here. The owner and relevant domain authorities must approve experiment scope, sensitive-data handling and acceptance exceptions before execution.

## 2. Required inputs and controls

Before an experiment starts:
- Identify the decision it informs, alternatives under test and accountable decision owner.
- Record the exact hypothesis; do not frame a preferred technology as a foregone conclusion.
- Use synthetic fixtures and isolated non-production infrastructure. No live player/customer/agent data, production exports, real funds, production credentials or real partner secrets.
- Document versions, configuration, topology, workload profile, failure injection, test commands and cleanup.
- Define expected behavior and pass/fail rules before running the test.
- Record limitations, assumptions, cost, operator burden and portability—not only whether the happy path worked.
- Do not expose public endpoints or contact a partner/provider as part of a prototype without explicit authorization.

A prototype may be **Pass**, **Fail**, **Inconclusive** or **Not run**. “Pass” means only that the defined experiment passed in its recorded environment; it does not establish production readiness or legal/compliance approval.

## 3. Experiment register

| ID | Prototype | Primary decision informed | Quality attributes |
|---|---|---|---|
| P-01 | Tenant boundary and context propagation | Isolation enforcement across request, database and asynchronous work | QA-01, QA-02, QA-09, QA-12 |
| P-02 | Financial transaction and reconciliation | Transaction boundary, exact amount handling, ledger and concurrency model | QA-03, QA-04, QA-07, QA-12 |
| P-03 | Provider failure and event delivery | Adapter, inbox/outbox, retry, replay and reconciliation design | QA-04, QA-06, QA-07, QA-11 |
| P-04 | Schema evolution and compatibility | Migration approach and application/worker version coexistence | QA-05, QA-14, QA-15 |
| P-05 | Backup, restore and recovery | Backup method, recovery dependencies and operational feasibility | QA-07, QA-08, QA-12 |
| P-06 | End-to-end observability and privacy | Telemetry architecture, correlation and sensitive-data controls | QA-09, QA-10, QA-12 |
| P-07 | Independent product composition | Bounded-context and packaging independence of Affiliate and Lottery | QA-01, QA-02, QA-13, QA-14, QA-15 |
| P-08 | Deployment, health gate and rollback | Artifact promotion, secrets injection, rollout and rollback safety | QA-06, QA-08, QA-09, QA-12, QA-14 |

## 4. Detailed prototype specifications

### P-01 — Tenant boundary and context propagation

**Question:** Can authenticated tenant context be derived, propagated and enforced across every data-access path without trusting caller-supplied tenant identifiers?

**Minimum fixture:** Two synthetic tenants, distinct users and API clients, an operator/support principal with explicitly scoped access, records with identical natural keys in both tenants, and one asynchronous job per tenant.

**Experiments:**
1. Authenticate a user and resolve tenant membership server-side; attempt to override tenant context in request parameters, headers and resource identifiers.
2. Read and mutate records through API and direct application service paths; test cross-tenant object references.
3. Enqueue, retry, schedule and replay jobs; verify tenant context is authenticated, immutable for the job and re-authorized at execution.
4. Exercise database access, cache keys, object storage, search, exports and reporting with colliding IDs.
5. Revoke membership and credentials while sessions/jobs are outstanding; test stale context behavior.
6. Exercise support/break-glass access with explicit reason, scope, expiry and audit trail.

**Pass criteria:**
- All cross-tenant read/write attempts are denied and produce no side effects.
- Tenant context cannot be elevated or switched by untrusted input.
- Every asynchronous and scheduled operation has an attributable tenant and workload identity.
- Revocation and privileged support access follow the documented policy.
- Tests cover each actual storage/cache/search/reporting boundary in the prototype; untested boundaries are recorded as gaps.

**Evidence:** test matrix by boundary, request/job traces, authorization outcomes, database policy evidence where applicable, negative-test output and an explicit list of untested paths.

**Current P-01 experiment note (2026-11-24):** PR #36 passed 20 synthetic integration tests. Follow-on PR #39 adds scoped, time-bound, read-only support grants and append-only audit; its latest observed CI run 45418177150 passed 26 tests on head d2e9fc81a17036e5d6e63c07ee1e64fa055a24eb. This is partial evidence only: support metadata minimization, production identity/MFA, endpoint race/failure stress, credential brokering, cache/storage/search/reporting, load and recovery remain open. No technology or production architecture is approved.

**Current P-01 secondary data-plane experiment (2026-11-24):** a stacked follow-on prototype adds tenant-derived cache keys, tenant-prefixed object keys, server-injected search filters and a separately RLS-protected reporting table. Cache/object/search use in-memory adapters only; provider-specific Redis/S3/OpenSearch/warehouse behavior remains explicitly unverified. The data-plane test suite passed 30 tests in run 45419828256 on code head 02850c6374dd295ec0df6ba42addf266a2d8a977. Provider-specific behavior remains unverified.

**Current P-01 tenant credential/pool experiment (2026-11-24):** a stacked prototype adds trusted server-side tenant credential resolution, coalesced pool creation, explicit global/per-pool connection bounds, lease reservations, idle-only LRU/TTL eviction, revocation-aware draining, idempotent shutdown and a fixed database identity check before pool publication. Synthetic PostgreSQL LOGIN roles prove the identity-bound path: [40 tests passed, 0 failed, 0 skipped](https://github.com/tecpey/lottorito-platform/actions/runs/45424792886) on head `153fc8974c9c620acd8d509afdea0341669e5c`; Documentation Governance also passed [45424793114](https://github.com/tecpey/lottorito-platform/actions/runs/45424793114). Vault/KMS, credential rotation, fleet-wide quotas, PgBouncer, TLS policy, failover and scale remain unverified. No topology is approved.

### P-02 — Financial transaction and reconciliation

**Question:** Can a concurrent, retried business event produce exactly one valid economic effect and a balanced, immutable journal?

**Minimum fixture:** Synthetic accounts across two tenants and at least two currencies; versioned sample commission inputs; controlled test clock; duplicate source-event deliveries and concurrent workers. No real money or withdrawable balance.

**Current P-02 first vertical slice (2026-11-24):** a separate synthetic prototype implements a tenant-bound SECURITY DEFINER posting boundary, immutable journal/line/request/outbox records, exact NUMERIC(38,0) minor-unit amounts, per-currency balance checks, two-level tenant-scoped idempotency (`idempotency_key` for request retries and `effect_id` for the logical financial effect), concurrent duplicate convergence and one-statement transactional outbox. Its tests cover rollback on outbox failure, 38-digit precision, multi-currency balance, tenant account isolation, different request keys for one effect, changed-content rejection and legitimate multiple effects from one source event. The expanded 25-test CI suite passed (0 failed, 0 skipped) in run [45465421133](https://github.com/tecpey/lottorito-platform/actions/runs/45465421133) on head `f4e8551c2297b9a4fd0771f66c3f9e7a91dbe7a0`; Documentation Governance run [45465421155](https://github.com/tecpey/lottorito-platform/actions/runs/45465421155) passed. The final schema separates immutable financial effects from immutable request-key aliases, rejects alias reuse for another effect, and propagates effect identity in the transactional outbox. Commission calculation, reversals, holds/balances and external reconciliation remain unimplemented.


**Experiments:**
1. Post balanced debit/credit entries with exact currency precision; reject invalid scale, currency mismatch and unbalanced journals.
2. Submit the same source event concurrently through multiple workers; vary transaction timing and process termination.
3. Separate source-event identity, economic-effect identity and journal-entry identity; test distinct source events that legitimately map to one or more effects.
4. Attempt to mutate/delete posted entries; verify correction requires linked reversal/adjustment.
5. Derive available/pending/held balances from journal and holds; compare independently computed statements.
6. Simulate partial failure before commit, after commit but before acknowledgement, and during downstream publication.
7. Reconcile source totals, calculation outputs, journal totals and derived balances.

**Pass criteria:**
- Every posted journal balances per currency and is immutable.
- The same economic-effect identity cannot post twice under concurrent or replayed delivery.
- Acknowledged postings survive the tested failure modes; retry returns the original result rather than creating another effect.
- Reversals/adjustments preserve lineage and do not rewrite history.
- Tenant/product/account ownership is enforced; no implicit cross-tenant or cross-product pooling occurs.
- Independent reconciliation detects deliberately injected discrepancies.

**Evidence:** transaction traces, journal fixtures, concurrency/replay test output, invariant checks, reconciliation report and documented isolation level/locking behavior.

### P-03 — Provider failure and event delivery

**Question:** Can the platform tolerate at-least-once, delayed, reordered and malformed provider events without silent loss or duplicate economic effects?

**Minimum fixture:** A local provider simulator with configurable latency, timeouts, rate limits, duplicate callbacks, out-of-order delivery, invalid signatures, schema versions, partial responses and settlement discrepancies.

**Experiments:**
1. Deliver valid, duplicate, delayed and reordered events through the adapter boundary.
2. Fail the process between event receipt, durable inbox persistence, domain processing and acknowledgement.
3. Fail between domain transaction and outbox publication; retry the dispatcher.
4. Simulate provider outage, rate limiting, malformed payload and schema drift.
5. Exercise bounded retries, backoff, circuit breaking, dead-letter inspection and controlled replay.
6. Compare provider statements/results with internal event and financial records; inject mismatches.

**Pass criteria:**
- Acknowledgement occurs only after the event is durably accepted according to the contract.
- Repeated delivery does not create duplicate economic effects.
- Unprocessable events remain visible and recoverable; no silent drop.
- Retry and replay are bounded, observable and safe; poison messages do not block unrelated tenants.
- Provider-specific translation remains inside the adapter; canonical domain events retain source provenance.
- Reconciliation identifies missing, duplicate, late and mismatched records.

**Evidence:** simulator configuration, delivery timeline, inbox/outbox records, retry/dead-letter history, reconciliation exceptions and recovery runbook draft.

### P-04 — Schema evolution and compatibility

**Question:** Can data structures evolve while supported application versions and background workers coexist without data loss or prolonged unsafe locks?

**Minimum fixture:** Synthetic database with representative tenant, event, ledger and reporting data; two application versions and two worker versions.

**Experiments:**
1. Apply an expand/migrate/contract change with old and new application versions running concurrently.
2. Run backfill in resumable batches; interrupt and resume it.
3. Test old/new readers and writers against transitional schema.
4. Exercise index/constraint creation, lock duration and migration failure.
5. Test forward repair and rollback/roll-forward strategy; distinguish reversible code rollback from irreversible data transformation.
6. Verify idempotent migration execution and deployment ordering for workers.

**Pass criteria:**
- No committed business or financial record is lost or silently reinterpreted.
- Supported versions can coexist for the documented compatibility window.
- Backfill is resumable, observable and safe to repeat.
- Constraints are enforced before legacy paths are removed.
- Failure recovery has a documented, tested path; destructive changes require explicit approval.
- Data integrity and tenant ownership invariants pass before and after migration.

**Evidence:** migration scripts, before/after checksums/counts, lock/latency observations, compatibility matrix, interrupted-run recovery and rollback/roll-forward record.

### P-05 — Backup, restore and recovery

**Question:** Can a disposable Lottorito-like PostgreSQL cluster be backed up, verified, restored to a named recovery point, and shown to preserve tenant isolation and financial invariants?

**Decision boundary:** P-05 has three independently accepted slices. P-05A proves physical base backup, WAL archive continuity, PITR, restore verification and synthetic financial reconciliation. P-05B separately tests object-byte recovery, key/configuration recovery and event replay. P-05C separately tests failover, writer fencing, split-brain prevention and failback. Passing P-05A does not imply P-05B or P-05C passed.

**Minimum fixture:** Disposable PostgreSQL 18.7 cluster, two synthetic tenants with distinct login identities, source-event records, balanced journal fixtures, object-reference metadata and a post-restore-point incident marker. No production backup, real funds, live credentials, partner secrets or customer/player data.

**P-05A experiments:**
1. Enable WAL archiving before the base backup; create a physical backup with pg_basebackup and its manifest.
2. Run pg_verifybackup; deliberately tamper with a copy of the manifest and prove verification fails closed.
3. Create a named restore point, commit post-point synthetic financial/event data, force WAL switch and wait for the required segment to be archived.
4. Restore the base backup into a second isolated data directory; configure restore_command, recovery.signal and the named recovery target; promote only after reaching the target.
5. Prove pre-target data exists and post-target data does not; record restore logs and elapsed time.
6. Recompute journal balance, source-event-to-ledger control totals, economic-effect uniqueness and object-reference metadata integrity.
7. Connect using each tenant's distinct database login and prove RLS still prevents cross-tenant reads after restore.
8. Record missing-WAL, invalid-manifest, interrupted-restore and unavailable-archive failures; do not silently skip scenarios.

**P-05A pass criteria:** successful base backup and pg_verifybackup; rejection of the corrupted copy; exact named PITR boundary; restored cluster starts and accepts authenticated connections; zero unbalanced journals, duplicate economic effects, unexplained source-to-ledger differences or broken synthetic object references; zero cross-tenant visibility; required WAL continuity is explicit; exact versions, timings, commands and CI evidence are recorded.

**P-05B (not in this slice):** restore object payloads from an isolated object-store emulator; verify content hashes; recover synthetic envelope/key material using a separate test-only key-encryption hierarchy; replay events with inbox/economic-effect idempotency and provider/source reconciliation. A database object-reference row does not prove object bytes are recoverable. Never put production keys in database backups or CI fixtures.

**P-05C (not in this slice):** simulate primary/standby divergence, promotion, epoch-based writer fencing, stale-primary write rejection, timeline-aware rejoin and failback. pg_rewind is only a candidate: WAL availability, checksum-or-wal_log_hints prerequisites, clean shutdown, post-rewind WAL replay and failure fallback must be tested. A failed rewind may leave the target unusable and require a fresh base backup.

**RPO/RTO authority:** Numeric targets remain TBD in LOT-QA-001 and require owner/domain approval. Report measured RPO, RTO and restore throughput without claiming target compliance. Cloud-provider example targets are not Lottorito commitments.

**Evidence:** backup manifest and verification output, tamper-negative result, archived WAL inventory, restore-point LSN/timeline, restore logs and timing, pre/post-target assertions, tenant-isolation results, journal/reconciliation report, exact versions, runbook and limitations.

**Status:** P-05A positive PITR and negative recovery drills passed in combined synthetic CI on executable-code head `146a9bc635e3b03db568c423fb0958b62bc31c7b`. Integration run [45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) and Documentation Governance run [45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) passed on that head. PostgreSQL 18.7 was used. Before writable assertions, the positive path explicitly waited for `pg_is_in_recovery() = false`; `pg_ctl` readiness alone was not treated as completed recovery. The negative path rejected an incomplete restore staging directory via `pg_verifybackup` and server startup, and removed the exact target WAL segment from isolated copies; recovery startup failed closed before the requested target and the missing segment was identified in the log. P-05B object-byte/key recovery and ordered idempotent replay also passed in the same job. P-05C failover/fencing/failback remains not run. This is not production readiness, an RPO/RTO commitment or technology approval.


### P-05B — Object, key and event recovery

**Question:** After P-05A restores the database, can the platform recover the exact object bytes and the independent key material needed to decrypt them, then replay pending events without losing or duplicating economic effects?

**Synthetic fixture:** A binary object owned by Tenant A, SHA-256 reference stored in the restored database, AES-256-GCM encrypted payload with a random DEK, separately wrapped DEK and a synthetic recovery KEK stored in a separate backup set; tenant-scoped inbox, aggregate sequence cursor and two independent synthetic source events. No cloud, live KMS/HSM, broker, provider, production secret or real data.

**Experiments:**
1. Encrypt the full object payload with AES-256-GCM and AAD bound to tenant/object/version; wrap the DEK with a separate KEK and AAD bound to key/object identity.
2. Back up object bytes/manifest/envelope and synthetic key-recovery material independently; remove active copies; restore both sets and compare full plaintext byte count and SHA-256 to the trusted PostgreSQL object reference.
3. Inject missing-key, modified-ciphertext and modified-wrapped-DEK faults; every path must fail closed. Verify plaintext is absent from the object backup.
4. Deliver aggregate sequence 2 before 1, duplicate sequence 2 and submit a different event ID with a duplicate economic-effect ID. Sequence gaps must block cursor advancement; duplicate identities must collapse.
5. Inject failure after the replay function's writes but before transaction commit; verify journal, lines, inbox status and cursor all roll back. Retry and assert exactly one balanced journal per effect, correct sequence cursor, source-to-ledger reconciliation and no-op subsequent replay.
6. Verify Tenant B cannot read Tenant A object/inbox metadata and cannot write cross-tenant inbox rows.

**Pass criteria:** exact object byte/hash match; missing/corrupt key or object rejected; tenant isolation enforced; duplicate event/economic-effect IDs deduplicated; no sequence-gap advancement; interrupted replay fully rolled back; retry yields exactly two effects and no duplicates; journals balance; source and ledger control totals reconcile; second replay is a no-op.

**Key custody limitation:** The raw KEK file is synthetic CI-only recovery material. It is not a production KMS/HSM design, exportable root-key recommendation, split-knowledge process, key ceremony or authorization model. AES-GCM is an experiment primitive, not a selected platform standard.

**Not proven:** KMS/HSM outage/rotation/revocation/compromise, IAM and dual control, immutable/versioned object retention, legal hold, multipart/large objects, regional replication, external broker durability, provider reconciliation, cross-service saga, high concurrency, production throughput, RPO/RTO or compliance. P-05A missing-WAL and incomplete-restore negative drills passed only in the synthetic CI fixture; production restore orchestration and recovery acceptance controls remain unproven. The positive path now gates writable checks on `pg_is_in_recovery() = false`. P-05C failover/fencing/failback is separate.

**References:** AWS S3 checksum validation; Google Cloud Storage data validation/versioning; NIST SP 800-57 Part 1 Rev. 5 (Rev. 6 remains a draft); AWS transactional outbox and at-least-once event processing guidance.

**Status:** P-05B synthetic CI passed on validated branch head e4820884194ecf1ab3acd539d77145904f14ab73. Combined P-05A/P-05B Pull-request Integration [45526975173](https://github.com/tecpey/lottorito-platform/actions/runs/45526975173) and Documentation Governance [45526975222](https://github.com/tecpey/lottorito-platform/actions/runs/45526975222) passed. The restored 4,409-byte object matched its database SHA-256 reference; missing/corrupt key and object cases failed closed; duplicate/out-of-order replay, transaction interruption/retry, ledger reconciliation and tenant isolation assertions passed. No technology, vendor, production readiness, RPO/RTO or release approval is implied.

### P-05C — Failover, writer fencing and failback

**Question:** Can the recovery prototype demonstrate a controlled primary-to-standby promotion, reject stale writers, preserve a single writable node, rewind the former primary and complete a controlled failback?

**Synthetic topology:** Two independent PostgreSQL 18.7 clusters in one disposable container; physical streaming replication; data checksums and wal_log_hints; a database-local writer epoch/lease row; no external DCS, consensus cluster, watchdog, cloud instance or production infrastructure.

**Experiments:**
1. Seed a baseline event and prove streaming standby recovery.
2. Require a local promotion gate to refuse while the former primary process is still alive. Stop the standby, commit a deliberately unreplicated synthetic tail on the old primary, then stop the old primary before promotion.
3. Start and promote the standby; increment epoch 1 → 2. Reject stale writer identity/epoch and expired lease.
4. Race two promotion claimants against expected epoch 2; one atomic compare-and-swap must win epoch 3, the other must receive no token.
5. Rewind the stopped former primary with pg_rewind, rejoin it as a read-only standby, and verify the promoted event exists while the intentionally unreplicated old-primary tail is absent.
6. Wait for replay, perform a controlled switchover back to the original node, increment epoch 3 → 4, write a failback marker, rewind the other node and rejoin it as standby.
7. Assert one writable primary, one read-only standby and consistent epoch/active-writer state after failback.

**Pass criteria:** promotion refused while old primary is alive; old process stopped before promotion; standby promotion succeeds; stale token and expired lease fail closed; exactly one concurrent epoch claimant wins; pg_rewind rejoin succeeds; divergent unreplicated tail is absent; former primary is read-only after rejoin; controlled failback and second rewind succeed; final topology has exactly one writer.

**Critical limitations:** The process stop is a local CI fence simulation, not STONITH, host/storage fencing or watchdog. The writer-epoch row is replicated application data, not an independent quorum-backed DCS; it cannot stop a partitioned old primary from accepting local writes. The experiment intentionally loses one committed-but-unreplicated synthetic event to expose asynchronous replication's data-loss window. It does not test a real network partition, quorum loss, simultaneous live primaries, DCS outage, watchdog failure, regional failover, production traffic, RPO or RTO.

**References:** PostgreSQL 18 failover, hot standby and pg_rewind; Patroni lease/watchdog guidance; etcd atomic transactions, leases and linearizability.

**Status:** Implementation is on P-05C PR #54, stacked on P-05B PR #53. CI validation is pending. No HA technology, vendor, topology, RPO/RTO or production readiness is approved.

### P-06 — End-to-end observability and privacy

**Question:** Can operators trace a synthetic partner event through attribution, commission decision and journal reference while preventing secrets and unnecessary personal/financial data from entering telemetry?

**Minimum fixture:** Synthetic event and tenant identities, generated credentials, fake personal data and controlled secret canaries.

**Experiments:**
1. Trace ingress through validation, inbox, domain processing, outbox, worker and ledger reference.
2. Correlate request, actor, tenant, product, source event, economic effect and journal entry.
3. Inspect logs, traces, metrics, exceptions, dashboards and alert payloads for canary secrets and sensitive fields.
4. Test high-cardinality identifiers and tenant/customer labels in metrics.
5. Trigger authorization denial, provider outage, queue backlog, reconciliation drift and ledger invariant violation.
6. Verify privileged audit events and access to telemetry.

**Pass criteria:**
- Critical journey can be reconstructed from authorized telemetry without treating logs as the ledger.
- Correlation is consistent across synchronous and asynchronous boundaries.
- Secret canaries and prohibited fields do not appear in telemetry.
- Metrics avoid unbounded tenant/customer cardinality; detailed identifiers remain access-controlled.
- Alerts have an owner, severity, actionable runbook and bounded noise.
- Telemetry access and privileged actions are auditable.

**Evidence:** redacted trace, metric/label inventory, log-field policy, secret-canary scan, alert/runbook mapping and access audit.

### P-07 — Independent product composition

**Question:** Can Affiliate & Agent and Lottery be built, configured, deployed and operated independently while sharing only explicitly owned platform capabilities?

**Minimum fixture:** Synthetic product configurations, independent tenant/product entitlements, domain events and mock adapters; no live Lottery provider or real partner.

**Experiments:**
1. Build and run Affiliate-only composition without Lottery runtime dependency.
2. Build and run Lottery-only composition without Affiliate runtime dependency.
3. Disable one product and verify the other retains its declared critical journeys.
4. Test identity, tenant, finance, notifications and audit as shared capabilities with explicit ownership and authorization boundaries.
5. Attempt cross-product data access and event consumption without an explicit contract/entitlement.
6. Compare migrations, configuration, deployment artifacts and support operations for accidental coupling.

**Pass criteria:**
- Each product's declared core journey works without installing or enabling the other product.
- Shared capabilities have explicit interfaces, ownership, permissions and lifecycle.
- Cross-product access is denied by default and enabled only through an explicit contract.
- Product-specific migrations/configuration do not require unrelated product activation.
- Disabling one product does not corrupt the other's data or operations.
- White-label presentation does not remove Lottorito ownership, audit or technical traceability.

**Evidence:** separate build/run records, dependency graph, configuration matrix, negative authorization tests, migration inventory and independent-product operational checklist.

### P-08 — Deployment, health gate and rollback

**Question:** Can an immutable artifact be promoted safely with controlled secrets injection, health verification and a tested rollback/roll-forward path?

**Minimum fixture:** Non-production environments, synthetic data, generated secrets, immutable build artifact and at least two application versions.

**Experiments:**
1. Build once and promote the same artifact digest across test/staging-like environments.
2. Inject secrets at runtime and scan artifacts, logs and build metadata for leakage.
3. Exercise readiness/liveness and dependency health gates before traffic or worker activation.
4. Simulate failed rollout, unhealthy worker, incompatible migration and partial deployment.
5. Roll back application code while preserving compatible data; exercise forward repair where rollback is unsafe.
6. Verify deployment audit, approvals, artifact provenance and separation of duties.

**Pass criteria:**
- The promoted artifact is immutable and its digest is traceable.
- No credential appears in source, artifact, image metadata, logs or test output.
- Traffic/worker activation is blocked when critical health gates fail.
- Rollback/forward procedures are tested and do not corrupt financial or tenant state.
- Deployment is attributable and auditable; production promotion remains approval-gated.
- No public exposure or production deployment is part of this experiment.

**Evidence:** artifact digest, deployment manifest, secret scan, health-check timeline, failure/rollback transcript, audit record and operator runbook.

## 5. Cross-prototype acceptance rules

All prototypes must:
- Use isolated synthetic data and non-production credentials.
- Test both expected and adversarial/failure paths.
- Record reproducible commands, configuration and exact software versions.
- Include at least one negative test for authorization, integrity or safe failure.
- Report limitations and untested boundaries explicitly.
- Avoid converting a prototype outcome into an owner decision without an ADR update.

A prototype is **Pass** only if all mandatory criteria for its stated scope pass. Partial success is **Inconclusive** or **Fail**, not “mostly production-ready.” Any exception needs an accountable owner, compensating control, expiry date and recorded decision.

## 6. Execution order and dependencies

1. P-01 tenant boundary: establish context and isolation assumptions before shared data paths.
2. P-02 financial transaction: establish posting invariants and idempotency identity.
3. P-03 provider/event delivery: build on the event and financial invariants.
4. P-04 schema evolution: exercise representative domain, event and ledger structures.
5. P-05 recovery: restore the stateful foundations and reconcile.
6. P-06 observability/privacy: instrument and verify the critical paths and failure cases.
7. P-07 independent product composition: verify bounded-context and packaging independence.
8. P-08 deployment/rollback: promote and recover the selected candidate architecture safely.

The sequence may be adjusted when dependencies require it, but every prototype remains required unless the owner records an explicit waiver.

## 7. Experiment report template

For each P-0x record:
- Decision and accountable owner:
- Hypothesis and alternatives:
- Candidate/version/configuration:
- Environment and topology:
- Synthetic data profile:
- Scenario IDs (LOT-QA-001):
- Commands and procedure:
- Expected result and pre-agreed threshold:
- Actual result and raw evidence links:
- Pass / Fail / Inconclusive / Not run:
- Failure modes and limitations:
- Cost and operational burden:
- Security/privacy/legal implications:
- Recommendation and confidence:
- Decision required / ADR update:
- Reviewer, date and expiry of any exception:

## 8. Completion gate

The prototype phase is complete only when all eight experiments have reproducible reports, mandatory invariants pass or have explicit owner-approved exceptions, risks and trade-offs are recorded, and the relevant technology ADRs are updated with evidence. This does not itself approve a technology stack, production readiness, market activation, merge or deployment.

## 9. Related documents

- LOT-QA-001 — architecture quality attributes and release gates.
- LOT-TECH-ADR-001 — technology, deployment and reliability decision framework.
- LOT-TEN-001 — tenant isolation model.
- LOT-FIN-POST-001 — financial posting and reconciliation.
- LOT-SEC-TM-001 — threat model.
- LOT-EVENT-001 — canonical event contract.
- LOT-OPS-001 — verified project status.

**Status reminder:** the plan remains proposed. The partial P-01 HTTP/PostgreSQL RLS slice on PR #36 passed 20 defined CI tests in run [45412556456](https://github.com/tecpey/lottorito-platform/actions/runs/45412556456) on code head `f53caa4e801c9eeed94dfe706e03c6dfcf02a660`, using the committed npm lockfile and SHA-pinned GitHub Actions. It covers tenant-scoped async jobs, atomic outbox/dispatch writes, concurrent dispatcher claims, Ed25519 envelopes, worker-side membership re-authorization and a comparative per-tenant LOGIN-role/session_user RLS model across records, membership and jobs, including SECURITY DEFINER owner/search_path and temporary-schema shadowing checks, plus deterministic two-connection proof that membership revocation waits behind an in-flight `FOR SHARE` transaction. This does not pass the full P-01 experiment: secure credential brokering, pool scaling, cache/object storage/search/reporting, support/break-glass, load and recovery remain untested. The shared-role custom-GUC trust limitation is explicitly demonstrated. No technology approval is claimed.


**Current P-04 experiment (2026-11-24):** Draft PR #51 on branch spike/p04-schema-evolution, based on P-03 head 45b37700cb2b9ad633158ba8d5f00b8c7f0553d5. The synthetic PostgreSQL candidate covers v1/v2 writer compatibility, additive expand, tenant-scoped resumable backfill, migration checksum/idempotency, lock-timeout failure, invalid concurrent-index recovery, staged constraint validation and a non-destructive contract rehearsal. Integration run 45471750215 passed 7 tests on head 15c536e5be2f61b1805191f5977a46b17eaf1971 and Documentation Governance run 45471750133 passed on the same head. This remains a synthetic experiment; no production migration, zero-downtime claim or technology approval is implied.
