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
    retryObservedAbsent

vars ==
    << originalStatus, retryStatus, originalOutcome, retryOutcome,
       receiptCount, receiptOwner, receiptFingerprints,
       retryObservedAbsent >>

Init ==
    /\ originalStatus = "not_started"
    /\ retryStatus = "not_started"
    /\ originalOutcome = "none"
    /\ retryOutcome = "none"
    /\ receiptCount = 0
    /\ receiptOwner = "none"
    /\ receiptFingerprints = {}
    /\ retryObservedAbsent = FALSE

StartOriginal ==
    /\ originalStatus = "not_started"
    /\ originalStatus' = "inflight"
    /\ originalOutcome' = "pending"
    /\ UNCHANGED <<retryStatus, retryOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent>>

TimeoutOriginal ==
    /\ originalStatus = "inflight"
    /\ originalOutcome = "pending"
    /\ originalOutcome' = "unknown"
    /\ UNCHANGED <<originalStatus, retryStatus, retryOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent>>

StartRetry ==
    /\ originalStatus \in {"inflight", "committed"}
    /\ originalOutcome = "unknown"
    /\ retryStatus = "not_started"
    /\ retryStatus' = "inflight"
    /\ retryOutcome' = "pending"
    /\ UNCHANGED <<originalStatus, originalOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent>>

ObserveAbsent ==
    /\ retryStatus = "inflight"
    /\ receiptCount = 0
    /\ retryObservedAbsent' = TRUE
    /\ retryOutcome' = "retry_wait"
    /\ UNCHANGED <<originalStatus, retryStatus, originalOutcome, receiptCount,
                   receiptOwner, receiptFingerprints>>

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
                   retryObservedAbsent>>

AbortOriginal ==
    /\ originalStatus = "inflight"
    /\ receiptCount = 0
    /\ originalStatus' = "aborted"
    /\ originalOutcome' = "aborted_confirmed"
    /\ UNCHANGED <<retryStatus, retryOutcome, receiptCount, receiptOwner,
                   receiptFingerprints, retryObservedAbsent>>

AckOriginal ==
    /\ originalStatus = "committed"
    /\ originalOutcome = "pending"
    /\ originalOutcome' = "accepted"
    /\ UNCHANGED <<originalStatus, retryStatus, retryOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent>>

LoseOriginalAck ==
    /\ originalStatus = "committed"
    /\ originalOutcome = "pending"
    /\ originalOutcome' = "unknown"
    /\ UNCHANGED <<originalStatus, retryStatus, retryOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent>>

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
                   receiptFingerprints, retryObservedAbsent>>

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
    /\ UNCHANGED <<originalStatus, originalOutcome, retryObservedAbsent>>

AckRetry ==
    /\ retryStatus = "committed"
    /\ retryOutcome = "pending"
    /\ retryOutcome' = "accepted"
    /\ UNCHANGED <<originalStatus, retryStatus, originalOutcome, receiptCount,
                   receiptOwner, receiptFingerprints, retryObservedAbsent>>

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
    /\ UNCHANGED <<originalStatus, originalOutcome, retryObservedAbsent>>

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
                   receiptFingerprints, retryObservedAbsent>>

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

ReceiptShape ==
    /\ (receiptCount = 0
        => receiptOwner = "none" /\ receiptFingerprints = {})
    /\ (receiptCount = 1
        => \/ /\ receiptOwner = "original"
              /\ receiptFingerprints = {OriginalFP}
           \/ /\ receiptOwner = "retry"
              /\ receiptFingerprints = {RetryFP})
    /\ (receiptCount = 2
        => receiptOwner = "both"
           /\ OriginalFP \in receiptFingerprints
           /\ RetryFP \in receiptFingerprints)

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
    ~(originalStatus = "inflight" /\ retryStatus = "committed")

NoTerminalRetryResolutionWhileOriginalInflight ==
    originalStatus = "inflight"
    => retryOutcome \notin {"accepted", "duplicate_confirmed", "conflict"}

=============================================================================
