# Lottorito Architecture Prototype and Evidence Plan

**Document ID:** LOT-PROT-001 | **Version:** 1.0.0 | **Status:** Proposed experiment plan; execution and technology choices not approved

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

### P-02 — Financial transaction and reconciliation

**Question:** Can a concurrent, retried business event produce exactly one valid economic effect and a balanced, immutable journal?

**Minimum fixture:** Synthetic accounts across two tenants and at least two currencies; versioned sample commission inputs; controlled test clock; duplicate source-event deliveries and concurrent workers. No real money or withdrawable balance.

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

**Status reminder:** proposed experiment plan only. No prototype execution or technology approval is claimed.
