# G09-A23 M3 — Worker Lease & Claim Generation Model

**Document ID:** LOT-AFFILIATE-G09-A23-M3  
**Version:** 0.1.6  
**Status:** MODEL DRAFT — TLC validation pending; independent review and candidate refinement not performed  
**Parent:** [A23 formal protocol model/test strategy](affiliate-g09-a23-formal-protocol-model-test-strategy.md)  
**Normative proposal:** [ADR-001 — WorkItem Claim, Lease and Fencing](adr-001-workitem-claim-lease-fencing.md)  
**Traceability:** [A7 47-case traceability](affiliate-g09-a7-47-case-traceability.md), A4-DUR-05, A8-DUR-05a/b/c, A11-WRK-01

## 1. Purpose and boundary

M3 isolates one durable WorkItem and two worker processes to model claim ownership, generation fencing, lease renewal, protected state transitions, lock wait and the expiry/reclaim race. It is candidate-neutral. It does not select a database, queue, clock provider, IAM provider, lease-duration policy or transaction-isolation level.

The durable WorkItem state is authoritative. Queue delivery is only a wake-up hint and is not modeled as ownership. The model protects source-side WorkItem persistence only; it does not revoke or fence an external request already dispatched.

## 2. Critical modeling decisions

1. **Worker process identity is distinct from authenticated principal identity.** W0 and W1 intentionally share the same abstract authenticated principal (worker-service). This prevents a false proof in which stale work is rejected only because the process identity differs. Generation and token must independently fence an older process that resumes under the same service principal.
2. **Claim generation is per immutable WorkItem.** A successful initial claim or reclaim advances it exactly once. Heartbeat/renewal, processing, completion, retry and park do not advance it. The finite model uses generations 0..2 only as exploration bounds, not as a production representation or exhaustion policy.
3. **The claim token is an opaque generation-bound symbol.** TLC models binding and mismatch, not cryptographic entropy, secrecy, token transport or credential theft. A token is not treated as a bearer credential by itself.
4. **Persistence time is distinct from worker-local time.** Each worker has a nondeterministically changeable clock offset in {-1, 0, +1} relative to persistence time. This explores bounded slow/fast clock observations without claiming a quantitative drift bound. The request also captures a pre-lock validity snapshot; neither local observation is authoritative in the baseline. A single scalar request context represents at most one pending worker request for this WorkItem at a time; a separate atomic competing-reclaim transition represents another claimant winning while the old request waits. This preserves the critical interleaving without modeling an unbounded request queue.
5. **The serialization point and guard are separate model steps.** A request captures its expected state/generation/token/lifecycle and pre-lock observation, waits, acquires the serialization point, then evaluates the guard against current durable state and persistence time. Time may advance while waiting or while the serialization point is held. The guard and protected mutation are one atomic linearization step.
6. **A lease expiry is not a state transition.** It makes a CLAIMED item eligible for reclaim. The model also treats PROCESSING as a lease-bearing state that becomes reclaimable after expiry. This is a deliberate refinement beyond ADR-001's current wording (which names READY and expired CLAIMED); the owner and independent reviewers must reconcile this state-machine gap before ADR approval. Before a new generation is committed, an old worker must still be rejected if its lease is expired at the post-serialization guard. If an old worker validly linearizes before expiry while holding the serialization point, its mutation is ordered before any later reclaim.
7. **A competing authorized `CLAIMED → PROCESSING` transition is represented as an atomic serialization/guard/mutation action while the older request waits. It is recorded in the same cumulative accepted-mutation history oracle; this ensures the stale-state negative control cannot pass by relying on an unrecorded state change. Installation lifecycle version changes are represented as an input; the model does not decide the unresolved owner policy for already accepted receipts.

## 3. Abstract state and transitions

The model source is formal/G09M3WorkerLeaseGeneration.tla.

| Concern | Abstract state / operation |
|---|---|
| WorkItem lifecycle | ready, claimed, processing, completed, failed, quarantined |
| Durable ownership | claimOwner, claimGeneration, claimToken, leaseExpiry |
| Recovery/guard version | lifecycleVersion |
| Time | persistenceTime, bounded workerClock offsets for W0/W1 |
| In-flight worker request | expected state, generation, token, lifecycle, tenant/installation, request-start time and pre-lock observation |
| Serialization | lockOwner, lock acquisition time, external blocker to model lock wait |
| Operations | claim/reclaim, heartbeat, start-processing, complete, retry, park |
| Audit oracle | accepted mutation history, claim-generation events, mutation count and failed-guard baseline |

A successful claim commits generation, owner, token, expiry and CLAIMED state atomically in the abstract action. Completion, retry and park clear the active owner, token and lease; the generation high-water mark is retained. Worker-local claim data is updated only by that successful claim action. A failed claim grants no ownership.

A retry returns the WorkItem to ready without resetting the generation. The next successful claim advances from the last generation. Park moves the item to quarantine; ordinary workers cannot claim it in this model.

## 4. Guard contract

A protected worker mutation is accepted only if all applicable predicates hold at the serialization/linearization point:

- the authenticated worker principal is the current durable claim owner;
- expected WorkItem state still matches;
- claim generation and opaque token match current durable values;
- lifecycle version matches the request snapshot;
- immutable tenant and installation bindings match;
- the WorkItem remains in an eligible claimed/processing state;
- persistence-authoritative time is strictly before leaseExpiry.

The failed guard changes zero protected rows. A worker-local clock check, pre-lock timestamp, queue message, process-local lease object or heartbeat thread cannot substitute for the post-serialization guard.

## 5. Invariants / oracles

| Invariant | Assertion |
|---|---|
| TypeOK | All abstract variables remain within declared finite domains |
| RequestLockCoherence | Idle/waiting/locked request state, request worker and lock owner remain coherent |
| SingleClaimOwner | Active CLAIMED/PROCESSING items retain the current principal and generation-bound token; READY/COMPLETED/FAILED/QUARANTINED items retain no owner, token or lease |
| HeartbeatDoesNotAdvanceGeneration | Heartbeat/renewal never advances claim generation |
| EveryAcceptedMutationWasAuthorized | Every accepted history entry matches owner, generation, token, lifecycle, expected state, tenant, installation, post-lock time and unexpired lease |
| GuardFailureHasZeroMutation | A failed guard does not change the protected mutation count |
| LeaseNeverRenewedAfterExpiry | No accepted heartbeat occurs at or after expiry |
| GenerationHighWaterNeverRegresses | Current generation equals the durable abstract high-water mark |
| ClaimAdvancesExactlyOnce | Every successful claim event advances by exactly one |
| NewClaimHasCurrentOwnerAndToken | A claimed/processing WorkItem has the current principal and generation-bound token |

The cumulative history oracle retains every accepted protected mutation and every modeled competing authorized mutation (within the finite mutation budget). It records request-start time, lock-acquisition time and the persistence-time observation at the guard. The required ordering is request start ≤ lock acquisition ≤ guard observation. The authoritative expiry decision is made at the last point.

## 6. Negative controls

The runner deliberately injects one defect per TLC configuration:

| Mutant | Defect | Expected oracle |
|---|---|---|
| prelock_time | Uses pre-lock observation after an arbitrary lock wait | EveryAcceptedMutationWasAuthorized |
| worker_clock | Uses a lagging/leading worker clock as authority | EveryAcceptedMutationWasAuthorized |
| stale_generation | Omits both generation and token binding checks | EveryAcceptedMutationWasAuthorized |
| wrong_token | Accepts a mismatched claim token | EveryAcceptedMutationWasAuthorized |
| wrong_tenant | Omits immutable tenant binding | EveryAcceptedMutationWasAuthorized |
| wrong_installation | Omits immutable installation binding | EveryAcceptedMutationWasAuthorized |
| stale_lifecycle | Omits lifecycle-version guard | EveryAcceptedMutationWasAuthorized |
| stale_state | Omits expected-state guard | EveryAcceptedMutationWasAuthorized |
| expired_heartbeat | Allows renewal after expiry | EveryAcceptedMutationWasAuthorized |
| heartbeat_generation | Advances generation during heartbeat | HeartbeatDoesNotAdvanceGeneration |
| guard_mutates | Mutates protected state after guard failure | GuardFailureHasZeroMutation |

A runner is successful only when the baseline completes without an invariant violation and each mutant produces its named expected counterexample. A parse failure, timeout, resource limit, missing counterexample or unexpected invariant is not PASS; it is FAIL or INCONCLUSIVE according to the failure mode.

## 7. Bounds and assumptions

- One immutable WorkItem; two worker processes W0/W1.
- Both worker processes share one authenticated service principal, intentionally.
- Two claim generations (0, 1, 2); LeaseDuration = 2 and persistence-time domain 0..2 are finite exploration constants only. A claim can be initially acquired at time 0 and reclaimed at expiry time 2; the second generation's subsequent expiry is outside this M3 bound.
- Worker-local clock offsets vary nondeterministically within -1..+1 relative to persistence time; this is a bounded skew abstraction, not a quantitative clock-drift bound.
- One serialization point and one external blocker model contention/lock wait.
- One tenant and one installation are modeled; cross-tenant behavior beyond detecting a mismatched binding belongs to M6.
- Token entropy, cryptographic authenticity, IAM implementation, database locking/isolation/time semantics, process kill/STONITH, queue behavior, external effects and restore-incarnation protocol are abstracted or excluded.
- A process restart is not a distinct transition in this finite model; stale local claim data is retained as the resumed-worker abstraction. The explicit restart/reload schedule remains required in the A7/A8 candidate-level test chain. The model does not establish liveness, throughput, lease-duration suitability, retry/backoff policy or production capacity.

## 8. Scope exclusions and dependencies

- M2: database authority epoch and storage-sink fencing.
- M4: outbox, consumer, receiver and external request acceptance after source lease loss.
- M5: restore/PITR, recovery incarnation and quarantine/reopen lifecycle.
- M6: multiple tenants/principals and adversarial authorization boundaries.
- M7: liveness, fairness, capacity, backpressure and resource budgets.
- A4-GATE-03/04 and persistence/worker ADRs: executable candidate tests remain blocked until their approvals. ADR-001 remains PROPOSED; M3 does not approve it.

## 9. Reproduction

The pinned runner is scripts/formal/run_g09_m3.sh; the workflow is .github/workflows/formal-g09-m3.yml. It pins TLA+ Tools v1.7.4 / TLC 2.19 by SHA-256 and preserves per-case logs and metadata as a GitHub Actions artifact. Exact model/config hashes, bounds, state counts, completion status, trace and artifact digest must be added here only after a successful exact-head run.

**Validation status:** pending TLC execution on the exact PR head. No runtime or candidate has been tested or approved.


## 10. Research references

- Martin Kleppmann, [How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html) (2016): stale processes and delayed requests can outlive a lease; the protected resource must actively reject stale fencing tokens.
- Marc Brooker / AWS Builders' Library, [Leader election in distributed systems](https://aws.amazon.com/builders-library/leader-election-in-distributed-systems/) (2019): lease/heartbeat behavior, pauses, clock-duration assumptions, and the risks of leader election; prefer idempotency/optimistic concurrency when a leader is unnecessary.
- PostgreSQL, [Date/Time Functions and Operators](https://www.postgresql.org/docs/current/functions-datetime.html): transaction-start timestamps differ from actual wall-clock sampling; cited as a semantic example, not a database choice.
- PostgreSQL, [Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html): row-lock serialization and lock-wait behavior; cited as a candidate-evaluation reference only.

These references motivate the model's adversarial schedules. They do not prove any Lottorito implementation or select a provider.


The finite clock-offset domain was tightened to -1..+1 to keep the explicit-state search tractable while retaining both slow and fast worker-clock counterexamples. This is an abstraction bound only; production clock behavior remains unselected and unproven.


The pending request context is represented as scalar state rather than per-worker request maps. The two worker processes remain distinct in their local generation/token/clock maps; the one-request abstraction is paired with the explicit competing-reclaim action so the stale-request-versus-new-claim race remains represented.


**Version 0.1.6 review note — mutation-oracle completeness:** A review found that the earlier competing `AuthorizedStartProcessing` transition changed WorkItem state outside the accepted-mutation history. It has been replaced by an explicitly authorized competing transition that validates the current claimant's generation/token/lifecycle/lease and appends its event to the same history oracle. The history now accumulates accepted events instead of retaining only the latest event. The SingleClaimOwner invariant also requires terminal/ready states to have no active owner, token or lease; completion clears those fields while preserving generation. Exact-head TLC validation is pending.
