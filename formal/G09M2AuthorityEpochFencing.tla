---------------- MODULE G09M2AuthorityEpochFencing ----------------
EXTENDS Naturals, FiniteSets

CONSTANT Mutation

Writers == {"W0", "W1"}
Phases == {"active", "frozen", "allocated", "fenced", "quarantined"}
Mutations == {"none", "early_promotion", "partition_promotion",
              "stale_write", "restore_rollback", "forged_epoch"}

ASSUME Mutation \in Mutations

VARIABLES
    rootEpoch,
    authorityHighWater,
    authorityOwner,
    phase,
    writerEpoch,
    tokenEpoch,
    tokenAuthenticated,
    writerOnline,
    writerReachable,
    writerActive,
    sinkFenceEpoch,
    fenceVerified,
    networkPartition,
    restoreMode,
    restoredEpoch,
    acceptedWrites

vars ==
    << rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, writerActive, sinkFenceEpoch, fenceVerified,
       networkPartition, restoreMode, restoredEpoch, acceptedWrites >>

Init ==
    /\ rootEpoch = 1
    /\ authorityHighWater = 1
    /\ authorityOwner = "W0"
    /\ phase = "active"
    /\ writerEpoch = ["W0" |-> 1, "W1" |-> 0]
    /\ tokenEpoch = ["W0" |-> 1, "W1" |-> 0]
    /\ tokenAuthenticated = ["W0" |-> TRUE, "W1" |-> FALSE]
    /\ writerOnline = ["W0" |-> TRUE, "W1" |-> TRUE]
    /\ writerReachable = ["W0" |-> TRUE, "W1" |-> TRUE]
    /\ writerActive = ["W0" |-> TRUE, "W1" |-> FALSE]
    /\ sinkFenceEpoch = 1
    /\ fenceVerified = TRUE
    /\ networkPartition = FALSE
    /\ restoreMode = FALSE
    /\ restoredEpoch = 1
    /\ acceptedWrites = {}

FreezeOldWriter ==
    /\ phase = "active"
    /\ authorityOwner = "W0"
    /\ phase' = "frozen"
    /\ writerActive' = [writerActive EXCEPT !["W0"] = FALSE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

AllocateNewEpoch ==
    /\ phase = "frozen"
    /\ rootEpoch < 3
    /\ rootEpoch' = rootEpoch + 1
    /\ authorityHighWater' = rootEpoch + 1
    /\ authorityOwner' = "W1"
    /\ writerEpoch' = [writerEpoch EXCEPT !["W1"] = rootEpoch + 1]
    /\ tokenEpoch' = [tokenEpoch EXCEPT !["W1"] = rootEpoch + 1]
    /\ tokenAuthenticated' = [tokenAuthenticated EXCEPT !["W1"] = TRUE]
    /\ phase' = "allocated"
    /\ fenceVerified' = FALSE
    /\ UNCHANGED <<writerOnline, writerReachable, writerActive,
       sinkFenceEpoch, networkPartition, restoreMode, restoredEpoch,
       acceptedWrites>>

ApplyFenceAtSink ==
    /\ phase = "allocated"
    /\ sinkFenceEpoch' = rootEpoch
    /\ phase' = "fenced"
    /\ fenceVerified' = FALSE
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, writerActive, networkPartition, restoreMode,
       restoredEpoch, acceptedWrites>>

VerifyFenceEvidence ==
    /\ phase = "fenced"
    /\ sinkFenceEpoch = rootEpoch
    /\ fenceVerified' = TRUE
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, writerActive, sinkFenceEpoch, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

ActivateNewWriter ==
    /\ phase = "fenced"
    /\ fenceVerified
    /\ sinkFenceEpoch = rootEpoch
    /\ authorityOwner = "W1"
    /\ ~restoreMode
    /\ phase' = "active"
    /\ writerActive' = [writerActive EXCEPT !["W1"] = TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

SetPartition ==
    /\ ~networkPartition
    /\ networkPartition' = TRUE
    /\ writerReachable' = [writerReachable EXCEPT !["W0"] = FALSE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerActive, sinkFenceEpoch, fenceVerified, restoreMode,
       restoredEpoch, acceptedWrites>>

HealPartition ==
    /\ networkPartition
    /\ networkPartition' = FALSE
    /\ writerReachable' = ["W0" |-> TRUE, "W1" |-> TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerActive, sinkFenceEpoch, fenceVerified, restoreMode,
       restoredEpoch, acceptedWrites>>

CrashOldWriter ==
    /\ writerOnline["W0"]
    /\ writerOnline' = [writerOnline EXCEPT !["W0"] = FALSE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerReachable,
       writerActive, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

ReturnOldWriter ==
    /\ ~writerOnline["W0"]
    /\ writerOnline' = [writerOnline EXCEPT !["W0"] = TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerReachable,
       writerActive, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

TryAuthorizedWrite(w) ==
    /\ w \in Writers
    /\ writerOnline[w]
    /\ writerReachable[w]
    /\ writerActive[w]
    /\ ~restoreMode
    /\ tokenAuthenticated[w]
    /\ tokenEpoch[w] = writerEpoch[w]
    /\ writerEpoch[w] = rootEpoch
    /\ writerEpoch[w] = sinkFenceEpoch
    /\ w = authorityOwner
    /\ acceptedWrites' =
         acceptedWrites \cup
           {[writer |-> w,
             epoch |-> writerEpoch[w],
             ownerAtWrite |-> authorityOwner,
             tokenEpochAtWrite |-> tokenEpoch[w],
             authorityEpochAtWrite |-> rootEpoch,
             fenceEpochAtWrite |-> sinkFenceEpoch]}
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, writerActive, sinkFenceEpoch, fenceVerified,
       networkPartition, restoreMode, restoredEpoch>>

BeginRestore ==
    /\ ~restoreMode
    /\ restoreMode' = TRUE
    /\ phase' = "quarantined"
    /\ restoredEpoch' = rootEpoch - 1
    /\ writerActive' = ["W0" |-> FALSE, "W1" |-> FALSE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, sinkFenceEpoch, fenceVerified, networkPartition,
       acceptedWrites>>

ReconcileRestore ==
    /\ restoreMode
    /\ phase = "quarantined"
    /\ restoredEpoch' = rootEpoch
    /\ sinkFenceEpoch' = rootEpoch
    /\ fenceVerified' = TRUE
    /\ phase' = "fenced"
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, writerActive, networkPartition, restoreMode,
       acceptedWrites>>

FinishRestore ==
    /\ restoreMode
    /\ phase = "fenced"
    /\ fenceVerified
    /\ restoredEpoch = rootEpoch
    /\ sinkFenceEpoch = rootEpoch
    /\ restoreMode' = FALSE
    /\ phase' = "active"
    /\ writerActive' = [writerActive EXCEPT ![authorityOwner] = TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, sinkFenceEpoch, fenceVerified, networkPartition,
       restoredEpoch, acceptedWrites>>

(* Negative control: activate the new writer before sink fencing/evidence. *)
UnsafeEarlyPromotion ==
    /\ Mutation = "early_promotion"
    /\ phase = "allocated"
    /\ phase' = "active"
    /\ writerActive' = [writerActive EXCEPT !["W1"] = TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

(* Negative control: a partition is incorrectly treated as proof of failure. *)
UnsafePartitionPromotion ==
    /\ Mutation = "partition_promotion"
    /\ networkPartition
    /\ phase = "allocated"
    /\ phase' = "active"
    /\ writerActive' = [writerActive EXCEPT !["W1"] = TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

(* Negative control: stale W0 bypasses the mutation sink after fencing. *)
UnsafeStaleWrite ==
    /\ Mutation = "stale_write"
    /\ writerOnline["W0"]
    /\ sinkFenceEpoch > writerEpoch["W0"]
    /\ acceptedWrites' =
         acceptedWrites \cup
           {[writer |-> "W0",
             epoch |-> writerEpoch["W0"],
             ownerAtWrite |-> authorityOwner,
             tokenEpochAtWrite |-> tokenEpoch["W0"],
             authorityEpochAtWrite |-> rootEpoch,
             fenceEpochAtWrite |-> sinkFenceEpoch]}
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerEpoch, tokenEpoch, tokenAuthenticated, writerOnline,
       writerReachable, writerActive, sinkFenceEpoch, fenceVerified,
       networkPartition, restoreMode, restoredEpoch>>

(* Negative control: restore rolls the authority root back to old data. *)
UnsafeRestoreRollback ==
    /\ Mutation = "restore_rollback"
    /\ restoreMode
    /\ rootEpoch' = restoredEpoch
    /\ UNCHANGED <<authorityHighWater, authorityOwner, phase, writerEpoch,
       tokenEpoch, tokenAuthenticated, writerOnline, writerReachable,
       writerActive, sinkFenceEpoch, fenceVerified, networkPartition,
       restoreMode, restoredEpoch, acceptedWrites>>

(* Negative control: an unauthorised writer forges a current-epoch token. *)
UnsafeForgedEpoch ==
    /\ Mutation = "forged_epoch"
    /\ authorityOwner = "W1"
    /\ writerEpoch["W0"] < rootEpoch
    /\ writerEpoch' = [writerEpoch EXCEPT !["W0"] = rootEpoch]
    /\ tokenEpoch' = [tokenEpoch EXCEPT !["W0"] = rootEpoch]
    /\ tokenAuthenticated' = [tokenAuthenticated EXCEPT !["W0"] = TRUE]
    /\ UNCHANGED <<rootEpoch, authorityHighWater, authorityOwner, phase,
       writerOnline, writerReachable, writerActive, sinkFenceEpoch,
       fenceVerified, networkPartition, restoreMode, restoredEpoch,
       acceptedWrites>>

Next ==
    \/ FreezeOldWriter
    \/ AllocateNewEpoch
    \/ ApplyFenceAtSink
    \/ VerifyFenceEvidence
    \/ ActivateNewWriter
    \/ SetPartition
    \/ HealPartition
    \/ CrashOldWriter
    \/ ReturnOldWriter
    \/ \E w \in Writers : TryAuthorizedWrite(w)
    \/ BeginRestore
    \/ ReconcileRestore
    \/ FinishRestore
    \/ UnsafeEarlyPromotion
    \/ UnsafePartitionPromotion
    \/ UnsafeStaleWrite
    \/ UnsafeRestoreRollback
    \/ UnsafeForgedEpoch

Spec == Init /\ [][Next]_vars

TypeOK ==
    /\ rootEpoch \in 0..3
    /\ authorityHighWater \in 1..3
    /\ authorityOwner \in Writers
    /\ phase \in Phases
    /\ writerEpoch \in [Writers -> 0..3]
    /\ tokenEpoch \in [Writers -> 0..3]
    /\ tokenAuthenticated \in [Writers -> BOOLEAN]
    /\ writerOnline \in [Writers -> BOOLEAN]
    /\ writerReachable \in [Writers -> BOOLEAN]
    /\ writerActive \in [Writers -> BOOLEAN]
    /\ sinkFenceEpoch \in 0..3
    /\ fenceVerified \in BOOLEAN
    /\ networkPartition \in BOOLEAN
    /\ restoreMode \in BOOLEAN
    /\ restoredEpoch \in 0..3
    /\ acceptedWrites \subseteq
         [writer : Writers,
          epoch : 0..3,
          ownerAtWrite : Writers,
          tokenEpochAtWrite : 0..3,
          authorityEpochAtWrite : 0..3,
          fenceEpochAtWrite : 0..3]

SingleWriter ==
    Cardinality({w \in Writers : writerActive[w]}) <= 1

RootEpochAtLeastHighWater ==
    rootEpoch >= authorityHighWater

NewWriterActivationRequiresFence ==
    writerActive["W1"] =>
      /\ authorityOwner = "W1"
      /\ phase = "active"
      /\ fenceVerified
      /\ sinkFenceEpoch = rootEpoch
      /\ writerEpoch["W1"] = rootEpoch

RestoreQuarantine ==
    restoreMode =>
      /\ phase = "quarantined" \/ phase = "fenced"
      /\ Cardinality({w \in Writers : writerActive[w]}) = 0

EveryWriteWasFencedAndAuthorized ==
    \A write \in acceptedWrites :
      /\ write.epoch = write.tokenEpochAtWrite
      /\ write.epoch = write.authorityEpochAtWrite
      /\ write.epoch = write.fenceEpochAtWrite
      /\ write.writer = write.ownerAtWrite

AuthenticatedCurrentTokenHasAuthorityOwner ==
    \A w \in Writers :
      (tokenAuthenticated[w] /\ tokenEpoch[w] = rootEpoch)
        => w = authorityOwner

NoActiveWriterDuringUnverifiedTransfer ==
    (phase \in {"allocated", "fenced"} /\ ~fenceVerified)
      => Cardinality({w \in Writers : writerActive[w]}) = 0

=============================================================================
