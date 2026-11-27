# Affiliate G09-A4 — Runtime Proof Architecture & Adversarial Test Design

**Document ID:** LOT-AFFILIATE-G09-A4-001 | **Version:** 0.1.0 | **Status:** Proposed; architecture/test design only; no implementation or security approval | **Date:** 2026-11-27
**Depends on:** LOT-AFFILIATE-SEC-ACC-001; LOT-AFFILIATE-G09-A3-001; LOT-AFFILIATE-WIRE-001; LOT-IAM-TENANT-001; LOT-EVENT-001; LOT-FIN-POST-001; LOT-QA-001; LOT-TECH-ADR-001; LOT-PROT-001.

## 1. Purpose and boundary

G09-A4 turns the G09-A3 security decisions and P0–P6 proof stages into a reviewable test architecture, adversarial catalogue, evidence model and execution order. It is not an implementation plan authorization, technology selection, penetration-test report or production-readiness claim.

The proof objective is deliberately narrow: for generated tenants and installations, prove that a synthetic authenticated source event can be accepted or rejected deterministically; that an accepted event creates one durable Inbox receipt and one durable WorkItem (processing-job) record atomically; that retries, concurrency and worker failures do not create duplicate durable work or stale state; and that the path has no financial side effects.

**Non-goals:** partner adapter, real partner traffic or credentials, public endpoint, production/staging access, commercial attribution or commission calculation, wallet/ledger/payment/payout operation, external schema retrieval, deployment, load generation against shared systems, or a claim of exactly-once delivery/economic execution.

## 2. Authority and decision dependencies

All architecture choices below are candidates until accepted through the owner-controlled decision register. G09-A4 does not silently approve a database, queue, runtime, identity provider, token format, canonicalization library, KMS/HSM, numeric limit, retention duration or test vendor.

| Dependency | Required decision/evidence before execution | Owner/reviewer roles |
|---|---|---|
| A4-GATE-01 Scope and isolation | Written approval of synthetic-only scope, disposable environment, no external egress, no financial connectivity, teardown and evidence handling | Product owner, security, operations/SRE |
| A4-GATE-02 Identity fixture | Approved test-only trust profile and threat cases; issuer and credentials remain local/non-production | IAM/security, architecture |
| A4-GATE-03 Persistence candidate | Technology ADR selects a disposable candidate; actual transaction, uniqueness, isolation and crash semantics documented | Architecture, data/platform, SRE |
| A4-GATE-04 Queue/worker | Durable job/outbox ownership and retry/lease/fencing model selected; queue notification is not source of truth | Architecture, SRE |
| A4-GATE-05 Data and audit | Synthetic-only field catalogue, redaction, retention and evidence access/expiry approved | Privacy/legal, security, operations |
| A4-GATE-06 Resource profile | Bounded workload profile and ceilings approved before N/N+1 or capacity experiments | Product, security, SRE, owner |
| A4-GATE-07 Financial non-effect | DB role/schema and network boundary prove no financial connectivity or write permission | Finance, security, architecture |
| A4-GATE-08 Test acceptance | Test cases, expected outcomes, failure severity and evidence reviewers accepted | QA, security, architecture, owner |

If a gate is not approved, its tests remain **BLOCKED / NOT RUN**. A test double may validate orchestration but cannot substitute for the actual persistence engine when proving atomicity, unique constraints, isolation, locking or recovery.

## 3. Threat model and coverage mapping

Threat actors considered: unauthenticated caller; authenticated but wrong-tenant partner client; compromised or revoked client; malicious/buggy event producer; malicious tenant administrator; stale/duplicated worker; compromised internal workload; and resource-exhaustion actor. No assumption is made that a partner is trusted merely because it is known.

| Threat family | Attack surface | Primary proof cases | Reference |
|---|---|---|---|
| Authentication and credential trust | Ingress credential, issuer/audience/client binding, expiry/revocation | A4-IAM-01..06 | OWASP API2:2023 |
| Object/function/property authorization | Tenant, installation, event, administrative operation and returned fields | A4-AUTH-01..07 | OWASP API1/API3/API5:2023 |
| Replay, identity collision and tampering | Event source/id, fingerprint, request retry key, concurrent delivery | A4-IDEM-01..08 | LOT-EVENT-001; RFC 8785 candidate profile |
| Parsing and schema supply chain | JSON parser, CloudEvents attributes/extensions, schema reference, remote fetch | A4-PARSE-01..06 | OWASP API7/API9/API10:2023 |
| Resource exhaustion | Body, nesting, arrays, parser CPU/memory, concurrency, tenant fairness | A4-RES-01..05 | OWASP API4:2023 |
| Transaction/worker correctness | InboxReceipt, WorkItem, commit/ack, lease, fencing, crash and retry | A4-DUR-01..08 | LOT-AFFILIATE-G09-A3-001 |
| Privacy and audit | Logs, traces, errors, audit, evidence artifacts | A4-DATA-01..04 | LOT-SEC-001; applicable privacy decisions |
| Financial side effects | DB permissions, service calls, network egress, economic-effect records | A4-FIN-01..03 | LOT-FIN-POST-001 |

OWASP API Security Top 10 is a coverage taxonomy, not a certification. A passing subset does not establish full OWASP conformance or penetration-test completion.

## 4. Proposed test harness architecture

### 4.1 Logical components

1. **Scenario orchestrator:** executes named cases with deterministic seeds; captures run ID, test case ID and source commit.
2. **Synthetic identity authority:** local test-only issuer/credential fixture or deterministic verifier stub; controls issuer, audience, client binding, expiry, revocation and key version. It must never reuse production secrets or pretend to certify production IAM.
3. **Tenant and installation fixture registry:** creates Tenant A/B, Installation A/B, principals and explicit server-side bindings. The request body/header cannot choose the authoritative tenant.
4. **Ingress system under test:** production-intended parsing, authentication, authorization, registry lookup and persistence path, with test-only endpoints/configuration visibly isolated.
5. **Strict parser and schema fixture store:** bounded parser; local pinned schemas only; no runtime network resolver; duplicate JSON members rejected before object materialization.
6. **Transactional persistence adapter:** actual selected disposable database and transaction engine. Independent connections/processes are required for race tests. A mock cannot prove DB invariants.
7. **Outbox/worker subsystem:** durable WorkItem committed atomically with Inbox; queue notifications are at-least-once hints; worker claims use an explicit lease and monotonically changing fencing/claim token if that model is selected.
8. **Fault and time controller:** injects failures at declared boundaries and advances a controllable clock for expiry/lease/retry tests.
9. **Egress deny layer:** network policy/firewall or equivalent denies outbound access by default; DNS and connection attempts are observable. No exception for schema URLs.
10. **Financial isolation sentinel:** test DB roles and service wiring expose no wallet/ledger/payment/payout connection; instrument attempted access as a hard failure.
11. **Evidence collector:** collects sanitized test output, DB state assertions, traces, network-deny telemetry, permissions and checksums; excludes credentials and raw payloads.
12. **Disposable environment controller:** creates unique namespace/database, applies approved fixtures, verifies isolation and destroys it after evidence sealing.

### 4.2 Trust boundaries and data flow

- **TB-1 External request → ingress:** bytes are untrusted. Enforce transport/body limits before expensive parsing; authenticate before trusting client identity.
- **TB-2 Principal → installation binding:** tenant is resolved from a server-controlled active installation/client binding, not a caller-supplied tenant field.
- **TB-3 Event → registry/parser:** source, type, extensions and schema version must match a locally approved registry record. Payload-controlled URLs are data, never fetch instructions.
- **TB-4 Ingress → persistence:** source identity, fingerprint, InboxReceipt and mandatory WorkItem are committed atomically under database-enforced uniqueness.
- **TB-5 Outbox → queue → worker:** queue is a wake-up channel; durable state is authoritative. Worker must re-check installation/tenant/status and claim ownership before transition.
- **TB-6 Runtime → financial domains:** this proof has no route, credential, network path or DB grant to financial domains. Any attempted access is a failed test and stop event.
- **TB-7 Runtime → observability/evidence:** telemetry is a separate data sink with field allowlist/redaction; evidence access is restricted and retention bounded.

### 4.3 Persistence invariants to prove

Let E be one accepted source-event identity, I its InboxReceipt row and J its mandatory WorkItem row.

- **INV-01 Atomic pair:** the mandatory InboxReceipt + WorkItem pair commits together or neither exists; no externally acknowledged acceptance before commit. A conditional DeliveryOutbox is a separate downstream-publication record and never substitutes for WorkItem.
- **INV-02 Unique source identity:** database-enforced uniqueness scopes the source-event identity using the accepted tenant/product/installation/source/id tuple. Application pre-checks alone are insufficient.
- **INV-03 Stable replay:** same identity and same accepted fingerprint returns/points to the original durable receipt; it does not create a second job.
- **INV-04 Integrity conflict:** same identity with a different fingerprint cannot overwrite the original event or enqueue new work; it produces a bounded, auditable conflict outcome.
- **INV-05 Claim ownership:** only the current valid worker claim may advance a job; an expired/stale claim cannot overwrite a newer claim or terminal state.
- **INV-06 Retry safety:** retries and repeated queue notifications may re-run delivery/claim logic but cannot duplicate the durable source receipt/job.
- **INV-07 No financial reachability:** ingress/worker proof principals have no permission or connection to financial stores/services.
- **INV-08 Tenant closure:** every read/write query and job transition is scoped by trusted tenant/install binding; a caller-controlled tenant value never expands authority.

The exact schema, isolation level, lock/claim statement, unique index, retry state machine and response codes remain technology/domain ADR decisions.

## 5. Adversarial acceptance catalogue

**Execution rule:** these are test specifications, not completed tests. Use synthetic fixtures only. For every case record expected HTTP/domain outcome, persisted state, audit event, network attempts, financial-access attempts and evidence. Any cross-tenant disclosure, unauthorized write, duplicate durable effect, financial access or outbound schema fetch is a critical stop.

| Case ID | Adversarial input/interleaving | Required invariant / expected result |
|---|---|---|
| A4-IAM-01 | No credential; malformed credential; unsupported scheme | Reject before principal is established; no Inbox/Job write |
| A4-IAM-02 | Expired credential at ingress | Reject; no durable event acceptance |
| A4-IAM-03 | Revoked credential with stale verifier/cache state | Revocation behavior matches approved consistency SLA; no acceptance after the defined revocation boundary |
| A4-IAM-04 | Correct signature but wrong issuer or audience | Reject; never fall back to another trust profile |
| A4-IAM-05 | Valid credential bound to Installation A presented for Installation B | Reject; no cross-installation authority |
| A4-IAM-06 | Credential rotation overlap, old key after retirement, unknown key ID | Only explicitly permitted rotation window accepted; unknown/retired key rejected; no secret in logs |
| A4-AUTH-01 | Tenant A principal changes tenant ID in path, query, header or body to B | Tenant remains server-bound; B data and even existence are not disclosed |
| A4-AUTH-02 | Tenant A references Tenant B event/installation/object ID | Object-level deny; no read, write or existence oracle |
| A4-AUTH-03 | Tenant admin invokes platform-only operation | Function-level deny; no privileged side effect |
| A4-AUTH-04 | Allowed operation attempts protected properties (tenantId, status, commission, role, createdAt) via mass assignment | Protected fields ignored/rejected; no unauthorized property mutation |
| A4-AUTH-05 | Response includes internal fields, credentials, raw payload or another tenant's metadata | Property-level response allowlist; sensitive/cross-tenant fields absent |
| A4-AUTH-06 | Membership or installation suspended between acceptance and worker execution | Worker re-checks required current state; defined policy prevents unauthorized processing |
| A4-AUTH-07 | Confused-deputy attempt via worker message carrying a forged tenant/install reference | Worker derives authority from durable trusted record and verifies binding; message fields alone confer no authority |
| A4-IDEM-01 | Same event delivered sequentially with same semantic payload | One durable InboxReceipt and one WorkItem; replay links to original outcome |
| A4-IDEM-02 | N concurrent identical deliveries on independent connections | Exactly one durable InboxReceipt/WorkItem pair; all other requests converge to duplicate outcome |
| A4-IDEM-03 | Same source identity, changed payload/fingerprint | Conflict; original immutable record unchanged; no second job |
| A4-IDEM-04 | Same event ID but different source, installation or tenant | Identity namespaces remain distinct only where contract says; no accidental global collision or cross-tenant dedupe |
| A4-IDEM-05 | Different raw JSON byte order/whitespace but same accepted semantic JSON | Result follows the explicitly selected fingerprint profile; raw digest and canonical digest remain distinguishable |
| A4-IDEM-06 | Duplicate JSON object member, invalid UTF-8, non-I-JSON number or out-of-profile numeric edge | Reject before canonicalization; no lossy parser normalization |
| A4-IDEM-07 | Unicode normalization variants, escaped/unescaped equivalent strings, surrogate edge cases | Behavior follows the pinned canonicalization standard; no undocumented Unicode normalization |
| A4-IDEM-08 | Client retry key differs while source-event identity is the same; or same retry key is reused for a different event | Source-event identity remains authoritative for event dedupe; request key cannot bypass uniqueness or merge distinct events |
| A4-PARSE-01 | Unknown CloudEvents source/type/extension/schema version | Fail closed; no remote lookup and no accepted durable work |
| A4-PARSE-02 | Payload supplies http(s), file, loopback, link-local, private, redirecting or DNS-rebinding schema URL | No resolver/network attempt; reject or treat as inert untrusted metadata according to contract |
| A4-PARSE-03 | Deep nesting, oversized body, huge arrays/strings, pathological numbers | Bounded rejection before unbounded CPU/memory/storage; no partial durable acceptance |
| A4-PARSE-04 | Content-Type mismatch, compressed body expansion, unsupported encoding | Reject or bounded decode according to explicit policy; enforce post-decompression limit |
| A4-PARSE-05 | Unknown extension, duplicate extension name or conflicting envelope/payload identity | Reject ambiguity; canonical envelope fields cannot be overridden by payload |
| A4-PARSE-06 | Schema artifact changes after event was accepted | Existing event retains immutable schema/version provenance; no mutable remote resolution at replay |
| A4-RES-01 | Request size exactly at approved limit and one unit above | Boundary accepted/rejected deterministically; limit values must be approved, not guessed |
| A4-RES-02 | Per-installation or per-tenant burst competes with another tenant | Fairness/backpressure follows approved quota policy; one tenant cannot consume global reserved capacity |
| A4-RES-03 | Concurrent requests exhaust DB pool/worker slots | Bounded queueing/rejection; no connection leak, unbounded retry storm or tenant starvation |
| A4-RES-04 | Repeated invalid authentication or parser failures | Rate/abuse controls bounded; sensitive details not disclosed; operational alerts attributable |
| A4-RES-05 | Retry-after/backoff and poison event behavior under repeated failures | Bounded retries, jitter/parking policy only if approved; poison event cannot block unrelated tenants |
| A4-DUR-01 | Crash/failure before transaction begins, after Inbox insert, after Job insert, immediately before commit | Transaction leaves neither row when not committed; no success ACK |
| A4-DUR-02 | Commit succeeds but response/ACK is lost | Retry resolves to same receipt/job; no duplicate pair |
| A4-DUR-03 | Transaction deadlock/serialization failure or unique-constraint race | Retry only at safe transaction boundary; one winner; no partial writes |
| A4-DUR-04 | Worker crashes before claim, after claim, during processing and before completion commit | Durable state supports safe recovery; no false terminal status |
| A4-DUR-05 | Lease expires; old worker resumes after a new worker acquires claim | Fencing/claim token rejects stale write; newer state is not overwritten |
| A4-DUR-06 | Duplicate/out-of-order queue notifications and repeated delivery | Queue is treated as hint; DB state controls claim; no duplicate durable processing transition |
| A4-DUR-07 | Poison/malformed internal job or deleted/mismatched referenced installation | Quarantine/fail closed; no tenant or financial side effect; alert contains correlation ID only |
| A4-DUR-08 | Restart/restore of disposable DB and worker after committed and uncommitted cases | Recovered state matches commit boundary; uncommitted work absent, committed work recoverable once |
| A4-DATA-01 | Synthetic secret/PII canary placed in payload then trigger success/error/exception | Canary absent from logs, traces, metrics labels and client error; raw payload not copied to evidence |
| A4-DATA-02 | Cross-tenant attempt produces errors and audit events | Response avoids object-existence leakage; security audit retains enough actor/tenant/correlation context without payload secrets |
| A4-DATA-03 | Privileged read/export of evidence and audit data by unauthorized principal | Denied and audited; least-privilege access; evidence artifacts have bounded retention |
| A4-DATA-04 | Retention expiry/deletion/backup restore scenario | Test only after approved policy; deletion and backup behavior produce verifiable evidence; no invented duration |
| A4-FIN-01 | Accepted event traverses ingress and worker path | No financial DB connection, query, command, service call or permission is available |
| A4-FIN-02 | Duplicate, conflict, retry, exception and replay variants | Zero wallet/ledger/payment/settlement/payout writes and zero economic-effect records for all paths |
| A4-FIN-03 | Forged commission/amount/currency/beneficiary fields included in synthetic event | Fields are not treated as authority or posting instruction; no financial calculation or mutation |

**Count:** 47 adversarial cases. Case numbering is stable; add cases rather than renumbering existing evidence references. A test may cover multiple cases only if its report identifies each case separately.

## 6. Test oracles and evidence requirements

Each case must define six independent oracles:

1. **Protocol oracle:** status/error class and externally observable response; avoid relying only on implementation-specific error text.
2. **Authorization oracle:** principal, trusted tenant/install binding, capability decision and object/property decision.
3. **Persistence oracle:** before/after rows and uniqueness assertions using independent DB reads; transaction outcome and commit boundary.
4. **Worker oracle:** claim token/lease, state transition, retry count, terminal/quarantine state and stale-write rejection.
5. **Boundary oracle:** DNS/network egress attempts, DB grants, financial service calls and outbound integrations.
6. **Privacy/audit oracle:** canary absence from logs/traces/errors; expected audit event and actor/correlation attribution.

Evidence bundle per run:
- repository, branch, exact tested commit SHA and clean/dirty state;
- test harness version, scenario catalogue version, fixture seed and case IDs;
- disposable environment ID, isolation policy and teardown result;
- DB/queue/runtime versions and relevant isolation/constraint configuration;
- command, start/end times, full result, counts, skipped/blocked cases and exit code;
- sanitized traces, transaction state assertions, DB permission snapshot and egress telemetry;
- financial connectivity/write telemetry and canary scan report;
- artifact checksums, reviewer, review date and explicit evidence scope.

Never include secrets, real partner/customer/player data, raw sensitive payloads or production identifiers. A PASS applies only to its exact case, environment and commit SHA.

## 7. Execution sequence and stop rules

| Order | Work package | Prerequisite | Exit evidence |
|---|---|---|---|
| 0 | Review and approve G09-A3/A4 scope, owners and threat model | Owner/security/operations sign-off | Signed decision records and bounded scope |
| 1 | Build disposable harness shell and prove isolation | A4-GATE-01, A4-GATE-05, A4-GATE-07 | P0 report; zero external/financial reachability |
| 2 | Implement test fixtures and identity/tenant boundary tests | A4-GATE-02 | P1 cases and reviewer approval |
| 3 | Add strict parser/registry tests and egress denial | Approved registry/schema profile | P2 cases; zero DNS/HTTP fetch attempts |
| 4 | Add actual DB transaction/uniqueness and concurrency tests | A4-GATE-03 | P3/P4 transaction traces and race evidence |
| 5 | Add worker lease/fencing/crash recovery tests | A4-GATE-04 | P4 recovery evidence |
| 6 | Add resource/privacy tests | A4-GATE-05/06 | P5 report with approved workload profile |
| 7 | Prove financial non-effect independently | A4-GATE-07 | P6 permissions, network and zero-write evidence |
| 8 | Independent adversarial review and closeout | All prior stages | Case-by-case disposition, residual risk and explicit owner decision |

**Immediate stop conditions:** any cross-tenant read/write or existence disclosure; authentication bypass; untrusted tenant override; duplicate durable job/receipt; ACK before commit; stale worker overwrite; outbound schema/network fetch; unbounded resource use; sensitive canary leakage; financial DB/service reachability or mutation; non-synthetic data/credentials; or environment isolation failure.

On stop: halt the run, preserve sanitized evidence, prevent automatic retries from continuing the unsafe scenario, isolate the disposable environment, notify designated reviewers and open a tracked finding. Do not “fix and rerun” without preserving the original failing evidence.

## 8. Severity and disposition

| Severity | Examples | Required disposition |
|---|---|---|
| Critical / Stop | Cross-tenant access, auth bypass, financial reachability/mutation, duplicate economic effect, external egress, secret/PII leakage, unbounded destructive resource behavior | Stop proof; security/owner review; root-cause and corrective evidence before rerun |
| High | Unauthorized function/property access, fingerprint ambiguity, duplicate durable work, stale worker overwrite, missing audit on privileged change | Block relevant gate; fix and retest affected plus regression cases |
| Medium | Incomplete audit context, weak alert attribution, recoverability gap without data/financial corruption | Record risk owner and remediation deadline; cannot waive a critical invariant |
| Low / Informational | Non-blocking tooling notices or documentation clarity issues | Track separately; do not inflate into security findings without evidence |

No severity may be downgraded solely because the environment is synthetic. Synthetic testing reduces exposure, not the significance of a demonstrated design flaw.

## 9. Required outputs before runtime implementation

G09-A4 is ready for owner review when:
- all 47 cases have an explicit owner, precondition, expected outcome and evidence oracle;
- test environment, database/queue candidate and isolation mechanism are selected through approved ADRs;
- the eight A4 gates are explicitly Accepted or clearly Blocked with accountable owners;
- no test requires real partner data, production credentials or financial access;
- bilingual parity and documentation CI pass on the exact PR head;
- security/QA/architecture review the harness threat model and test-oracle independence.

G09-A4 acceptance does **not** authorize partner integration or production runtime. Runtime implementation requires a separate owner-approved decision and scope, actual partner documentation/authorization for any adapter, and subsequent independent release gates.

## 10. Open questions

1. Who are the named accountable owners and reviewers for the eight A4 gates?
2. Which disposable persistence and queue candidates may be evaluated under LOT-TECH-ADR-001 / LOT-PROT-001?
3. What exact test-only identity profile can be safely used without implying production IAM approval?
4. What registry fixture and schema compatibility policy should be used for the synthetic event profile?
5. Which workload profile and numeric ceilings will be approved, and by whom?
6. What evidence retention/access policy applies to synthetic test artifacts?
7. Which finance/security reviewers attest to zero financial reachability?

Until resolved, relevant execution remains BLOCKED. No partner adapter, real credential, external sandbox request, commission calculation, financial posting, merge or deployment is authorized.

## 11. Reference standards and source material

- OWASP API Security Top 10 (2023), especially API1 BOLA, API2 Broken Authentication, API3 object-property authorization, API4 resource consumption, API5 function-level authorization, API7 SSRF, API9 inventory and API10 unsafe API consumption: https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- OWASP API Security Project: https://owasp.org/www-project-api-security/
- RFC 8785, JSON Canonicalization Scheme (JCS): https://www.rfc-editor.org/rfc/rfc8785.html — candidate canonicalization profile only; not an approved implementation choice. RFC 8785 is Informational and constrains inputs to I-JSON; it does not define application event identity or idempotency semantics.
- CloudEvents specification: https://github.com/cloudevents/spec — use the exact version pinned by LOT-EVENT-001; do not infer partner behavior from the generic specification.
- PostgreSQL transaction isolation documentation, only if PostgreSQL is later selected as a proof candidate: https://www.postgresql.org/docs/current/transaction-iso.html — reference material, not a database selection.
