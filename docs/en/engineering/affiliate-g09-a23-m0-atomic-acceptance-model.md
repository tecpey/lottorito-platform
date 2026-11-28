# G09-A23-M0 — Formal Atomic Acceptance Model

**Document ID:** LOT-AFFILIATE-G09-A23-M0-001  
**Version:** 0.1.4  
**Status:** TLC-executed bounded model; independent review and candidate refinement not performed  
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

The following results were observed in Run #11 on exact head `2ec0350e476e6ec3b90ce241bfedbe53a50799af`:

| Configuration | Actual TLC result | Recorded exploration |
|---|---|---|
| Baseline | No invariant violation; state space exhausted | 87 generated, 52 distinct, zero queued, depth 7 |
| Partial commit | `PairAtomicity` violated at depth 3 | 7 generated, 7 distinct; stopped after counterexample |
| Duplicate pair | `AtMostOneReceipt` violated at depth 5 | 34 generated, 24 distinct; stopped after counterexample |
| Early acknowledgement | `AcceptedAckSoundness` violated at depth 3 | 7 generated, 7 distinct; stopped after counterexample |

All three negative controls triggered exactly the predicted oracle. Mutant counts are not complete state-space counts; TLC stopped after finding each counterexample.

## 6. Toolchain pin and executed evidence

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

The runner records Java version, JAR hash, SHA-256 hashes for the model/configurations, complete output for each run and metadata for each state store. It uses one worker, a fixed seed and an isolated metadata directory per configuration.

**Executed evidence:** [GitHub Actions — G09 M0 Formal Model Run #11](https://github.com/tecpey/lottorito-platform/actions/runs/46170075939). Job result: SUCCESS. Toolchain: Eclipse Temurin OpenJDK 17.0.21.1; TLA+ Tools v1.7.4 / TLC 2.19; JAR SHA-256 matches the pin above. Artifact: `g09-a23-m0-tlc-46170075939-1`; digest: `sha256:c92d28c736ef367934a8823709ed9df11f81d9d131c4ce64b5df0420527e9e3b`.

SHA-256 hashes of the executed module and configurations:

| File | SHA-256 |
|---|---|
| `G09M0AtomicAcceptance.tla` | `4740bc9d76c10ec76bf0bca00b5f829963b99365fef0a600a0886a2fe9cf2e6f` |
| `G09M0AtomicAcceptance.cfg` | `ad63aa16b0604b4c82d5f6c5e3435ccb5e6cd51a3fca994e303a3cd263132f7e` |
| `G09M0MutantPartialCommit.cfg` | `3fab9ce1b8d3b1b1bcdad8690d28db2e9254171cc5b962526df7ba82fefc7767` |
| `G09M0MutantDuplicatePair.cfg` | `7e24f26489c8e02c7798a298101d73efd71e49ca61ea383d5885aded91224f3a` |
| `G09M0MutantEarlyAck.cfg` | `975ecfbf8e14541311ada32e812413a918c6f8d759bfa3c9024258e7b5e39938` |

This result applies only to this module/config/toolchain/bounds; it does not generalize to an implementation, candidate, durability or production behavior.

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

## 8. Reproducible execution evidence

**PR-associated run:** GitHub Actions Run `46171747722` — [G09 M0 Formal Model](https://github.com/tecpey/lottorito-platform/actions/runs/46171482274)  
**PR head:** `19f8e995596bd4fca96b3bea0a211ddb916b1725`  
**Synthetic merge commit checked by the pull_request runner:** `c50c70bcfb8e1ece85ab155b5c36d547099bac3e` (merge of the head above into base `f032065f47fe85de2aabf8d47565a57af6af3ae9`)  
**Artifact:** [g09-a23-m0-tlc-46171747722-1](https://github.com/tecpey/lottorito-platform/actions/runs/46171482274/artifacts/15273842484)  
**Artifact ZIP SHA-256:** `7f346cde1cb5f48b9ae042b5cb23266a53561cccfc4960acd479e8ddf90cc832`

Toolchain and environment:
- TLA+ Tools release: `v1.7.4`
- TLC: `2.19`, revision `5a47802`, dated 2024-08-08
- TLA+ Tools JAR SHA-256: `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`
- Java: Eclipse Temurin `17.0.21.1+2`
- Runner: Ubuntu `24.04.5`, GitHub-hosted `ubuntu-24.04`
- TLC options: breadth-first search, one worker, seed 1, fp 0, 1 GiB heap.

Results:
| Case | TLC result | Generated / distinct states | Depth | Oracle result |
|---|---|---:|---:|---|
| Baseline | No violation | 87 / 52 | 7 | As expected |
| Partial-commit mutant | `PairAtomicity` violated | 7 / 7 | 3 | Detected |
| Duplicate-pair mutant | `AtMostOneReceipt` violated | 34 / 24 | 5 | Detected |
| Early-ack mutant | `AcceptedAckSoundness` violated | 7 / 7 | 3 | Detected |

Model/configuration hashes retained in the artifact's `sha256-manifest.txt`:
- TLA module: `4740bc9d76c10ec76bf0bca00b5f829963b99365fef0a600a0886a2fe9cf2e6f`
- Baseline config: `ad63aa16b0604b4c82d5f6c5e3435ccb5e6cd51a3fca994e303a3cd263132f7e`
- Partial-commit config: `3fab9ce1b8d3b1b1bcdad8690d28db2e9254171cc5b962526df7ba82fefc7767`
- Duplicate-pair config: `7e24f26489c8e02c7798a298101d73efd71e49ca61ea383d5885aded91224f3a`
- Early-ack config: `975ecfbf8e14541311ada32e812413a918c6f8d759bfa3c9024258e7b5e39938`

TLC parsed and semantically processed the module and checked the invariants; no separate type-system tool was run. All three mutants produced actual, reproducible counterexamples. The artifact contains four TLC logs and the hash manifest.

**Interpretation boundary:** the GitHub run is associated with the PR head above, but the `pull_request` runner executed on the synthetic merge commit listed above. This is an integration check of the PR/base combination, not a claim that the branch tip alone was directly executed. Checkout v7.0.1 and Upload Artifact v7.0.2 are pinned to immutable SHAs, and persisted checkout credentials are disabled.

Independent model review and candidate refinement have not yet been performed;
- no candidate or runtime has been evaluated;
- ADR-002 remains PROPOSED and A11-F01..F08 remain open;
- A20-01..A20-28 remain NOT RUN.

**Conclusion:** M0 was checked by TLC within its finite bounds and detected all three deliberate mutations with the predicted oracles. This is evidence for that bounded model only, not a general protocol proof or implementation qualification. Independent review and candidate refinement remain mandatory.
