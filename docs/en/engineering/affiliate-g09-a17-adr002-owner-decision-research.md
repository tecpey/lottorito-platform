# G09-A17 — ADR-002 Owner Decision Research & Recommendation Dossier

**Document ID:** LOT-AFFILIATE-G09-A17-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** RESEARCH / RECOMMENDATION ONLY — no owner decision, independent approval, candidate selection or runtime authorization  
**Baseline:** PR #76; inspected head `019b5edaeaf8e21f3d3a2b45335ebb4f849c6091`  
**Related:** ADR-002 v0.3.0; G09-A11 through A16; LOT-EVENT-001; LOT-API-001; LOT-TECH-ADR-001; LOT-QA-001; LOT-PROT-001  
**Authority:** Advisory analysis. Recommendations below are not defaults, policy, approval or permission to implement.

## 1. Executive disposition

This dossier analyzes the twelve unresolved owner decisions in G09-A15 against primary technical documentation, established distributed-systems research and failure-oriented engineering practice.

**Central conclusion:** ADR-002 is not blocked by the absence of a preferred database. It is blocked by unresolved business failure semantics and by the absence of candidate-specific evidence that a persistence authority can enforce the protocol under concurrency, ambiguous commit, failover, restore and stale-writer conditions.

Do not select a database, queue, cloud topology or numeric RPO/RTO before the owner has defined the supported failure model and loss tolerance. Do not weaken an invariant to fit a preferred product. Candidate documentation is a hypothesis source; disposable real-engine tests and independent observations are the acceptance evidence.

### Recommended work order

1. Freeze the logical identity and API semantics (OD-01, OD-02, OD-03, OD-11).
2. Obtain owner risk decisions and data-lifecycle constraints (OD-04, OD-08, OD-12).
3. Define authority, transaction and pair-integrity proof obligations (OD-05, OD-06, OD-07).
4. Define quarantine and installation lifecycle semantics (OD-09, OD-10).
5. Only after the above are approved or explicitly deferred with accepted impact, evaluate named persistence candidates (R1), design the synthetic harness (R2), and request separate authorization for isolated proof execution (R3).

This is a dependency order, not permission to skip A12 independent review or A4 gates.

## 2. Decision status and authority model

All OD-01..OD-12 remain **OPEN** until the accountable authority records a decision artifact. The role names in A15 are responsibility domains, not assigned individuals. No person is presumed to hold legal, finance, SRE, security or partner authority merely because this project currently has a small working team.

For each decision record:
- decision owner and consulted authorities;
- exact question and scope;
- selected option and rejected alternatives;
- evidence and assumptions;
- effective date, version and review trigger;
- residual risks and accepted failure modes;
- dependent ADR, API, test and operational artifacts.

If an accountable authority is unavailable, record **DEFERRED / BLOCKED**, the impact and the condition for reopening. Do not convert a recommendation into a default by omission.

## 3. Cross-cutting findings from research

### 3.1 A timeout is not an abort

A client that loses the commit response cannot infer whether the transaction committed. Google Spanner explicitly documents an UNKNOWN commit outcome and recommends a subsequent read; its transaction guarantees are product-specific and must not be generalized to another candidate. AWS's idempotent API guidance explains why a caller-provided request token, semantic binding and atomic recording of token plus mutation reduce retry ambiguity. [R1][R2]

**Lottorito implication:** preserve UNKNOWN as a first-class state; retry with the same identity; arbitrate against the original in-flight attempt; never treat a weak negative read as proof of abort.

### 3.2 Isolation labels do not replace schedule proofs

PostgreSQL Read Committed gives each command a snapshot as of command start; successive SELECTs in one transaction may observe different committed states. PostgreSQL also documents that unique constraints enforce key uniqueness and that foreign keys enforce references, but a foreign key alone does not prove mandatory reverse participation (every parent has exactly one child). [R3][R4]

**Lottorito implication:** specify the required observable history and prove the actual constraint/transaction design. Do not accept "we use a transaction", "serializable", or "upsert" as a complete proof.

### 3.3 A lease or epoch is not fencing unless the resource enforces it

PostgreSQL's failover guidance explicitly warns that the old primary must be informed it is no longer primary; otherwise both nodes may believe they are primary. It describes STONITH as one way to prevent this split-brain condition. Google's Chubby paper is useful background on lock-service design, but a lock service does not magically fence writes to an unrelated storage resource. [R5][R6]

**Lottorito implication:** prove stale-writer rejection at every protected write boundary, including ingress, worker, repair, administrative and migration paths. An epoch stored only in state that can itself be rolled back is insufficient.

### 3.4 "Exactly once" must be decomposed

HTTP's idempotent method definition concerns intended server effect, not a magical exactly-once network delivery guarantee. AWS's transactional outbox guidance warns that duplicate downstream messages can occur and consumers should be idempotent. [R7][R8]

**Lottorito implication:** separately define source-event deduplication, request-key replay, acceptance-pair uniqueness, outbox publication and future economic-effect identity. Do not claim exactly-once end-to-end processing.

### 3.5 Canonicalization is a versioned protocol, not a hash shortcut

RFC 8785 JCS requires I-JSON-compatible input, rejects duplicate property names, constrains number representation and preserves Unicode string data as-is. It is an informational RFC, not a mandate that Lottorito use JCS. [R9]

**Lottorito implication:** reject ambiguous JSON before ordinary object materialization; choose and version the fingerprint profile only after cross-language vectors and migration behavior are defined.

### 3.6 Evidence provenance matters

NIST SP 800-204D describes supply-chain security measures in CI/CD, including provenance and attestations. Jepsen's research practice tests whether real systems satisfy their documented consistency claims, rather than treating documentation as proof. [R10][R11]

**Lottorito implication:** retain source SHA, candidate version/configuration, deterministic fault schedule, independent oracle observations and signed disposition. CI validates configured checks; it is not a database durability oracle.

## 4. OD-01..OD-12 analysis and recommendations

The recommendations are deliberately conditional. They are proposed decision positions for review, not adopted policy.

### OD-01 — Source namespace and immutable event identity scope

**Question:** Who defines the source namespace, and what tuple identifies one source event without collisions or cross-tenant disclosure?

**Recommended position:** use a tenant- and installation-scoped composite identity, provisionally:
`(trusted_tenant_id, trusted_installation_id, approved_source_namespace, source_event_id)`.

- Derive tenant and installation from authenticated server-side configuration, never from payload claims.
- Maintain an approved source-namespace registry tied to a partner/integration contract.
- Treat source event ID as opaque and namespace-scoped; do not assume global uniqueness.
- Keep event identity separate from request Idempotency-Key and future economic-effect identity.
- Include event type, schema/profile and immutable binding data in the versioned fingerprint/conflict comparison, not as an accidental substitute for a stable identity key.
- Cross-tenant identity collisions must not trigger cross-tenant lookup or reveal record existence.

**Alternatives rejected:** global event_id uniqueness without source authority; payload hash as identity; tenant-only scope where one tenant can host multiple independent installations.

**Required evidence:** source contract; collision policy; same-ID/different-tenant tests; same-ID/different-installation tests; same-scope duplicate and conflict vectors.

**Owners:** product/domain, partner owner, security. **Blocks:** PO-01/02/05; S01/S02/S22.

### OD-02 — Request Idempotency-Key scope, binding and retention

**Question:** Which requests share a key namespace, what request is bound to the key, and how long is that binding retained?

**Recommended position:** scope request keys to the authenticated tenant, installation/client principal and API operation (including version where semantics differ). Bind each key to a versioned request fingerprint and stable outcome/reference. Reuse of the same key with different intent must produce a deterministic conflict, never replay an unrelated response.

- Keep request-key storage and retention distinct from source-event deduplication.
- Require clients to reuse the same key and source identity after timeout/UNKNOWN.
- Define late-arrival behavior and retention from actual partner retry contracts and operational/legal needs; do not invent a universal TTL.
- If the request key expires before source-event identity evidence, source-event dedupe must still prevent a second acceptance.

**Alternatives rejected:** globally scoped keys; key-only matching without payload binding; deriving identity solely from request body; silent acceptance of same key/different body.

**Required evidence:** same key/same request; same key/different request; different keys/same source event; concurrent duplicate; late-arrival and expiry tests.

**Owners:** API/platform, security, privacy. **Blocks:** PO-02/05; S01/S02/S05/S11/S23.

### OD-03 — Parser, duplicate-member policy, fingerprint and migration

**Question:** What exact bytes/semantic representation is compared, and how can that meaning evolve without reinterpreting historical events?

**Recommended position:**
1. Reject duplicate JSON object member names at the raw parser boundary before conversion to a map/object that could discard evidence.
2. Reject malformed Unicode and define numeric precision/range constraints.
3. Specify whether fingerprints cover raw bytes or a normalized semantic envelope. Prefer a versioned semantic profile only when the normalization rules are explicit and cross-language tested.
4. Evaluate RFC 8785 JCS as one candidate, not as an automatic selection. If chosen, satisfy I-JSON constraints, preserve Unicode code points as specified, and handle high-precision integers/decimals as strings or typed fields where required.
5. Persist the fingerprint profile/version with the accepted receipt. Never recompute old identity under a new algorithm without an explicit migration protocol.
6. Maintain golden vectors across every supported producer/consumer language.

**Alternatives rejected:** ordinary JSON.parse followed by hashing; implicit Unicode normalization; unversioned canonicalization; floating-point conversion of arbitrary financial/large integer values.

**Required evidence:** duplicate-member raw fixtures; Unicode edge vectors; number boundary vectors; cross-language canonicalization corpus; mixed-version deployment and migration tests.

**Owners:** architecture, security, integration. **Blocks:** PO-05; S02/S11.

### OD-04 — Failure model and acknowledged-commit durability promise

**Question:** Which failures must an acknowledged acceptance survive, and what RPO/RTO is acceptable for each class?

**Recommended position:** the owner must approve a failure-class matrix before a numeric durability promise is made. At minimum distinguish process crash, host loss, storage loss, availability-zone loss, region loss, operator error, logical corruption and restore/PITR. Define separately:
- acknowledgement durability condition;
- permitted acknowledged-data loss (RPO) per failure class;
- service restoration target (RTO);
- promotion eligibility and recovery-point rule;
- behavior when the durability acknowledgement itself is uncertain.

If the promise is zero acknowledged loss for a failure class, the selected candidate must not acknowledge before its documented durability condition for that class is met. If bounded loss is accepted, the owner must explicitly accept it and define the consequences for previously acknowledged work. Do not infer zero RPO from "synchronous" branding.

**Alternatives rejected:** a single undocumented "HA" label; numeric RPO/RTO copied from a vendor tier; treating backup as synchronous replication.

**Required evidence:** candidate write/flush/replication semantics; controlled loss immediately after acknowledgement; promotion and restore drills; acknowledged-identity comparison; cost and operational impact.

**Owners:** product owner, SRE/data platform, finance/risk. **Blocks:** PO-03; S08; A11-F01.

### OD-05 — Single-writer authority root and fencing

**Question:** What authority grants the right to mutate the acceptance domain, and how is a stale writer prevented from acting after failover or restore?

**Recommended position:** use a monotonic authority incarnation/epoch only as part of a complete fencing design. The protected persistence boundary must reject stale epochs or stale writer credentials. The authority root must not fork or roll back under the same partition/restore scenario it is meant to control.

- Explicitly identify the authority root and its own failure model.
- Fence old writers at storage/network/compute or another independently enforced resource boundary before promotion permits writes.
- Check the active epoch on every protected write path; include admin, repair, migration and background paths.
- Keep Persistence Authority Epoch separate from WorkItem Claim Generation.
- On restore, keep ingress and workers stopped until old writers and credentials are fenced and the recovered authority incarnation is re-established.
- A queue lease or advisory lock is not proof of storage fencing.

**Alternatives rejected:** database-local epoch counter that can be rolled back with the database; heartbeat-only primary election; lease expiry without resource-side enforcement.

**Required evidence:** partition, promotion, old-primary rejoin, restore rollback and stale-credential schedules; direct rejected-write evidence at the protected resource.

**Owners:** platform/SRE, security. **Blocks:** PO-04; S09/S10; A11-F02.

### OD-06 — Isolation, serialization and in-flight transaction arbitration

**Question:** What exact concurrency primitive makes simultaneous acceptance and UNKNOWN reconciliation converge on one result?

**Recommended position:** require a candidate-specific proof of one serialization point for the full source identity. The mechanism may be a unique constraint plus a transaction, serializable transaction, explicit lock, compare-and-swap or another primitive, but its complete behavior under concurrent insert, conflict visibility, abort, failover and retry must be demonstrated.

- The retry must arbitrate against the original attempt, not merely run a negative read and assume the original has ended.
- Receipt and WorkItem must be committed atomically.
- Reconciliation must inspect both pair cardinality and linkage in one consistent snapshot/atomic query.
- State the exact consistency mode for positive and negative reads.
- Do not require global serializability if a narrower proven serialization primitive satisfies the invariant; do not accept weaker isolation without schedule evidence.

**Alternatives rejected:** application read-then-insert; blind upsert; separate receipt/work-item transactions; two independent reads with unspecified snapshot semantics.

**Required evidence:** S01/S03/S04/S05/S06/S07; database transaction traces; deterministic barriers; authoritative reads; proof of uniqueness arbitration and conflict semantics.

**Owners:** data platform, architecture. **Blocks:** PO-01/02/04; A11-F03.

### OD-07 — Pair cardinality, linkage, repair and quarantine

**Question:** How is exactly one Receipt and exactly one WorkItem enforced, and who may repair an invariant breach?

**Recommended position:** enforce source-identity uniqueness, tenant/installation equality, WorkItem-to-Receipt referential integrity and at-most-one WorkItem per Receipt at the persistence boundary. Separately prove mandatory pair completeness; a one-way foreign key alone does not prove that every Receipt has a WorkItem. If the chosen engine cannot express the invariant declaratively, document and test the approved transactional/capability mechanism and its restore behavior.

A partial pair or broken link is an invariant breach:
- stop automated retry and worker pickup for the affected scope;
- preserve evidence;
- quarantine at the narrowest safe scope;
- repair only through an audited, separately authorized operation;
- never silently synthesize the missing half during normal retry.

**Alternatives rejected:** application-only checks; "eventually consistent repair"; automatic retry that guesses which half is missing; unbounded tenant-wide quarantine from one untrusted event.

**Required evidence:** attempts to commit each partial state; multiple WorkItems per Receipt; cross-tenant links; concurrent repair; restore and audit verification.

**Owners:** data platform, domain, security. **Blocks:** PO-01/06; S01/S03/S04/S12; A11-F04.

### OD-08 — Replay horizon, tombstones, backup/restore, deletion and legal hold

**Question:** For how long must the system recognize an old source event, and how does that identity evidence survive deletion, backup and tenant offboarding?

**Recommended position:** derive replay horizon from signed source retry/replay contracts, dispute windows, operational recovery needs and applicable legal/privacy requirements. Retain the minimum non-sensitive identity tombstone needed to prevent a second acceptance for at least the approved horizon, including backup/restore and offboarding effects.

- Define source-event and request-key retention separately.
- Specify behavior for replay before, at and after the horizon.
- Define how restore can resurrect old data or remove newer tombstones, and how the system reconciles that divergence before writes resume.
- Minimize retained payload/PII; identity tombstones should not become indefinite payload archives.
- Legal hold, deletion and retention exceptions require the relevant legal/privacy authority.

**Alternatives rejected:** arbitrary 30/90/365-day TTL; deleting dedupe state while accepting indefinite source replay; indefinite retention without legal basis; assuming offboarding safely deletes all replay evidence.

**Required evidence:** boundary replay tests; backup/PITR restoration; tenant offboarding; deletion and legal-hold workflows; proof that restore cannot silently reopen an already consumed identity.

**Owners:** privacy/legal, security, operations, owner. **Blocks:** PO-05; S11; A11-F06.

### OD-09 — Quarantine authority, scope, expiry, review and recovery

**Question:** Who may quarantine what, based on which evidence, and how is service safely restored?

**Recommended position:** use graduated containment: event identity first; installation/source partition only when evidence shows broader compromise; tenant-wide only when necessary and authorized. Require authenticated authority, reason code, evidence reference, immutable audit, expiry/review, and explicit recovery authorization.

- Untrusted payloads must not independently trigger broad quarantine.
- Define emergency authority and post-incident review.
- Make quarantine and worker claim compete through a proven serialization point.
- Preserve unaffected tenants and products.
- Define whether quarantine blocks ingress, claim, execution, or all three; these are distinct controls.

**Alternatives rejected:** one global quarantine flag; indefinite quarantine; operator action without evidence/reason; worker-side best-effort check outside the claim transaction.

**Required evidence:** S12 and blast-radius tests; stale claim rejection; expiry/recovery audit; cross-tenant non-interference.

**Owners:** security, operations, domain owner. **Blocks:** PO-06; S12; A11-F07.

### OD-10 — Installation suspension/revocation and previously accepted receipts

**Question:** What happens to new and already accepted events when an installation is suspended or revoked?

**Recommended position:** define a linearization point for revocation and distinguish:
- new ingress after revocation;
- ingress already in flight at revocation;
- accepted but unclaimed work;
- claimed/in-progress work;
- quarantined or legally held work.

A conservative starting proposal is: reject new ingress after the authoritative revocation point; preserve accepted history; do not silently delete or rebind accepted receipts; decide explicitly whether accepted-but-unprocessed work continues, pauses or is cancelled under an audited policy. The answer may differ for compromise, voluntary offboarding and legal suspension.

**Alternatives rejected:** retroactively treating all accepted events as never accepted; allowing stale credentials to continue; implicit cancellation or processing without policy.

**Required evidence:** revoke-versus-ingress and revoke-versus-claim schedules; credential revocation propagation; historical record preservation; explicit reason-coded transitions.

**Owners:** product/domain, security, partner owner. **Blocks:** PO-06; S12; A11-F07.

### OD-11 — Public UNKNOWN/unavailable response and retry guidance

**Question:** What can the caller safely infer from the wire response when commit or reconciliation is uncertain?

**Recommended position:** separate business outcome from transport status and make retry instructions machine-readable.

- Return success (for example, 202) only after confirmed durable acceptance under the approved OD-04 contract.
- For UNKNOWN or authoritative reconciliation unavailable, return a non-success response with an explicit machine-readable outcome such as `acceptance_outcome_unknown` or `acceptance_reconciliation_unavailable`. A 503 is a reasonable candidate for transient unavailability, subject to API/partner review; it must not imply confirmed abort.
- Tell the caller to retry using the **same source identity and same Idempotency-Key**. Never ask for a new identity/key to escape uncertainty.
- For a proven identity/fingerprint mismatch, return a conflict outcome; never replay an unrelated prior response.
- Do not expose internal topology, tenant existence, database errors or security controls.
- Document whether and when the caller can query a stable acceptance-status resource.

**Alternatives rejected:** 202 for UNKNOWN; 4xx that falsely implies the request was not applied; generic 500 with no retry contract; changing the key on retry.

**Required evidence:** OpenAPI/AsyncAPI response matrix; contract tests; client retry conformance; lost-response and unavailable-authority schedules; cross-tenant disclosure tests.

**Owners:** API/platform, owner, partner owner. **Blocks:** PO-02/07; A11-F08 and API response alignment.

### OD-12 — Evidence retention, access, integrity and independent review authority

**Question:** What evidence is retained, who can access it, how is integrity established, and who can issue an independent disposition?

**Recommended position:** require a tamper-evident evidence manifest for each proof run, containing source SHA/artifact hashes, candidate version/configuration, topology, harness and fixture versions, fault schedule, clock source, synthetic identities, authority/read mode, transaction/ack metadata, fault-point proof, independent oracle observations, expected/actual results, deviations and signed reviewer disposition.

- Separate operational logs from independent persistence observations.
- Minimize payload and personal data; retain only what is necessary under an approved schedule.
- Apply least-privilege access, access logging, integrity verification and controlled export.
- Define immutable retention, legal hold, deletion and reviewer access.
- Reviewer must be independent of design authorship and disclose competence/conflicts. If independence cannot be established, disposition is NOT ASSESSABLE.
- CI artifacts and a green status check are supporting provenance, not independent database correctness evidence.

**Alternatives rejected:** screenshots as sole proof; mutable logs without hashes; self-review labelled independent; evidence retention without privacy/access controls.

**Required evidence:** evidence schema and sample manifest; access-control test; hash/signature verification; retention/deletion test; signed finding-by-finding independent review.

**Owners:** security, privacy/legal, QA, owner. **Blocks:** all POs and R0–R4.

## 5. Priority, dependencies and decision sequencing

| Priority | Decisions | Why now | Exit condition |
|---|---|---|---|
| P0 — identity/API semantics | OD-01, OD-02, OD-03, OD-11 | Define what counts as the same event/request and what callers can safely do | Versioned source identity, key lifecycle, fingerprint profile proposal and response contract |
| P0 — risk authority | OD-04, OD-08, OD-12 | Durability and retention cannot be inferred by engineers or vendors | Owner-approved failure/lifecycle/evidence policies or explicit documented deferral |
| P1 — persistence correctness | OD-05, OD-06, OD-07 | Candidate must prove authority, serialization and pair integrity | Authority/fencing model and candidate-neutral proof criteria |
| P1 — lifecycle containment | OD-09, OD-10 | Prevent unsafe quarantine and revocation races | Authorized state machines and deterministic race semantics |
| P2 — candidate evaluation | R1 | Only now can candidates be compared against stable requirements | Candidate semantics dossier with evidence per PO |
| P2 — proof design | R2 | Harness must test the approved contract, not a moving target | Deterministic schedules, independent oracles and evidence manifest |
| P3 — isolated execution | R3 | Requires separate written authorization | Approved candidate, isolated synthetic environment and signed test scope |

P0/P1 labels are sequencing recommendations, not severity reclassification of A11 findings.

## 6. Candidate evaluation framework — no vendor ranking yet

When R1 is authorized, evaluate each candidate against the same weighted evidence sheet, but retain hard gates that cannot be compensated by a high aggregate score.

**Hard gates (fail = reject candidate or redesign contract):**
- atomic acceptance transaction and source-identity uniqueness;
- authoritative positive/negative read semantics and in-flight arbitration;
- documented commit acknowledgement durability and recovery-point behavior;
- single-writer fencing across promotion, rejoin and restore;
- pair cardinality/linkage enforcement;
- backup/restore behavior that preserves dedupe and authority safety;
- tenant isolation and restricted mutation capabilities;
- independent testability and operational evidence access.

**Comparative dimensions (score only after hard gates):**
- transaction/consistency semantics and contention behavior;
- failure-domain topology and recovery complexity;
- operational maturity, observability and upgrade safety;
- backup/PITR and restore rehearsal;
- latency/throughput under representative synthetic load;
- regional/data-residency fit;
- portability and exit strategy;
- total cost of ownership, staffing and 24/7 operational burden;
- ecosystem, tooling and integration complexity.

Do not publish numeric weights until the owner approves business priorities. Vendor claims, reference architectures and benchmark marketing are not substitutes for proof.

## 7. Required adversarial test strategy

Use the A15 S01–S12 schedule as the minimum persistence proof set, then add:
- property-based generation of same-key/different-payload and tenant-boundary cases;
- deterministic concurrency histories and linearizability/serializability checking where applicable;
- fault injection at every transaction boundary and acknowledgement boundary;
- restore from backups taken before and after tombstone/epoch changes;
- stale credential and old-primary write attempts against the actual enforcement point;
- negative assertions for zero writes, zero worker claims and zero downstream effects.

Use a test oracle independent of the application path: direct candidate-native authoritative reads, transaction/replication metadata, controlled network/fault evidence and independently collected traces. No one oracle is sufficient for every property.

Jepsen's approach is a useful model for testing real systems against consistency claims, but adopting Jepsen tooling is not mandatory; the required property and evidence are. [R10]

## 8. What this dossier does not decide

This dossier does not:
- select PostgreSQL, Spanner, CockroachDB, a queue, a cloud or topology;
- choose a numeric RPO/RTO, retention period, retry count, timeout or replica count;
- approve a parser library, JCS implementation, schema, physical data model or deployment;
- close A11-F01..F08 or A7/A8 extensions;
- constitute the A12 independent review;
- authorize R1/R2 execution, R3 runtime proof, partner integration, financial processing, merge or deployment.

## 9. Immediate next actions

1. Present OD-01..OD-12 to the accountable owner roles; record the actual named decision authority only when confirmed.
2. Resolve or formally defer P0 decisions with impact and reopening conditions.
3. Keep A12 independent review on its separate track; a decision dossier is not a reviewer sign-off.
4. After P0/P1 closure, produce a candidate-neutral R1 evidence template before naming products.
5. Update ADR-002, API contracts and A15 only from approved decisions; preserve the bilingual pair and rerun exact-head governance/contract CI.

**Final disposition:** G09-A17 is a researched recommendation dossier. All OD-01..OD-12 remain OPEN pending authorized decisions. ADR-002 remains PROPOSED; A11-F01..F08 remain OPEN; R0 remains BLOCKED; R1/R2 NOT STARTED; R3 NOT AUTHORIZED; all A4 gates remain NOT APPROVED.

## 10. Primary research and technical references

- [R1] Google Cloud Spanner Commit API — UNKNOWN commit outcome and subsequent read guidance: https://docs.cloud.google.com/workflows/docs/reference/googleapis/spanner/v1/projects.instances.databases.sessions/commit
- [R2] AWS Builders' Library — Making retries safe with idempotent APIs: https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- [R3] PostgreSQL — Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- [R4] PostgreSQL — Constraints (UNIQUE, PRIMARY KEY, FOREIGN KEY): https://www.postgresql.org/docs/current/ddl-constraints.html
- [R5] PostgreSQL — Failover and fencing/STONITH caution: https://www.postgresql.org/docs/current/warm-standby-failover.html
- [R6] Mike Burrows, The Chubby Lock Service for Loosely-Coupled Distributed Systems, OSDI 2006: https://research.google/pubs/the-chubby-lock-service-for-loosely-coupled-distributed-systems/
- [R7] IETF RFC 9110 §9.2.2 — Idempotent Methods: https://www.rfc-editor.org/rfc/rfc9110.html
- [R8] AWS Prescriptive Guidance — Transactional Outbox Pattern: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- [R9] IETF RFC 8785 — JSON Canonicalization Scheme: https://www.rfc-editor.org/rfc/rfc8785.html
- [R10] Jepsen — Distributed Systems Safety Research and consistency models: https://jepsen.io/ and https://jepsen.io/consistency/models/linearizable
- [R11] NIST SP 800-204D (2024) — Software Supply Chain Security in DevSecOps CI/CD: https://csrc.nist.gov/pubs/sp/800/204/d/final
