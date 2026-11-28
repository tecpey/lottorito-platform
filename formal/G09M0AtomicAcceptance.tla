---------------- MODULE G09M0AtomicAcceptance ----------------
EXTENDS Naturals

CONSTANTS
    Callers,
    AllowPartialCommit,
    AllowEarlyAck

ASSUME
    /\ Callers # {}
    /\ AllowPartialCommit \in BOOLEAN
    /\ AllowEarlyAck \in BOOLEAN

(*
M0 abstraction:
- One approved source identity and one semantic fingerprint.
- All callers submit that same identity/fingerprint.
- Receipt + WorkItem are represented by cardinality counters.
- A successful acceptance changes both counters in one atomic action.
- UNKNOWN is an observation, not a server-side commit state.
- Partial-commit and early-ack actions are disabled in the baseline.
  They exist only as negative controls to test oracle sensitivity.
*)

CallerStates ==
    {"idle", "inflight", "committed", "aborted", "duplicate"}

CallerOutcomes ==
    {"none", "pending", "accepted", "rejected",
     "duplicate_confirmed", "unknown"}

VARIABLES
    receiptCount,
    workItemCount,
    receiptOwner,
    txState,
    callerOutcome

vars ==
    << receiptCount, workItemCount, receiptOwner, txState, callerOutcome >>

Init ==
    /\ receiptCount = 0
    /\ workItemCount = 0
    /\ receiptOwner = "none"
    /\ txState = [c \in Callers |-> "idle"]
    /\ callerOutcome = [c \in Callers |-> "none"]

BeginIngress(c) ==
    /\ txState[c] = "idle"
    /\ txState' = [txState EXCEPT ![c] = "inflight"]
    /\ callerOutcome' = [callerOutcome EXCEPT ![c] = "pending"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner>>

CommitAcceptance(c) ==
    /\ txState[c] = "inflight"
    /\ receiptCount = 0
    /\ workItemCount = 0
    /\ receiptCount' = 1
    /\ workItemCount' = 1
    /\ receiptOwner' = c
    /\ txState' = [txState EXCEPT ![c] = "committed"]
    /\ UNCHANGED callerOutcome

ConfirmDuplicate(c) ==
    /\ txState[c] = "inflight"
    /\ receiptCount = 1
    /\ workItemCount = 1
    /\ receiptOwner # c
    /\ txState' = [txState EXCEPT ![c] = "duplicate"]
    /\ callerOutcome' =
         [callerOutcome EXCEPT ![c] = "duplicate_confirmed"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner>>

AbortBeforeCommit(c) ==
    /\ txState[c] = "inflight"
    /\ receiptCount = 0
    /\ workItemCount = 0
    /\ txState' = [txState EXCEPT ![c] = "aborted"]
    /\ callerOutcome' = [callerOutcome EXCEPT ![c] = "rejected"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner>>

CrashBeforeCommit(c) ==
    /\ txState[c] = "inflight"
    /\ receiptCount = 0
    /\ workItemCount = 0
    /\ txState' = [txState EXCEPT ![c] = "aborted"]
    /\ callerOutcome' = [callerOutcome EXCEPT ![c] = "unknown"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner>>

DeliverCommitAck(c) ==
    /\ txState[c] = "committed"
    /\ callerOutcome[c] = "pending"
    /\ callerOutcome' = [callerOutcome EXCEPT ![c] = "accepted"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner, txState>>

LoseCommitAck(c) ==
    /\ txState[c] = "committed"
    /\ callerOutcome[c] = "pending"
    /\ callerOutcome' = [callerOutcome EXCEPT ![c] = "unknown"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner, txState>>

ReconcileUnknown(c) ==
    /\ callerOutcome[c] = "unknown"
    /\ receiptCount = 1
    /\ workItemCount = 1
    /\ callerOutcome' =
         [callerOutcome EXCEPT
             ![c] = IF receiptOwner = c
                    THEN "accepted"
                    ELSE "duplicate_confirmed"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner, txState>>

(*
Negative control 1: deliberately broken atomicity.
Enabled only by a mutant TLC configuration.
*)
CommitReceiptOnly(c) ==
    /\ AllowPartialCommit
    /\ txState[c] = "inflight"
    /\ receiptCount = 0
    /\ workItemCount = 0
    /\ receiptCount' = 1
    /\ workItemCount' = 0
    /\ receiptOwner' = c
    /\ txState' = [txState EXCEPT ![c] = "committed"]
    /\ UNCHANGED callerOutcome

(*
Negative control 2: deliberately broken acknowledgement ordering.
Enabled only by a mutant TLC configuration.
*)
EmitEarlyAck(c) ==
    /\ AllowEarlyAck
    /\ txState[c] = "inflight"
    /\ receiptCount = 0
    /\ workItemCount = 0
    /\ callerOutcome' = [callerOutcome EXCEPT ![c] = "accepted"]
    /\ UNCHANGED <<receiptCount, workItemCount, receiptOwner, txState>>

Next ==
    \E c \in Callers :
        \/ BeginIngress(c)
        \/ CommitAcceptance(c)
        \/ ConfirmDuplicate(c)
        \/ AbortBeforeCommit(c)
        \/ CrashBeforeCommit(c)
        \/ DeliverCommitAck(c)
        \/ LoseCommitAck(c)
        \/ ReconcileUnknown(c)
        \/ CommitReceiptOnly(c)
        \/ EmitEarlyAck(c)

Spec ==
    Init /\ [][Next]_vars

TypeOK ==
    /\ receiptCount \in 0..1
    /\ workItemCount \in 0..1
    /\ receiptOwner \in (Callers \cup {"none"})
    /\ txState \in [Callers -> CallerStates]
    /\ callerOutcome \in [Callers -> CallerOutcomes]

PairAtomicity ==
    receiptCount = workItemCount

AtMostOneReceipt ==
    receiptCount <= 1

AtMostOneWorkItem ==
    workItemCount <= 1

ReceiptOwnerConsistency ==
    /\ (receiptCount = 0 => receiptOwner = "none")
    /\ (receiptCount = 1 => receiptOwner \in Callers)

CommittedRequiresPair ==
    \A c \in Callers :
        txState[c] = "committed"
        => receiptCount = 1 /\ workItemCount = 1 /\ receiptOwner = c

AcceptedAckSoundness ==
    \A c \in Callers :
        callerOutcome[c] = "accepted"
        => txState[c] = "committed"
           /\ receiptCount = 1
           /\ workItemCount = 1
           /\ receiptOwner = c

DuplicateAckSoundness ==
    \A c \in Callers :
        callerOutcome[c] = "duplicate_confirmed"
        => receiptCount = 1
           /\ workItemCount = 1
           /\ receiptOwner # c

UnknownIsNotTerminalSuccess ==
    \A c \in Callers :
        callerOutcome[c] = "unknown"
        => txState[c] \in {"committed", "aborted"}

=============================================================================
