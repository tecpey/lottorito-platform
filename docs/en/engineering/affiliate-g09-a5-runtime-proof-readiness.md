# Affiliate G09-A5 — Runtime Proof Readiness & Implementation Blueprint

**Document ID:** LOT-AFFILIATE-G09-A5-001 | **Version:** 0.1.0 | **Status:** Proposed; implementation blueprint only; no technology, runtime, or security approval | **Date:** 2026-11-27
**Depends on:** LOT-AFFILIATE-G09-A4-001, LOT-AFFILIATE-SEC-ACC-001, LOT-AFFILIATE-WIRE-001, LOT-EVENT-001, LOT-IAM-TENANT-001, LOT-FIN-POST-001, LOT-QA-001, LOT-TECH-ADR-001.

## 1. Purpose and decision boundary

A5 converts the 47 stable adversarial cases in A4 into a reviewable implementation-ready proof specification. It defines logical persistence records, atomic boundaries, concurrency/worker protocols, identity fixtures, failure-injection points, executable-test contracts and evidence requirements.

A5 does **not** select PostgreSQL, Redis, a broker, an IAM vendor, a framework, a hosting provider, a schema migration, a partner protocol, a commission rule or a production topology. It does not authorize runtime implementation or execution. A4's eight approval gates remain binding. The only permitted future proof target is synthetic, disposable, isolated and demonstrably disconnected from financial systems and external partner endpoints.

The target claim is deliberately limited: authenticated synthetic ingress either rejects without durable acceptance, or commits one tenant-bound receipt and one durable work record atomically; duplicate/retry/concurrent delivery converges deterministically; workers cannot overwrite newer ownership/state; and every path has zero economic or financial side effects.

## 2. Normative language and unresolved choices

“Must” describes a proof invariant, not a selected implementation. “Candidate” is not approval. The following remain unresolved until explicit ADR/owner decisions: physical DB and isolation level; queue/broker and notification semantics; credential issuer/profile and revocation SLA; event identity namespace; canonicalization profile and cross-language vectors; retry/backoff/parking policy; quotas; retention/deletion; observability vendor; exact resource ceilings.

Do not convert example SQL or state diagrams into production design without a technology ADR and reviewed threat model.

## 3. Logical persistence model (technology-neutral)

The minimum durable model has the following logical records. Physical normalization, types, partitioning and indexes are deferred.

| Record | Required logical attributes | Invariant |
|---|---|---|
| Installation | tenant identity, installation identity, product/environment binding, status, credential reference/version, policy version | Tenant/product/environment come from trusted server-side registry, never payload. |
| InboxReceipt | immutable receipt ID; tenant + installation binding; source-event identity tuple; event type/version; received timestamp; raw-body digest; accepted schema/version reference; canonical fingerprint only if approved; outcome | One source event identity maps to at most one accepted receipt within its contract-defined namespace. |
| WorkItem | immutable work ID; receipt ID; tenant/installation binding; state; attempt counter; not-before; claim generation/token; lease metadata; created/updated timestamps | Work is created in the same transaction as receipt; it is the durable source of truth. |
| DeliveryOutbox (conditional) | outbox ID; work/event reference; destination class; delivery state; attempt metadata; next-attempt time | Exists only if a separately approved external notification is needed; it is not a second source of truth for internal work. |
| AuditRecord | actor/principal class; tenant/installation; action/result; correlation IDs; timestamp; policy version; safe reason code | Append-oriented, least-privilege and payload/secret-free. |
| EvidenceManifest | run ID; source commit; harness/catalogue version; case ID; fixture seed; environment identity; artifact digests; reviewer state | Contains references and hashes, not raw secrets or unrestricted payload copies. |

### 3.1 Identity and uniqueness

A4 requires source-event identity, request idempotency key and economic-effect identity to remain distinct. For ingress deduplication, define an approved identity tuple before implementation. Candidate tuple:

`(tenant_id, installation_id, source, event_id)`

This is a candidate, not a universal rule: LOT-EVENT-001 and partner contract must decide whether source and installation are in the namespace, whether tenant binding is implicit, and how identity changes across installation rotation. A global event_id-only uniqueness rule is prohibited unless evidence and contract explicitly justify it.

The database must enforce uniqueness at the durable boundary. An application-level “check then insert” is insufficient under concurrency. On conflict, compare immutable identity and approved fingerprint: exact semantic duplicate returns the original receipt outcome; same identity with changed content becomes a conflict without mutating the original receipt or creating another work item. Do not overwrite the first payload/fingerprint on conflict.

### 3.2 Atomic acceptance boundary

The only success boundary is one commit containing:
1. the immutable InboxReceipt;
2. exactly one corresponding WorkItem;
3. any required audit/outbox metadata that the approved design declares transactionally mandatory.

The success response (for example, HTTP 202 if retained by the wire contract) may be emitted only after commit is known successful. Before-commit failure yields no accepted receipt/work pair and no success response. If commit succeeds but the response is lost, retry must resolve to the already committed receipt/work pair. A broker publish must never be required to complete the acceptance transaction.

### 3.3 State machine

WorkItem states are logical, not final enum values:

- `READY` → `CLAIMED` → `SUCCEEDED`
- `CLAIMED` → `RETRY_WAIT` → `READY`
- `CLAIMED` → `PARKED` only under an approved poison/failure policy.
- Terminal states cannot be reopened by a stale worker. Reprocessing requires an explicit audited operator action and a new generation, if later approved.

Every transition is conditional on current state and current claim generation. A queue message is only a wake-up hint; workers must load and claim durable state. Queue visibility/acknowledgement is not proof of completion.

## 4. Concurrency, lease and fencing protocol

### 4.1 Claim protocol

A worker may claim only an eligible READY/RETRY_WAIT record whose not-before time has arrived. Claim acquisition must be one atomic compare-and-set/locking operation that:
- verifies current state and eligibility;
- increments a monotonic claim generation (fencing number) or creates an unguessable claim token tied to that generation;
- records owner identity and lease expiry;
- changes state to CLAIMED;
- returns the authoritative generation/token.

A lease alone is insufficient: a paused worker can resume after expiry. Every heartbeat, completion, retry, and error transition must condition on the exact claim generation/token and expected state. A stale generation must affect zero rows and produce a safe stale-claim outcome. It must not be allowed to update audit/business state as if still owner.

### 4.2 Lease expiry and recovery

Lease expiry makes a record eligible for a new claim; it does not itself prove the old worker stopped. A new claim increments the generation. The old worker is fenced even if its process resumes. Time source, clock-skew tolerance and lease duration require an approved operational profile; no numeric value is set here.

### 4.3 Retry semantics

Retry is permitted only for classified transient failures and only after the prior attempt's transaction has definitively rolled back or safely recorded a retry transition. Never blindly retry an unknown commit outcome: first reconcile durable state by receipt/work identity. Backoff, jitter, maximum attempts and parking are owner/SRE decisions. Poison work must not block unrelated tenants or monopolize global worker capacity.

### 4.4 Isolation and tenant binding

Every durable read/write is scoped by server-derived tenant and installation context. Worker authority is re-derived from the durable receipt/installation relationship; message payload fields cannot grant tenant authority. Cross-tenant IDs must not become existence oracles. A worker's DB role and network policy must make wallet, ledger, payment, settlement and payout systems unreachable.

## 5. Identity and authorization fixture architecture

Use synthetic identities only. Fixtures are deterministic and versioned; no production credential, customer PII or partner secret is allowed.

| Fixture class | Required variants | Assertions |
|---|---|---|
| Principal | absent, malformed, expired, revoked, valid, wrong issuer/audience | Authentication fails closed; no receipt/work write on rejection. |
| Installation | active, suspended, rotated credential, retired credential, unknown installation | Credential is bound to one installation and trusted tenant context. |
| Tenant | Tenant A, Tenant B, platform principal, tenant administrator, worker principal | Function/object/property authorization enforced independently. |
| Lifecycle race | valid at ingress then suspended before worker; key rotated during request; stale cache | Behavior follows an approved consistency boundary; worker rechecks required state. |
| Worker | worker-1, worker-2, stale worker-1 generation | Only current claim owner can transition durable work. |

Fixture issuer, signing algorithm, key lifecycle, token shape, revocation consistency and clock policy remain open until IAM/security approval. Tests must not use a mock as the sole evidence for authorization or persistence behavior.

## 6. Failure-injection matrix and mapping to A4's 47 cases

Injection points are named relative to logical boundaries; the eventual adapter must map them to deterministic hooks. A failure test records both the injected point and the independently observed durable state.

| A4 case(s) | Injection / adversarial action | Required postcondition |
|---|---|---|
| IAM-01..06 | Before principal creation; after credential verification; during rotation/revocation lookup | Rejected identity creates no receipt/work; accepted identity is installation-bound; no secret leakage. |
| AUTH-01..05 | Mutate tenant/object/function/property at ingress and response projection | No cross-tenant disclosure or unauthorized mutation; protected fields remain server-owned. |
| AUTH-06 | Suspend membership/installation after receipt commit but before worker claim | Worker follows approved revalidation rule; no unauthorized processing. |
| AUTH-07 | Forge tenant/install IDs in queue/job payload | Worker ignores untrusted authority claims and derives binding from durable records. |
| IDEM-01 | Sequential duplicate after successful commit | Same receipt/work outcome; no second durable pair. |
| IDEM-02 | Barrier-synchronize N independent transactions on same identity | Exactly one winner; all others resolve duplicate/conflict deterministically. |
| IDEM-03 | Same identity, changed payload | Immutable original remains; conflict; no second work item. |
| IDEM-04 | Colliding event IDs across sources/installations/tenants | Behavior matches approved identity namespace; no accidental global collision or cross-tenant merge. |
| IDEM-05..07 | Vary byte order, whitespace, duplicate members, numeric and Unicode edge cases | Strict parse/canonicalization profile decides; no lossy normalization or undocumented equivalence. |
| IDEM-08 | Change request key while retaining event identity; reuse request key for another event | Request key cannot bypass or collapse source-event identity. |
| PARSE-01..06 | Unknown schema/type; malicious schema URL; parser boundary; compression; ambiguous fields; schema artifact mutation | Fail closed/bounded; no network resolution; accepted receipt pins immutable schema provenance. |
| RES-01 | Exact approved body limit and one unit over | Deterministic boundary behavior; limit comes from approved profile. |
| RES-02..05 | Tenant burst, pool exhaustion, repeated invalid requests, poison retries | Bounded resource use, fairness, safe backpressure and no retry storm. |
| DUR-01 | Crash before transaction, after receipt insert, after work insert, immediately before commit | Rollback leaves neither receipt nor work; no success response. |
| DUR-02 | Commit succeeds, then drop response/ack | Retry finds original committed pair; no duplicate. |
| DUR-03 | Force unique conflict, deadlock or serialization abort | One durable winner; retry occurs only at safe transaction boundary. |
| DUR-04 | Crash before claim, after claim, during work, before completion commit | Durable state supports recovery; no false success. |
| DUR-05 | Expire lease, reclaim with worker-2, resume worker-1 | Old generation is fenced; newer state cannot be overwritten. |
| DUR-06 | Duplicate/out-of-order queue notifications and repeated delivery | Durable DB state governs claim; notifications cannot duplicate work. |
| DUR-07 | Corrupt/mismatch internal job or installation reference | Fail closed/park per policy; no tenant or financial effect. |
| DUR-08 | Restart/restore disposable persistence and workers across committed/uncommitted cases | Commit boundary is preserved; committed work recoverable, uncommitted work absent. |
| DATA-01..04 | Secret canary in payload; unauthorized evidence read; retention/restore simulation | Canary absent from telemetry/evidence; access denied/audited; retention only tested after policy approval. |
| FIN-01..03 | Attempt DB/network/service access and forge amount/currency/beneficiary/commission fields | No financial connection, permission, call, record or economic effect. |

This table is a mapping, not a claim that tests have been implemented or passed. A4's exact 47 IDs remain the canonical case catalogue; A5 must not renumber them.

## 7. Executable test specification contract

Every executable case must be data-driven and contain:

- `case_id`: exact A4 identifier; `case_version`; severity; requirement/invariant references.
- `preconditions`: fixture IDs, tenant/installation state, seeded durable state and policy version.
- `stimulus`: request/job/action, concurrency barrier, fault point and deterministic seed.
- `expected_api`: status class and safe response code; no unstable raw error text.
- `expected_persistence`: exact row cardinalities, immutable fields, state transitions and absence assertions.
- `expected_authorization`: principal, tenant, installation and allowed operation.
- `expected_financial_non_effect`: zero financial connections/calls/writes/economic-effect rows.
- `evidence`: sanitized transaction trace, state snapshot, correlation IDs, relevant logs/metrics, artifact digest.
- `cleanup`: disposable-environment teardown proof; no cleanup that erases original failure evidence.
- `oracle`: independent method that does not merely repeat the SUT's own response.

### 7.1 Test layers

1. Pure unit tests: parser rules, state transition predicates, fingerprint vectors and response projection.
2. Real persistence integration tests: actual selected engine, real constraints/transactions/locking and independent reads.
3. Worker protocol tests: real durable claim/fencing behavior with deterministic fault injection.
4. Security boundary tests: principal/tenant/object/function/property controls with negative assertions.
5. End-to-end synthetic proof: only after all A4 gates, from ingress to durable work and zero financial reachability.
6. Contract/schema tests: validate OpenAPI/AsyncAPI and pinned schema vectors; these do not substitute for runtime proof.

Mocks may isolate non-critical collaborators but cannot be the sole oracle for unique constraints, transaction atomicity, isolation, crash recovery, worker fencing or financial non-reachability.

## 8. Independent oracles and evidence

At minimum, use independent oracles for: (1) API response; (2) direct read-only persistence inspection; (3) DB constraint/transaction trace; (4) worker claim-generation audit; (5) network/DB permission sentinel proving no financial reachability; (6) sanitized telemetry/evidence scan for secret canaries.

Each run manifest binds repository commit, harness version, A4 catalogue version, A5 specification version, fixture seed, disposable environment identity, case IDs, timestamps, artifact digests, tool versions and reviewer disposition. Preserve failed-run evidence before any repair/retry. Evidence must be tamper-evident, access-controlled and retention-bounded under an approved policy; do not store raw credentials or unrestricted payloads.

## 9. Execution sequence and gates

| Stage | Work | Entry conditions | Exit evidence |
|---|---|---|---|
| A5-0 | Review and approve logical model, identity tuple and state machine | A4-GATE-01/08 review; no physical choices assumed | Signed decision records and unresolved-item register |
| A5-1 | Select disposable persistence candidate | A4-GATE-03; technology ADR | Documented uniqueness, isolation, rollback and crash semantics |
| A5-2 | Select worker/queue notification model | A4-GATE-04 | Durable claim, lease, fencing and recovery decision |
| A5-3 | Approve identity fixture and policy | A4-GATE-02 | Test-only issuer/profile and revocation boundary |
| A5-4 | Approve data/evidence and workload policy | A4-GATE-05/06 | Field catalogue, redaction, retention, ceilings |
| A5-5 | Prove financial non-reachability | A4-GATE-07 | DB grants, network deny evidence, independent sentinel |
| A5-6 | Implement and run synthetic proof | All eight A4 gates approved | Reproducible 47-case results with independent oracles |
| A5-7 | Review findings and decide next gate | A5-6 complete | Signed findings; no automatic production promotion |

A5-0 through A5-5 are design/governance work. A5-6 is blocked until every required gate is explicitly approved. Passing A5-6 would prove only the isolated synthetic scope, not partner compatibility, commercial correctness, production security or regulatory readiness.

## 10. Stop conditions

Stop immediately on any external network egress, financial-system reachability, real credential/PII discovery, cross-tenant disclosure, stale-worker overwrite, duplicate durable work, unexplained partial commit, unbounded retry/resource growth, secret in telemetry, evidence-integrity failure or mismatch between test catalogue and executed cases. Preserve sanitized evidence, isolate and tear down only under approved procedure, and open a finding. Never suppress, rewrite or discard the original failing evidence.

## 11. Design references

- AWS Prescriptive Guidance, Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html — atomic dual-write boundary, duplicate delivery and ordering considerations; not a broker selection.
- PostgreSQL documentation, INSERT / ON CONFLICT: https://www.postgresql.org/docs/current/sql-insert.html — conditional reference for unique-conflict handling if PostgreSQL is selected.
- PostgreSQL explicit locking: https://www.postgresql.org/docs/current/explicit-locking.html — conditional reference for row locks.
- PostgreSQL transaction isolation: https://www.postgresql.org/docs/current/transaction-iso.html — conditional reference for isolation anomalies and retry behavior.
- OWASP ASVS 5.0: https://asvs.owasp.org/ — verification requirement catalogue; applicability/level must be mapped by security reviewers.
- OWASP Authorization Regression Testing: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Regression_Testing_Cheat_Sheet.html — continuous authorization regression approach.
- Martin Fowler, Practical Test Pyramid: https://martinfowler.com/articles/practical-test-pyramid.html — balanced unit/integration/contract/system test portfolio.

These sources inform design; they do not approve a technology, control, vendor or implementation.
