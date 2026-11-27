# Affiliate G09-A8 — Independent Verification & Adversarial Challenge

**Document ID:** LOT-AFFILIATE-G09-A8-001  
**Version:** 0.1.0  
**Status:** Self-review / adversarial design challenge; NOT an independent approval; no runtime execution  
**Date:** 2026-11-27  
**Scope:** G09-A4, G09-A5 and G09-A7 on the reviewed PR #76 head `aa9573f90eb5283409d20d33a3b963078ed93f7f`.

## 1. Executive disposition

This review challenges the design artifacts, not a running system. It finds that A4/A5/A7 provide a useful and unusually explicit proof blueprint, but they do **not** yet establish runtime safety, independent verification, production readiness or authorization to implement/execute the harness.

**Disposition: DESIGN REVIEW — CONDITIONAL; MATERIAL OPEN FINDINGS.** The authoring/review pass is performed in the same assistant workflow and is therefore a self-review. It must not be represented as an independent reviewer sign-off. A qualified reviewer who did not author A4/A5/A7/A8 must repeat and disposition the findings.

The 47-case traceability is structurally useful, but case-to-oracle mapping alone does not prove oracle independence or complete fault coverage. Several critical behaviors need stronger temporal, privilege, network, evidence and lifecycle assertions before runtime design can be accepted.

No A4 gate is waived. All eight gates remain mandatory. No runtime, harness, database, queue, IAM provider, schema, partner adapter, external sandbox, financial operation, merge or deployment is authorized by this document.

## 2. Review method and limits

Reviewed the bilingual A4, A5 and A7 artifacts and their governance references on the exact PR head stated above. Challenged:
- each oracle's independence from the system under test (SUT);
- temporal correctness of claim, lease, fencing, acknowledgement and lifecycle races;
- direct and indirect financial-domain reachability;
- tenant/installation authority across ingress, durable state and workers;
- failure schedules, case overlap and untested interleavings;
- evidence provenance, clock integrity, tamper evidence, retention and deletion;
- bilingual parity and governance traceability.

This is a document review only. No source runtime, infrastructure, database, queue, identity provider, deployment configuration, IAM policy, network policy, secrets store or test harness was inspected or executed. Conclusions are design findings, not empirical observations about deployed controls.

## 3. Critical design findings

| ID | Severity | Finding | Required closure evidence |
|---|---|---|---|
| A8-F01 | Critical | **Lease expiry is not yet a complete fencing condition.** A5 requires claim generation/token on transitions, but its text does not consistently require the lease still be valid at the exact mutation/commit point. A worker could resume after expiry and complete before another worker increments the generation. | Specify and test a database-authoritative conditional transition requiring expected state, owner, generation/token and unexpired lease at mutation time; define transaction/clock semantics. Include completion, heartbeat, retry and error paths. |
| A8-F02 | Critical | **Fencing only the WorkItem row does not fence external side effects.** A stale worker might perform a side effect before its fenced completion update. The current proof scope prohibits financial effects, but future extensibility must not mistake row fencing for end-to-end effect fencing. | Keep this runtime vertical slice side-effect-free beyond its own durable state. For any future downstream effect, require recipient-enforced idempotency/fencing or a separately authorized transactional command and effect identity. Prove no external side-effect capability in this scope. |
| A8-F03 | Critical | **Financial non-reachability is described but not yet a complete capability proof.** A DB role/network sentinel alone can miss indirect paths through shared service credentials, service mesh, internal APIs, workload identity, cloud metadata, mounted secrets, dynamic configuration, DNS, inherited environment or privileged control planes. | Produce a complete capability inventory for ingress and worker identities: grants, schemas, credentials, secret mounts, workload identity, routes, DNS/egress, service discovery, internal APIs and runtime configuration. Deny by default at multiple layers; independently inspect effective permissions and attempt prohibited paths. |
| A8-F04 | High | **Tenant lifecycle race needs a linearization rule.** “Re-check current state” is insufficient if suspension/revocation commits between the worker's check and its state transition. | Owner-approved lifecycle policy must define the authoritative ordering point and whether acceptance authority is durable or current status wins. Test barriers on both sides of the linearization point; ensure check and protected transition are atomic or version-conditioned. |
| A8-F05 | High | **Oracle independence is not operationally specified.** O-DB, O-WRK, O-FIN and telemetry checks can become correlated if they read SUT-generated logs, use the same service identity, share mutable code, or query through the same application path. | For every oracle, document operator/identity, data source, code path, trust boundary, read-only status, failure modes and independence rationale. At least one persistence observer and one permission/network observer must be independently provisioned and unable to mutate SUT state. |
| A8-F06 | High | **Claim-generation monotonicity and token lifecycle need formal bounds.** “Monotonic” does not define integer width, overflow behavior, reset/restore behavior, tenant/job reuse, token uniqueness or backup rollback implications. | Define generation domain and non-reuse rule; fail closed before overflow; prohibit reset/recycling for an identity; bind token to immutable job identity and generation. Test restore/rollback and identifier reuse. |
| A8-F07 | High | **Commit ambiguity and retry reconciliation need a complete state table.** A5 correctly rejects blind retry after unknown commit outcome, but the reconciliation read's authority, consistency and outcomes (committed pair, absent pair, partial/corrupt state, conflicting fingerprint, unavailable DB) need explicit treatment. | Add decision table. Reconcile using the authoritative unique identity and primary/consistency-guaranteed read; never infer absence from a stale replica. Partial pair is an invariant breach/stop, not a normal retry. |
| A8-F08 | High | **Evidence integrity and time provenance are underspecified.** Digests detect change only relative to a trusted digest; they do not establish who produced an artifact, when, with which clock, or prevent replacement of both artifact and manifest. | Define signed or independently anchored manifest, signer identity/key custody, trusted timestamp/clock source, monotonic sequence, artifact chain, access audit, reviewer signature and preservation of failed-run evidence. Keep secrets/raw payloads out. |
| A8-F09 | High | **Retention/deletion and audit preservation can conflict.** “Retention-bounded” evidence and deletion/backup testing are not enough to decide what must be deleted, what may be retained as minimal proof, and how legal holds or backup expiry work. | Approve a data lifecycle policy before A4-GATE-05: data classes, purpose, access, retention trigger, deletion propagation, backup expiry, legal hold, evidence minimization and verifiable deletion semantics. No duration is assumed here. |
| A8-F10 | Medium | **Case overlap can conceal missing interleavings.** A4-DUR-02/03/04/05/06 and A7 schedules cover important failures, but they do not explicitly enumerate lease-expired-before-reclaim completion, heartbeat racing with reclaim, cancellation/revocation racing with commit, or restore while old workers remain alive. | Extend schedules with these interleavings and preserve stable A4 IDs; add subcase IDs rather than renumbering. Each subcase needs a distinct expected state and oracle result. |
| A8-F11 | Medium | **Resource controls need multi-dimensional fairness and amplification coverage.** The catalogue covers size, bursts, pools and retries, but not the combined cost of decompression, parse, schema validation, logging, retries and tenant contention, nor queue-age starvation. | Define measured cost dimensions and per-tenant/global budgets at A4-GATE-06; test adversarial amplification and noisy-neighbor fairness with external workload telemetry. Do not choose numeric ceilings in this review. |
| A8-F12 | Medium | **Bilingual and governance checks are structural, not semantic proof.** Matching IDs/order and successful documentation CI cannot prove that FA and EN preserve identical normative meaning, severity, status or stop conditions. | Require bilingual reviewer sign-off against a clause-level parity checklist and verify README, status, decision register and PR evidence point to the same version/head. |

## 4. Oracle independence contract

A7 names O-API, O-DB, O-TX, O-IAM, O-WRK, O-NET, O-FIN, O-OBS, O-LOAD, O-DATA and O-SCHEMA. These are useful categories, not yet evidence of independence.

Before execution, create an oracle register with these mandatory columns:
1. oracle ID and exact assertion;
2. source of truth and collection mechanism;
3. execution identity and effective permissions;
4. whether its implementation/code is shared with the SUT;
5. whether it is read-only and how that is enforced;
6. independent reviewer/operator;
7. failure modes and blind spots;
8. evidence artifact, digest, provenance and timestamp source;
9. expected result for each applicable case/subcase.

Minimum independence rules:
- O-API may observe client-visible behavior but cannot prove persistence.
- O-DB must use a separately provisioned read-only identity and direct authoritative persistence inspection, not the SUT's repository/service layer.
- O-TX must rely on database-native constraint/transaction/lock evidence, not application log claims alone.
- O-WRK must compare durable row state and claim history with an independently collected worker/process timeline.
- O-NET must observe enforcement points outside the SUT process (egress policy, DNS and connection telemetry).
- O-FIN must combine effective DB grants, secret/workload identity inventory, route/service discovery policy and prohibited-call sentinels; a single “no call observed” metric is insufficient.
- O-OBS must scan independent sinks and artifacts for canaries; a logger's own redaction assertion is not enough.
- O-DATA must verify deletion/access outcomes across primary data, replicas, backups and evidence stores under the approved policy.

No oracle may write to the SUT while observing it. An oracle failure or unavailable observation is **INCONCLUSIVE**, never PASS.

## 5. Required temporal protocol clarifications

### 5.1 Worker claim and lease

The authoritative transition must be conditional at the database mutation point on all of:
- immutable WorkItem identity and tenant/install binding;
- expected current state;
- current claim generation and token;
- expected owner identity;
- lease validity according to one approved authoritative clock;
- lifecycle/version precondition where policy requires it.

A generation mismatch, expired lease, changed owner, changed state or failed lifecycle version condition must yield zero protected-row changes. Define whether a heartbeat can extend a lease after expiry (recommended fail closed) and whether a heartbeat racing with a reclaim is serialized by the same atomic protocol.

Use a database-authoritative time source for lease decisions unless a reviewed alternative proves equivalent semantics. Define clock behavior across failover/restore. Never rely on a worker's local wall clock as the sole authority.

Generation must not wrap, reset or be reused. If the generation space is exhausted or state is ambiguous, stop/park for operator resolution; do not silently recycle.

### 5.2 Unknown commit outcome

For an ingress transaction whose commit acknowledgement is lost:
1. Do not issue an unconditional new insert or infer rollback.
2. Reconcile against the authoritative persistence source using the complete approved event identity.
3. If exactly one valid Receipt+WorkItem pair exists and fingerprint/provenance match, return the stable accepted/replay result.
4. If neither exists, retry only after the read's consistency guarantee establishes absence and the original transaction can no longer commit.
5. If one row exists without its mandatory pair, more than one row exists, identity/fingerprint conflicts, or state cannot be established, stop and raise an invariant incident.
6. If the authoritative store is unavailable or only a stale replica is available, return an indeterminate/retryable outcome without claiming acceptance.

### 5.3 Lifecycle linearization

The owner must decide whether a durable receipt accepted while an installation was active remains processable after subsequent suspension/revocation, or whether current lifecycle state cancels/parks it. The decision must identify a single linearization point and its version/transaction boundary. “Check then act” in separate unprotected operations is not sufficient.

## 6. Financial non-reachability proof boundary

The proof claim must be framed as **no effective capability and no observed attempt within the defined isolated environment**, not an absolute claim about every future deployment.

Inventory and deny:
- database credentials, roles, schemas, grants, connection strings and secret references;
- workload identity, service-account permissions, token exchange and metadata endpoints;
- mounted files, environment variables, secret managers and dynamic configuration;
- internal service routes, service mesh authorization, DNS/service discovery and egress;
- wallet, ledger, payment, settlement, payout, commission and economic-effect APIs/events;
- privileged operator/debug paths that could inject a capability at runtime.

Ingress and worker must use separate least-privilege identities where practical. The harness must be isolated from real financial infrastructure, not merely instructed not to call it. Any attempted prohibited access, secret discovery, unexpected route or permission drift is a critical stop. A future financial command must be a separate authorization and design boundary; it is outside this proof.

## 7. A4 case challenge and coverage additions

The 47 A4 IDs remain stable and A7's one-row-per-ID structure is retained. The following **subcases** are required additions; they do not imply tests have run:

| Proposed subcase | Parent | Interleaving / challenge | Required assertion |
|---|---|---|---|
| A8-DUR-05a | A4-DUR-05 | Lease expires; old worker attempts completion before any new claim occurs. | Expiry itself invalidates completion; zero protected-row changes. |
| A8-DUR-05b | A4-DUR-05 | Heartbeat races with expiry and second worker claim. | Exactly one serialized winner; no lease resurrection after expiry. |
| A8-DUR-05c | A4-DUR-05 | Old worker performs completion after generation increments and after process restart. | Stale generation remains fenced; no state regression. |
| A8-DUR-08a | A4-DUR-08 | Restore durable state while an old worker/process remains alive. | Old process cannot act on restored/reused identity; generation/token remains non-reusable. |
| A8-AUTH-06a | A4-AUTH-06 | Suspension/revocation commits between lifecycle read and worker transition. | Approved linearization policy is enforced atomically/version-conditionally. |
| A8-DUR-02a | A4-DUR-02 | Commit outcome unknown while primary is unavailable and replica is stale. | No false acceptance/absence inference; indeterminate result. |
| A8-FIN-01a | A4-FIN-01 | Attempt indirect capability through service discovery, workload identity, secret mount or metadata route. | Denied at independent policy layer; no credential/call or financial effect. |
| A8-DATA-04a | A4-DATA-04 | Delete/expire evidence while backup/restore and legal-hold state vary. | Outcome follows approved lifecycle policy and is independently evidenced. |

The existing 47-case count is not changed. These are review-added subcases to be integrated into the case manifest before runtime design approval. No numeric limits, policy values or technology choices are supplied here.

## 8. Finding disposition and decision dependencies

| Finding | Required decision/artifact | Status |
|---|---|---|
| A8-F01 | Worker claim/lease ADR and temporal state-transition contract | OPEN |
| A8-F02 | Side-effect boundary / downstream capability ADR | OPEN |
| A8-F03 | Financial non-reachability capability inventory and security/finance attestation | OPEN |
| A8-F04 | Installation/tenant lifecycle linearization ADR | OPEN |
| A8-F05 | Oracle independence register and reviewer assignment | OPEN |
| A8-F06 | Claim generation/token lifecycle ADR | OPEN |
| A8-F07 | Unknown-commit reconciliation decision table | OPEN |
| A8-F08 | Evidence provenance and integrity policy | OPEN |
| A8-F09 | Data lifecycle, deletion, backup and legal-hold policy | OPEN |
| A8-F10 | Extended deterministic schedule catalogue | OPEN |
| A8-F11 | Resource/fairness measurement and budget policy | OPEN |
| A8-F12 | Bilingual semantic parity review record | OPEN |

A7's F01–F10 are **not closed by this self-review**. In particular, A7-F01 remains ready for independent review only; this document is not that independent review. F02–F10 remain open pending their accountable decisions, ADRs and evidence. A8 findings are additional and do not silently replace or renumber A7 findings.

## 9. Gate and execution status

- A4-GATE-01 through A4-GATE-08: **NOT APPROVED / execution remains BLOCKED**.
- A4 47 cases: **NOT RUN**; A7 policy/ADR-dependent cases remain blocked.
- A8 review: **self-review completed as a design challenge; independent review pending**.
- Runtime/harness/database/queue/IAM implementation: **not authorized**.
- Partner adapter, real credentials, external sandbox, commission logic, financial posting, merge and deployment: **not authorized**.
- Technology, numeric quotas, retention durations and vendors: **not selected**.

## 10. Required next sequence

1. Obtain a genuinely independent architecture/security/QA review of A4–A8; record reviewer identity/role, conflicts, scope, findings and disposition.
2. Resolve A8-F01/F04/F06/F07 as a coherent temporal protocol before selecting implementation details.
3. Complete A8-F03 with finance/security and operations; demonstrate capability denial, not merely absence of observed calls.
4. Approve A8-F05/F08/F09 before relying on test evidence.
5. Add the eight A8 subcases to A7 in both languages, preserving the original 47 stable IDs.
6. Create separately owned ADRs and decision records for all unresolved F02–F10 and A8 findings.
7. Re-run bilingual semantic review and documentation/contract CI on the exact final head.
8. Only after all eight A4 gates are explicitly approved may the owner authorize a synthetic disposable runtime proof.

## 11. References

- OWASP ASVS 5.0.0 stable release: https://asvs.owasp.org/ and https://github.com/OWASP/ASVS/releases
- OWASP API Security Top 10 (2023): https://owasp.org/API-Security/
- NIST SP 800-204D, Strategies for the Integration of Software Supply Chain Security in DevSecOps CI/CD Pipelines: https://csrc.nist.gov/pubs/sp/800/204/d/final
- PostgreSQL transaction isolation and explicit locking documentation (conceptual references only; no database selected): https://www.postgresql.org/docs/current/transaction-iso.html and https://www.postgresql.org/docs/current/explicit-locking.html
- AWS Prescriptive Guidance, Transactional Outbox (pattern reference only; no cloud/provider selected): https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- Google SRE, Handling Overload (resource/fairness reference): https://sre.google/sre-book/handling-overload/

These references inform review questions; they do not establish compliance, vendor selection or implementation approval.
