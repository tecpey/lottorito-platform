# Lottorito Architecture Prototype and Evidence Plan

**Document ID:** LOT-PROT-001 | **Version:** 1.6.0 | **Status:** Proposed experiment plan; execution and technology choices not approved

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

**Question:** Can critical data and required dependencies be restored to a usable, internally consistent state within owner-approved recovery objectives?

**Minimum fixture:** Isolated environment with synthetic database records, event history, ledger, object references, configuration and non-production keys. No production backup or secret.

**Experiments:**
1. Create encrypted backup and restore into a clean isolated environment.
2. Exercise point-in-time recovery if the candidate supports it.
3. Restore required object data and key material using the approved test-key process.
4. Simulate database, worker and dependency interruption; establish recovery order.
5. Replay events received during the outage and reconcile provider/source totals to restored state.
6. Test failback and prevent split-brain writers during recovery.

**Pass criteria:**
- Restore is reproducible and produces integrity-checked data.
- Tenant boundaries, journal balance, event uniqueness and object references remain valid.
- Required keys/configuration can be recovered without exposing secrets.
- Recovery steps, dependencies, roles and decision points are documented.
- Measured recovery results are recorded against approved RPO/RTO; if targets are not approved, report measurements without claiming target compliance.
- Backup existence alone is never treated as proof of recoverability.

**Evidence:** timed exercise log, restore manifest, integrity/reconciliation reports, key-recovery evidence, runbook and observed data-loss/downtime window.

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


## P-03 evidence reconciliation and P-03D continuation — 2026-11-25

- PR #41 is the earlier provider-event inbox/outbound-delivery fixture. Its reported 22 tests passed, but it is based on the older P-02 branch head `90cc45464c25c325befd35bd7af1c8a16c1f78d3` and uses a shared custom-GUC tenant/product context. It is not a compatible implementation base for the current per-tenant database-session identity model.
- PR #50 is the current tenant-scoped outbound relay on P-02 head `76d1f421ecdf8e921c7e8a116e2c23dcdaef4b7b`; its Integration run [45469172124](https://github.com/tecpey/lottorito-platform/actions/runs/45469172124) passed 10 tests.
- PR #60, LOT-PROT-P03C-001, connects the immutable P-02 ledger outbox to P-03 delivery state. Its Integration run [45576594884](https://github.com/tecpey/lottorito-platform/actions/runs/45576594884) passed 15 tests; Documentation Governance [45576594868](https://github.com/tecpey/lottorito-platform/actions/runs/45576594868) passed. It remains Draft/unmerged.
- P-03C and P-03D now verify the synthetic outbound and inbound bridge: P-03C links the immutable P-02 outbox to delivery state, and P-03D connects signed provider inbox acceptance to atomic P-02 posting and P-03C delivery state. This closes the current synthetic provider-to-ledger integration slice; it does not complete every P-03 platform requirement or production provider integration.
- **P-03D synthetic acceptance completed:** the required controls are exercised by the combined P-03C/P-03D suite: raw-body signature and timestamp/replay checks, trusted installation/database scope, durable inbox acceptance, duplicate/conflict handling, trusted mapping, atomic posting/outbox/delivery state, retry/dead-letter/quarantine, lease fencing, product isolation and reconciliation. See LOT-PROT-P03D-001 for exact run evidence and limitations.
- P-03D branch `spike/p03d-provider-ledger-integration` is based on P-03C head `32b34f4c7c67b12874cdf6a14a2788d9a2f4c6dc`. CI passed on exact head `40d002a2af5875a6ead178604b90dc92aa678dc5`: P-02 25/25, P-03C 15/15, P-03D 19/19, and Documentation Governance passed (runs 45607187120, 45607186885 and 45607186745). Tenant-wide uniqueness constraints remain conservative pending key-model review.
**Next sequencing gate:** PR #51 (P-04) is a sibling of PR #60 (P-03C) on the P-03 base, not a descendant. Before treating P-04–P-08 as a coherent stack, reconcile their base/head ancestry against P-03C, inspect diffs for duplicated or incompatible schema changes, and run the complete P-02/P-03C/P-04–P-08 regression chain on the reconciled head. Keep PRs Draft/open; no merge or deployment is authorized.
- No provider, broker, transport, accounting rule, commission/NGR formula, legal entity, production schema, technology stack, merge or deployment is approved by these synthetic experiments.



## P-04 continuation on the reconciled P-03D stack — 2026-11-25

- Original P-04 PR #51 (branch spike/p04-schema-evolution) was built on P-03 PR #50 head 45b37700cb2b9ad633158ba8d5f00b8c7f0553d5, the same parent as P-03C PR #60. It is therefore a sibling, not a descendant of P-03C/P-03D.
- A clean continuation branch spike/p04-schema-evolution-p03d has been created from P-03D PR #61's latest docs-synchronized head 11f2069b537d4cf74175fd7b628a331650c45f52. The P-04-only prototype files and bilingual report have been carried forward; shared docs were merged semantically rather than overwritten from the older branch.
- The original P-04 integration evidence is run [45471750215](https://github.com/tecpey/lottorito-platform/actions/runs/45471750215): 7 tests passed on original code head 15c536e5be2f61b1805191f5977a46b17eaf1971; Documentation Governance [45471750133](https://github.com/tecpey/lottorito-platform/actions/runs/45471750133) passed. This is historical evidence for the original P-04 branch only.
- **Revalidation passed:** on reconciled PR #62 code head `dca0762678ed45da122ba109276c54ce61ac0846`, P-02 run [45608274029](https://github.com/tecpey/lottorito-platform/actions/runs/45608274029) passed 25 tests, P-03C/P-03D run [45608274098](https://github.com/tecpey/lottorito-platform/actions/runs/45608274098) passed 15 + 19 tests, P-04 run [45608274118](https://github.com/tecpey/lottorito-platform/actions/runs/45608274118) passed 7 tests, and Documentation Governance [45608274060](https://github.com/tecpey/lottorito-platform/actions/runs/45608274060) passed. All had zero failures and zero skips. The P-04 experiment remains isolated and synthetic; it does not modify the P-02/P-03 schemas.
- Do not retarget or merge original PR #51. Keep it as historical review context. Replacement PR #62 targets P-03D PR #61 and remains Draft/open pending review; PR #51 remains open/Draft and untouched.
- P-04 is now verified in the reconciled synthetic stack. Next: replay/rebase P-05A, P-05B, P-05C, P-06, P-07A, P-07B, P-07C and P-08 in dependency order, preserving each experiment's boundaries and re-running the full regression chain. No destructive migrations, merges, main updates or deployments are authorized.


## P-05A on reconciled P-03D/P-04 stack — 2026-11-25

- Original P-05A PR #52 was stacked on original P-04 PR #51, whose parent was the old P-03 base. It therefore inherited the missing P-03C/P-03D ancestry.
- Replacement branch `spike/p05-backup-restore-recovery-p03d` starts from reconciled P-04 PR #62 head `1013f3b93b55b2cb0859b371db58e1e17ec4ad5e`. It carries the P-05A-specific recovery workflow, disposable PostgreSQL Docker fixture, setup SQL, recovery script and bilingual report.
- Original P-05A evidence: run [45524797849](https://github.com/tecpey/lottorito-platform/actions/runs/45524797849) passed; Documentation Governance [45524797818](https://github.com/tecpey/lottorito-platform/actions/runs/45524797818) passed. This remains historical evidence for original PR #52 only.
- Revalidate the replacement on one exact head: P-02, P-03C/P-03D, P-04, P-05A and bilingual Documentation Governance. Preserve the limits in LOT-PROT-P05A-001: no off-site/immutable retention, key custody, object-byte recovery, missing-WAL/interrupted-restore negative drills, application/worker recovery, provider reconciliation, regional failover, RPO/RTO approval or production readiness.
- Original PR #52 remains open/Draft and untouched. Replacement PR #63 will stack on PR #62 and remain Draft until full regression passes. No merge, main update, destructive operation or deployment.


## P-05A verified on reconciled stack — 2026-11-25

- Replacement PR #63 branch spike/p05-backup-restore-recovery-p03d is based on reconciled P-04 PR #62 head 1013f3b93b55b2cb0859b371db58e1e17ec4ad5e. Original PR #52 remains open/Draft as historical context.
- Exact tested code head 76650b0c799e2f2a5b2f3ae4831bb55d3a3811a6 passed P-02 25, P-03C 15, P-03D 19, P-04 7, P-05A recovery P05A_RESULT=PASS and Documentation Governance. Runs: 45609220358, 45609220468, 45609220377, 45609220359 and 45609220328. All workflows succeeded; automated suite count 66, zero failures/skips.
- P-05A is synthetic only. Missing-WAL/interrupted-restore negative drills, off-site immutable retention, key custody, object-byte recovery, app/worker recovery, provider reconciliation, regional recovery and RPO/RTO approval remain open.
- Next: P-05B object/key/idempotent-event recovery. Replay it onto PR #63 in a new branch and run the complete P-02/P-03C/P-03D/P-04/P-05A/P-05B regression chain. Keep original PR #52 open/Draft and do not merge or deploy.


## P-05B on reconciled P-05A/P-04 stack — 2026-11-25

- Original P-05B PR #53 is stacked on original P-05A PR #52, which descends from the original P-04 branch and omits reconciled P-03C/P-03D ancestry.
- Replacement branch `spike/p05b-object-key-event-recovery-p03d` starts from P-05A PR #63's docs-synchronized head `481a0ab2ac15ee982745e0a3b48d4d93cc829431`. It carries P-05A recovery-complete readiness and missing-WAL/incomplete-restore negative drills, plus P-05B object/key/event recovery.
- Additional hardening: manifest context validation; tenant/key/object-bound AES-GCM envelope AAD; strict base64 and nonce checks; plaintext size/hash verification against the manifest and database; unique aggregate sequence; deterministic locked event selection; SECURITY DEFINER search_path with pg_temp last.
- Original PR #53 combined workflow [45533100486](https://github.com/tecpey/lottorito-platform/actions/runs/45533100486) and Documentation Governance [45533100369](https://github.com/tecpey/lottorito-platform/actions/runs/45533100369) passed, including P05A positive/negative drills, P05B object/key recovery and event replay. Historical evidence only.
- Re-run the combined P-05 workflow and P-02/P-03C/P-03D/P-04 regression plus bilingual Documentation Governance on the replacement PR head. Do not mark P-05B verified until all pass on the exact final head.
- No real KMS/HSM, object store, broker, provider, key custody, production data, RPO/RTO or production recovery decision is approved. P-05C failover/fencing/failback remains a separate next experiment.


## P-05B verified on reconciled stack — 2026-11-25

- PR #64 head bbad5969fc3c952ebafdaed3c8d2306dbd018ad4 passed P-02 25, P-03C 15, P-03D 19, P-04 7, combined P-05A/P-05B positive and negative recovery, and Documentation Governance. Runs: 45611209596, 45611209613, 45611209559, 45611209642 and 45611209546.
- P-05B hardening covers strict manifest context, tenant-bound wrapped-DEK AAD, nonce/base64/size checks, plaintext size/hash, unique aggregate sequence and deterministic locked event processing. P-05A negative recovery checks pass.
- P-05B remains synthetic only. Next experiment: P-05C failover/fencing/failback, with explicit lease/fencing safety, promotion readiness and financial consistency; RPO/RTO remain TBD. Original PR #53 stays open/Draft as historical review context; PR #64 remains Draft/open. No merge or deployment.


## P-05C on reconciled P-05B stack — 2026-11-25

- Original PR #54 was based on original P-05B PR #53. Replacement branch spike/p05c-failover-fencing-failback-p03d is based on reconciled P-05B PR #64 head eff4176b4d2ea0c25591c76173c3ec28753e1dc8.
- Original P-05C run [45534242728](https://github.com/tecpey/lottorito-platform/actions/runs/45534242728), combined P-05A/B run [45534242739](https://github.com/tecpey/lottorito-platform/actions/runs/45534242739), and Documentation Governance [45534242653](https://github.com/tecpey/lottorito-platform/actions/runs/45534242653) passed on the original branch; historical only.
- Revalidate P-05C plus P-02/P-03C/P-03D/P-04/P-05A/P-05B and bilingual Documentation Governance on the replacement PR head. P-05C remains synthetic-only; no real STONITH, quorum/DCS, watchdog, cloud failover, production fencing, RPO/RTO or HA design is approved.
