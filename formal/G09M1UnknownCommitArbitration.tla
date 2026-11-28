---------------- MODULE G09M1UnknownCommitArbitration ----------------
EXTENDS Naturals, FiniteSets

CONSTANTS
    SameFingerprint,
    AllowUnsafeRetryOnAbsent,
    AllowPrematureConflict

ASSUME
    /\ SameFingerprint \in BOOLEAN
    /\ AllowUnsafeRetryOnAbsent \in BOOLEAN
    /\ AllowPrematureConflict \in BOOLEAN

OriginalFP == "fp_original"
RetryFP == IF SameFingerprint THEN "fp_original" ELSE "fp_retry"

OriginalStates == {"not_started", "inflight", "committed", "aborted"}
RetryStates == {"not_started", "inflight", "committed", "duplicate", "conflict"}
OriginalOutcomes == {"none", "pending", "unknown", "accepted", "aborted_confirmed"}
RetryOutcomes == {"none", "pending", "unknown", "retry_wait",
                  "accepted", "duplicate_confirmed", "conflict"}

VARIABLES
    originalStatus,
    retryStatus,
    originalOutcome,
    retryOutcome,
    receiptCount,
    receiptOwner,
    receiptFingerprints,
    retryObservedAbsent,
    retryCommittedWhileOriginalInflight

vars ==
    << originalStatus, retryStatus, originalOutcome, retryOutcome,
       receiptCount, receiptOwner, receiptFingerprints,
       retryObservedAbsent, retryCommittedWhileOriginalInflight >>

Init ==
    /\ originalStatus = "not_started"
    /\ retryStatus = "not_started"
    /\ originalOutcome = "none"
    /\ retryOutcome = "none"
    /\ receiptCount = 0
    /\ receiptOwner = "none"
    /\ receiptFingerprints = {}
    /\ retryObservedAbsent = FALSE
    /\ retryCommittedWhileOriginalInflight = FALSE

StartOriginal ==
    /\ originalStatus = "not_started"
    /\ originalStatus' = "inflight"
    /\ originalOutcome' = "pending"
    /\ UNCHANGED <<retryStatus, retryOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

TimeoutOriginal ==
    /\ originalStatus = "inflight"
    /\ originalOutcome = "pending"
    /\ originalOutcome' = "unknown"
    /\ UNCHANGED <<originalStatus, retryStatus, retryOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

StartRetry ==
    /\ originalStatus \in {"inflight", "committed"}
    /\ originalOutcome = "unknown"
    /\ retryStatus = "not_started"
    /\ retryStatus' = "inflight"
    /\ retryOutcome' = "pending"
    /\ UNCHANGED <<originalStatus, originalOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

ObserveAbsent ==
    /\ retryStatus = "inflight"
    /\ receiptCount = 0
    /\ retryObservedAbsent' = TRUE
    /\ retryOutcome' = "retry_wait"
    /\ UNCHANGED <<originalStatus, retryStatus, originalOutcome, receiptCount,
                   receiptOwner, receiptFingerprints,
                   retryCommittedWhileOriginalInflight>>

CommitOriginal ==
    /\ originalStatus = "inflight"
    /\ \/ receiptCount = 0
       \/ /\ receiptCount = 1
          /\ receiptOwner = "retry"
    /\ receiptCount' = receiptCount + 1
    /\ receiptOwner' = IF receiptCount = 0 THEN "original" ELSE "both"
    /\ receiptFingerprints' = receiptFingerprints \cup {OriginalFP}
    /\ originalStatus' = "committed"
    /\ UNCHANGED <<retryStatus, originalOutcome, retryOutcome,
                   retryObservedAbsent, retryCommittedWhileOriginalInflight>>

AbortOriginal ==
    /\ originalStatus = "inflight"
    /\ receiptCount = 0
    /\ originalStatus' = "aborted"
    /\ originalOutcome' = "aborted_confirmed"
    /\ UNCHANGED <<retryStatus, retryOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

AckOriginal ==
    /\ originalStatus = "committed"
    /\ originalOutcome = "pending"
    /\ originalOutcome' = "accepted"
    /\ UNCHANGED <<originalStatus, retryStatus, retryOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

LoseOriginalAck ==
    /\ originalStatus = "committed"
    /\ originalOutcome = "pending"
    /\ originalOutcome' = "unknown"
    /\ UNCHANGED <<originalStatus, retryStatus, retryOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

ObserveCommitted ==
    /\ retryStatus = "inflight"
    /\ originalStatus = "committed"
    /\ receiptCount = 1
    /\ receiptOwner = "original"
    /\ IF RetryFP \in receiptFingerprints
          THEN /\ retryStatus' = "duplicate"
               /\ retryOutcome' = "duplicate_confirmed"
          ELSE /\ retryStatus' = "conflict"
               /\ retryOutcome' = "conflict"
    /\ UNCHANGED <<originalStatus, originalOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

CommitRetryAfterConfirmedAbort ==
    /\ retryStatus = "inflight"
    /\ originalStatus = "aborted"
    /\ originalOutcome = "aborted_confirmed"
    /\ receiptCount = 0
    /\ receiptCount' = 1
    /\ receiptOwner' = "retry"
    /\ receiptFingerprints' = {RetryFP}
    /\ retryStatus' = "committed"
    /\ retryOutcome' = "pending"
    /\ UNCHANGED <<originalStatus, originalOutcome, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

AckRetry ==
    /\ retryStatus = "committed"
    /\ retryOutcome = "pending"
    /\ retryOutcome' = "accepted"
    /\ UNCHANGED <<originalStatus, retryStatus, originalOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

(*
Negative control: a negative read is incorrectly treated as proof that the
original transaction has ended. The retry commits while the original is
still authoritative/in-flight.
*)
UnsafeRetryCommitOnAbsent ==
    /\ AllowUnsafeRetryOnAbsent
    /\ retryStatus = "inflight"
    /\ retryObservedAbsent
    /\ originalStatus = "inflight"
    /\ receiptCount = 0
    /\ receiptCount' = 1
    /\ receiptOwner' = "retry"
    /\ receiptFingerprints' = {RetryFP}
    /\ retryStatus' = "committed"
    /\ retryOutcome' = "pending"
    /\ retryCommittedWhileOriginalInflight' = TRUE
    /\ UNCHANGED <<originalStatus, originalOutcome>>

(*
Negative control: a differing fingerprint is rejected as a conflict before
the original identity has a committed canonical receipt.
*)
PrematureConflict ==
    /\ AllowPrematureConflict
    /\ ~SameFingerprint
    /\ retryStatus = "inflight"
    /\ originalStatus = "inflight"
    /\ receiptCount = 0
    /\ retryStatus' = "conflict"
    /\ retryOutcome' = "conflict"
    /\ UNCHANGED <<originalStatus, originalOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent,
                   retryCommittedWhileOriginalInflight>>

Next ==
    \/ StartOriginal
    \/ TimeoutOriginal
    \/ StartRetry
    \/ ObserveAbsent
    \/ CommitOriginal
    \/ AbortOriginal
    \/ AckOriginal
    \/ LoseOriginalAck
    \/ ObserveCommitted
    \/ CommitRetryAfterConfirmedAbort
    \/ AckRetry
    \/ UnsafeRetryCommitOnAbsent
    \/ PrematureConflict

Spec ==
    Init /\ [][Next]_vars

TypeOK ==
    /\ originalStatus \in OriginalStates
    /\ retryStatus \in RetryStates
    /\ originalOutcome \in OriginalOutcomes
    /\ retryOutcome \in RetryOutcomes
    /\ receiptCount \in 0..2
    /\ receiptOwner \in {"none", "original", "retry", "both"}
    /\ receiptFingerprints \subseteq {OriginalFP, RetryFP}
    /\ retryObservedAbsent \in BOOLEAN
    /\ retryCommittedWhileOriginalInflight \in BOOLEAN

ReceiptShape ==
    /\ (receiptCount = 0
        => receiptOwner = "none" /\ receiptFingerprints = {})
    /\ (receiptCount = 1
        => receiptOwner \in {"original", "retry"}
           /\ Cardinality(receiptFingerprints) = 1)
    /\ (receiptCount = 2
        => receiptOwner = "both"
           /\ OriginalFP \in receiptFingerprints)

ReceiptCardinality ==
    receiptCount <= 1

OriginalAckSoundness ==
    originalOutcome = "accepted"
    => originalStatus = "committed"
       /\ receiptCount = 1
       /\ receiptOwner = "original"
       /\ OriginalFP \in receiptFingerprints

RetryAckSoundness ==
    retryOutcome = "accepted"
    => originalStatus = "aborted"
       /\ receiptCount = 1
       /\ receiptOwner = "retry"
       /\ receiptFingerprints = {RetryFP}

DuplicateSoundness ==
    retryOutcome = "duplicate_confirmed"
    => originalStatus = "committed"
       /\ receiptCount = 1
       /\ receiptOwner = "original"
       /\ RetryFP \in receiptFingerprints

ConflictSoundness ==
    retryOutcome = "conflict"
    => originalStatus = "committed"
       /\ receiptCount = 1
       /\ receiptOwner = "original"
       /\ RetryFP \notin receiptFingerprints

NoRetryCommitWhileOriginalInflight ==
    retryCommittedWhileOriginalInflight = FALSE

NoTerminalRetryResolutionWhileOriginalInflight ==
    originalStatus = "inflight"
    => retryOutcome \notin {"accepted", "duplicate_confirmed", "conflict"}

=============================================================================
