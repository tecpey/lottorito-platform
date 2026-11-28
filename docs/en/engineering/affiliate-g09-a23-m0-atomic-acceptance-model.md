# G09-A23-M0 — Formal Atomic Acceptance Model

**Document ID:** LOT-AFFILIATE-G09-A23-M0-001  
**Version:** 0.1.0  
**Status:** Initial proposed model; TLC execution and independent review not performed  
**Model:** `formal/G09M0AtomicAcceptance.tla`  
**Baseline configuration:** `formal/G09M0AtomicAcceptance.cfg`  
**Normative basis:** ADR-002 §§2, 4, 5, 6 and 7; A22 §5; A23 §§3, 4, 5 and 7

## 1. Purpose and scope

M0 is the first bounded model in the A23 model family. It examines the minimum acceptance contract for **one fixed Source Identity and one fixed Semantic Fingerprint** with two concurrent callers:

1. Receipt and WorkItem both commit or neither commits;
2. no more than one Receipt or WorkItem is created for the modeled identity;
3. ACCEPTED is emitted only after the durable pair commits;
4. a lost response after commit yields UNKNOWN rather than an assumed failure;
5. the second caller with the same identity/fingerprint converges to a confirmed duplicate, not a second acceptance.

M0 does not decide owner-open values such as the final identity tuple, fingerprint, tenant/installation, durability/RPO, isolation level, database, queue or wire status.

## 2. Abstraction and assumptions

| Concern | M0 abstraction |
|---|---|
| Callers | Exactly two symbolic actors: callerA and callerB |
| Source Identity | One fixed identity shared by both callers |
| Semantic Fingerprint | One fixed, identical fingerprint; conflict is out of scope |
| Receipt / WorkItem | Independent cardinality counters, each bounded 0..2 so mutants can be detected |
| Commit authority | One logical authority; successful commit is one atomic transition |
| Concurrency | Interleaving of atomic steps; both Begin operations may precede Commit |
| Crash | Before the commit transition, or after commit and before acknowledgement |
| Retry/UNKNOWN without a record | Deferred to M1 |
| Tenant, authority epoch, worker and external effects | Out of scope |

**Important abstraction boundary:** the atomic `CommitAcceptance` transition assumes the persistence authority commits the pair as one logical operation. This model alone does not prove that a real candidate places both writes in one transaction, enforces cardinality at commit time or survives failover. Those require later refinement and implementation evidence.

## 3. Variables and transitions

- `receiptCount` and `workItemCount`: logical record counts for the single identity.
- `receiptOwner`: caller that won initial acceptance.
- `txState[c]`: transaction-attempt state for each caller.
- `callerOutcome[c]`: outcome actually observed by the caller.

Main transitions:

- `BeginIngress`: start an attempt without acceptance.
- `CommitAcceptance`: atomically increment both cardinalities from zero to one.
- `ConfirmDuplicate`: confirm a duplicate for the other caller without another write.
- `AbortBeforeCommit`: a definite, known abort before commit.
- `CrashBeforeCommit`: crash before the commit point; caller observes UNKNOWN.
- `LoseCommitAck`: commit happened but the acknowledgement is lost; caller observes UNKNOWN.
- `ReconcileUnknown`: if the durable pair exists in the model, recover the existing outcome.

A crash during commit is abstracted to the two sides of the linearization point: either the crash occurs before the atomic transition, or commit occurs and the response is subsequently lost. A partially committed pair is not allowed on the healthy path.

## 4. Checked invariants

| Model ID | Invariant | Intended meaning |
|---|---|---|
| TypeOK | Variable domains | State remains within declared domains |
| PairAtomicity | `receiptCount = workItemCount` | No partial pair |
| AtMostOneReceipt | `receiptCount <= 1` | At most one Receipt |
| AtMostOneWorkItem | `workItemCount <= 1` | At most one WorkItem |
| ReceiptOwnerConsistency | Owner consistency | Owner exists only when a Receipt exists |
| CommittedRequiresPair | Commit requires pair | A committed attempt cannot lack the pair |
| AcceptedAckSoundness | Ack soundness | ACCEPTED only for the committed pair and winning caller |
| DuplicateAckSoundness | Duplicate soundness | Duplicate only with an existing pair owned by another caller |
| UnknownIsNotTerminalSuccess | UNKNOWN preservation | UNKNOWN is not converted into a definite success |

M0 does not claim or check Liveness/Fairness. `CHECK_DEADLOCK FALSE` prevents normal termination of the bounded model from being interpreted as a progress violation; it makes no Liveness claim.

## 5. Negative controls and oracle sensitivity

Three mutant configurations deliberately enable an unsafe transition to test whether the selected invariants detect the violation:

| Configuration | Deliberate mutation | Expected violation |
|---|---|---|
| `G09M0MutantPartialCommit.cfg` | Commit Receipt only | PairAtomicity |
| `G09M0MutantDuplicatePair.cfg` | Create a second pair for the same identity | AtMostOneReceipt / AtMostOneWorkItem |
| `G09M0MutantEarlyAck.cfg` | Emit success acknowledgement before commit | AcceptedAckSoundness |

These are **design expectations**, not executed results. Until TLC is run, no actual counterexample or oracle-sensitivity result is recorded.

## 6. Toolchain pin and reproducible execution

The model's baseline toolchain is pinned to stable **TLA+ Tools v1.7.4 (TLC 2.19)**; Java 11 or newer is required. Version 1.8.0, published as a pre-release/rolling build at this review, is not adopted into the baseline. Expected JAR hash:

`SHA-256: 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`

Download and verify the tool:

```bash
curl --fail --location --silent --show-error \
  https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar \
  --output /tmp/tla2tools.jar
echo "936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88  /tmp/tla2tools.jar" | sha256sum --check -
```

Run all four configurations from the repository root:

```bash
TLA2TOOLS_JAR=/tmp/tla2tools.jar \
TLC_OUT_DIR=/tmp/g09-m0-results \
bash scripts/formal/run_g09_m0.sh
```

The runner records the Java version, JAR hash, complete output for each run and metadata for each state store. It uses one worker, a fixed seed and an isolated metadata directory per configuration. The baseline must complete with TLC's success output; each mutant must violate its predicted invariant. An unexpected exit code, different message, parser error or missing expected counterexample fails the gate.

For every run, retain model/config hashes, complete TLC output, state/transition counts, elapsed time/resources, completion status and counterexamples. If a mutant is not detected, review the oracle or mutation; do not call it PASS.

## 7. Limitations and next models

M0 does not prove the following and deliberately defers them:

- Arbitration of an in-flight original attempt against retry, negative reads and UNKNOWN without a record: **M1**;
- Authority epochs, split-brain, promotion and stale-writer return: **M2**;
- Lease, claim, generation and worker fencing: **M3**;
- Outbox, consumer and external receiver effects: **M4**;
- Restore, tombstones and replay horizon: **M5**;
- Tenant/principal and authorization boundaries: **M6**;
- Liveness, resource pressure and fairness: **M7**.

In particular, M0 does not assume that observing no record proves the original transaction has terminated. That race is the central subject of M1. M0 also does not model tenant isolation or disclosure of another tenant's identity.

## 8. Evidence status

- TLA+ module and configurations are recorded;
- TLC was not run in this step;
- formal syntax/type checking has not yet been performed;
- no state-space count or actual counterexample exists;
- negative controls are design-only;
- no candidate or runtime has been evaluated;
- ADR-002 remains PROPOSED and A11-F01..F08 remain open;
- A20-01..A20-28 remain NOT RUN.

**Conclusion:** M0 defines an initial executable model for atomic acceptance. Until TLC execution and subsequent refinement against candidate behavior, no implementation-correctness or qualification claim is permitted.
