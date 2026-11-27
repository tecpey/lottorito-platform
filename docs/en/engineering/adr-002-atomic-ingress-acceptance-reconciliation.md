# ADR-002 — Atomic Affiliate Ingress Acceptance and Unknown-Commit Reconciliation

**Document ID:** LOT-AFFILIATE-G09-ADR-002  
**Decision ID:** LOT-AFFILIATE-G09-ADR-002  
**Related:** LOT-AFFILIATE-SEC-ACC-001; G09-A4; G09-A5; G09-A7; G09-A8  
**Status:** PROPOSED — owner decision and genuinely independent review required  
**Version:** 0.2.0 | **Date:** 2026-11-28  
**Scope:** Synthetic Affiliate ingress acceptance only. No commission qualification, financial posting, external side effect, partner integration or production authority.

## 1. Decision requested

Adopt this logical acceptance contract, subject to §12:

1. Successful ingress acceptance consists of exactly one durable **InboxReceipt + WorkItem** pair for the approved source-event identity.
2. Both records commit in one atomic persistence transaction: both durable or neither durable.
3. Success acknowledgement (for example HTTP 202) is allowed only after authoritative evidence of commit success.
4. If the caller cannot determine whether commit succeeded, outcome is **UNKNOWN**, not FAILED. It must not create another pair or repeat business effects blindly.
5. Reconciliation uses an authoritative, sufficiently consistent persistence read and the approved source-event identity. A stale replica, cache, queue, log or client timeout is not proof of absence.
6. DeliveryOutbox, if needed for downstream publication, is a separate conditional record; it is not WorkItem and cannot replace the mandatory pair.

This is technology-neutral. No database, isolation level, queue, CDC product, schema, vendor, retry count, timeout or topology is selected.

## 2. Failure model and outcome taxonomy

The client sends an authenticated, tenant-bound event. Ingress validates it, writes receipt and work item in a transaction, then commits. Network loss may occur before, during or after commit response; the process may crash after commit but before HTTP response; retries may be concurrent or arrive after failover.

A missing response does not establish whether the durable transaction committed. Blind replay can create duplicate work and, in an unsafe later design, duplicate economic effects.

Distinguish:
- **KNOWN_COMMITTED:** authoritative commit success observed.
- **KNOWN_ABORTED:** reliable evidence establishes that the transaction did not commit.
- **UNKNOWN:** neither commit nor abort can safely be established by the caller.
- **CONFLICT:** identity exists but immutable binding/fingerprint differs.
- **UNAVAILABLE:** authoritative reconciliation cannot currently be completed.

UNKNOWN is a first-class protocol state, not a synonym for transient failure.

## 3. Identity and trusted tenant binding

Candidate source-event uniqueness tuple:

    (trusted_tenant_id, trusted_installation_id, approved_source_namespace, source_event_id)

This remains a candidate pending LOT-EVENT-001 and an actual partner contract. Tenant and installation derive from authenticated server-side installation configuration and authorization context, never payload claims.

Keep three identity namespaces separate:
- source-event identity;
- HTTP request Idempotency-Key, with its own scope and retention policy;
- future economic-effect identity owned by a separately authorized commission/finance command.

Do not assume globally unique event_id. A repeated source identity within the same authenticated tenant/installation scope may be a duplicate only when all approved immutable bindings match. A different tenant is a separate identity scope unless a signed source contract explicitly defines global uniqueness; never perform cross-tenant lookup or disclose another tenant's record. A mismatch against the authenticated tenant/installation context is an authorization failure. Source, event type, schema version and approved fingerprint mismatches within the same scope are conflicts, not updates.

## 4. Atomic acceptance invariants

One logical transaction must:
- establish trusted tenant and installation binding;
- enforce uniqueness of the approved source-event identity;
- persist one immutable InboxReceipt;
- persist exactly one linked WorkItem in its initial eligible state;
- include only other records whose separately approved invariant requires the same atomic boundary;
- commit once.

**A.** After any crash/recovery point, no accepted InboxReceipt may exist without its required WorkItem, and no accepted WorkItem without its InboxReceipt.  
**B.** Success acknowledgement is causally after confirmed commit.  
**C.** No queue publish, external HTTP call, financial command or partner callback occurs inside the acceptance transaction.  
**D.** Uniqueness is enforced by a persistence-level constraint or equivalent atomic/serializable primitive. Application-only read-then-insert is insufficient under concurrency.

Atomicity only makes writes actually included in one transaction all-or-none; it does not prove application code cannot omit one write and still commit. The selected candidate must demonstrate a commit-time or capability-enforced exactly-one pair invariant. A partial pair is an invariant breach, not a normal retry state. Stop acceptance for the affected scope, preserve evidence, prevent worker pickup and downstream effects, alert the responsible operator, and require controlled audited repair. Never silently synthesize the missing half during ordinary retry.

## 5. Commit outcomes and caller behavior

| Observed condition | Classification | Required behavior |
|---|---|---|
| Commit acknowledgement received | Known committed | Return stable reference; no duplicate insert |
| Explicit abort with reliable semantics | Known aborted | Classify cause; retry only if approved retryable |
| Connection loss/timeout during commit | Unknown | No success/failure claim; reconcile |
| Crash after commit before HTTP response | Unknown to caller | Retry with same identity; find existing pair |
| Primary unavailable; no authoritative read | Unavailable/unknown | Fail closed; no new pair or success claim |
| Matching identity and immutable binding | Already accepted | Idempotent response referencing existing acceptance |
| Identity exists but binding/fingerprint differs | Conflict | Reject; sanitized security evidence; no overwrite |
| Stale replica returns no row | No conclusion | Never infer absence |
| Authoritative read returns no row | Candidate absence only | Re-enter same atomic operation under uniqueness arbitration |

Exact HTTP status/envelope follows the approved API contract. This ADR does not mandate a status for UNKNOWN. If uncertainty cannot be represented safely, return non-success with explicit instruction to retry using the same identity/key; never issue a new identity.

## 6. Reconciliation algorithm (logical)

1. Preserve original source identity, request idempotency key, trusted tenant/installation binding and approved fingerprint version across retries.
2. Never generate a new event identity because a response was lost.
3. Query the authoritative persistence authority by the full approved unique tuple using one consistent snapshot or atomic query for receipt/work-item cardinality and linkage. A stale replica, cache or asynchronously replicated projection cannot establish absence.
4. If exactly one receipt and exactly one linked WorkItem exist, verify tenant/installation/source/event/fingerprint/schema bindings and linkage. If valid, classify as already accepted and return the existing stable reference.
5. If neither exists on an authoritative read, re-enter the same atomic acceptance operation. The original transaction may still be in flight: the uniqueness/serialization mechanism must arbitrate both attempts on the same key, waiting/serializing or returning a definitive conflict/abort before the retry classifies the winner. Re-read and compare immutable bindings; never assume the original attempt has terminated merely because one snapshot returned no row.
6. If only one half exists, multiple WorkItems link to one receipt, linkage is broken or immutable fields disagree, classify invariant breach/conflict; quarantine scope and stop automated retry.
7. If authoritative read or commit status is unavailable, preserve UNKNOWN/UNAVAILABLE and retry reconciliation only under a future approved bounded backoff/jitter/resource policy. Never use stale replica reads to manufacture certainty.
8. Record a sanitized append-only reconciliation decision: correlation IDs, read authority/source, consistency class, observed cardinality, decision and evidence reference. Never log credentials, raw payloads or unnecessary PII.

A persistence candidate must document guarantees supporting authoritative reads and uniqueness through failover, restore and replication. If these guarantees cannot be established, the candidate is unacceptable until the contract is redesigned.

## 7. Concurrency, uniqueness and transaction semantics

- Persistence must enforce uniqueness for the approved source-event tuple.
- Concurrent identical attempts converge on one pair. The losing transaction resolves the winner's durable result and compares immutable bindings.
- A uniqueness conflict is not automatically a valid duplicate; compare the complete approved identity and fingerprint profile.
- Isolation must prevent write-skew/races that create multiple WorkItems per receipt or a partial pair.
- Candidate evaluation documents serialization points, unique constraint/index behavior, conflict visibility, retryable abort semantics, read-your-writes/linearizability guarantees, failover and durability. No isolation level is selected here.
- Syntax such as INSERT ... ON CONFLICT is not, by itself, a correctness proof. Correctness depends on unique key, transaction boundary, returned/observed row semantics, isolation, concurrent updates and recovery behavior.
- Unknown commit must not become blind transaction replay. Safe retry reuses the same identity under the same persistence uniqueness invariant.
- Transactions are short and contain no external I/O. WorkItem execution starts only after durable acceptance commit.

## 8. DeliveryOutbox boundary

InboxReceipt + WorkItem is the mandatory acceptance pair. DeliveryOutbox is optional and only exists if a later approved design requires durable publication of a wake-up/event to another subsystem.

If introduced, it needs a named owner, event contract, idempotency identity, ordering requirements, retention and reconciliation policy. Its atomicity relationship to the pair must be separately specified. It may join the same transaction only if an approved invariant requires publication intent to be inseparable from acceptance. Queue delivery remains at-least-once unless a concrete provider contract proves otherwise; consumers must be idempotent. Outbox publication is not WorkItem completion and does not authorize financial processing.

## 9. Crash-point and adversarial test matrix

All cases are **NOT RUN**; they define future acceptance evidence, not proof.

| Case | Injected point/race | Required result |
|---|---|---|
| C01 | Crash before either insert | No pair; no success acknowledgement |
| C02 | Crash after receipt write, before WorkItem, before commit | Rollback; neither durable |
| C03 | Crash after WorkItem write, before commit | Rollback; neither durable |
| C04 | Commit succeeds; response lost | Retry finds one valid pair; no second pair |
| C05 | Commit sent; connection lost before outcome known | UNKNOWN; authoritative reconciliation only |
| C06 | Explicit abort | No pair; retry only if classified retryable |
| C07 | Two concurrent identical ingress attempts | Exactly one pair; loser resolves same acceptance |
| C08 | Same identity, different fingerprint/binding | Conflict; no overwrite or second pair |
| C09 | Primary unavailable; stale replica returns no row | No absence inference; remain unresolved |
| C10 | Primary recovers; authoritative read finds pair | Return existing acceptance after binding check |
| C11 | Primary recovers; authoritative read proves no pair | Re-enter same atomic operation under unique constraint |
| C12 | Partial pair seeded in disposable test | Invariant breach; quarantine; no automatic repair/pickup |
| C13 | Duplicate delivery after process restart | Same durable pair/reference |
| C14 | Outbox publish succeeds but acknowledgement is lost | Duplicate publication tolerated; consumer idempotent |
| C15 | Outbox publish fails after acceptance commit | Acceptance remains durable; separate publication retry |
| C16 | Tenant/installation lifecycle changes during ingress | Approved lifecycle linearization; no cross-tenant acceptance |
| C17 | Restore/failover yields stale/divergent view | Fail closed until recovery authority/consistency attested |

Every executable case must add fixture version, deterministic schedule, API assertions, direct persistence assertions, tenant authorization, financial non-effect sentinel, independent oracle, evidence provenance and cleanup. A4 parent and A8 subcase outcomes must be reported separately.

## 10. Independent oracles and evidence

Future execution requires:
1. API/client observation (not a commit oracle).
2. Read-only authoritative persistence inspection with documented consistency mode and endpoint identity.
3. Constraint/index and transaction trace proving unique arbitration and atomic pair.
4. Independent cardinality/linkage query proving exactly one receipt and one WorkItem.
5. Fault-injection controller evidence proving the injection point.
6. Financial non-reachability sentinel proving no access/mutation to Wallet/Ledger/Payment/Settlement/Payout.
7. Sanitized audit/evidence manifest with correlation, trusted timestamps, source/head/build identity and integrity hash.

Logs emitted by the system under test are not independent oracles. API success alone does not prove durable state. A replica read without consistency guarantees does not prove absence. Evidence must distinguish design review, documentation CI, isolated runtime proof, partner sandbox proof and production attestation.

## 11. Alternatives considered

- Blind retry after timeout — rejected; may duplicate work/economic effects.
- New client idempotency key on each retry — rejected; destroys stable retry identity.
- Read-before-write without persistence uniqueness — rejected; concurrent callers may both observe absence.
- Queue as source of truth — rejected; delivery/ack does not prove durable acceptance.
- Receipt-only acceptance with later WorkItem creation — rejected; violates atomic pair.
- Outbox-only acceptance — rejected; DeliveryOutbox is not WorkItem.
- Stale-replica absence check — rejected; asynchronous replication can hide committed state.
- End-to-end exactly-once delivery claim — rejected absent a precise end-to-end contract; require durable idempotent acceptance and idempotent consumers instead.

## 12. Open owner decisions and candidate evaluation

No choice is silently made for:
- approved source-event uniqueness tuple and source namespace authority (coordinate with LOT-EVENT-001 and partner contract);
- request Idempotency-Key scope, retention and replay response policy;
- persistence consistency model and definition of authoritative read after commit, failover and restore;
- acceptable transaction isolation/locking/unique constraint semantics;
- durability acknowledgement and replication/failover RPO/RTO;
- conflict classification and quarantine/repair authority;
- tenant/installation revocation lifecycle linearization;
- bounded reconciliation retry, backoff, queueing and resource quotas;
- whether DeliveryOutbox is needed and its owner/atomicity boundary;
- evidence retention, privacy, deletion, backup and legal-hold policy.

Candidate selection requires vendor documentation and disposable real-engine proof. Documentation claims alone are insufficient. No PostgreSQL, Spanner, CockroachDB, queue or cloud service is selected.

## 13. Future acceptance criteria

ADR-002 may leave PROPOSED only when:
1. Accountable owner approves every §12 decision or records explicit deferrals with safe defaults.
2. A genuinely independent reviewer challenges identity scope, transaction contract, unknown-commit protocol and failure matrix.
3. The selected persistence candidate proves atomic pair commit/rollback, concurrent uniqueness and authoritative reconciliation under its documented failover model.
4. Tests prove response loss after commit creates no second pair.
5. Tests prove primary unavailability/stale replica never infer absence.
6. Tests prove partial pairs are detected/quarantined, not silently repaired.
7. Tenant/installation binding is independently verified.
8. Financial non-reachability is attested by finance/security and technical capability evidence.
9. Bilingual semantic parity and documentation governance pass on the exact final commit.
10. All eight A4 gates are separately approved before any G09-A4/A5 runtime execution.

## 14. Authority and current disposition

This ADR is **PROPOSED**. It is not an approved architecture decision, implementation specification, runtime authorization, partner contract, accounting policy or production-readiness statement. No runtime test has been run by this ADR. A7-F01–F10 and A8-F01–F12 remain open unless separately closed by independent evidence. All A4 gates remain NOT APPROVED. No database, queue, vendor, physical schema, financial integration, merge or deployment is authorized.

## 15. References

- PostgreSQL INSERT / ON CONFLICT (illustrative candidate semantics only): https://www.postgresql.org/docs/current/sql-insert.html
- PostgreSQL Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL Constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- AWS Prescriptive Guidance, Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- Google Cloud Spanner, Unknown Commit Status and safe retry guidance: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- NIST SP 800-204D, Software Supply Chain Security in DevSecOps CI/CD Pipelines: https://csrc.nist.gov/pubs/sp/800/204/d/final

References inform evaluation; they neither select technology nor prove Lottorito behavior.

## 16. Adversarial design challenge — same-author review, not independent sign-off

This is a further analytical challenge based on the official references in §15. It is a same-author review, **not** independent sign-off, runtime proof or owner decision. These clarifications supersede inconsistent earlier wording.

### 16.1 Tenant-scoped identity and non-disclosure

The candidate uniqueness tuple is tenant-scoped. Therefore, the same source namespace and event ID in two different tenants is **not automatically a cross-tenant conflict**. It is a separate scoped identity unless a signed source contract explicitly establishes a globally shared namespace and global uniqueness. Never query another tenant's row to detect a collision or disclose its existence. Authenticate and bind tenant/installation before idempotency lookup. A mismatch against the authenticated installation is an authorization failure, not a cross-tenant duplicate response.

### 16.2 Request idempotency binding

The request Idempotency-Key is separate, but must bind to a stable request fingerprint and resolved source-event identity within its approved scope. Reuse of the same key with a different body, tenant/installation binding or source-event identity is a conflict; do not replay the earlier response as if the requests were equivalent. Different request keys for the same valid source-event identity still converge on one accepted pair. Key scope, retention and response replay remain owner decisions.

### 16.3 Absence, in-flight commits and uniqueness arbitration

An authoritative read returning no row is only a snapshot observation; it does not prove that an earlier transaction whose commit response was lost has terminated. A reconciliation retry may race an original still-in-flight transaction. The persistence candidate must prove both attempts arbitrate on the same unique source-event key: the second attempt must wait/serialize or receive a definitive conflict/abort, then re-read and compare the winner. It must never create a second pair. If the engine cannot prove this under its documented isolation and failover model, it is unacceptable.

Receipt and WorkItem cardinality/linkage must be checked in one consistent snapshot or atomic query. Two independent reads must not manufacture a false partial-pair diagnosis during concurrent commit visibility.

### 16.4 Acknowledged durability across failover

“Commit acknowledged” is meaningful only relative to a declared durability and failure model. The candidate must prove an acknowledged acceptance survives every failover/restore class in the explicitly supported failure model, or the API must not promise durability across that class. RPO, replication acknowledgement, promotion eligibility, recovery-point selection and post-restore replay behavior must be explicit. A readable replica is not necessarily authoritative. If acknowledged data may be absent after promotion, acceptance remains unresolved and the system must quarantine/reconcile without issuing a second accepted identity or allowing worker execution from divergent history.

### 16.5 Commit-time pair invariant, not merely crash atomicity

Atomic transaction semantics make writes actually included in a transaction all-or-none; they do not prove application code cannot commit a receipt while omitting its WorkItem. The candidate must demonstrate a commit-time or capability-enforced invariant that accepted receipts cannot commit without exactly one WorkItem and WorkItems cannot exist without their receipt. Possible mechanisms include a database-enforced deferred invariant, a single atomic aggregate representation, or a narrowly controlled transaction boundary with database privileges and independently tested code-path guarantees. The mechanism must be justified; a prose promise or happy-path test is insufficient. If exact-one pairing cannot be enforced or convincingly proven, redesign before runtime approval.

### 16.6 Fingerprint and conflict safety

A same-identity retry may be called a duplicate only when the approved canonicalization/fingerprint profile and immutable comparison fields are finalized and versioned. Until then, a matching identity with payload differences that cannot be safely compared is unresolved/conflict and must not silently reuse prior acceptance. Canonicalization version changes must not reinterpret old receipts without a migration/compatibility decision.

### 16.7 Additional future test cases

All remain **NOT RUN** and require relevant owner/technology decisions.

| Case | Adversarial challenge | Required result |
|---|---|---|
| C18 | Original commit is still in flight; authoritative snapshot reads no row; reconciliation retries concurrently. | Unique-key arbitration serializes attempts; exactly one pair; loser resolves winner or waits for definitive abort. |
| C19 | Acknowledged commit is followed by primary loss and promotion/restore to a candidate recovery point. | Behavior matches declared durability/RPO contract; no false accepted/absent claim; workers remain fenced on divergent history. |
| C20 | Faulted application path attempts to commit InboxReceipt without WorkItem, or WorkItem without Receipt. | Commit-time/capability invariant rejects partial acceptance, or candidate is rejected pending redesign. |
| C21 | Receipt and WorkItem are read in separate snapshots while a concurrent acceptance commits. | Reconciliation uses one consistent snapshot/atomic query; no false partial-pair quarantine. |
| C22 | Same source namespace/event ID is presented by two distinct authenticated tenants. | Tenant-scoped identities remain isolated; no cross-tenant lookup or existence disclosure. |
| C23 | Same HTTP Idempotency-Key is reused with a different body/source identity; separately, different keys retry the same source event. | First case conflicts without replaying an unrelated response; second converges to one source-event pair. |

### 16.8 Reference-derived cautions

Google Spanner guidance explicitly describes UNKNOWN commit status and recommends a subsequent database read; it also explains why blind automatic retry can duplicate business effects. This is provider-specific guidance, not a universal guarantee for any future Lottorito persistence engine. PostgreSQL documentation demonstrates that snapshots and conflict handling vary by isolation level and statement shape; separate statements can observe different committed snapshots under Read Committed. AWS outbox guidance confirms downstream publication can be duplicated and consumers need idempotency. These references reinforce candidate-proof requirements; none selects a vendor or proves Lottorito behavior.


## 16. Adversarial review linkage (G09-A11)

The same-workflow adversarial self-review is recorded in [G09-A11](affiliate-g09-a11-adr002-adversarial-review.md). It is not independent approval. The following findings block approval of this ADR until resolved with owner decisions, independent review and candidate-specific evidence: A11-F01 (commit durability across failover), A11-F02 (single-writer authority epoch and split-brain fencing), A11-F03 (negative reconciliation read versus in-flight commit), A11-F06 (retention-bounded idempotency), plus High findings A11-F04/F05/F07/F08. Nine proposed A11 subcases are NOT RUN. This linkage does not authorize runtime execution or waive any A4 gate.
