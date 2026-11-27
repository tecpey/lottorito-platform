# Affiliate G09-A6 — Design Verification & Proof Closure

**Document ID:** LOT-AFFILIATE-G09-A6-001 | **Version:** 0.1.0 | **Status:** Proposed; independent design review only; no runtime authorization | **Date:** 2026-11-27

## 1. Purpose and review boundary

G09-A6 independently challenges A4 (47 adversarial acceptance cases) and A5 (technology-neutral runtime-proof blueprint) before any implementation decision. It verifies traceability, assertion completeness, concurrency/recovery reasoning, trust boundaries, unresolved policy dependencies and bilingual governance.

This is a document-level design review. It is not a code review, threat-model certification, penetration test, runtime proof, technology approval or production-readiness assessment. No A4 gate is waived. A4-GATE-01..08 remain mandatory.

## 2. Evidence reviewed

- LOT-AFFILIATE-G09-A4-001, English and Persian, at review head `e6808bda79a65c84d0dfab6e8b07094014184910`.
- LOT-AFFILIATE-G09-A5-001, English and Persian, at the same head.
- The PR #76 metadata, bilingual indexes, project-status records and decision registers at that head.
- GitHub Actions on that exact head: Affiliate Contract Validation run `46060385984` (#73) and Documentation Governance run `46060385973`, both completed with conclusion `success`. These are documentation/contract workflow results, not runtime-security evidence. The commit status endpoint separately returned `pending` with no legacy statuses; do not confuse that status endpoint with the completed workflow conclusions.

PR #76 is open and Draft, head branch `docs/g09-affiliate-api-wire-contract-v1`, base `docs/affiliate-api-capability-contract-v1`. No merge or deployment is performed.

## 3. Traceability result — all 47 stable A4 IDs

A5's shorthand ranges map to the A4 catalogue's stable identifiers. The ranges are not evidence that each case already has a fully executable test. A5 supplies a generic executable-case schema, but its failure-injection table groups many cases and does not instantiate each case's complete fixture, stimulus, API/persistence/authz assertions, oracle and evidence requirements.

| A4 stable IDs | A5 mapping | Review disposition |
|---|---|---|
| A4-IAM-01..06 | IAM-01..06 | Range mapped; six distinct credential cases still need per-case executable vectors and revocation/rotation consistency policy. |
| A4-AUTH-01..07 | AUTH-01..07 | Range mapped; AUTH-06 depends on an unresolved lifecycle revalidation policy; AUTH-01/02 need explicit non-enumeration assertions. |
| A4-IDEM-01..08 | IDEM-01..08 | Range mapped; canonicalization profile and cross-language vectors remain unapproved; concurrency schedule and identity namespace need decision records. |
| A4-PARSE-01..06 | PARSE-01..06 | Range mapped; parser/decompression limits, schema pinning and URL non-resolution need concrete policy and observable network-deny assertions. |
| A4-RES-01..05 | RES-01..05 | Range mapped; no numeric ceilings are approved; fairness, saturation and retry behavior need measurable workload profiles. |
| A4-DUR-01..08 | DUR-01..08 | Range mapped; highest-risk area. Transaction race, commit-unknown reconciliation, claim fencing and restore evidence need more explicit executable schedules. |
| A4-DATA-01..04 | DATA-01..04 | Range mapped; evidence access, canary scan and retention/backup behavior require separate per-case evidence. DATA-04 remains policy-gated. |
| A4-FIN-01..03 | FIN-01..03 | Range mapped; financial non-reachability needs defense-in-depth proof across DB grants, service credentials, network policy, secrets and runtime dependency graph. |

**Count check:** 6 + 7 + 8 + 6 + 5 + 8 + 4 + 3 = 47. No A4 case is intentionally dropped or renumbered.

## 4. Findings requiring closure before runtime design approval

### A6-F01 — Case-level test traceability is not yet executable (High)

A5's section 6 compresses the 47 cases into grouped rows (for example, DATA-01..04 and PARSE-01..06). Section 7 defines the fields each test must contain, but there is no 47-row case manifest that binds every stable A4 ID to exact fixture, deterministic stimulus, protocol assertion, persistence cardinality, authorization assertion, financial non-effect assertion, independent oracle and evidence artifact.

**Required closure:** create a versioned 47-row machine-readable or tabular test manifest. No case may be marked covered merely because its range appears in A5. Record explicit `NOT RUN` until a gated runtime run exists.

### A6-F02 — Required WorkItem versus conditional DeliveryOutbox terminology (High)

A4 INV-01 and the proof objective require an Inbox receipt plus exactly one durable Job/Outbox record to commit atomically. A5 introduces a required logical `WorkItem` and a `DeliveryOutbox (conditional)`. These can be compatible only if the terms and ownership are made explicit. An optional downstream delivery outbox must not weaken the mandatory durable processing-work pair.

**Required closure:** define the minimum atomic pair as `InboxReceipt + WorkItem`; state whether `DeliveryOutbox` is a distinct optional publication record, its owner and its own atomicity boundary. Align terms across A4, A5, API contract and future physical ADR. No physical schema is selected here.

### A6-F03 — Transaction races and unknown commit outcome need deterministic schedules (High)

A4-DUR-01..03 and A4-IDEM-02 require crash points, concurrent independent transactions, uniqueness races and safe retry. A5 names these behaviors but does not yet provide a deterministic schedule for each interleaving or a formal reconciliation rule for a client that cannot determine whether commit succeeded.

**Required closure:** define barriers and independent DB connections; capture commit/rollback outcome; specify read-after-unknown reconciliation by the candidate identity; prove no blind retry; and test the actual selected engine's constraints/isolation/locking. A mock is insufficient.

### A6-F04 — Worker fencing needs an explicit stale-writer proof contract (High)

A5 correctly states that lease expiry does not stop an old process and that every state-changing transition must be conditional on the current claim generation/token. It does not yet bind this to a concrete, independently inspected write predicate and zero-row stale-write assertion.

**Required closure:** when a persistence candidate is approved, specify the atomic claim operation and every heartbeat/success/retry/failure transition predicate. Test worker-1 claim generation n, worker-2 generation n+1, then resume worker-1; independently prove worker-1 cannot mutate WorkItem, terminal state or authoritative audit ownership. Do not choose SQL or a database before its ADR.

### A6-F05 — Identity and fingerprint policy remain open (High)

The candidate identity tuple `(tenant_id, installation_id, source, event_id)` is not approved. A4-IDEM-04 explicitly requires namespace behavior to follow the eventual contract. A4-IDEM-05..07 depend on a pinned parser/canonicalization profile; RFC 8785 alone does not decide every ingress policy, duplicate-member handling, accepted numeric domain or Unicode normalization policy.

**Required closure:** approve the identity namespace and conflict semantics from LOT-EVENT-001 plus actual partner contract evidence; separately approve strict parse rules and a versioned cross-language fingerprint vector set. Until then these cases are design-defined but cannot be implemented as final behavior.

### A6-F06 — Tenant lifecycle race needs an owner-approved consistency rule (High)

A4-AUTH-06 asks what happens when membership/installation is suspended between ingress acceptance and worker execution. A5 says the worker follows an approved revalidation rule, but does not define whether accepted work is cancelled, parked, processed under acceptance-time authority or rejected at execution.

**Required closure:** define the lifecycle state and consistency boundary, revocation SLA, race winner semantics and audit record. The decision must be explicit; do not silently pick a policy in code.

### A6-F07 — Financial isolation must be proven across all authority paths (Critical)

A4-FIN-01..03 and A5 require no financial reachability. A single DB-role assertion or a single network-deny check is insufficient if credentials, service discovery, shared application clients, secrets, queues or indirect service calls can still create a path.

**Required closure:** provide a threat-informed reachability matrix covering database grants/roles, credentials/secrets available to the harness and workers, service bindings/dependencies, network egress/DNS, queue payload authority and attempted-call telemetry. Use independent negative probes and fail the run on any reachable financial endpoint or attempted financial mutation. Finance and Security must attest before A5-6.

### A6-F08 — Resource governance requires measurable profiles, not guessed limits (Medium)

A4-RES-01..05 are correctly policy-gated, but A5 does not yet define the measurement contract for fairness, queue saturation, pool exhaustion, parser resource ceilings, retry amplification or tenant starvation.

**Required closure:** approve workload shape and ceilings under A4-GATE-06; define observable metrics, test duration, tenant distribution, saturation/recovery criteria and stop thresholds. No numeric values are invented by this review.

### A6-F09 — Evidence oracle independence and provenance need a case-level map (Medium)

A5 lists six oracle categories and a run manifest. It does not yet show, per case, which oracle is authoritative and how it is independent from the system-under-test response. A DB trace and direct read may share the same underlying failure mode unless independently sourced.

**Required closure:** add an oracle matrix per case: source, trust boundary, failure modes, collection method, read-only status, correlation and expected artifact. Preserve failed-run evidence before retry; use tamper-evident storage under an approved policy.

### A6-F10 — Data lifecycle tests must remain policy-gated (Medium)

A4-DATA-04 cannot be meaningfully passed until retention, deletion, backup and restore semantics are approved. A5 correctly leaves duration unspecified; do not convert this into a guessed retention value or mark the case complete.

**Required closure:** approve data classification, retention/deletion scope, backup treatment, legal hold and evidence expiry; then define a synthetic test proving deletion and restore behavior. Until then mark `BLOCKED — POLICY NOT APPROVED`.

## 5. Cross-cutting invariants confirmed by design review

The following principles are consistent across A4/A5 and should remain non-negotiable:
1. Source-event identity, HTTP request idempotency key and economic-effect identity are separate namespaces.
2. Tenant and Installation authority are resolved server-side; caller/job payload fields cannot grant authority.
3. InboxReceipt and mandatory WorkItem must share one durable commit before acceptance acknowledgement.
4. Queue notifications are hints; durable persistence is authoritative.
5. Lease expiry alone is not fencing; stale generations must be unable to write.
6. Unknown commit outcome is reconciled from durable state before retry.
7. No ingress/worker path may reach Wallet, Ledger, Payment, Settlement or Payout.
8. Synthetic-only disposable environment, no partner credentials, no external schema fetch, no production/staging access.
9. No claim of exactly-once delivery; the target is at-least-once input with durable deduplication and controlled effects.
10. Design, implementation, isolated verification and production approval remain separate states.

## 6. Gate decision and next sequence

**G09-A6 disposition: CONDITIONAL DESIGN PASS WITH OPEN FINDINGS.** A4/A5 are directionally coherent and all 47 A4 IDs are represented in A5's grouped mapping. They are not yet an executable, case-complete proof specification. F01–F07 are closure blockers for runtime design approval; F08–F10 must close before the affected test groups can be accepted.

Permitted next work:
- Close F01–F10 through bilingual design artifacts and decision records.
- Produce the 47-case traceability/oracle manifest and explicit unresolved-decision register.
- Review canonical external source URLs and standards applicability.
- Re-run exact-head CI and verify bilingual parity.

Still blocked:
- Any runtime implementation or test execution (including disposable DB/queue setup).
- Database/queue/IAM/KMS/HSM/vendor selection absent approved ADRs.
- Partner adapter, real credentials, external sandbox, commission calculation or financial posting.
- Merge, deployment or production readiness claims.

## 7. References and applicability

- OWASP API Security Top 10 (2023): https://owasp.org/API-Security/ — threat taxonomy, not certification.
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/ — verification catalogue; select version/level through Security review.
- RFC 8785: https://www.rfc-editor.org/rfc/rfc8785 — JSON Canonicalization Scheme; does not replace ingress parser policy.
- CloudEvents specifications: https://cloudevents.io/ — event envelope semantics; does not approve a partner mapping.
- PostgreSQL INSERT: https://www.postgresql.org/docs/current/sql-insert.html ; explicit locking: https://www.postgresql.org/docs/current/explicit-locking.html ; transaction isolation: https://www.postgresql.org/docs/current/transaction-iso.html — conditional references only if PostgreSQL is selected.
- AWS Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html — pattern reference, not a broker or architecture approval.

Canonical URLs are recorded without tracking parameters. No external source overrides owner decisions or project-specific contracts.

## 8. Review limitations

This review is based on the exact repository artifacts and workflow metadata listed above. It does not independently execute code, inspect a live runtime, prove security controls or certify translation quality. CI success applies only to the workflows and exact commit recorded; it does not close any runtime finding.

