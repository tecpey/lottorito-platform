# ADR-001 — Durable WorkItem Claim, Lease and Fencing Protocol

**Decision ID:** LOT-AFFILIATE-G09-ADR-001  
**Related findings:** A7-F01; A8-F01, A8-F04, A8-F06, A8-F10  
**Status:** PROPOSED — owner approval and independent review required  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Scope:** Synthetic Affiliate ingress WorkItem lifecycle only. No external side effects or financial effects.

## 1. Context and problem

A worker may pause, lose connectivity, exceed its lease, or continue running after another worker has legitimately reclaimed the same WorkItem. A lease timeout alone cannot revoke a paused process. A worker-local belief that it still owns a lease is not authoritative.

The protocol must prevent stale workers from changing durable WorkItem state after a newer claim has become authoritative. It must also define the race where a lease expires while a worker is attempting a state transition, and it must not claim to fence external systems that do not validate the token.

This ADR is a technology-neutral decision proposal. It does not select a database, queue, lock service, IAM provider, schema, lease duration, timeout, retry count or deployment topology.

## 2. Decision requested

Adopt a **durable, per-WorkItem claim generation with database-authoritative conditional transitions**, subject to the owner and independent reviewers approving the unresolved policy choices in §11.

The durable WorkItem record is the authority for claim state. A queue message is only a wake-up hint and never grants ownership.

## 3. Terms and identity

- **WorkItem identity:** immutable identifier bound to one tenant and one installation for its entire lifetime.
- **Claim generation:** strictly increasing integer scoped to one immutable WorkItem identity.
- **Claim token:** opaque token bound to WorkItem identity, tenant/installation binding, generation and claim owner. It is not a bearer credential by itself.
- **Claim owner:** authenticated worker principal identity, not a caller-supplied string.
- **Lease expiry:** authoritative persistence timestamp after which a new claimant may attempt reclaim.
- **Linearization point:** the successful guarded durable row mutation that serializes a claim or protected state transition against competing claimants.
- **Stale worker:** a process whose owner/generation/token no longer matches the durable WorkItem authority, or whose lease was no longer valid at the transition's linearization point.

The source-event identity, HTTP request idempotency key and economic-effect identity remain separate. This ADR does not redefine them.

## 4. Proposed state and invariants

The logical WorkItem carries at least:
- immutable WorkItem ID, tenant ID and installation ID;
- lifecycle state;
- claim generation;
- claim owner identity;
- claim token reference/value;
- lease expiry;
- attempt metadata required by the approved retry policy;
- version/audit metadata sufficient to reconstruct transitions.

These are logical fields, not an approved physical schema.

Mandatory invariants:

1. A WorkItem identity is never reassigned to another tenant, installation or logical job.
2. Every successful new claim advances generation exactly once.
3. Generation never decreases, wraps, resets or is reused for the same WorkItem identity.
4. Claim owner and token are changed atomically with generation and lease.
5. Every heartbeat, completion, retry scheduling, parking or cancellation transition is conditional on the expected state, immutable identity binding, owner, generation/token and applicable lifecycle version.
6. A failed guard changes zero protected WorkItem rows.
7. Queue delivery, queue order and queue acknowledgement do not establish ownership or durable completion.
8. No worker transition in this scope may call or mutate Wallet, Ledger, Payment, Settlement, Payout, Commission or any economic-effect service.
9. No network I/O or external side effect occurs inside the short transaction that performs a protected durable transition.
10. Unknown transaction outcome is reconciled against authoritative durable state; it is never treated as an automatic rollback.

## 5. Claim protocol

A claimant receives a queue wake-up hint or discovers eligible work through an approved scheduler. It authenticates as a worker principal and asks the authoritative persistence layer to claim a specific eligible WorkItem.

The claim operation must be one serialized durable transaction:
1. Resolve the immutable WorkItem identity and tenant/installation binding from trusted durable state.
2. Acquire the serialization mechanism for that WorkItem (for example, a row-level lock or equivalent atomic compare-and-set; no database technology is selected).
3. Evaluate eligibility against authoritative persistence time and current durable state.
4. If state is READY, or CLAIMED with an expired lease under the approved lifecycle policy, increment generation exactly once.
5. Set the authenticated owner, a fresh claim token, lease expiry and CLAIMED state in the same transaction.
6. Commit before the worker is told it owns the WorkItem.

If another claimant wins, the losing claimant receives no token and performs no work. Duplicate or out-of-order queue messages merely cause another eligibility check.

A lease renewal is not a new claim and must not increment generation. A reclaim is a new claim and must increment generation.

## 6. Protected transition protocol and lease-expiry race

Every protected transition (heartbeat, completion, retry scheduling, parking, cancellation where worker-authorized) must be a short transaction guarded by all applicable predicates:
- exact WorkItem ID and immutable tenant/installation binding;
- expected current state;
- authenticated owner;
- current claim generation;
- current claim token;
- lease validity at the transition's linearization point;
- expected lifecycle/version condition when the approved lifecycle policy requires it.

The guard and mutation must be serialized against a competing reclaim. A conditional update or lock-and-check protocol is acceptable only if its database isolation/locking semantics are documented and tested.

**Lease-expiry race rule proposed:** expiry makes the WorkItem eligible for reclaim; it does not asynchronously interrupt a process. The first serialized durable transition wins:
- If the old worker obtains the serialization point while its lease is still valid, and its guarded mutation succeeds, that transition is ordered before a later reclaim. The row lock/serialization must prevent a new generation from being granted concurrently. The transaction must remain short and contain no external I/O.
- If the lease is expired when the old worker reaches the guarded transition, the guard fails and it changes zero protected rows.
- If a new claimant has already advanced generation, every transition from the old generation fails regardless of the old worker's local clock or belief.
- If the database cannot establish reliable ordering/time due to failover, clock discontinuity or uncertain recovery state, claims and protected transitions fail closed until the recovery fence in §9 is satisfied.

This rule deliberately defines one linearization point rather than relying on a worker's local clock or an imprecise “check then act” sequence.

Heartbeat after lease expiry is rejected. A worker cannot resurrect an expired lease. A worker that needs more time must renew before expiry. Completion after expiry is rejected unless it had already successfully linearized before expiry under the rule above.

## 7. State transition matrix

| Operation | Required precondition | Generation effect | Failure behavior |
|---|---|---|---|
| Initial claim | READY and eligible | Increment once | No ownership granted |
| Reclaim | CLAIMED and lease expired under approved policy | Increment once | Existing authority remains until a serialized winner |
| Heartbeat | CLAIMED; owner/token/generation match; lease valid at linearization | No increment | Zero protected-row changes; expired lease cannot revive |
| Complete | CLAIMED; owner/token/generation match; lease valid at linearization | No increment | Zero protected-row changes; stale completion rejected |
| Schedule retry | CLAIMED; owner/token/generation match; lease valid at linearization | No increment | Zero protected-row changes |
| Park | CLAIMED; owner/token/generation match; lease valid at linearization or separately authorized operator path | No increment | Zero protected-row changes |
| Cancel/revoke | Explicit lifecycle/owner policy; version-conditioned | Policy-defined; never silently reuse a token | Conflict or park; no blind overwrite |

A retry that returns the item to READY does not reset generation. The next claim increments from the last durable generation.

## 8. Transaction duration, external work and retries

- CPU-bound preparation may occur outside the protected transition transaction.
- Network I/O, partner calls, email, webhook publication, financial calls and unbounded computation are prohibited inside the claim/finalization transaction.
- The transaction that validates and mutates the WorkItem must be bounded by an owner-approved operational policy. No numeric timeout is selected here.
- If the transaction aborts conclusively, the worker may re-read and follow the approved state machine.
- If the commit result is unknown, the worker must reconcile from the authoritative primary/consistency-guaranteed store using WorkItem ID + generation + owner/token and expected state. It must not blindly repeat a non-idempotent transition.
- Retry classification, backoff, jitter, retry budgets and terminal parking require a separate policy/ADR. Retries must not amplify overload.

## 9. Generation lifecycle, restore and disaster recovery

Generation must use a representation with a defined maximum and fail-closed exhaustion behavior. No wraparound, reset, reuse, tenant transfer or WorkItem ID recycling is allowed.

A database restore or point-in-time recovery can roll durable generation backwards while old processes may still exist. A generation counter stored only in the restored database cannot, by itself, prove that old tokens are invalid.

**Recovery fence proposed:**
1. Stop ingress and worker admission before restore/failover recovery that may roll back claim state.
2. Prove all old worker processes and credentials are terminated/revoked, or isolate them so they cannot reach the restored authority.
3. Establish a new recovery incarnation/epoch using an independently controlled mechanism that is not rolled back with the restored WorkItem data.
4. Bind all new worker claims/tokens to that incarnation.
5. Verify old identities/tokens are rejected and clock/consistency health is acceptable.
6. Re-enable claims only after an accountable recovery attestation.

If the platform cannot provide a non-reusable recovery incarnation or cannot prove old workers are fenced, the system remains stopped. The incarnation mechanism and owner are unresolved; no provider is selected.

## 10. Tenant and installation lifecycle

The claim/transition guard must include immutable tenant and installation binding. The owner must separately decide whether a previously accepted Receipt remains processable after installation suspension/revocation.

For any policy where current lifecycle state takes precedence, the protected transition must atomically validate the authoritative lifecycle version/state or serialize against its change. A separate unprotected “read status, then update WorkItem” is insufficient.

Tenant transfer or installation reassignment of an existing WorkItem is prohibited. Migration/replay into a different installation requires a new, explicitly authorized identity and audit trail.

## 11. Alternatives and unresolved owner decisions

| Option | Benefit | Risk / reason not selected |
|---|---|---|
| Lease expiry only | Simple recovery from abandoned claims | Does not stop a paused stale worker; rejected as sufficient protection |
| Worker-local time check | Easy to implement | Clock skew/pause and check-then-act race; rejected as authority |
| Queue visibility timeout/ack as ownership | Convenient queue-native flow | Queue is not durable business authority; duplicate/out-of-order delivery and ack loss remain |
| Durable generation + guarded persistence mutation | Stale generations can be rejected at the authority | Requires carefully defined serialization, clock/failover and restore behavior; proposed |
| External fencing token checked by every downstream resource | Can fence effects beyond WorkItem storage | No downstream capability is in this scope; future design must separately prove recipient enforcement |

Owner decisions required before approval:
- authoritative time source and failover/clock-discontinuity policy;
- exact serialization/transaction isolation semantics after a database candidate is selected;
- claim generation representation and exhaustion response;
- recovery incarnation authority and operational owner;
- installation suspension/revocation behavior for already accepted receipts;
- bounded transaction and worker execution policy;
- accountable owner, independent reviewer and acceptance authority.

No values or providers are assumed.

## 12. Acceptance criteria — design and future proof

This ADR may be accepted only when:
1. Accountable owner approves every decision in §11 or records a justified deferral that does not weaken the invariants.
2. Independent architecture/security/QA reviewers approve the temporal protocol and test schedule.
3. A7 includes explicit subcases for expiry-before-reclaim, heartbeat/reclaim race, stale completion after generation change, restart, restore with old worker alive, and lifecycle revocation/commit race.
4. The selected persistence candidate's locking, isolation, time and failover semantics are documented.
5. A test oracle independent of the worker code verifies generation, owner, state and zero-row stale writes.
6. Commit ambiguity and reconciliation have deterministic outcomes.
7. Restore procedure proves old workers/identities cannot mutate recovered state.
8. No external or financial side-effect capability is present in the test vertical slice.
9. Evidence includes provenance, clock source, transaction/claim timeline and negative assertions.
10. All eight A4 gates are approved before any runtime proof begins.

These are future acceptance criteria. No test has been run and no runtime is approved by this ADR.

## 13. Consequences

Positive:
- Makes the authority and serialization point explicit.
- Distinguishes lease eligibility from stale-owner fencing.
- Prevents worker-local clocks and queue acknowledgements from becoming authority.
- Exposes restore/rollback as a separate fencing problem rather than assuming a counter is enough.

Costs and limitations:
- Requires durable state transitions and carefully controlled transaction boundaries.
- Clock/failover and recovery-incarnation operations add operational complexity.
- This protects only the WorkItem persistence boundary; it does not fence external side effects.
- Correctness still depends on the chosen persistence engine's documented and tested semantics.

## 14. References

- Martin Kleppmann, “How to do distributed locking” — fencing tokens and why the protected resource must reject stale tokens: https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
- PostgreSQL documentation, Explicit Locking — reference for row-lock serialization concepts only; PostgreSQL is not selected: https://www.postgresql.org/docs/current/explicit-locking.html
- PostgreSQL documentation, Transaction Isolation — reference for serialization and retry behavior only; PostgreSQL is not selected: https://www.postgresql.org/docs/current/transaction-iso.html
- etcd API guarantees — lease expiry, revisions and uncertain operation outcomes as coordination-system concepts; etcd is not selected: https://etcd.io/docs/v3.4/learning/api_guarantees/
- AWS Builders’ Library, “Timeouts, retries, and backoff with jitter” — retry amplification, idempotency and backoff: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/

References inform the proposal; they do not establish product compliance or approve a technology.
