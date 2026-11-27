# Affiliate G09-A7 — 47-Case Traceability & Decision Closure Blueprint

**Document ID:** LOT-AFFILIATE-G09-A7-001 | **Version:** 0.1.0 | **Status:** Proposed; design only; all cases NOT RUN | **Date:** 2026-11-27

## 1. Purpose and authority

This artifact responds to A6-F01 and provides case-level closure contracts for A6-F02..F10. Every stable A4 case is bound to a fixture, deterministic stimulus, protocol/authorization expectation, persistence and financial assertions, independent oracle, evidence and status.

This is not executable code, a harness, runtime proof, technology ADR, security certification or execution approval. All cases remain NOT RUN. Policy-dependent cases are additionally BLOCKED. No runtime, database, queue, IAM, KMS/HSM, vendor, physical schema or numeric resource limit is selected.

## 2. Normative design contract

### 2.1 Mandatory atomic pair and optional publication outbox

The mandatory durable acceptance pair is **InboxReceipt + WorkItem**:
- InboxReceipt is the immutable record of accepted source-event identity, trusted installation binding, accepted fingerprint/profile version, schema provenance, acceptance time and correlation reference.
- WorkItem is exactly one durable processing-work record owned by the Affiliate ingress/processing domain and linked to that receipt.

Both records commit in one persistence transaction, or neither commits. Acceptance acknowledgement is permitted only after commit is known successful. If commit outcome is unknown to the caller, reconcile durable state by the approved source-event identity before retry; never blindly create another pair.

**DeliveryOutbox is not WorkItem.** If later needed for publishing a wake-up notification, it is a distinct conditional publication record with an assigned owner and its own documented atomicity boundary. It must not make WorkItem optional. Queue delivery is not authoritative state. Physical implementation remains an ADR decision.

### 2.2 Identity namespaces

Keep separate: (1) source-event identity, whose candidate tuple is trusted tenant + trusted installation + approved source namespace + event ID; (2) HTTP request idempotency key; (3) later economic-effect identity owned by a separately authorized financial command. The candidate source tuple remains unapproved until LOT-EVENT-001 and an actual partner contract establish its scope. Payload fields cannot establish tenant or installation authority.

Fingerprinting occurs only after strict parsing under an approved, versioned profile. RFC 8785 is only a candidate canonicalization component, not a complete ingress policy.

### 2.3 Synthetic fixtures

- F-IAM: synthetic issuer, key versions, valid/expired/revoked/unknown credentials and installation binding; no production secrets.
- F-TEN: Tenant-A/B, Installation-A/B, principals and active/suspended membership seeded server-side.
- F-EVT: local event registry, immutable schema versions and deterministic event/payload variants.
- F-DB: disposable persistence candidate after A4-GATE-03; independent connections and read-only observer role.
- F-WRK: two independently controlled workers, deterministic clock, lease/generation and fault hooks after A4-GATE-04.
- F-OBS: synthetic secret/PII canaries, sanitized telemetry and read-only evidence observer.
- F-NET: default-deny egress, observable DNS/connection attempts and isolated namespace.
- F-FIN: proof fixture with no financial credentials, grants, service bindings or routes; finance/security attestation required.
- F-LOAD: synthetic tenant workload and approved ceilings; no numeric values are invented here.
- F-DATA: approved synthetic classification, retention/deletion/backup/evidence policy; unavailable before A4-GATE-05.

### 2.4 Common assertions and immediate stop rules

Accepted event: exactly one InboxReceipt and one linked WorkItem; immutable identity/fingerprint/schema provenance; no ACK before commit; server-derived tenant/installation authority; zero Wallet/Ledger/Payment/Settlement/Payout connection, call, write or economic-effect row; no secret/raw prohibited payload in logs, traces, metric labels or evidence.

Rejected/conflict event: no new pair and no partial mutation, except where a case explicitly tests an already committed receipt.

Immediate stop on cross-tenant disclosure, unauthorized mutation, duplicate pair, stale-worker write, financial reachability/attempt, external schema/DNS fetch, secret leak, evidence tampering or unbounded resource growth. Preserve failed-run evidence before cleanup/retry.

### 2.5 Independent oracle catalogue

O-API: client-boundary response class/problem code. O-DB: independent read-only persistence inspection. O-TX: database-native transaction/constraint/lock evidence, only after DB ADR. O-IAM: independent synthetic issuer/verifier/key audit. O-WRK: worker generation audit plus independently observed durable row state. O-NET: network policy counters and DNS/connection telemetry. O-FIN: independent scan of credentials, grants, service bindings/routes and attempted-call sentinel. O-OBS: secret-canary scan across logs/traces/metrics/errors/evidence. O-LOAD: external workload driver and resource/tenant telemetry. O-DATA: independently verified deletion/backup/restore and evidence-access audit. O-SCHEMA: pinned schema digest and parser conformance vectors.

Evidence path convention: run-id/case-id/oracle-id/artifact. Each run manifest binds exact commit, A4/A5/A7 versions, harness version, fixture seed, policy/ADR versions, environment, tool versions, timestamps, case outcomes, artifact digests and reviewer. Raw credentials and unrestricted production-like payloads are prohibited.

## 3. The 47-case traceability and acceptance manifest

The rows below are design contracts, not implemented or passed tests. Response expectations use stable response classes; no HTTP code is invented where the upstream contract remains open.

| Stable A4 ID | Fixture and deterministic stimulus | Expected protocol / authorization | Persistence / financial assertions | Independent oracle and evidence | Status |
|---|---|---|---|---|---|
| A4-IAM-01 | F-IAM/F-DB; omit credential, then malformed credential and unsupported scheme. | Reject before principal establishment; no anonymous fallback. | No receipt/work pair; no financial access. | O-IAM/O-API/O-DB; verifier decision, response and state diff. | NOT RUN |
| A4-IAM-02 | F-IAM; submit expired credential. | Reject; do not resolve installation authority. | No new pair; no financial access. | O-IAM/O-API/O-DB; expiry decision and state diff. | NOT RUN |
| A4-IAM-03 | F-IAM; revoke credential while verifier/cache retains stale state; submit after approved revocation boundary. | Enforce owner-approved revocation consistency SLA; SLA is OPEN. | No pair after boundary; stale authority rejected. | O-IAM/O-API/O-DB; revocation time, cache version and state diff. | BLOCKED — POLICY |
| A4-IAM-04 | F-IAM; valid signature with wrong issuer, audience or trust profile. | Reject; no trust-profile fallback. | No pair; no financial access. | O-IAM/O-API/O-DB; issuer/audience decision. | NOT RUN |
| A4-IAM-05 | F-IAM/F-TEN; Installation-A credential presented for Installation-B. | Reject installation binding; caller cannot choose installation. | No B receipt/work or cross-installation read. | O-IAM/O-API/O-DB; binding snapshot and access audit. | NOT RUN |
| A4-IAM-06 | F-IAM; test rotation overlap, retired/unknown key ID and malformed key reference. | Only approved rotation window accepted; retired/unknown key rejected; no fallback. | No pair for rejected key; no secret leakage. | O-IAM/O-API/O-OBS; key-version decision and canary scan. | BLOCKED — KEY POLICY |
| A4-AUTH-01 | F-TEN; Tenant-A changes tenant ID in path, query, header and body to B. | Tenant remains server-bound; B object existence not disclosed. | No B read/write or unauthorized pair. | O-API/O-DB; per-vector authorization trace and B state. | NOT RUN |
| A4-AUTH-02 | F-TEN; Tenant-A references B event, installation and object IDs. | Object-level deny with non-enumerating response. | No B data returned/mutated; no unauthorized pair. | O-API/O-DB; object access matrix and state diff. | NOT RUN |
| A4-AUTH-03 | F-TEN; tenant administrator invokes platform-only function. | Function-level deny; no privilege escalation. | No privileged mutation or financial access. | O-API/O-DB; capability decision and state diff. | NOT RUN |
| A4-AUTH-04 | F-TEN; mass-assign tenantId, status, commission, role and createdAt. | Protected properties rejected/ignored per pinned contract; client values never authoritative. | Protected columns unchanged; no role/economic mutation. | O-API/O-DB; before/after protected-field snapshot. | NOT RUN |
| A4-AUTH-05 | F-TEN/F-OBS; response projection with internal, raw payload, credential and cross-tenant canaries. | Response allowlist excludes protected/internal/cross-tenant properties. | No mutation; canaries absent from response/telemetry. | O-API/O-OBS/O-DB; response diff and canary scan. | NOT RUN |
| A4-AUTH-06 | F-TEN/F-WRK; commit receipt/work, suspend membership/installation at barrier before worker check. | Follow owner-approved lifecycle rule (cancel/park/process under acceptance authority/reject); policy OPEN. | State matches approved race winner; no unauthorized work. | O-WRK/O-DB/O-API; barrier schedule, lifecycle audit, row versions. | BLOCKED — POLICY |
| A4-AUTH-07 | F-TEN/F-WRK; forge tenant/install/privilege fields in queue/job payload. | Worker derives authority from durable trusted receipt/binding; payload grants none. | No cross-tenant work or forged binding; no financial access. | O-WRK/O-DB/O-FIN; message digest, binding and state diff. | NOT RUN |
| A4-IDEM-01 | F-EVT/F-DB; sequentially replay same event and payload after commit. | Replay resolves to original stable outcome. | Exactly one receipt and one WorkItem; original immutable. | O-API/O-DB; responses and cardinality snapshot. | NOT RUN |
| A4-IDEM-02 | F-EVT/F-DB; barrier-synchronize N independent connections on same identity/fingerprint. | One accepted winner; others resolve deterministically as duplicates. | Exactly one pair; no partial rows. | O-TX/O-DB/O-API; barrier schedule, transaction trace, cardinality. | BLOCKED — DB ADR |
| A4-IDEM-03 | F-EVT/F-DB; same source identity with changed semantic payload/fingerprint. | Stable conflict; never overwrite original. | Original immutable; no second WorkItem. | O-DB/O-TX/O-API; fingerprints and conflict trace. | BLOCKED — FINGERPRINT ADR |
| A4-IDEM-04 | F-TEN/F-EVT; reuse event ID across source, installation and tenant combinations. | Follow approved namespace; no accidental global collision/cross-tenant dedupe. | No cross-tenant row association; uniqueness matches contract. | O-DB/O-API/O-TX; tuple matrix and uniqueness result. | BLOCKED — LOT-EVENT-001 |
| A4-IDEM-05 | F-EVT; permute JSON key order/whitespace while semantic content remains same under approved profile. | Follow pinned fingerprint profile; parse strictly before equivalence. | One identity; deterministic fingerprint/version; no second work. | O-SCHEMA/O-DB/O-API; raw/canonical digests and profile version. | BLOCKED — FINGERPRINT ADR |
| A4-IDEM-06 | F-EVT; duplicate object members, invalid UTF-8, out-of-profile numbers and parser ambiguity. | Reject before canonicalization; no last-key-wins ambiguity. | No accepted pair or lossy normalized payload. | O-SCHEMA/O-API/O-DB; byte vectors, parser diagnostics, state diff. | BLOCKED — PARSER POLICY |
| A4-IDEM-07 | F-EVT; Unicode normalization, escaped/unescaped and surrogate edge vectors. | Follow pinned profile; no undocumented Unicode normalization. | Deterministic cross-implementation fingerprint; no silent collision. | O-SCHEMA/O-DB; cross-language vectors and profile digest. | BLOCKED — FINGERPRINT ADR |
| A4-IDEM-08 | F-EVT; vary request idempotency key but retain event identity; reuse request key for another event. | Request key cannot bypass event dedupe or collapse distinct events. | Source identity remains authoritative; no duplicate pair/unintended merge. | O-API/O-DB/O-TX; request-key/event-identity matrix. | BLOCKED — API POLICY |
| A4-PARSE-01 | F-EVT/F-NET; unknown source/type/extension/schema version. | Fail closed; no remote schema lookup. | No pair; zero DNS/egress; no financial access. | O-SCHEMA/O-NET/O-DB; registry decision and network counters. | NOT RUN |
| A4-PARSE-02 | F-NET; provide http(s), file, loopback, link-local, private, redirecting and DNS-rebinding schema refs. | Treat as inert untrusted data or reject; never resolve/fetch. | No pair; zero DNS/HTTP/socket attempts. | O-NET/O-API/O-DB; DNS/firewall counters and vectors. | NOT RUN |
| A4-PARSE-03 | F-EVT/F-LOAD; deep nesting, oversized strings/arrays and pathological numbers. | Bounded rejection before unbounded resource use. | No partial pair; resource use within approved profile. | O-LOAD/O-SCHEMA/O-DB; vectors, resource telemetry, state diff. | BLOCKED — A4-GATE-06 |
| A4-PARSE-04 | F-EVT/F-LOAD; Content-Type mismatch, compressed expansion, unsupported encoding. | Reject or bounded decode per explicit policy; enforce wire and post-decompression limits. | No partial pair/parser bypass; no financial access. | O-LOAD/O-API/O-DB; encoded/expanded byte counts and response. | BLOCKED — PARSER/RESOURCE POLICY |
| A4-PARSE-05 | F-EVT; duplicate/unknown extension and envelope/payload identity conflict. | Reject ambiguity; payload cannot override canonical envelope identity. | No accepted pair or tenant/source reassignment. | O-SCHEMA/O-API/O-DB; envelope comparison and state diff. | BLOCKED — EVENT CONTRACT |
| A4-PARSE-06 | F-EVT; mutate local schema after acceptance, then replay/reprocess. | Existing event retains immutable accepted schema/version provenance. | Original schema digest/version retained; no mutable re-resolution/new work. | O-SCHEMA/O-DB; registry history, receipt snapshot and replay trace. | NOT RUN |
| A4-RES-01 | F-LOAD; body exactly at approved byte limit and one byte above. | Deterministic boundary; values only from approved quota profile. | Over-limit creates no pair; accepted boundary at most one pair. | O-LOAD/O-API/O-DB; byte counts, policy version and state. | BLOCKED — A4-GATE-06 |
| A4-RES-02 | F-LOAD/F-TEN; burst Tenant-A while Tenant-B submits baseline workload. | Fairness/backpressure follows approved quota; one tenant cannot consume reserved capacity. | No cross-tenant starvation or duplicate work. | O-LOAD/O-DB; per-tenant latency/rejection/queue metrics. | BLOCKED — A4-GATE-06 |
| A4-RES-03 | F-LOAD/F-DB/F-WRK; saturate DB pool and worker slots with bounded synthetic concurrency. | Bounded rejection/queueing; no connection leak, retry storm or starvation. | Durable invariants preserved; no duplicate pair. | O-LOAD/O-TX/O-DB; pool/queue telemetry, connection census. | BLOCKED — DB/QUEUE ADR + GATE |
| A4-RES-04 | F-IAM/F-LOAD/F-OBS; repeat invalid credentials and malformed parser requests. | Abuse controls bound work; no sensitive error detail. | No pair for rejected requests; no canary leakage. | O-LOAD/O-IAM/O-OBS; rate counters, response classes, scan. | BLOCKED — A4-GATE-06 |
| A4-RES-05 | F-WRK/F-LOAD; repeated transient failures and poison event beside healthy tenant work. | Retry budget/backoff/parking per approved policy; poison work cannot block other tenants. | No duplicate pair; bounded attempts; other tenant progresses. | O-WRK/O-LOAD/O-DB; attempt history, queue age, tenant progress. | BLOCKED — RETRY POLICY/GATE |
| A4-DUR-01 | F-DB; crash before transaction, after receipt insert, after work insert, immediately before commit. | No success ACK unless commit is known; safe failure on abort. | Before commit neither row survives; after commit both exist. | O-TX/O-DB/O-API; fault point, transaction trace, cardinality. | BLOCKED — DB ADR |
| A4-DUR-02 | F-DB; commit pair, drop response before client sees it, then retry same event. | Reconcile to original accepted outcome; never blind-create. | Exactly one pair; original correlation retained. | O-TX/O-DB/O-API; commit evidence, dropped-response marker, retry trace. | BLOCKED — DB ADR |
| A4-DUR-03 | F-DB; force unique-key race, deadlock and serialization abort across independent transactions. | One winner; retry only at safe whole-transaction boundary. | Exactly one pair; aborted transaction leaves no partial rows. | O-TX/O-DB; engine conflict/deadlock/serialization evidence. | BLOCKED — DB ADR |
| A4-DUR-04 | F-WRK/F-DB; crash worker before claim, after claim, mid-work and before completion commit. | Recovery follows durable state; no false terminal success; bounded retry. | Work remains recoverable or terminal only after durable completion; no duplicate effect. | O-WRK/O-DB/O-TX; crash point, state history, claim audit. | BLOCKED — DB/WORKER ADR |
| A4-DUR-05 | F-WRK/F-DB; W1 claims generation n; expire lease; W2 claims n+1; resume W1 and attempt every state-changing transition. | Every stale W1 write rejected; zero rows affected. | W2/terminal state and audit ownership unchanged by W1. | O-WRK/O-DB/O-TX; generation timeline and affected-row result. | BLOCKED — DB/WORKER ADR |
| A4-DUR-06 | F-WRK/F-DB; duplicate/out-of-order queue notifications, including replay after terminal state. | Queue is wake-up hint; DB state governs claim/transition. | One pair; no illegal regression or duplicate terminal transition. | O-WRK/O-DB; notification sequence and state history. | BLOCKED — QUEUE/WORKER ADR |
| A4-DUR-07 | F-WRK/F-TEN; corrupt job reference, mismatched tenant/install, missing installation or malformed internal payload. | Fail closed/park per approved policy; no confused deputy. | No cross-tenant mutation, financial access or fabricated receipt. | O-WRK/O-DB/O-FIN; payload digest, binding lookup and state diff. | BLOCKED — WORKER POLICY |
| A4-DUR-08 | F-DB/F-WRK; snapshot committed/uncommitted boundaries, restart/restore candidate and reconcile workers. | Recovery preserves commit boundary; committed work recoverable, uncommitted pair absent. | Exactly one committed pair; no orphan/duplicate; no financial effect. | O-TX/O-DB/O-WRK; snapshot digest, recovery log, reconciliation. | BLOCKED — DB/RESTORE ADR |
| A4-DATA-01 | F-OBS; inject synthetic secret/PII canary; exercise success, error, exception and retry. | Errors/telemetry sanitized; no raw payload echo. | Canary absent from logs/traces/metrics/evidence. | O-OBS/O-API; canary scan and telemetry digests. | NOT RUN |
| A4-DATA-02 | F-TEN/F-OBS; denied cross-tenant requests; inspect response and audit. | No object-existence leakage; audit retains only necessary actor/tenant/correlation context. | No B read/write; no secret/raw payload in audit. | O-API/O-DB/O-OBS; response diff, audit record, canary scan. | NOT RUN |
| A4-DATA-03 | F-OBS; unauthorized principal attempts evidence/audit read and export. | Deny and audit; least-privileged approved role only. | No evidence disclosure/mutation. | O-API/O-DB/O-OBS; access decision and audit trail. | BLOCKED — A4-GATE-05 |
| A4-DATA-04 | F-DATA; synthetic retention expiry, deletion, backup, legal-hold and restore. | Match owner/legal-approved lifecycle policy; policy currently absent. | Deletion/restore/evidence expiry verifiable; no invented duration. | O-DATA/O-DB; policy version, deletion proof, restore diff. | BLOCKED — POLICY |
| A4-FIN-01 | F-FIN/F-NET; traverse ingress/worker and probe DB grants, secrets, service bindings, DNS and routes. | No financial principal, credential, route, binding or reachable endpoint. | Zero financial connections/queries/calls/writes/economic-effect rows. | O-FIN/O-NET/O-DB; permission inventory, route scan, call sentinel. | BLOCKED — A4-GATE-07 |
| A4-FIN-02 | F-FIN; run duplicate/conflict/retry/exception/replay with financial sentinels. | All paths remain outside finance; any attempted call fails proof. | Zero Wallet/Ledger/Payment/Settlement/Payout mutations/effects. | O-FIN/O-DB/O-NET; per-path counters and financial snapshots. | BLOCKED — A4-GATE-07 |
| A4-FIN-03 | F-FIN/F-EVT; inject forged commission, amount, currency, beneficiary and payout fields. | Treat as untrusted data; no calculation/qualification/posting command. | No financial record, connection or call; no payload-derived authority. | O-FIN/O-API/O-DB; field handling trace and sentinel report. | BLOCKED — A4-GATE-07 |

**Count:** IAM 6 + AUTH 7 + IDEM 8 + PARSE 6 + RES 5 + DUR 8 + DATA 4 + FIN 3 = **47**. IDs are copied from the canonical A4 catalogue; renumbering is prohibited.

## 4. Deterministic concurrency and recovery schedules

These are abstract schedules. They become executable only after A4-GATE-03/04 and relevant persistence/worker ADRs.

### S1 — Concurrent duplicate ingress (A4-IDEM-02)
1. Seed no receipt/work for event identity E.
2. Start N independent ingress transactions/connections; pause before uniqueness decision.
3. Release all at one barrier.
4. Allow each transaction to commit or receive engine conflict.
5. Reconcile every caller response to authoritative identity E.
6. Independently inspect persistence and transaction trace.

Pass: exactly one InboxReceipt and one linked WorkItem; one commit winner; no orphan; losers receive deterministic duplicate/conflict result; no acceptance response before commit. N is an approved test parameter, not set here.

### S2 — Unknown commit outcome (A4-DUR-02)
1. Commit the pair for E.
2. Drop response after commit but before client observes it.
3. Client retries using approved source identity/request retry contract.
4. Ingress reconciles durable state before create.
5. Independent observer checks cardinality and provenance.

Pass: retry resolves to original pair; no blind retry, second pair or changed fingerprint. Timeout alone is not proof of rollback.

### S3 — Stale worker fencing (A4-DUR-05)
1. W1 atomically claims J at generation n and pauses.
2. Lease expires under deterministic clock.
3. W2 atomically claims J at generation n+1 and advances state.
4. Resume W1; attempt heartbeat, success, retry, failure and audit-owner changes with generation n.
5. Independently inspect every write result and durable row/audit history.

Pass: every stale W1 state-changing write affects zero rows and cannot alter state, terminal result, current owner or authoritative audit ownership. Lease expiry without a new generation is not fencing.

### S4 — Atomic-pair crash matrix (A4-DUR-01)
Inject process/connection termination before transaction, after receipt insert, after WorkItem insert, immediately before commit, immediately after commit and after commit before ACK. Independently capture actual engine outcome.

Pass: before successful commit neither row is visible after recovery; after commit both are visible; no ACK for uncommitted pair. Application logs alone are not the oracle.

### S5 — Tenant lifecycle race (A4-AUTH-06)
Barrier after atomic acceptance and before worker authorization; change membership/installation lifecycle state; release worker. Run only after owner approves lifecycle policy and consistency boundary.

Pass: behavior exactly matches approved policy and revocation SLA, consistently across worker replicas.

## 5. Decision closure register for A6 findings

Documenting a decision does not approve it. Accountable owners and evidence remain required.

| Finding | Required decision/artifact | Accountable roles | Closure evidence | Current state |
|---|---|---|---|---|
| F01 | This 47-row manifest; versioned test-case schema; stable-ID lint; per-case oracle/evidence. | QA, Architecture, Security | 47/47 validated; required fields; unique IDs; bilingual semantic parity; NOT RUN preserved. | ARTIFACT ADDED; independent review pending |
| F02 | Approve InboxReceipt + WorkItem mandatory pair; define optional DeliveryOutbox owner/publication boundary; align A4/A5/API terms. | Domain Architecture, Data/Platform, Owner | Decision record and cross-document consistency review; no physical schema implied. | PROPOSED |
| F03 | Persistence ADR; transaction schedules; unknown-commit reconciliation and safe retry semantics. | Data/Platform, Architecture, SRE, QA | Candidate engine documentation, deterministic race schedules, independent engine trace plan. | BLOCKED — ADR |
| F04 | Worker claim/fencing ADR for generation, lease, owner and every conditional transition. | Architecture, Data/Platform, SRE, QA | All stale transitions independently shown to affect zero rows in actual candidate engine. | BLOCKED — ADR |
| F05 | LOT-EVENT-001 namespace decision; strict parser policy; fingerprint profile/version and cross-language vectors. | Event Domain, Partner Integration, Security, Owner | Actual partner contract when available; approved policy; deterministic vectors/conflict semantics. | BLOCKED — CONTRACT/POLICY |
| F06 | Membership/installation suspension semantics; acceptance-time vs execution-time authority; revocation SLA/race winner. | IAM/Domain, Security, Product Owner | Explicit transition table, consistency boundary, SLA and audit requirements. | BLOCKED — OWNER POLICY |
| F07 | Financial non-reachability matrix for grants, credentials/secrets, service graph, network/DNS, queue authority and telemetry. | Finance, Security, Platform/SRE, Architecture | Independent negative probes; zero reachable paths/attempted mutations; recorded attestations. | BLOCKED — A4-GATE-07 |
| F08 | Workload profile, tenant distribution, fairness objective, limits, retry budget, saturation/recovery and stop thresholds. | SRE, Security, Product, Owner | Approved numeric profile, metrics and repeatable workload/stop plan. | BLOCKED — A4-GATE-06 |
| F09 | Per-case oracle independence, evidence provenance, artifact integrity/access/expiry policy. | QA, Security, SRE, Privacy/Legal | Oracle source/trust boundary per row; evidence chain and tamper detection validated. | PARTIAL — MATRIX IN MANIFEST; POLICY OPEN |
| F10 | Data classification, retention/deletion, backups, legal hold, restore and evidence expiry. | Privacy/Legal, Security, Operations, Owner | Approved lifecycle policy and synthetic deletion/restore acceptance plan. | BLOCKED — A4-GATE-05 |

### F01 acceptance checklist
- Exactly 47 unique canonical A4 IDs; no missing, extra or renumbered IDs.
- Every row has fixture, stimulus, protocol result, authorization result, persistence assertions, financial non-effect, independent oracle, evidence and status.
- Policy-dependent rows name the exact blocker; no guessed values.
- Status vocabulary only: NOT RUN, BLOCKED — reason, PASS, FAIL, INCONCLUSIVE. Only a gated run with preserved evidence may set PASS/FAIL.
- Future run manifest pins manifest version and source commit.
- CI lint must fail on duplicate/unknown IDs, missing fields or accidental status promotion.

## 6. Resource governance measurement contract

When A4-GATE-06 is reviewed, approve wire and decompressed request limits; parser depth/array/string/numeric bounds; per-installation/tenant admission; global reserved capacity; DB connection and worker budgets; queue age/depth; retry budget/backoff/jitter; poison handling; fairness objective; test duration/tenant mix; warm/cold behavior; saturation/recovery criteria and stop thresholds.

Measure at least accepted/rejected throughput, p50/p95/p99 latency, CPU/memory, parser cost, DB pool occupancy/wait, lock/conflict rate, queue depth/age, attempts per event, per-tenant service share, starvation duration and recovery time. Values must come from approved workload/SLO evidence, not guesses in this document.

## 7. Financial non-reachability assurance matrix

| Path | Required negative proof | Independent evidence |
|---|---|---|
| DB credentials/roles | No credential present; no grant/schema visibility/write privilege to financial stores. | Secret inventory and independent DB role/grant inspection. |
| Secret/config distribution | No wallet/ledger/payment/payout secret mounted, injected or retrievable. | Workload identity/config/secret mount inventory; denied canary retrieval. |
| Service dependencies | No client, SDK, service binding or indirect command path to financial services. | Dependency graph/runtime binding inventory and attempted-call sentinel. |
| Network/DNS | No route, egress exception or resolvable internal financial endpoint. | Network policy export, DNS telemetry, connection probes and deny counters. |
| Queue/message authority | Queue payload cannot instruct financial mutation or establish tenant authority. | Payload schema/consumer map, forged-command negative tests, worker authorization audit. |
| Shared infrastructure | No privileged shared credential or sidecar bridges to finance. | Process/container identity, sidecar, service mesh and workload policy review. |
| Observability/evidence | No financial secret/customer data leaks through logs/traces/artifacts. | Secret-canary scan and evidence allowlist audit. |

Any failed negative probe, reachable financial endpoint or attempted financial mutation is hard FAIL and STOP. Absence of observed traffic alone does not prove absence of reachability.

## 8. Standards and engineering references

Use stable, version-pinned requirements; do not silently follow bleeding-edge content:
- OWASP ASVS **5.0.0 stable** as application-security verification catalogue. Security must map exact controls and use version-qualified IDs such as v5.0.0-...; this manifest does not claim ASVS compliance.
- OWASP API Security Top 10 (2023) as threat taxonomy, not certification.
- RFC 8785 as candidate JSON canonicalization; strict parser, duplicate-member rejection and numeric/Unicode policy are separate decisions.
- CloudEvents 1.0.2 as envelope semantics, not partner contract or trust decision.
- PostgreSQL transaction isolation, explicit locking and INSERT/ON CONFLICT docs only if PostgreSQL is selected; verify behavior against selected version.
- AWS Transactional Outbox as pattern reference, not an AWS or queue mandate.
- Google SRE overload/retry guidance as operational design reference; numeric retry budgets require project SLO and owner approval.
- NIST SP 800-204D as DevSecOps/software-supply-chain security reference for provenance and pipeline assurance.

Official references:
- https://asvs.owasp.org/
- https://github.com/OWASP/ASVS/releases
- https://owasp.org/API-Security/
- https://www.rfc-editor.org/rfc/rfc8785
- https://cloudevents.io/
- https://www.postgresql.org/docs/current/transaction-iso.html
- https://www.postgresql.org/docs/current/explicit-locking.html
- https://www.postgresql.org/docs/current/sql-insert.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- https://sre.google/sre-book/handling-overload/
- https://csrc.nist.gov/pubs/sp/800/204/d/final

## 9. Gate and release disposition

G09-A7 provides a case-level design manifest and proposed decision closure path. Recording F02–F10 does not close owner/security/architecture decisions. F01 is ready for independent review, not independently accepted.

Still blocked: all runtime implementation/test execution including disposable DB/queue; final event identity/parser/fingerprint/lifecycle/retention/resource policies; DB/queue/IAM/KMS/HSM/vendor selection absent ADR; partner adapter/real credentials/external sandbox/commission/financial posting; merge/deploy/production readiness.

Before proposing runtime proof, all eight A4 gates must be explicitly approved by accountable owners, relevant A6 findings closed, technology ADRs accepted, and QA/Security/Finance/SRE reviewers assigned. Approval must be recorded and cannot be inferred from CI.

## 10. Limitations

This is a technology-neutral test-design artifact derived from A4's canonical catalogue and A5/A6 findings. It has not been executed and proves no database, queue, IAM, network policy, worker or financial boundary. Green documentation CI validates only configured documentation/contract checks on the exact commit.


## 11. G09-A8/A9 adversarial subcase extension — design only

The twenty-one subcases below extend existing stable A4 cases without changing the canonical 47-case count or IDs. They are proposed traceability additions, not executed tests. All remain NOT RUN; policy/ADR-dependent cases are additionally blocked.

| Subcase ID | Parent A4 ID | Deterministic challenge | Required assertion | Independent oracle/evidence | Status |
|---|---|---|---|---|---|
| A8-DUR-05a | A4-DUR-05 | Lease expires; old worker attempts a guarded transition before any new claimant increments generation. | Expired lease fails the guard at the linearization point; zero protected-row changes. | O-DB/O-TX/O-WRK; authoritative time, transaction ordering, affected-row count. | BLOCKED — ADR-001 / DB TIME & LOCK SEMANTICS |
| A8-DUR-05b | A4-DUR-05 | Heartbeat races with expiry and a second worker's reclaim. | One serialized winner; heartbeat cannot resurrect an expired lease; generation advances only for successful reclaim. | O-DB/O-TX/O-WRK; barrier schedule, generation timeline, lease values. | BLOCKED — ADR-001 / DB TIME & LOCK SEMANTICS |
| A8-DUR-05c | A4-DUR-05 | Old worker attempts completion after generation increments and after process restart. | Old owner/token/generation changes zero protected rows; no state regression. | O-DB/O-TX/O-WRK; durable row history, old-token attempt and affected-row count. | BLOCKED — ADR-001 / WORKER PROTOCOL |
| A8-DUR-08a | A4-DUR-08 | Restore durable state while an old worker/process may still be alive. | Claims remain stopped until old workers/identities are fenced and a non-reusable recovery incarnation is established. | O-WRK/O-IAM/O-DB/O-OBS; restore attestation, identity revocation, incarnation and rejection evidence. | BLOCKED — RESTORE/RECOVERY ADR |
| A8-AUTH-06a | A4-AUTH-06 | Suspension/revocation commits between lifecycle read and worker transition. | Owner-approved lifecycle linearization policy is enforced atomically or by version-conditioned serialization. | O-DB/O-TX/O-WRK/O-IAM; lifecycle version, barrier timeline and state diff. | BLOCKED — OWNER LIFECYCLE POLICY |
| A8-DUR-02a | A4-DUR-02 | Commit outcome unknown while primary is unavailable and a replica may be stale. | No false absence or acceptance; indeterminate result until authoritative reconciliation is possible. | O-DB/O-TX/O-API; primary/replica consistency evidence, retry outcome and cardinality. | BLOCKED — PERSISTENCE/RECONCILIATION ADR |
| A8-FIN-01a | A4-FIN-01 | Attempt indirect financial capability through service discovery, workload identity, secret mount or metadata route. | Denied at independently observed enforcement points; no credential, connection, call or financial effect. | O-FIN/O-NET/O-OBS/O-DB; capability inventory, denied probes and secret-canary scan. | BLOCKED — A4-GATE-07 / SECURITY-FINANCE ATTESTATION |
| A8-DATA-04a | A4-DATA-04 | Evidence deletion/expiry races with backup/restore and legal-hold state. | Outcome follows approved lifecycle policy and is independently evidenced across primary, backup and evidence stores. | O-DATA/O-DB/O-OBS; policy version, deletion/restore evidence and access audit. | BLOCKED — A4-GATE-05 / DATA LIFECYCLE POLICY |


| A11-DUR-02b | A4-DUR-02 / A4-IDEM | Original commit remains in flight while same-identity retry starts. | Exactly one pair; retry cannot bypass unique arbitration. | O-DB/O-TX/O-API; deterministic barriers, transaction state and final cardinality. | BLOCKED — ADR-002 |
| A11-DUR-02c | A4-DUR-02 | Original transaction aborts while retry races. | At most one successful pair; loser resolves final durable state. | O-DB/O-TX; abort/commit schedule and pair cardinality. | BLOCKED — ADR-002 |
| A11-DUR-08b | A4-DUR-08 | Primary acknowledges local commit but failover candidate lacks the write. | No false durability claim; behavior follows explicit acknowledged-write RPO. | O-DB/O-TX/O-OBS; replication acknowledgement and recovery-point evidence. | BLOCKED — ADR-002 |
| A11-DUR-08c | A4-DUR-08 | Old primary returns after promotion and attempts a write. | Old authority epoch rejected; no split-brain acceptance. | O-DB/O-NET/O-OBS; epoch and fencing evidence. | BLOCKED — ADR-002 |
| A11-DUR-08d | A4-DUR-08 | Promotion occurs while commit response is lost. | UNKNOWN until new authority is fenced and durability reconciliation completes. | O-DB/O-TX/O-API; promotion timeline and authoritative state. | BLOCKED — ADR-002 |
| A11-IDEM-09 | A4-IDEM-08 | Replay arrives after event identity expiry/deletion. | Result follows approved replay horizon/tombstone policy. | O-DB/O-DATA; retention and backup/restore evidence. | BLOCKED — ADR-002 |
| A11-IDEM-10 | A4-IDEM-08 | Same source identity arrives under changed fingerprint/parser version. | Version-aware conflict; no silent reinterpretation. | O-API/O-DB; parser/fingerprint version evidence. | BLOCKED — ADR-002 |
| A11-AUTH-08 | A4-AUTH-08 | Poisoned event attempts broad quarantine. | Graduated containment; unrelated tenants remain serviceable. | O-IAM/O-DB/O-OBS; scope audit and noisy-neighbor evidence. | BLOCKED — ADR-002 |
| A11-WRK-01 | A4-AUTH-08 / A4-DUR-05 | Quarantine races with worker claim. | One serialized winner; no pickup after quarantine boundary. | O-DB/O-TX/O-WRK; barrier schedule and claim result. | BLOCKED — ADR-002 |
| A10-DUR-02d | A4-DUR-02 | Faulted application path commits only Receipt or only WorkItem. | Commit-time/capability invariant rejects partial acceptance. | O-DB/O-TX; fault injection and cardinality query. | BLOCKED — ADR-002 |
| A10-DUR-02e | A4-DUR-02 | Receipt and WorkItem read in separate snapshots during concurrent acceptance. | One consistent snapshot/atomic query; no false partial-pair diagnosis. | O-DB/O-TX; snapshot/statement trace. | BLOCKED — ADR-002 |
| A10-AUTH-06b | A4-AUTH-06 | Same source namespace/event ID arrives from two authenticated tenants. | Tenant-scoped isolation; no cross-tenant lookup/disclosure. | O-IAM/O-DB/O-API; principal/tenant binding and query audit. | BLOCKED — ADR-002 |
| A10-IDEM-08a | A4-IDEM-08 | Same request key reused with changed body; different keys retry one source event. | Changed body conflicts; different keys converge on one pair. | O-API/O-DB/O-TX; key binding and pair cardinality. | BLOCKED — ADR-002 |

### Temporal protocol reference

Proposed LOT-AFFILIATE-G09-ADR-001 defines a durable per-WorkItem claim generation, authenticated owner/token, persistence-authoritative guarded transition, lease-expiry linearization rule and restore/recovery fence. It remains PROPOSED and requires owner approval, independent review and candidate persistence semantics. It does not select a database or authorize runtime execution.

Subcases are mapped to their parent cases; they do not add to the canonical 47-case total. ADR-002 v0.3.0 adds authority-epoch fencing, acknowledged-commit durability/RPO, retention-bounded dedupe, quarantine containment and acceptance-versus-execution response semantics. The future runner must report parent and subcase outcomes separately so a passing parent cannot hide a failed interleaving.

<!-- ADR-002 A11 case traceability extension is maintained in the bilingual A11 review record. -->
