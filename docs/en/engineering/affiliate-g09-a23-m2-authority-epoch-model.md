# G09-A23-M2 — Authority Epoch and Writer Fencing Model

**Document ID:** LOT-AFFILIATE-G09-A23-M2-001  
**Version:** 0.1.0 | **Status:** AUTHORED; TLC BASELINE AND NEGATIVE CONTROLS PENDING  
**Model:** formal/G09M2AuthorityEpochFencing.tla  
**Baseline:** formal/G09M2AuthorityEpochFencing.cfg  
**Runner:** scripts/formal/run_g09_m2.sh  
**Workflow:** .github/workflows/formal-g09-m2.yml  
**Normative parent:** LOT-AFFILIATE-G09-A23-001 §§3–7; proposed ADR-002; G09-A21/A22

## 1. Purpose and scope

M2 models the A23 Authority Epoch family: two writers, two epochs, a network partition, authority transfer, enforcement at the mutation sink, old-primary return and restore of stale data. It is candidate-neutral. It does not select a database, consensus implementation, cloud, failover manager, topology or physical fencing mechanism.

The model keeps three questions distinct:

1. **Election/selection:** which writer is proposed as the next owner?
2. **Authority transfer:** when does the trusted authority allocate the next non-reusable epoch?
3. **Fencing:** when does the actual mutation sink begin rejecting the old epoch?

A selected or elected writer is not thereby safe to write. The sink must enforce the authority epoch, and activation follows verified enforcement.

## 2. Abstraction and assumptions

| Concern | M2 abstraction |
|---|---|
| Writers | Two symbolic actors, W0 (old) and W1 (candidate) |
| Epoch domain | Finite integers 1..3; one transfer is reachable in the baseline |
| Authority root | rootEpoch, authorityOwner, and monotonic authorityHighWater |
| Writer credential | Abstract authenticated token, bound to writer and epoch; no cryptography modeled |
| Mutation enforcement | One canonical sink with sinkFenceEpoch |
| Transfer phases | active → frozen → allocated → fenced → active |
| Partition | W0 becomes unreachable while W1 remains reachable; this is a fault abstraction, not a quorum algorithm |
| Restore | Restored data may contain an older epoch; authority root is separate and restore remains quarantined |
| Writes | A successful write records writer, token epoch, authority epoch and sink fence epoch at that transition |

The model assumes the authority root/high-water mark is trusted and cannot be silently rolled back in the healthy protocol. The restore mutant deliberately violates that assumption to test the oracle. If the actual authority root itself can be rolled back and no independent recovery authority exists, the system must fail closed; this model does not invent a recovery mechanism.

## 3. Protocol and linearization boundary

The healthy transfer is:

1. **Freeze:** stop old-writer admission.
2. **Allocate:** allocate a new epoch from the authority root and bind it to W1.
3. **Apply fence:** advance the canonical mutation sink's accepted epoch. This is the modeled fencing/linearization barrier.
4. **Verify:** obtain evidence that the sink enforces the new epoch.
5. **Activate:** only now enable W1.
6. **Resume:** allow writes only when writer, authenticated token, authority owner, root epoch and sink epoch all match.

The model separates ApplyFenceAtSink from VerifyFenceEvidence; an allocation or control-plane acknowledgement alone is not fence evidence. A write that linearizes before the sink barrier is not retroactively cancelled. A write after the barrier must carry the current epoch and be accepted by the same canonical enforcement boundary.

A partition or missed heartbeat is not itself proof that W0 is dead. It cannot enable promotion. The healthy model can make progress only through the explicit freeze/allocate/fence/verify sequence.

## 4. Variables and principal transitions

| Variable | Meaning |
|---|---|
| rootEpoch | Current epoch allocated by the trusted authority |
| authorityHighWater | Non-rollback high-water mark for allocated epochs |
| authorityOwner | Writer authorized by the authority root |
| writerEpoch | Epoch bound to each writer |
| tokenEpoch, tokenAuthenticated | Abstract credential authenticity and epoch binding |
| sinkFenceEpoch | Minimum epoch accepted by the canonical mutation sink |
| fenceVerified | Evidence flag after the sink barrier |
| phase | Transfer/recovery phase |
| networkPartition, writerReachable | Simplified reachability fault |
| restoreMode, restoredEpoch | Restore quarantine and epoch in restored data |
| acceptedWrites | Write-time evidence tuple, not just a final-state counter |

Main transitions: FreezeOldWriter, AllocateNewEpoch, ApplyFenceAtSink, VerifyFenceEvidence, ActivateNewWriter, SetPartition, HealPartition, CrashOldWriter, ReturnOldWriter, TryAuthorizedWrite, BeginRestore, ReconcileRestore and FinishRestore.

TryAuthorizedWrite is enabled only when the writer is online/reachable/active, its token is authenticated and epoch-bound, and writer epoch = token epoch = authority epoch = sink fence epoch, with the writer equal to the authority owner. A stale writer returning after failover cannot satisfy this guard.

## 5. Checked safety invariants

| Invariant | Contract |
|---|---|
| TypeOK | All state remains within the declared finite domains |
| SingleWriter | At most one writer is active |
| RootEpochAtLeastHighWater | Restored data cannot lower the authority root below its non-rollback high-water mark |
| NewWriterActivationRequiresFence | W1 cannot be active before verified sink fencing at the current epoch |
| RestoreQuarantine | During restore/reconciliation, no writer is active and the phase remains quarantined/fenced |
| EveryWriteWasFencedAndAuthorized | Each accepted write records equal writer/token/authority/sink epochs and the authority owner |
| AuthenticatedCurrentTokenHasAuthorityOwner | A token claiming the current epoch cannot belong to a non-owner |
| NoActiveWriterDuringUnverifiedTransfer | No writer is active while transfer fencing is unverified |

These are safety checks. M2 makes no liveness claim and does not add fairness assumptions. A deadlocked or safely stopped state is not evidence of progress.

## 6. Negative controls and expected oracle sensitivity

| Configuration | Deliberate fault | Expected invariant violation |
|---|---|---|
| G09M2MutantEarlyPromotion.cfg | Activate W1 before sink fence/evidence | NewWriterActivationRequiresFence |
| G09M2MutantPartitionPromotion.cfg | Treat partition as sufficient promotion authority | NewWriterActivationRequiresFence |
| G09M2MutantStaleWrite.cfg | Let W0 write after sink epoch advances | EveryWriteWasFencedAndAuthorized |
| G09M2MutantRestoreRollback.cfg | Roll authority epoch back to restored stale data | RootEpochAtLeastHighWater |
| G09M2MutantForgedEpoch.cfg | Give non-owner W0 an authenticated-looking current-epoch token | AuthenticatedCurrentTokenHasAuthorityOwner |

A mutant is accepted only if TLC reports the named invariant violation. If the baseline fails, a mutant is not considered validated. If a mutant does not trigger its expected oracle, inspect the transition and invariant; do not weaken the oracle merely to obtain green CI.

## 7. Reproduction

The runner verifies the pinned TLA+ Tools v1.7.4 JAR SHA-256 before executing one baseline and five negative controls:

    TLA2TOOLS_JAR=/path/to/tla2tools.jar \
    TLC_OUT_DIR=/tmp/g09-m2-results \
    bash scripts/formal/run_g09_m2.sh

The GitHub Actions workflow downloads the same pinned JAR, verifies its hash, executes the runner and retains TLC logs/state metadata as an artifact. It uses the same deterministic runner pattern as M0/M1.

**Execution status:** NOT RUN at the time this document was authored. No state count, counterexample, PASS or model-checking completion is claimed. Only an exact-head Actions run and its retained artifact can establish the result for this revision.

## 8. Limitations and refinement obligations

- The finite model uses two writers and at most one epoch transfer; it is not an unbounded proof.
- tokenAuthenticated abstracts signature/issuer validation. It does not prove key management, token unforgeability, revocation propagation or credential rotation.
- One canonical sink is modeled. If old and new writers can mutate independent writable stores, fencing one sink does not fence the other. Such a topology needs a shared enforcement authority or independently proven physical fencing (for example, STONITH).
- Partition reachability is deliberately simple. The model does not implement Raft/Paxos, quorum membership, failure detectors or a witness protocol.
- The root/high-water mark is abstractly trusted. Backup/PITR restoration of the authority root, loss of quorum state, disaster recovery and recovery-incarnation allocation need separate evidence and model refinement.
- The model does not define the ordering of in-flight writes across a real storage engine's transaction/commit boundary. A candidate must prove its actual mutation linearization and durability semantics.
- No database, queue, vendor, topology, RPO, failover timer or numeric operational threshold is selected.
- TLC does not prove a real database, runtime, failover controller or production environment correct. Candidate refinement, deterministic fault injection and history/linearizability checking remain later, separately authorized work.

## 9. Research basis

- Google, Mike Burrows, **The Chubby lock service for loosely-coupled distributed systems**, OSDI 2006. Chubby sequencers carry lock-generation information and the receiving resource server is expected to reject invalid/stale sequencers: https://www.usenix.org/legacy/event/osdi06/tech/full_papers/burrows/burrows_html/
- PostgreSQL, **Warm Standby — Failover**. The old primary must be informed/fenced after standby promotion to avoid both nodes acting as primary: https://www.postgresql.org/docs/current/warm-standby-failover.html
- Leslie Lamport, **Proving Safety Properties**. Invariants are state properties checked across all reachable states of the specified model; the conclusion remains scoped to that specification: https://lamport.org/tla/proving-safety.pdf

These sources support the design method and failure model; they do not certify this model or any Lottorito implementation.

## 10. Disposition

M2 is authored as a candidate-neutral finite-state model with one baseline and five oracle-targeted negative controls. Its status remains **AUTHORED / TLC PENDING** until exact-head CI completes and its logs are inspected. It does not close A21 findings, approve ADR-002, satisfy an A4 gate, authorize R2, select a persistence candidate, or authorize runtime/partner/financial/production work, merge or deployment.
