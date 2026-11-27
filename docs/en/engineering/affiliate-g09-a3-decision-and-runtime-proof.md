# Affiliate G09-A3 — Security Decision Packet and Synthetic Runtime Proof Plan

**Document ID:** LOT-AFFILIATE-G09-A3-001 | **Version:** 0.1.0 | **Status:** Proposed; no security, technology or production approval | **Date:** 2026-11-27

## 1. Purpose and decision authority

This packet decomposes LOT-AFFILIATE-SEC-ACC-001 into decision records and a reproducible, isolated proof plan. It is a design artifact only. It does not select an identity provider, token profile, database, queue, KMS, deployment platform, partner, commercial formula or jurisdiction.

**Authority rule:** a decision is Accepted only when the accountable owner and required reviewers explicitly approve its exact scope and the decision register records who, when, rationale and evidence. Until then, all values below remain Proposed, Open or TBD. No implementation is authorized by this packet.

## 2. Decision register for G09-A3

| ID | Decision | Candidate direction (not approved) | Required evidence / reviewers | Current state |
|---|---|---|---|---|
| A3-IAM-01 | Principal taxonomy | Separate human user, delegated application, partner machine client, platform workload and break-glass principal; never infer authority from role labels alone | Threat model, LOT-IAM-TENANT-001 mapping, abuse cases; owner, architecture, IAM/security, privacy | Proposed |
| A3-IAM-02 | Authorization evaluation | Deny-by-default capability + tenant membership/binding + product entitlement + object/resource policy; evaluate server-side on every request and re-check at worker execution | Complete operation-to-capability matrix, BOLA tests, revocation consistency requirement; owner, architecture, security, product | Proposed |
| A3-IAM-03 | Credential profile and lifecycle | Distinct management and ingress credentials; short-lived credentials where supported; explicit issue, activate, rotate, revoke, expire and audit states | Issuer/audience/client-binding requirements, key custody, compromise response, revocation SLA and operational runbook; owner, IAM/security, SRE, legal/privacy | Open |
| A3-REG-01 | Installation registry ownership | Platform-controlled immutable installation identity with versioned tenant/product/environment binding and approval history | Ownership/RACI, lifecycle/state machine, migration and offboarding; owner, architecture, security, operations | Proposed |
| A3-REG-02 | Event/schema registry | Allowlisted source namespaces, event types, extensions and immutable schema versions; local/pinned resolution only; fail closed | Registry change control, compatibility policy, schema provenance and review; domain owner, partner (only after authorization), security | Proposed |
| A3-IDEM-01 | Source-event identity | Durable unique key: tenant + product + installation + source + id; independent of HTTP retry key and economic-effect identity | Collision analysis, database uniqueness proof, replay semantics; architecture, data, security, finance | Proposed |
| A3-IDEM-02 | Fingerprint profile | Evaluate strict JSON parsing, duplicate-member rejection, RFC 8785 JCS and SHA-256; preserve raw-byte digest separately; version the profile | Independent implementation review, normative standard review, cross-language vectors, number/Unicode edge cases and migration strategy; architecture, security | Proposed; not approved |
| A3-IDEM-03 | Conflict and concurrency semantics | Same identity/same fingerprint resolves to one durable receipt/job; same identity/different fingerprint is integrity conflict; concurrency decided by database transaction/constraint | Race tests under real DB isolation, retry/response-loss tests, quarantine/audit behavior; data, security, SRE | Proposed |
| A3-RES-01 | Resource ceilings | Define limits per request, parser, installation, tenant and global service; tenant quotas cannot exceed global hard ceilings | Workload model, benchmark/load test, abuse model, cost/capacity envelope and alert thresholds; product, security, SRE, owner | Open; numeric values TBD |
| A3-DATA-01 | Data classification and minimization | Classify envelope, raw payload, normalized event, identifiers, fingerprints and operational metadata separately; collect only required fields | Purpose/legal basis, data-flow map, threat model, jurisdiction and partner contract; privacy/legal, security, product | Open |
| A3-DATA-02 | Retention, deletion and backup | Per-class retention and deletion schedule; define legal hold, backup expiry, restore behavior and whether digests survive payload deletion | Applicable law/contract, restore test, deletion evidence and re-identification assessment; legal/privacy, security, SRE, owner | Open; durations TBD |
| A3-DATA-03 | Encryption and key governance | Encryption in transit and at rest; key separation and controlled access; KMS/HSM choice remains technology decision | Key ownership, rotation/revocation, access logging, recovery and threat review; security, SRE, owner | Proposed; provider TBD |
| A3-AUD-01 | Audit evidence | Append-only, access-controlled records for credential/installation/allowlist/policy changes, event outcomes, replay, worker transitions and privileged access | Threat-driven audit catalogue, tamper-resistance, access/retention and incident runbook; security, operations, legal/privacy | Proposed |
| A3-FIN-01 | Economic-effect boundary | Ingress only records source receipt and durable work; no wallet/ledger/payment/settlement/payout mutation; future commission effect requires separate command, authorization and effect key | LOT-FIN-POST-001 mapping, zero-write proof, finance-owned effect identity and reconciliation; finance, security, architecture, owner | Proposed constraint; no posting approval |

### 2.1 Decision record template

Every decision moved to Accepted must record: stable decision ID; exact scope and exclusions; decision owner; required reviewers; status; date; context/problem; considered alternatives; selected option and rationale; security/privacy/tenant/financial impact; operational consequences; migration/rollback; evidence links; and review/revisit trigger. Silence, a passing documentation workflow, or a synthetic test is not approval.

## 3. Synthetic Runtime Proof — scope and trust boundaries

### 3.1 Allowed proof

Build only an isolated, disposable environment using generated tenants A/B, generated principals, synthetic installations, synthetic event fixtures and non-production credentials. The proof may exercise authentication stubs or a locally controlled test issuer only after the test profile is explicitly documented. It must not contact a real partner, production endpoint, external schema URL, payment provider, wallet or ledger.

The proof target is: authenticated synthetic event → trusted installation binding → strict parse and registry validation → durable Inbox receipt + durable Job/outbox in one transaction → deterministic deduplication/conflict handling → worker claim/retry/recovery → explicit terminal processing outcome.

### 3.2 Forbidden proof behavior

- No real customer/player/partner payloads or credentials.
- No public ingress endpoint, external partner callback or outbound schema fetch.
- No production database, shared staging data, payment rails, wallet balance or ledger write.
- No commission formula, qualification assumption, payout or economic effect.
- No unbounded load test, paid service, secret rotation or repository/deployment setting change.
- No claim of production readiness from a local or synthetic pass.

### 3.3 Harness components

1. **Fixture generator:** deterministic tenant/principal/installation IDs and synthetic CloudEvents; fixed seeds recorded with each run.
2. **Identity test double:** explicit issuer/audience/client/credential state; supports missing, wrong, expired, revoked and rotated credentials. It is not a production IAM implementation.
3. **Installation and schema registry:** local immutable fixtures; registry changes are versioned and audited; schema references resolve only to local pinned artifacts.
4. **Ingress service under test:** same authorization, parser, validation, persistence and error path intended for runtime; test-only configuration must be visibly separated.
5. **Real transactional persistence engine:** use the selected candidate database only after the technology decision permits it. In-memory maps or mocked repositories cannot prove transaction atomicity, unique constraints, isolation or crash recovery.
6. **Durable job/outbox:** persisted in the same transaction as Inbox; queue notification may be delayed/repeated and must not become the source of truth.
7. **Worker harness:** controllable clock, lease expiry, fencing token, crash injection and retry scheduler.
8. **Network egress guard:** deny all outbound network by default; assert zero DNS/HTTP attempts for payload-controlled schema/URL fields.
9. **Fault injector:** fail before write, between writes, before commit, after commit/before response, during claim, during domain processing and after lease expiry.
10. **Evidence collector:** sanitized logs, database snapshots, transaction traces, test reports, commit SHA, fixture version, environment/tool versions and run IDs. Never collect secrets or raw sensitive payloads.

## 4. Proof stages and acceptance gates

| Stage | Required experiments | Pass condition | Stop condition |
|---|---|---|---|
| P0 — Harness isolation | Disposable namespace/database; generated fixtures; outbound network denied; no financial tables/credentials | Isolation assertions pass; zero external egress; zero financial connectivity | Any real credential/data, external call or financial connection |
| P1 — Identity and tenant boundary | Missing/invalid/expired/revoked credential; wrong issuer/audience/client; Tenant A attempting Tenant B; revoked membership; object-level access | Deny-by-default; tenant derived only from trusted installation; no cross-tenant data or existence leak | Any cross-tenant read/write or untrusted tenant override |
| P2 — Parsing and registry | Duplicate JSON members; invalid UTF-8; deep/large payload; unknown source/type/extension/schema; remote/private/redirect schema references | Strict bounded rejection; unknown registry values fail closed; zero outbound fetch | Parser ambiguity, resource exhaustion or any schema URL fetch |
| P3 — Idempotency and concurrency | Sequential duplicate; N concurrent identical deliveries; same identity/different fingerprint; request-key mismatch; lost response/retry | Exactly one durable receipt and job for one source identity; conflicts quarantined; retry returns stable prior result | Duplicate receipt/job, silent overwrite or business side effect |
| P4 — Transaction and recovery | Fail between Inbox/Job writes; rollback; commit then lost ACK; worker crash before/after claim; lease expiry and stale worker; repeated outbox notification | No ACK before commit; failed transaction leaves neither record; committed retry finds same receipt; fencing prevents stale transition | ACK without durable pair, orphan runnable job, duplicate processing or stale overwrite |
| P5 — Resource and privacy | N/N+1 limits once approved; tenant quota isolation; global backpressure; synthetic secret/PII canaries in logs/errors/traces | Bounded deterministic rejection; one tenant cannot exhaust others; canaries redacted; audit is attributable | Unbounded work, cross-tenant starvation, sensitive log leakage |
| P6 — Financial non-effect | Instrument all database permissions/tables and outbound clients; submit accepted, duplicate, conflict and worker-failure events | No wallet/ledger/payment/settlement/payout connection or write path invoked; no economic-effect record | Any financial mutation, external money movement or implicit commission qualification |

**Important:** “Exactly one” in P3 refers only to the durable Inbox receipt and Job for a single source-event identity. It does not claim exactly-once network delivery or prove exactly-once external side effects. Future economic effects require a separate design and proof.

## 5. Required test techniques

- Property-based and mutation testing for parser, canonicalization, schema allowlists and authorization policy.
- Cross-language golden vectors for canonicalization, including Unicode code points, escaped characters, integer/decimal boundaries, exponent notation, negative zero, arrays, object member ordering and duplicate keys. Reject values outside the selected canonicalization profile rather than silently coercing them.
- Database race tests using independent connections/processes and the actual chosen isolation/unique-constraint behavior.
- Fault injection at every transaction and worker boundary; verify both database state and externally observable response.
- Time-controlled tests for credential expiry/revocation, lease expiry, retries and retention transitions.
- Negative assertions for outbound network, secret/PII leakage and every forbidden financial table/client.
- Independent review of the test harness itself; a harness that shares the implementation's assumptions can produce false confidence.

## 6. Evidence packet for each run

Record: proof ID/stage; exact source commit SHA; clean/dirty state; environment isolation description; database/queue/runtime versions; fixture generator version and seed; test command and full result; test counts; failed/skipped tests; fault injection point; before/after state assertions; sanitized artifacts and checksums; outbound network telemetry; financial-access/write telemetry; reviewer and review date.

Evidence status vocabulary: PASS, FAIL, PENDING, BLOCKED, NOT TESTED. A PASS applies only to the named test, environment and exact commit. It does not transfer to another SHA or environment.

## 7. Exit criteria and handoff

G09-A3 design exit requires all decision records to have an explicit owner and reviewer, with every unresolved value marked TBD; no implementation-critical security decision may be silently defaulted. Synthetic proof may begin only after the owner approves its bounded scope, architecture selects a disposable persistence candidate, and security/operations approve isolation and fault-injection controls.

Partner sandbox remains a later gate requiring official partner documentation, written authorization, synthetic test data and approved credential profile. Production remains separately gated by legal/jurisdiction, privacy, security assessment, operational readiness, finance policy and explicit owner release approval.

## 8. Open questions that block approval

1. Which accountable individuals/roles approve IAM, security, data, resource and financial-boundary decisions?
2. Which identity issuer and client-authentication profile are supported by the actual platform and operating model?
3. Who owns installation creation, approval, suspension, rotation and offboarding?
4. Who may register event sources, types, extensions and schema versions, and what review/compatibility SLA applies?
5. Which database/queue candidate is authorized for a disposable transaction proof?
6. What workload profile and service tier determine numeric resource ceilings?
7. Which jurisdiction, partner contract and purpose determine data classification, retention and deletion?
8. Which finance authority owns the future economic-effect identity and reconciliation policy?

Until answered and approved, keep the corresponding decisions Open/TBD. No partner adapter, real credential, production endpoint, financial posting or deployment is authorized.
