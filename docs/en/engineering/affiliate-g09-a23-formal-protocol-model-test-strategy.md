# G09-A23 — Formal Protocol Model & Adversarial Test Strategy

**Document ID:** LOT-AFFILIATE-G09-A23-001  
**Version:** 0.1.8 | **Status:** PROPOSED; M0 AND M1 TLC-CHECKED WITHIN FINITE BOUNDS; RUNTIME NOT EXECUTED; M2–M7 NOT AUTHORED  
**Date:** 2026-11-28  
**Review basis:** G09-A21, G09-A22, G09-A20, G09-A7, ADR-001 and ADR-002  
**Authority:** Advisory design; no owner decision, candidate, gate or execution permission is approved.

## 1. Purpose and authority boundary

A23 advances the A21 remediation sequence for F03, F04, F05, F11 and F12: explicit state-machine modeling, separation of safety from liveness, declared progress assumptions, fault-combination analysis and reproducible schedule generation.

This document is a **model contract and test strategy**. It is not an executed TLA+ model, TLC result, executed Jepsen test or proof of any candidate's behavior. No PASS result, state count, coverage, benchmark or effectiveness claim may be inferred.

A23:
- does not approve ADR-002 or resolve OD-01..OD-12;
- does not select a database, queue, cloud, region, vendor, isolation level or topology;
- does not claim A20-01..A20-28 have run;
- does not close A21-F01/F06/F08/F13; assurance and bilingual parity remain for A24;
- grants no R2, partner integration, real-data, financial-system, production, merge or deployment authorization.

## 2. Inputs and model boundary

Normative inputs are: the proposed atomic InboxReceipt + WorkItem pair in ADR-002; the Claim/Lease/Fencing protocol in ADR-001; the 47 stable A4 identifiers and S1..S5 schedules in A7; A20-01..A20-28; the trace/evidence contract in A22; and unresolved owner decisions.

### 2.1 Included components

1. Ingress with at least two concurrent callers/nodes.
2. Source-event identity and versioned semantic fingerprint, without assuming the final tuple.
3. Persistence authority with an epoch/term and authority transfer.
4. Acceptance transaction that atomically stores Receipt and WorkItem.
5. Commit outcomes: ACCEPTED, REJECTED, DUPLICATE_CONFIRMED, CONFLICT, UNKNOWN and QUARANTINED.
6. Worker claim with generation and lease, plus serialized state transitions.
7. Optional DeliveryOutbox, distinct from WorkItem; asynchronous broker and consumer.
8. Restore/PITR, tombstone, recovery incarnation and reconciliation.
9. Trusted tenant/installation context and least-privilege principals.
10. Faults: crash, partition, delay, reorder, lost response, retry, clock skew, failover, restore, key/config/schema change and resource pressure.

### 2.2 Excluded from the base model

Commission formulas, NGR, ledger posting, wallet, payment, payout, prize, player state and actual partner behavior are outside the ingress-acceptance model. Ingress/worker identities have no financial mutation capability in the base model. A20-27 may be examined only under separate authorization and a separate model; A23 is not that authorization.

## 3. State vocabulary and abstract contract

| Variable | Model meaning |
|---|---|
| tenant | authoritative tenant derived from trusted installation/context |
| sourceIdentity | versioned event tuple under approved ODs; symbolic for now |
| semanticFingerprint | versioned semantic-content fingerprint; symbolic for now |
| authorityEpoch | monotonically increasing persistence write/repair authority epoch |
| authorityOwner | only actor permitted to commit in the current epoch |
| acceptanceTxn | acceptance transaction state: absent / in-flight / committed / aborted / unknown |
| receipt | durable acceptance receipt |
| workItem | durable accepted work record |
| callerOutcome | last outcome actually observed by the caller |
| claimGeneration | monotonically increasing claim generation per WorkItem; never decremented, wrapped, reset or reused |
| claimOwner | authenticated principal owning the current claim |
| claimToken | secret/unpredictable token bound to the current owner and generation |
| lifecycleVersion | lifecycle version used to guard protected transitions |
| leaseExpiry | persistence-authoritative expiry time for the current claim |
| leaseState | lease state; expiry alone does not authorize mutation |
| leaseClockModel | authoritative time/skew model and how time is sampled relative to the serialization point |
| leaseObservation | lease-validity observation after acquiring the serialization point, not a stale pre-lock timestamp |
| workState | abstract WorkItem state: ready / claimed / processing / completed / failed / quarantined / blocked |
| outboxState | optional publication state after source commit |
| consumerReceipt | consumer-side independent deduplication/receipt |
| restoreIncarnation | unique identifier for a restore/recovery incarnation |
| tombstone | durable marker for consumed/expired identity under approved policy |
| tombstoneState | marker lifecycle: active / eligible_for_expiry / expired / legal_hold |
| sourceReplayHorizon | source redelivery/replay horizon; approved finite bound or explicitly unbounded |
| identityProtectionHighWaterMark | authoritative high-water mark preventing resurrection of consumed identities |
| restoreMode | restore state: quarantined / reconciling / eligible_to_reopen |
| recoveryGateSet | required gate set for restore reconciliation and reopening |
| destinationIdentity | stable effect/operation identity at the external destination under its contract |
| destinationAuthority | destination's independent epoch/generation or acceptance authority, if supported |
| destinationReceipt | authoritative destination receipt for idempotency/lookup |
| destinationOutcome | caller-observed destination result: confirmed / rejected / unknown |
| externalEffect | destination-side effect; outside the source transaction and without end-to-end atomicity |
| quarantineState | contained state not claimable by ordinary workers |

Identity, fingerprint, retention, authority epoch, clock reference, physical cardinality and wire outcomes remain open parameters until ODs are approved. The model must not turn example values into policy.

## 4. Required transitions

The formal model must define at least the following transitions with preconditions, state changes and permitted/prohibited effects:

| Transition | Preconditions and expected effect |
|---|---|
| BeginIngress | records an attempt; creates neither acceptance nor successful acknowledgement |
| CommitAcceptance | current authority only; Receipt and WorkItem commit together or neither commits |
| LoseResponse | caller response is lost; server state may be committed or aborted |
| ObserveUnknown | caller lacks sufficient evidence and observes UNKNOWN; it must not become an assumed success/failure |
| Reconcile | sufficiently consistent authoritative read; race-safe against an in-flight original transaction |
| DuplicateIngress | same identity and fingerprint; at most one durable pair |
| ConflictingIngress | same identity, different fingerprint; conflict/quarantine, never overwrite |
| TransferAuthority | new epoch activates only through authoritative protocol and enforceable fencing |
| RejectStaleWriter | old-epoch writer is rejected at the mutation point |
| ClaimWork | resolve WorkItem and tenant/installation binding from trusted persistence; after serialization, claim only READY or CLAIMED with expired lease under approved policy; increment generation exactly once and commit owner/token/expiry/state in one transaction; never report ownership before commit |
| ExpireAndReclaim | CLAIMED with expired lease under approved policy; serialized reclaim increments generation exactly once and atomically changes owner/token/expiry/state; reject the old generation after commit |
| LinearizeLeaseTransition | after acquiring the serialization point, the guard evaluates lease validity there; if expired, mutation is rejected; only a transition with a valid lease and complete guard may linearize |
| ResumeStaleWorker | source-side protected mutation is rejected if the lease is expired at the guard point or owner/generation/token/authority no longer matches. This rejection does not cancel an external request already dispatched; the destination outcome must be checked under the receiver contract |
| RenewLease | CLAIMED; owner/token/generation/authority/state/lifecycle version match and lease is still valid at the post-serialization guard; extend expiry only, never increment generation or resurrect an expired lease |
| CommitWorkTransition | guard WorkItem/tenant/installation binding, expected state, authenticated principal, owner, generation, token, lease validity at the linearization point, authority and lifecycle version; a failed guard changes zero protected rows |
| PublishOutbox | only from durable outbox; delivery may duplicate or reorder |
| ConsumeMessage | consumer rereads/claims authoritative work; broker message alone is not authority |
| Restore | data and metadata are restored without silently rolling back authority/identity |
| ReconcileRestore | data, epoch, identity/tombstone high-water mark, queue/inbox/outbox, credential/key, schema and tenant divergence is exposed and resolved; environment remains quarantined |
| ReopenAfterRestore | only after all recovery gates and approved evidence are complete; otherwise fail closed |
| ReplaySourceIdentity | examine replay before/after tombstone expiry against the actual source horizon and source epoch/namespace; a consumed identity must not be silently accepted again |
| ExpireTombstone | only after the finite redelivery/replay/backup/PITR/queue/manual-replay horizon is proven exhausted and no legal hold applies; if no finite horizon can be proven, expiry is forbidden and permanent retention or a proven epoch/namespace rollover/cutover is required |
| Quarantine/Repair | authorized, bounded, fully audited actor; ordinary workers cannot claim quarantined work |
| SubmitExternalEffect | only after valid work/outbox; destination enforces its own identity/idempotency/fencing contract |
| ReconcileExternalEffect | resolve destination UNKNOWN using authoritative destination lookup; do not infer absence from cache/timeout |
| RejectStaleDestinationActor | only a destination with proven receiver-side fencing rejects an old epoch/generation at effect time; otherwise late acceptance may occur and UNKNOWN/residual risk must be recorded |
| DispatchExternalRequest | dispatch with stable destinationIdentity and fingerprint across the process boundary; in-flight state is independent of the source lease |
| AcceptExternalRequest | receiver accepts/rejects under its own idempotency/fencing/ordering contract; arrival may occur after the source lease expires |
| LoseExternalResponse | receiver may have applied the effect but the response is lost; caller observes destinationOutcome=unknown |
| RetryExternalRequest | retry only with the same approved destinationIdentity/idempotency key and fingerprint; never mint a new key for the same effect |
| ExpireReceiverDedupWindow | record destination dedup-retention expiry; replay after expiry must not be assumed a safe duplicate without a new receiver contract and explicit risk/outcome |

**Linearization and lease-expiry rule (aligned with ADR-001):** every protected transition must have a defined linearization point. Checking lease/epoch or sampling time before waiting for a lock is insufficient; after acquiring the serialization point, the guard must re-evaluate lease validity at that point. If the lease has expired at this point, the transition is rejected even if reclaim or a new generation has not yet been recorded. Expiry alone does not mutate state or generation; it invalidates the lease condition and makes work eligible for reclaim. If the old worker still has a valid lease and current owner/generation/token/authority at the guard point and the serialized mutation succeeds, that transition is ordered before reclaim. If reclaim commits first, the old generation is rejected. A local worker clock or pre-lock timestamp cannot replace this rule. A23 does not prescribe one implementation mechanism as a universal answer.

## 5. Safety properties — invariants

Each property must have a stable ID, related state/transitions, independent oracle, expected counterexample and A20/A7 mapping.

| ID | Required property |
|---|---|
| S-01 Atomic Pair | for every accepted identity, Receipt and WorkItem are both durable or neither is |
| S-02 Uniqueness | at most one acceptance pair exists for each approved identity tuple |
| S-03 Conflict Safety | same identity with a different fingerprint is never treated as a harmless duplicate or overwritten |
| S-04 Ack Soundness | ACCEPTED is returned only after durable commit is proven under the approved policy |
| S-05 Unknown Preservation | UNKNOWN is neither ACCEPTED nor REJECTED until valid reconciliation |
| S-06 Authority Fencing | an old-epoch actor cannot mutate protected state after authority transfer |
| S-07 Worker Fencing | every protected mutation checks identity/tenant/installation binding, expected state, principal, owner, generation, token, lease validity at the linearization point, authority and lifecycle version; stale generations are rejected and a failed guard changes zero protected rows. External effects are protected only by proven receiver-side controls, otherwise S-14/UNKNOWN/residual risk applies |
| S-08 Restore Monotonicity | restore/PITR cannot silently resurrect or roll back epoch, consumed identity or revocation; a restored environment remains quarantined until reconciliation and approved recovery gates complete, with ingress/workers/egress disabled |
| S-09 Tenant Isolation | no cross-tenant read/write/disclosure through identity, payload, retry or repair |
| S-10 Outbox Boundary | broker messages are not acceptance authority; publisher/consumer and the internal consumer receipt follow the consumer-side deduplication contract; duplicate broker delivery alone must not create duplicate mutation in the consumer's authoritative store. External receiver guarantees are separate under S-14 |
| S-11 External Effect Boundary | database atomicity is never represented as end-to-end exactly-once for an external destination |
| S-12 Financial Non-effect | ingress and worker lack an authorized path to financial mutation; financial delta remains zero |
| S-13 Evidence Integrity | every result is attributable to history, config, version, clock, actor and hashed artifact |
| S-14 Destination Safety | every external effect is protected by provable destination-side idempotency/lookup/fencing, or explicitly remains outside any exactly-once guarantee as UNKNOWN/residual risk; a database token alone does not fence a destination |
| S-15 Lease Linearization | lease validity is checked after acquiring the serialization point and in the guard for that mutation; if expired at that point, mutation is rejected even before reclaim; expiry alone does not mutate state/generation; a valid transition before expiry and before reclaim is ordered before reclaim; after reclaim commits with a new generation, all old-generation mutations are rejected |

Safety must hold for every reachable prefix, not merely at the end of a lucky run. A valid counterexample is FAIL; absence of a counterexample in a bounded model is not proof of the real system.

## 6. Liveness, fairness and degraded mode

Liveness is conditional on explicit assumptions. No claim that work is “always processed” is valid under permanent partition, quorum loss, permanent destination failure, lack of capacity or a stopped scheduler.

Proposed progress properties, under stated assumptions:

- L-01: with valid/stable authority, available persistence, resources below approved limits and a fair scheduler, eligible WorkItem eventually becomes claimed and reaches processing/a declared outcome; quarantine is allowed only under an explicit predicate and audit, not as a general escape from progress.
- L-02: when the original transaction terminates definitively and authoritative reconciliation is available, UNKNOWN eventually becomes provable; otherwise UNKNOWN is preserved and escalated.
- L-03: after broker/consumer recovery and backpressure relief, eligible outbox work is eventually retried; duplicate delivery is allowed, a second effect is not.
- L-04: one high-volume tenant cannot indefinitely prevent all other tenants from progressing beyond approved limits.
- L-05: quarantine/repair has a visible human/operational path and does not become an unbounded hidden queue.

Strong/weak fairness, scheduler behavior, arrival rate, capacity, retry budget, quota and deadline are separate parameters and decisions. The model must separately examine degraded state, safe stop, backpressure, retry storm, starvation and post-fault recovery. Safety PASS is not Liveness PASS.

## 7. Model-checking architecture and bounds

### 7.1 Model families

Do not start with one enormous model. Build staged models with shared interfaces/invariants:

1. **M0 — Atomic Acceptance:** two callers, one identity, one Receipt and one WorkItem; crash before/during/after commit.
2. **M1 — UNKNOWN Arbitration:** original transaction in-flight, lost response, negative read, concurrent retry and late commit/abort.
3. **M2 — Authority Epoch:** two writers, two epochs, partition, promotion, old-primary return and restored epoch.
4. **M3 — Worker Lease:** two workers/generations, claim and reclaim, lease renewal, heartbeat/completion/retry/park, state/token/lifecycle-version mismatch, zero-mutation guard failure, lock wait, pre/post-lock timestamp, clock skew, lease expiry before reclaim and stale-worker resume.
5. **M4 — Outbox/Consumer/Receiver:** duplicate publication, delay, reorder, broker outage, consumer crash, in-flight external request, receiver acceptance after source lease expiry, lost response, retry, destination idempotency/fencing and receiver dedup-retention expiry.
6. **M5 — Restore/Lifecycle:** old PITR/backup, tombstone and expiry boundary, finite/unbounded replay horizon, late queue message, credential/key/schema rotation, recovery incarnation, failback, clean-room quarantine and reopening gates.
7. **M6 — Tenant/Principal:** at least two tenants and two principals with different permissions; payload spoofing and low-privilege repair.
8. **M7 — Liveness/Resources:** hot tenant, burst, retry, quota, backpressure, fairness and degraded mode.

### 7.2 Initial bounds for finite models

The following are starting points for model exploration only, not product capacity, SLO or policy:

- 2 tenants; 2 source identities; 2 fingerprints;
- 2 ingress nodes/callers; 2 authority epochs;
- 2 workers; 2 claim generations;
- 1 broker; 1 consumer; at most 2 messages;
- 1 old and 1 new restore incarnation;
- 2 retry attempts and bounded crash/partition/delay events.

Explore cardinalities 0, 1 and 2 and alternate transition orderings. Symmetry reduction is allowed only when actor identities are genuinely symmetric for the property being checked. Small bounds do not prove behavior for 3+ actors, real capacity, real time or every interleaving.

### 7.3 Required model-checker output

For every run record: tool/runtime version, model/config hashes, constants/bounds, assumptions, invariants/temporal properties, state/transition counts, time/resources, completion/termination status, complete counterexample, trace and reproduction procedure. M0 has been checked with TLC v1.7.4: its baseline exhausted all 52 distinct states without invariant violations, and all three negative controls detected their predicted violations. Evidence and hashes are recorded in the companion M0 document. This result is limited to that model and its bounds. State-space exhaustion applies only to that model and those bounds. An incomplete run, resource limit or unchecked property is INCONCLUSIVE.

TLC is an explicit-state model checker for a subset of TLA+ and finite models; results are therefore bounded by the model, bounds and properties actually checked. [R1]

## 8. Implementation test strategy: Model → History → Fault

Model checking does not replace testing the actual candidate. After separate gates and authorization, the test chain has three layers:

### 8.1 Model layer

- TLA+/TLC for safety and modelable temporal properties;
- explicit state-space bounds, assumptions and abstractions;
- minimal reproducible counterexamples;
- comparison of abstract model with actual contract and implementation.

### 8.2 History/concurrency layer

- record Invoke/Complete operations with correlation ID, identity, actor, epoch, generation and observed outcome; for external effects, record dispatch time, receiver acceptance, receipt and caller outcome separately;
- independent history checker for uniqueness, ordering, linearization and absence of duplicate effects;
- fault injector for partition, process kill, network delay/loss, node restart, failover and clock skew;
- deterministic seed, barriers and ordered schedules for exact race reproduction;
- report safety, liveness, availability and performance separately.

Jepsen provides a useful reference pattern for concurrent operations, history recording, Nemesis fault injection and checker-based history analysis; this does not select a tool or candidate. [R2]

### 8.3 Simulation/failure-injection layer

FoundationDB's deterministic simulation approach demonstrates how simulated and production execution can share a runtime design while enabling broad, controlled fault reproduction. This is a research pattern, not a recommendation to select FoundationDB. [R3]

### 8.4 Retry and transaction callbacks

A retriable transaction must perform only operations inside its transaction boundary. External side effects, webhook/email/payment calls or non-transactional mutations must not occur inside a callback the engine may execute again. Spanner documents that transaction bodies may run multiple times and external side effects may repeat; PostgreSQL requires retrying the entire transaction and its decision logic after serialization failures. [R4][R5]

Retries must be error-classified, idempotent, bounded by budget/deadline and use backoff/jitter; retries at multiple layers must not compound. These are design requirements; values remain open pending approved workload/owner decisions. [R6]

## 9. Schedule generation and combinatorial coverage

Every schedule must have an immutable manifest: schedule ID, seed, ordered events, actor, preconditions, fault, trigger/release barrier, wait, observation point, oracle, expected history and hash.

Generation method:

1. Preserve A7/A20 hand-authored schedules as the regression corpus.
2. Use the state machine and transitions as the basis for property-based generation.
3. Use pairwise and risk-weighted t-way fault combinations; explicitly add critical combinations.
4. Shrink counterexamples to the shortest reproducible schedule.
5. Turn every discovered bug into a permanent regression with fixed seed/trace.
6. Mutation-test oracle/checker correctness using known mutants.

Minimum mutants: remove unique constraint; acknowledge before commit; accept a negative read from a stale replica; omit epoch check at mutation; accept an old worker generation; accept a mutation after lease expiry but before reclaim; renew an expired lease or increment generation during heartbeat; commit with wrong token/state/lifecycle version; mutate a row after guard failure; reset epoch after restore; expire a tombstone before the replay/backup horizon ends; enable ingress/workers/egress before restore gates complete; retry with a new identity; accept a stale external request without a receiver contract; retry an external effect with a new idempotency key; ignore receiver-side dedup-retention expiry; execute side effects inside a retried transaction; remove consumer deduplication; and convert UNKNOWN to REJECTED/ACCEPTED without evidence. If the checker misses its corresponding mutant, checker sensitivity is INCONCLUSIVE.

Seed count, repetitions, soak duration, combinatorial coverage and thresholds must be derived from approved workload/risk; no example value is a default.

## 10. Mapping to A20 and A7

| Model area | A20 | A7 / A4 | Expected output |
|---|---|---|---|
| Atomic pair and commit | 04–08 | A4-DUR-01/02; S2/S4 | uniqueness and UNKNOWN histories |
| Authority and failover | 01–04, 09, 16–17, 24 | A4-DUR-03/05 | fencing and durability proof |
| Worker lease and stale actor | 09–10 | A4-DUR-05; S3 | stale-generation rejection |
| Outbox and consumer | 11–12 | A4-DUR-06 and related cases | deduplication, ordering and backpressure |
| Restore and lifecycle | 13–18, 21–22, 26 | A4-DUR/AUTH; S4/S5 | no identity/authority resurrection |
| Tenant and principal | 19–20 | A4-AUTH; S5 | no tenant-boundary crossing |
| Resource and liveness | 12, 23, 28 | A4-RESOURCE | fairness and degraded mode |
| Financial non-effect | 27 | A4-FIN | zero financial effect; no posting authorization |
| Evidence/audit | 20, 25 | A4-EVIDENCE | reconstructability and evidence integrity |

This mapping is initial; a complete bidirectional Requirement→Property→Schedule→Oracle→Artifact matrix must be finalized in A24/the machine-readable manifest. New cases must not change stable A4 identifiers; subcases have separate IDs and parent/child outcomes are reported separately.

## 11. Results, classification and stop rules

- **PASS:** all mandatory assertions pass within the named scope/bounds/configuration using valid oracles.
- **FAIL:** a valid counterexample or assertion violation is observed.
- **INCONCLUSIVE:** incomplete model/run, unproven fault, invalid oracle, missing evidence or insufficient bounds.
- **NOT_RUN:** not executed.
- **BLOCKED:** prerequisite, owner decision, gate or authorization is missing.

Model, simulation, history, performance and recovery results are reported separately. Bounded-model PASS is not candidate PASS or production PASS. Findings cannot be offset by a count of successful tests or a benchmark.

## 12. Gate sequence and authorization

| Stage | Work | Entry/exit condition |
|---|---|---|
| R1 / A23 | complete model and test strategy | A23 reviewed; bounds/assumptions/properties and traceability clear |
| R1 / A24 | assurance, oracle trust and bilingual parity | F01/F06/F08/F13 and evidence package dispositioned |
| R1 exit | re-review A20–A24 | all P0/P1 and required decisions have authorized dispositions; no hidden blocker |
| R2 | harness and candidate proof | written scope authorization, isolated synthetic environment, exact candidate and relevant gates |
| R3 | production proof/release | separate authorization and all legal/security/finance/operations gates; outside A23 |

## 13. Research basis

- [R1] TLA+ Wiki — TLC Explicit-State Model Checker: https://docs.tlapl.us/using:tlc:start
- [R2] Jepsen — Distributed Systems Verification with Fault Injection: https://github.com/jepsen-io/jepsen
- [R3] FoundationDB — Simulation and Testing: https://github.com/apple/foundationdb/blob/main/documentation/sphinx/source/testing.rst
- [R4] Google Cloud Spanner — Transactions overview and transaction callback retry behavior: https://docs.cloud.google.com/spanner/docs/transactions
- [R5] PostgreSQL — Transaction Isolation and Serializable failure handling: https://www.postgresql.org/docs/current/transaction-iso.html ; https://www.postgresql.org/docs/16/mvcc-serialization-failure-handling.html
- [R6] AWS Well-Architected — Control and limit retry calls: https://docs.aws.amazon.com/wellarchitected/latest/framework/rel05-bp03.html
- Lamport — Safety and Liveness: https://lamport.azurewebsites.net/tla/safety-liveness.pdf

These sources support methods and failure classes; they do not prove Lottorito correctness, any specific candidate or a deployment.

## 14. Final disposition

**Version 0.1.3 review note:** cross-review against ADR-001 and A22 made three boundaries explicit: an expired lease rejects a mutation at the post-serialization guard even before reclaim; source-side fencing does not cancel an external request already in flight; and a restored environment remains quarantined until identity high-water mark, tombstone, queue/outbox, credential/key, schema and tenant reconciliation plus reopening gates are complete. Restore/Reopen/Replay/ExpireTombstone transitions, lifecycle variables, S-08 and M5 were refined. The ADR-001 cross-check also added Claim/Generation/Owner/Token/LeaseExpiry/LifecycleVersion and the full guard for heartbeat/completion/retry/park; RenewLease does not increment generation or resurrect an expired lease. A21-F04/F05/F10/F11 remain OPEN; all refinements still require model checking, evidence and authorized review.


- A23: proposed model contract and test strategy; **NOT EXECUTED**.
- M0 was checked with TLC v1.7.4: 52 distinct baseline states; expected counterexamples for partial commit, duplicate pair and early acknowledgement. Independent review and candidate refinement have not been performed; M1–M7 are not yet authored.
- Jepsen/history checker/simulation: not executed.
- A20-01..A20-28: DESIGNED / NOT RUN.
- A21-F03/F04/F05/F11/F12: receive a design-level method/model response; remain OPEN pending model completion, review and evidence.
- A21-F01/F06/F08/F13: remain for A24.
- OD-01..OD-12, C-01..C-16, G1..G9: OPEN / NOT APPROVED.
- ADR-002: PROPOSED; A11-F01..F08 OPEN; A12 not performed.
- R0 BLOCKED; R1 research; R2 not started; R3 not authorized; A4 not approved.
- No candidate, runtime, executable harness, partner, financial operation, production, merge or deployment is authorized.

**Version 0.1.4 review note:** the first TLA+ module for M0, one baseline configuration and three negative-control configurations were authored; a bilingual M0 model note was added.

**Version 0.1.6 review note:** M0 was rerun in GitHub Actions Run `46170218651`, associated with PR head `c9d2e2b7e3d80bf53a64e928df647bcd1cb20ebc`. The `pull_request` runner executed on synthetic merge commit `9a9aa076de9700717e4d41d14766d8414fdd2b5b`. TLC 2.19 / Tools v1.7.4, Temurin Java 17.0.21.1; baseline: 87 generated, 52 distinct, zero queued, depth 7, no violation. The three mutants violated `PairAtomicity`, `AtMostOneReceipt` and `AcceptedAckSoundness`, respectively. Artifact ID `15273631651`, ZIP SHA-256 `0ae142aac63ca8bc9e9cdd1e802b98bdd8abf8e829045e3d99879ba92bd60d4d`. This bounded model has not received independent review and covers no candidate/runtime. M1–M7, the history checker and simulation remain unstarted.

**Conclusion:** A23 upgrades modeling and testing from a list of scenarios to a traceable engineering method; it does not claim real execution or system acceptance.


**Version 0.1.8 review note:** M0 and M1 were run independently on PR head `10d143bfb8eaff1892a74e3277f4dcac1f024337` and synthetic merge commit `a7a670bd6453a2c86fd7733c4aeae3f8aa7b4777`. M0 Run `46171482274`: 52 distinct baseline states; all three mutants produced expected counterexamples; artifact ID `15273523034`, SHA-256 `5cd254c2bd9b7121af93c0b7384d9927f054031d2acbd7c6eef1e41670eb72d9`. M1 Run `46171482180`: both baselines (same/different fingerprint) had 19 distinct and 25 generated states, depth 8; the three mutants violated `NoRetryCommitWhileOriginalInflight`, `ReceiptCardinality` and `ConflictSoundness`, respectively; artifact ID `15273920318`, SHA-256 `eb38518421706ed88d03c8bf77339d1747036c5aff6811e6d666ef62b7b78ea9`. Both workflows used Checkout v7.0.1 and Upload Artifact v7.0.2 pinned to immutable SHAs; persisted credentials were disabled. This evidence is limited to the bounded models; independent review, candidate refinement, Jepsen/history checking and simulation have not occurred. M2–M7 are not authored.
