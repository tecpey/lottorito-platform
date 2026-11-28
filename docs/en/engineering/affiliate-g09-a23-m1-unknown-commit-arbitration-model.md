# G09-A23-M1 — Unknown Commit Arbitration and Concurrent Retry Model

**Document ID:** LOT-AFFILIATE-G09-A23-M1-001  
**Version:** 0.1.0  
**Status:** Initial proposed model; TLC execution and independent review pending CI  
**Model:** `formal/G09M1UnknownCommitArbitration.tla`  
**Configurations:** two baselines and three negative controls in `formal/G09M1*.cfg`  
**Normative basis:** ADR-002, A22 and A23; M0

## 1. Problem isolated by M1

M0 established that a lost acknowledgement after commit must yield UNKNOWN. M1 models the more dangerous race: Caller 1 may still have an active database transaction, while a timeout makes its caller observe UNKNOWN and Caller 2 starts a retry.

**A read that cannot see a Receipt does not prove that the original transaction aborted.** The model keeps these propositions distinct:

- `receiptCount = 0`: no Receipt is visible in the observed snapshot;
- `originalStatus = "aborted"`: the transaction authority has definitively reported an abort.

Only the second proposition permits the retry to commit as a new acceptance attempt.

## 2. Reference evidence and applicability boundary

- PostgreSQL documents that when inserting a unique key conflicting with a row inserted by an uncommitted transaction, the inserter must wait for that transaction to resolve; if it rolls back there is no conflict, and if it commits uniqueness is violated. This is a relevant design principle, but no PostgreSQL version or candidate implementation has been selected or verified for Lottorito. [PostgreSQL — Index Uniqueness Checks](https://www.postgresql.org/docs/current/index-unique-checks.html). <Cite refs={["turn809426search4"]}/>
- PostgreSQL documentation for `INSERT ... ON CONFLICT` also explains that a concurrent transaction's result may not be visible in an ordinary snapshot, while the unique-conflict path must resolve that transaction. This is a database-specific example, not authorization to select a Lottorito version or SQL statement. [PostgreSQL — INSERT](https://www.postgresql.org/docs/current/sql-insert.html). <Cite refs={["turn809426search1","turn809426search3"]}/>
- Google Spanner explicitly describes Unknown Commit Status: a timeout may occur before or after commit; retrying without deduplication can execute a business operation twice. [Spanner — Unknown Commit Status](https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once). <Cite refs={["turn809426search0","turn809426search2"]}/>
- AWS Builders’ Library emphasizes retaining the request identifier and original parameters for idempotency; reusing the same identifier with different intent must be detected as a mismatch. [Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). <Cite refs={["turn809426search15"]}/>

These sources inform the hypothesis and design; none independently selects the final candidate or architecture.

## 3. Scope and abstraction

M1 models one fixed Source Identity, one original attempt, one retry and one commit authority. The `SameFingerprint` parameter creates two baseline cases:

1. Same identity and same fingerprint: a retry after the original commit must become a confirmed duplicate;
2. Same identity and different fingerprint: a retry after the original commit must become a confirmed conflict.

If the original transaction definitively aborts and no Receipt was created, the retry may commit its own fingerprint as the sole Receipt. Its fingerprint may differ from the original attempt because the original attempt never became canonical.

M1 does not model tenants, installations, source epochs, multiple identities, leases/workers, outbox, external receivers, retention or restore.

## 4. Key variables

- `originalStatus`: `not_started | inflight | committed | aborted`
- `originalOutcome`: what the first caller observes; timeout and actual commit status are separate state.
- `retryStatus` and `retryOutcome`: retry execution state and its observed response.
- `receiptCount`: Receipt count for the identity; bounded 0..2 so a mutant can expose duplication.
- `receiptOwner` and `receiptFingerprints`: owner and fingerprints of committed Receipts.
- `retryObservedAbsent`: observation of no Receipt; not evidence of abort.
- `retryCommittedWhileOriginalInflight`: records an unauthorized retry commit while the original attempt remained in flight.

## 5. Main transitions

- `StartOriginal` and `TimeoutOriginal`: start the original attempt and turn the observed timeout into UNKNOWN without changing the transaction's actual state.
- `StartRetry`: start a retry after UNKNOWN; the original may still be in flight or may already have committed.
- `ObserveAbsent`: observe no Receipt; the retry enters `retry_wait` and gains no commit authority.
- `CommitOriginal` / `AbortOriginal`: definitively resolve the original transaction.
- `LoseOriginalAck`: commit occurred, but the caller observes UNKNOWN.
- `ObserveCommitted`: after original commit, equal fingerprints resolve to Duplicate and differing fingerprints to Conflict.
- `CommitRetryAfterConfirmedAbort`: the only healthy path that lets a retry become accepted after a definitive original abort.
- `AckRetry`: acknowledgement is emitted only after the retry's Receipt commits.

## 6. Invariants and test objective

| Invariant | Contract |
|---|---|
| `TypeOK` | State domains remain valid |
| `ReceiptShape` | Cardinality, owner and fingerprints remain consistent |
| `ReceiptCardinality` | No more than one Receipt is created for the identity |
| `OriginalAckSoundness` | Original acknowledgement requires its committed Receipt |
| `RetryAckSoundness` | Retry may become ACCEPTED only after definitive original abort |
| `DuplicateSoundness` | Duplicate is allowed only after canonical commit with equal fingerprint |
| `ConflictSoundness` | Conflict is allowed only after canonical commit with a differing fingerprint |
| `NoRetryCommitWhileOriginalInflight` | Retry must not commit while the original attempt is in flight |
| `NoTerminalRetryResolutionWhileOriginalInflight` | While the original is in flight, retry cannot reach terminal Accepted/Duplicate/Conflict |

M1 makes no Liveness claim and sets no time bound for resolving UNKNOWN. `retry_wait` may remain until the commit authority supplies a definitive result.

## 7. Negative controls

| Config | Injected fault | Expected violation |
|---|---|---|
| `G09M1MutantUnsafeRetry.cfg` | Retry incorrectly treats an absence observation as commit authority | `NoRetryCommitWhileOriginalInflight` |
| `G09M1MutantDoubleCommit.cfg` | The same unsafe retry is followed by original commit | `ReceiptCardinality` |
| `G09M1MutantPrematureConflict.cfg` | A differing fingerprint is classified as Conflict before canonical commit | `ConflictSoundness` |

Two separate baselines cover equal and differing fingerprints. Negative controls must demonstrate oracle sensitivity; if an expected violation is not detected, M1 is not acceptable.

## 8. Limitations and next step

- M1 is not a model of a specific database or a proof of real lock/unique-index behavior; those require candidate refinement and implementation testing.
- The model abstracts a definitive abort as a state; proving which real adapter responses may safely be classified as definitive abort remains open.
- M1 does not assume UNKNOWN without a Receipt is resolved while the original transaction is active; it models waiting and denial of a second acceptance.
- M2 must cover authority epochs, promotion and stale writers.
- Jepsen/history checking and real database tests have not run.

**Evidence status:** the model and configurations are authored; no PASS or counterexample is claimed until CI completes and its logs are reviewed. This document authorizes no candidate, runtime, partner, financial operation, production, merge or deployment.
