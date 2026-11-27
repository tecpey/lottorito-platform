# Affiliate G09-A11 — ADR-002 Adversarial Design Review

**Document ID:** LOT-AFFILIATE-G09-A11-001  
**Related decision:** LOT-AFFILIATE-G09-ADR-002  
**Version:** 0.1.0 | **Date:** 2026-11-28  
**Status:** Same-workflow adversarial self-review — NOT independent sign-off; no runtime execution  
**Reviewed artifact:** ADR-002 v0.1.0 on PR #76 head 985cfee7ce233e6297b7de2d5d2339d8484b843e  
**Scope:** Atomic ingress acceptance, unknown commit, authoritative reconciliation, failover and identity retention.

## 1. Disposition

**DESIGN REVIEW — MATERIAL GAPS; ADR-002 MUST REMAIN PROPOSED.**

ADR-002 correctly identifies unknown commit as a distinct state, rejects blind retries and stale-replica absence checks, and separates the mandatory InboxReceipt + WorkItem pair from optional DeliveryOutbox. The current text does not yet fully define the durability meaning of an acknowledged commit across failover, the authority/fencing transition between old and promoted primaries, or the race between a negative reconciliation read and an in-flight transaction. The idempotency guarantee also has no explicit temporal boundary while identity retention is open.

This review was produced in the same assistant workflow that authored ADR-002. It is a **self-review**, not an independent reviewer approval. A reviewer who did not author ADR-002/A11 must independently challenge and disposition every finding.

No runtime, database, queue, source implementation, infrastructure, IAM, partner endpoint or harness was inspected or executed. Findings are design-level, not empirical defects in a deployed system.

## 2. Review method

The review challenged acknowledged commit versus crash/failover durability; primary authority epochs, split-brain exclusion and old-primary fencing; negative reconciliation reads racing with in-flight commits; pair cardinality and referential invariants; identity/fingerprint conflict semantics; deduplication horizon, retention and replay after deletion; quarantine blast radius and denial-of-service potential; and evidence needed to prove each property.

Reference material was checked against current official documentation, including Google Cloud Spanner's unknown-commit guidance and PostgreSQL's high-availability, synchronous/asynchronous replication and WAL durability documentation. These are comparative references, not technology selections.

## 3. Findings

| ID | Severity | Finding | Required closure |
|---|---|---|---|
| A11-F01 | Critical | **“Confirmed commit” is underspecified across failover.** A primary may acknowledge a locally durable commit that has not reached the replica later promoted. After failover the new authority can legitimately lack the pair. An acknowledged acceptance could then disappear, and retry may create a new WorkItem. | Define the exact durability class required before success acknowledgement, including local persistence, synchronous replication/consensus acknowledgement, failover eligibility and documented RPO. If acknowledged ingress must survive any permitted failover, require a zero-loss commit contract for that failure set. Otherwise explicitly define the accepted loss window and prohibit downstream execution/acknowledgement claims inconsistent with it. |
| A11-F02 | Critical | **Authority transition and split-brain fencing are not specified.** “Primary unavailable” and “authoritative read” presume one current writer. During promotion, partition or delayed old-primary recovery, old and new authorities may both accept writes unless an external fencing/epoch mechanism prevents it. A unique constraint on each isolated writer does not provide global uniqueness. | Define a monotonically advancing, non-reusable authority/recovery epoch or equivalent consensus-backed single-writer fence. Every ingress write and reconciliation decision must be bound to the current epoch. Promotion requires old-writer termination or cryptographic/network/storage fencing before new writes. Old-primary rejoin must remain read-only/quarantined until reconciliation and explicit re-admission. Prove no overlapping write authority. |
| A11-F03 | Critical | **A negative authoritative read is not by itself proof that an earlier in-flight commit cannot still become visible.** C11 says re-enter the atomic operation after a read proves no pair. If an earlier transaction is still unresolved, the safety argument depends on same-authority uniqueness arbitration and transaction visibility/serialization semantics. Across failover, epoch fencing is also required. | Replace “read proves no pair” with “read found no pair at a documented consistency point; absence is provisional.” Re-enter only through the same unique-key atomic operation on the currently fenced writer. The uniqueness/serialization primitive must arbitrate against all still-live attempts. If the old attempt may still commit outside that authority, remain UNKNOWN until it is resolved or fenced. Add deterministic tests for delayed commit versus retry, abort versus retry, and promotion during commit. |
| A11-F04 | High | **Exactly-one pair is stated logically but its cardinality enforcement is not fully decomposed.** Atomic transaction alone does not prevent multiple WorkItems referencing one receipt if the persistence model lacks a uniqueness invariant on the relationship; nor does it define orphan detection across restore/corruption. | Require independent persistence invariants: unique source identity for Receipt; unique WorkItem-to-Receipt relationship; enforceable referential integrity or equivalent; tenant/installation consistency across both records; and a reconciliation query that detects zero, one or multiple linked WorkItems. Candidate schema/constraints remain deferred to a DB ADR. |
| A11-F05 | High | **Identity conflict depends on an unspecified fingerprint profile.** “Same approved immutable binding/fingerprint” is not executable until canonicalization, field allowlist, versioning, duplicate JSON member behavior, Unicode/number semantics and raw-versus-semantic payload treatment are approved. | Bind ADR-002 to LOT-EVENT-001 and a dedicated fingerprint/canonicalization decision. Define fingerprint version and immutable fields; reject parser ambiguity before fingerprinting. A version migration must not silently reinterpret old events. Until then, duplicate-vs-conflict behavior remains BLOCKED. |
| A11-F06 | Critical | **Idempotency has no declared temporal boundary.** If the Receipt/identity tombstone is deleted or expires, a late replay may be accepted as new. “Never create a second pair” is only enforceable while the identity uniqueness evidence remains available or an equivalent compact tombstone survives. | Define a source replay horizon from a real partner contract and business/legal requirements; retain dedupe identity/tombstone for at least that horizon, including backup/restore and tenant offboarding behavior. If the source can replay indefinitely, preserve a non-sensitive durable tombstone indefinitely or explicitly weaken the guarantee. Request-key retention and source-event dedupe retention must remain distinct. |
| A11-F07 | High | **Quarantine “affected scope” is ambiguous and can become a denial-of-service lever.** A malicious or malformed event could trigger a broad tenant/installation stop if scope is not bounded; too narrow a scope could leave corrupt work executable. | Define a graduated containment hierarchy: event identity → installation/source partition → tenant boundary only when blast radius evidence requires it. A partial pair must be made ineligible for worker pickup through an independent guard. Quarantine changes require authenticated authority, audit, expiry/review and recovery procedure. Add noisy-neighbor/targeted-poisoning tests. |
| A11-F08 | High | **Commit success, acceptance success and work execution are not distinguished enough in response semantics.** A successful durable acceptance does not mean WorkItem has been claimed or processed. Client retries must receive a stable acceptance result without learning worker state or causing re-execution. | Specify response as “accepted/durably recorded” only; stable opaque receipt/reference; no promise of processing completion. Duplicate response is derived from the durable acceptance record and must not re-enqueue a second WorkItem. Define behavior if record is quarantined after initial acceptance. |

## 4. Required protocol refinements

### 4.1 Commit durability contract
Before an acceptance success response, the system must know which durability guarantee it has obtained. “Database returned commit success” is insufficient unless the candidate's documented configuration proves that the acknowledged transaction survives the declared failure set. The contract must state local durable flush, replication/consensus acknowledgement, eligible failover set and promotion rule, acknowledged-write RPO for the stated failure model, and fail-closed behavior when durability cannot be confirmed.

A zero-loss promise must not be inferred from the word “synchronous”; the actual mode, acknowledgement point and failover topology matter.

### 4.2 Single-writer authority epoch
Introduce a logical authority epoch/incarnation, independent of WorkItem claim generation:
- authority epoch increases monotonically and is never reused;
- every accepted write is fenced to the active epoch;
- only one epoch may possess write authority at a time;
- promotion is blocked until the old writer is fenced/terminated and the recovery authority is attested;
- stale epoch writes fail closed;
- restored backups cannot silently reintroduce an older epoch.

This is a design requirement to evaluate, not an implementation mandate for a particular consensus or lease service.

### 4.3 Reconciliation and retry race
A read that finds no pair does not authorize an unguarded insert. It permits a retry only through the same atomic unique-identity operation on the active fenced authority. If the prior attempt could still commit on a live writer or an un-fenced old authority, the outcome remains UNKNOWN. A duplicate-key/serialization result must be followed by a read with the documented consistency semantics and full immutable-binding comparison.

### 4.4 Retention-bounded idempotency
State the guarantee as a function of a defined replay horizon. A deletion policy that removes the only uniqueness record also removes the ability to deduplicate a later replay. Define minimal tombstone content, privacy controls, retention trigger, backup expiry and legal-hold interaction before setting a numeric period. Do not invent a partner replay horizon.

### 4.5 Pair relationship invariants
The future physical persistence design must enforce independently: unique source identity on InboxReceipt; at most one WorkItem for a given receipt; each accepted WorkItem references exactly one valid receipt; tenant and installation bindings match on both sides; and no worker may claim a quarantined or structurally inconsistent pair. Exact schema, constraint syntax and transaction isolation remain for a later database decision and real-engine proof.

## 5. Required additional adversarial cases

Add these as A11 subcases under existing A4/A8 parent IDs; do not renumber the canonical 47 A4 IDs:

| Proposed subcase | Parent area | Stimulus | Required result |
|---|---|---|---|
| A11-DUR-02b | A4-IDEM-02 / A4-DUR | Original commit remains in flight while same-identity retry starts | Exactly one pair; retry cannot outrun unresolved attempt or bypass uniqueness |
| A11-DUR-02c | A4-DUR | Original transaction aborts while retry races | One successful pair at most; loser resolves final durable state |
| A11-DUR-08b | A4-DUR | Primary acknowledges local commit; failover candidate lacks the write | No false durable-acceptance claim; behavior matches explicit RPO contract |
| A11-DUR-08c | A4-DUR | Old primary returns after promotion and attempts write | Old epoch rejected; no split-brain pair |
| A11-DUR-08d | A4-DUR | Promotion occurs while commit response is lost | UNKNOWN until new authority is fenced and reconciliation meets durability contract |
| A11-IDEM-09 | A4-IDEM | Replay arrives after event record expiry/deletion | Result matches approved replay horizon/tombstone policy; no undocumented dedupe promise |
| A11-IDEM-10 | A4-IDEM | Same source identity with changed fingerprint version or parser profile | Explicit version-aware conflict; no silent reinterpretation |
| A11-AUTH-08 | A4-AUTH | Poisoned event attempts to trigger broad quarantine | Containment limited to approved scope; unaffected tenants remain serviceable |
| A11-WRK-01 | A4-AUTH / A4-DUR | Quarantine races with worker claim | Either claim linearizes first and follows approved stop rule, or quarantine wins and claim changes zero rows; no pickup after quarantine boundary |

Each subcase requires deterministic barrier/schedule, exact authority epoch, persistence state before/after, independent read-only oracle, fault-controller evidence and a negative financial-effect assertion. All are NOT RUN.

## 6. Decision impact

- ADR-002 remains **PROPOSED**.
- A11-F01, F02, F03 and F06 are **Critical / blocking** for approval.
- A11-F04, F05, F07 and F08 are **High / blocking** for approval.
- No finding is closed by documentation CI.
- No A7/A8 finding is closed by this review.
- All eight A4 gates remain mandatory and NOT APPROVED.
- No runtime, persistence candidate, queue, partner, financial path, merge or deployment is authorized.

## 7. Evidence required for closure

For each finding, closure requires revised bilingual ADR with stable IDs and explicit normative language; owner decision for policy choices; genuinely independent reviewer disposition; candidate-specific vendor semantics and configuration evidence; disposable real-engine fault tests where behavior depends on persistence/failover; independent oracle results and immutable evidence provenance; exact-head documentation/contract CI; and explicit distinction between design, implementation, test execution and acceptance.

## 8. References

- Google Cloud Spanner, unknown commit status and retry risks: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- Google Cloud Spanner Commit API, UNKNOWN commit guidance: https://docs.cloud.google.com/workflows/docs/reference/googleapis/spanner/v1/projects.instances.databases.sessions/commit
- PostgreSQL High Availability, replication consistency and failover trade-offs: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL synchronous replication and failover behavior: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL WAL and asynchronous commit durability window: https://www.postgresql.org/docs/current/wal-async-commit.html
- PostgreSQL constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- AWS Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html

These references illustrate concrete failure semantics. They do not select PostgreSQL, Spanner, AWS or any other provider, and do not prove Lottorito runtime behavior.


## 9. Reconciliation against ADR-002 v0.2.0 / v0.3.0

The initial review above evaluated ADR-002 v0.1.0. Subsequent revisions incorporated several findings, but **this does not close them**: this remains same-author reconciliation and requires independent verification.

| Finding | Design response now present | Remaining closure evidence |
|---|---|---|
| A11-F01 durability across failover | ADR-002 §17.2 requires an explicit acknowledged-commit durability/RPO contract. | Owner-approved failure model; candidate replication/flush/promotion semantics; fault test proving acknowledged writes survive the supported failover set. |
| A11-F02 authority/split brain | ADR-002 §17.1 requires a monotonic authority epoch, single-writer proof, old-primary fencing and restore protection. | Identify authority root; prove epoch cannot fork/roll back; demonstrate old writer rejection through network/control-plane partition and rejoin. |
| A11-F03 negative read/in-flight commit | ADR-002 §§16.3, 17.1 require same-key arbitration on the active fenced authority; no assumption that a negative snapshot means the old transaction ended. | Deterministic original-commit/retry/promotion schedules on candidate engine; exact conflict/serialization and read consistency proof. |
| A11-F04 pair cardinality | ADR-002 §§16.5, 17.7 require commit-time/capability pair enforcement and explicit cardinality/linkage proof. | Candidate-specific unique/FK/relationship constraints or justified aggregate boundary; direct zero/one/multiple relationship tests including restore/corruption. |
| A11-F05 fingerprint version | ADR-002 §16.6 makes duplicate classification dependent on a finalized, versioned canonicalization/fingerprint profile. | LOT-EVENT-001 alignment; parser/canonicalization decision and cross-language vectors; compatibility and migration tests. |
| A11-F06 retention horizon | ADR-002 §17.3 requires owner-approved replay horizon and minimal tombstone/backup/offboarding policy. | Actual source contract; legal/privacy decision; deletion/restore/legal-hold and late-replay tests. No numeric horizon assumed. |
| A11-F07 quarantine blast radius | ADR-002 §17.4 requires graduated event→installation/source→tenant containment and worker exclusion. | Owner-approved scopes; authorization/audit/expiry/recovery policy; targeted-poisoning/noisy-neighbor and claim-race tests. |
| A11-F08 acceptance vs execution | ADR-002 §17.5 defines response as durable acceptance only, with stable reference and no processing-completion promise. | Wire-contract/API response alignment; quarantine-after-acceptance behavior; contract tests proving no duplicate WorkItem or worker-state disclosure. |

### 9.1 Additional identity and snapshot clarifications

ADR-002 v0.2.0 also clarifies that tenant-scoped source identities must not trigger cross-tenant lookup/disclosure; request Idempotency-Key must bind to a stable request fingerprint and resolved source identity; receipt/work-item linkage is inspected in one consistent snapshot; and fingerprint profile changes cannot silently reinterpret old receipts. Four supplemental cases are traced in A7: A10-DUR-02d, A10-DUR-02e, A10-AUTH-06b and A10-IDEM-08a. The nine A11 subcases are also represented there. Canonical A4 remains 47 IDs.

The reviewed artifact version in this reconciliation is ADR-002 v0.3.0, but no independent review of v0.2.0/v0.3.0 has occurred. A reviewer independent of the author must re-review the complete current ADR, A7 mappings and all findings rather than relying on this crosswalk.

## 10. Current disposition

- A11-F01..F08 remain OPEN; design text has been strengthened but findings are not closed.
- All A11 and A10 subcases remain NOT RUN/BLOCKED.
- The canonical A4 catalogue remains 47; extensions are tracked separately.
- All eight A4 gates remain NOT APPROVED.
- No database/queue/provider/authority service, runtime, partner, financial operation, merge or deployment is authorized.
