# ADR-002 — Atomic Affiliate Ingress Acceptance and Unknown-Commit Reconciliation

**Document ID:** LOT-AFFILIATE-G09-ADR-002  
**Decision ID:** LOT-AFFILIATE-G09-ADR-002  
**Related:** LOT-AFFILIATE-SEC-ACC-001; G09-A4; G09-A5; G09-A7; G09-A8  
**Status:** PROPOSED — owner decision and genuinely independent review required  
**Version:** 0.1.0 | **Date:** 2026-11-28  
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

Do not assume globally unique event_id. A repeated source identity with the same approved immutable binding may be a duplicate; the same identity with a different tenant, installation, source, event type, schema version or approved fingerprint is a conflict/security signal, not an update.

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

A partial pair is an invariant breach, not a normal retry state. Stop acceptance for the affected scope, preserve evidence, prevent worker pickup and downstream effects, alert the responsible operator, and require controlled audited repair. Never silently synthesize the missing half during ordinary retry.

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
3. Query the authoritative persistence authority by the full approved unique tuple. A stale replica, cache or asynchronously replicated projection cannot establish absence.
4. If exactly one receipt and exactly one linked WorkItem exist, verify tenant/installation/source/event/fingerprint/schema bindings and linkage. If valid, classify as already accepted and return the existing stable reference.
5. If neither exists on an authoritative read, re-enter the same atomic acceptance operation. The uniqueness/serialization mechanism arbitrates concurrent attempts. Re-read and classify a concurrent conflict.
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
