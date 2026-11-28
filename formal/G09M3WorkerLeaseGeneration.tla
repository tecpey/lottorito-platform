---------------- MODULE G09M3WorkerLeaseGeneration ----------------
EXTENDS Naturals, Integers, FiniteSets, TLC

CONSTANTS
    Workers,
    LeaseDuration,
    Mutation

Ops == {"none", "claim", "heartbeat", "start_processing",
        "complete", "retry", "park"}
RequestStates == {"idle", "waiting", "locked"}
WorkStates == {"ready", "claimed", "processing", "completed",
               "failed", "quarantined"}
Mutations == {"none", "prelock_time", "worker_clock", "stale_generation",
              "wrong_token", "wrong_tenant", "wrong_installation", "stale_lifecycle", "stale_state",
              "expired_heartbeat", "heartbeat_generation",
              "guard_mutates"}

ASSUME
    /\ Cardinality(Workers) = 2
    /\ LeaseDuration = 2
    /\ Mutation \in Mutations

TenantID == "tenant-A"
InstallationID == "installation-A"
PrincipalOf(w) == "worker-service"
NoOwner == "none"
MaxGeneration == 2
MaxTime == 2

ProtectedOps == {"heartbeat", "start_processing", "complete", "retry", "park"}

WorkerPermutations == Permutations(Workers)

VARIABLES
    workState,
    claimGeneration,
    generationHighWater,
    claimOwner,
    claimToken,
    leaseExpiry,
    lifecycleVersion,
    persistenceTime,
    workerClock,
    workerGeneration,
    workerToken,
    workerLifecycle,
    requestState,
    requestOp,
    requestGeneration,
    requestToken,
    requestLifecycle,
    requestExpectedState,
    requestTenant,
    requestInstallation,
    requestStartTime,
    requestPreLockValid,
    lockAcquireTime,
    lockOwner,
    blockerAvailable,
    mutationCount,
    lastGuardFailed,
    lastFailureMutationCount,
    acceptedHistory,
    claimEvents

vars ==
    <<workState, claimGeneration, generationHighWater, claimOwner, claimToken,
      leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
      workerGeneration, workerToken, workerLifecycle, requestState, requestOp,
      requestGeneration, requestToken, requestLifecycle, requestExpectedState,
      requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
      lockAcquireTime, lockOwner, blockerAvailable, mutationCount,
      lastGuardFailed, lastFailureMutationCount, acceptedHistory, claimEvents>>

Init ==
    /\ workState = "ready"
    /\ claimGeneration = 0
    /\ generationHighWater = 0
    /\ claimOwner = NoOwner
    /\ claimToken = 0
    /\ leaseExpiry = 0
    /\ lifecycleVersion = 0
    /\ persistenceTime = 0
    /\ workerClock = [w \in Workers |-> 0]
    /\ workerGeneration = [w \in Workers |-> 0]
    /\ workerToken = [w \in Workers |-> 0]
    /\ workerLifecycle = [w \in Workers |-> 0]
    /\ requestState = [w \in Workers |-> "idle"]
    /\ requestOp = [w \in Workers |-> "none"]
    /\ requestGeneration = [w \in Workers |-> 0]
    /\ requestToken = [w \in Workers |-> 0]
    /\ requestLifecycle = [w \in Workers |-> 0]
    /\ requestExpectedState = [w \in Workers |-> "ready"]
    /\ requestTenant = [w \in Workers |-> TenantID]
    /\ requestInstallation = [w \in Workers |-> InstallationID]
    /\ requestStartTime = [w \in Workers |-> 0]
    /\ requestPreLockValid = [w \in Workers |-> FALSE]
    /\ lockAcquireTime = [w \in Workers |-> 0]
    /\ lockOwner = NoOwner
    /\ blockerAvailable = TRUE
    /\ mutationCount = 0
    /\ lastGuardFailed = FALSE
    /\ lastFailureMutationCount = 0
    /\ acceptedHistory = {}
    /\ claimEvents = {}

StartRequest(w, op) ==
    /\ w \in Workers
    /\ op \in Ops \ {"none"}
    /\ requestState[w] = "idle"
    /\ \A other \in Workers \ {w} : requestState[other] = "idle"
    /\ (op = "claim" => ClaimEligible)
    /\ (op \in ProtectedOps => workState \in {"claimed", "processing"})
    /\ (op = "claim" \/ workerGeneration[w] > 0)
    /\ requestState' = [requestState EXCEPT ![w] = "waiting"]
    /\ requestOp' = [requestOp EXCEPT ![w] = op]
    /\ requestGeneration' = [requestGeneration EXCEPT ![w] = workerGeneration[w]]
    /\ requestToken' = [requestToken EXCEPT
         ![w] = IF Mutation = "wrong_token" /\ op \in ProtectedOps
                THEN workerToken[w] + 1 ELSE workerToken[w]]
    /\ requestLifecycle' = [requestLifecycle EXCEPT ![w] = workerLifecycle[w]]
    /\ requestExpectedState' = [requestExpectedState EXCEPT ![w] = workState]
    /\ requestTenant' = [requestTenant EXCEPT
         ![w] = IF Mutation = "wrong_tenant" /\ op \in ProtectedOps
                THEN "tenant-B" ELSE TenantID]
    /\ requestInstallation' = [requestInstallation EXCEPT
         ![w] = IF Mutation = "wrong_installation" /\ op \in ProtectedOps
                THEN "installation-B" ELSE InstallationID]
    /\ requestStartTime' = [requestStartTime EXCEPT ![w] = persistenceTime]
    /\ requestPreLockValid' = [requestPreLockValid EXCEPT
         ![w] = persistenceTime + workerClock[w] < leaseExpiry]
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, lockAcquireTime, lockOwner,
       blockerAvailable, mutationCount, lastFailureMutationCount, acceptedHistory,
       claimEvents>>

AcquireSerializationBlocker ==
    /\ lockOwner = NoOwner
    /\ blockerAvailable
    /\ lockOwner' = "external"
    /\ blockerAvailable' = FALSE
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestState, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, mutationCount, lastGuardFailed, lastFailureMutationCount,
       acceptedHistory, claimEvents>>

ReleaseSerializationBlocker ==
    /\ lockOwner = "external"
    /\ lockOwner' = NoOwner
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestState, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

AcquireSerializationPoint(w) ==
    /\ w \in Workers
    /\ lockOwner = NoOwner
    /\ requestState[w] = "waiting"
    /\ lockOwner' = w
    /\ requestState' = [requestState EXCEPT ![w] = "locked"]
    /\ lockAcquireTime' = [lockAcquireTime EXCEPT ![w] = persistenceTime]
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestOp, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, blockerAvailable,
       mutationCount, lastGuardFailed, lastFailureMutationCount, acceptedHistory,
       claimEvents>>

ReleaseSerializationPoint(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState[w] = "locked"
    /\ lockOwner' = NoOwner
    /\ requestState' = [requestState EXCEPT ![w] = "idle"]
    /\ requestOp' = [requestOp EXCEPT ![w] = "none"]
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       blockerAvailable, mutationCount, lastGuardFailed, lastFailureMutationCount,
       acceptedHistory, claimEvents>>

(* Processing remains lease-bearing; an expired processing claim is reclaimable.
   This is an explicit model refinement requiring ADR-001 owner reconciliation. *)
ClaimEligible ==
    \/ workState = "ready"
    \/ (workState \in {"claimed", "processing"} /\ persistenceTime >= leaseExpiry)

CompetingReclaim(w) ==
    /\ w \in Workers
    /\ \E old \in Workers \ {w} : requestState[old] = "waiting"
    /\ lockOwner = NoOwner
    /\ workState \in {"claimed", "processing"}
    /\ persistenceTime >= leaseExpiry
    /\ claimGeneration < MaxGeneration
    /\ mutationCount < 10
    /\ claimGeneration' = claimGeneration + 1
    /\ generationHighWater' = claimGeneration + 1
    /\ claimOwner' = PrincipalOf(w)
    /\ claimToken' = claimGeneration + 1
    /\ leaseExpiry' = persistenceTime + LeaseDuration
    /\ workState' = "claimed"
    /\ workerGeneration' = [workerGeneration EXCEPT ![w] = claimGeneration + 1]
    /\ workerToken' = [workerToken EXCEPT ![w] = claimGeneration + 1]
    /\ workerLifecycle' = [workerLifecycle EXCEPT ![w] = lifecycleVersion]
    /\ mutationCount' = mutationCount + 1
    /\ claimEvents' = claimEvents \cup {<<claimGeneration, claimGeneration + 1, w>>}
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<lifecycleVersion, persistenceTime, workerClock, requestState,
       requestOp, requestGeneration, requestToken, requestLifecycle,
       requestExpectedState, requestTenant, requestInstallation, requestStartTime,
       requestPreLockValid, lockAcquireTime, lockOwner, blockerAvailable,
       lastFailureMutationCount, acceptedHistory>>

ApplyClaim(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState[w] = "locked"
    /\ requestOp[w] = "claim"
    /\ ClaimEligible
    /\ claimGeneration < MaxGeneration
    /\ mutationCount < 10
    /\ (Mutation = "wrong_tenant" \/ requestTenant[w] = TenantID)
    /\ (Mutation = "wrong_installation" \/ requestInstallation[w] = InstallationID)
    /\ claimGeneration' = claimGeneration + 1
    /\ generationHighWater' = claimGeneration + 1
    /\ claimOwner' = PrincipalOf(w)
    /\ claimToken' = claimGeneration + 1
    /\ leaseExpiry' = persistenceTime + LeaseDuration
    /\ workState' = "claimed"
    /\ workerGeneration' = [workerGeneration EXCEPT ![w] = claimGeneration + 1]
    /\ workerToken' = [workerToken EXCEPT ![w] = claimGeneration + 1]
    /\ workerLifecycle' = [workerLifecycle EXCEPT ![w] = lifecycleVersion]
    /\ mutationCount' = mutationCount + 1
    /\ claimEvents' = claimEvents \cup {<<claimGeneration, claimGeneration + 1, w>>}
    /\ requestState' = [requestState EXCEPT ![w] = "idle"]
    /\ requestOp' = [requestOp EXCEPT ![w] = "none"]
    /\ lockOwner' = NoOwner
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<lifecycleVersion, persistenceTime, workerClock, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       blockerAvailable, lastFailureMutationCount, acceptedHistory>>

RejectClaim(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState[w] = "locked"
    /\ requestOp[w] = "claim"
    /\ (~ClaimEligible \/ claimGeneration = MaxGeneration
        \/ requestTenant[w] # TenantID
        \/ requestInstallation[w] # InstallationID)
    /\ requestState' = [requestState EXCEPT ![w] = "idle"]
    /\ requestOp' = [requestOp EXCEPT ![w] = "none"]
    /\ lockOwner' = NoOwner
    /\ lastGuardFailed' = TRUE
    /\ lastFailureMutationCount' = mutationCount
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       blockerAvailable, mutationCount, acceptedHistory, claimEvents>>

AdvancePersistenceTime ==
    /\ persistenceTime < MaxTime
    /\ persistenceTime' = persistenceTime + 1
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, workerClock, workerGeneration,
       workerToken, workerLifecycle, requestState, requestOp, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       lockOwner, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

SetWorkerClockSkew(w, skew) ==
    /\ w \in Workers
    /\ skew \in (-1)..1
    /\ workerClock' = [workerClock EXCEPT ![w] = skew]
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerGeneration,
       workerToken, workerLifecycle, requestState, requestOp, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       lockOwner, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>


AuthorizedStartProcessing ==
    /\ lockOwner = NoOwner
    /\ workState = "claimed"
    /\ persistenceTime < leaseExpiry
    /\ mutationCount < 10
    /\ workState' = "processing"
    /\ mutationCount' = mutationCount + 1
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<claimGeneration, generationHighWater, claimOwner, claimToken,
       leaseExpiry, lifecycleVersion, persistenceTime, workerClock, workerGeneration,
       workerToken, workerLifecycle, requestState, requestOp, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       lockOwner, blockerAvailable, lastFailureMutationCount, acceptedHistory,
       claimEvents>>

AdvanceLifecycleVersion ==
    /\ lifecycleVersion < 1
    /\ lifecycleVersion' = lifecycleVersion + 1
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, persistenceTime, workerClock, workerGeneration,
       workerToken, workerLifecycle, requestState, requestOp, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       lockOwner, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

OperatorQuarantine ==
    /\ lockOwner = NoOwner
    /\ workState \in {"claimed", "processing"}
    /\ mutationCount < 10
    /\ workState' = "quarantined"
    /\ claimOwner' = NoOwner
    /\ claimToken' = 0
    /\ leaseExpiry' = 0
    /\ mutationCount' = mutationCount + 1
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<claimGeneration, generationHighWater, lifecycleVersion,
       persistenceTime, workerClock, workerGeneration, workerToken, workerLifecycle,
       requestState, requestOp, requestGeneration, requestToken, requestLifecycle,
       requestExpectedState, requestTenant, requestInstallation, requestStartTime,
       requestPreLockValid, lockAcquireTime, lockOwner, blockerAvailable,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

GuardOK(w) ==
    /\ claimOwner = PrincipalOf(w)
    /\ (Mutation = "stale_state" \/ requestExpectedState[w] = workState)
    /\ workState \in {"claimed", "processing"}
    /\ (Mutation = "stale_generation" \/ requestGeneration[w] = claimGeneration)
    /\ (Mutation \in {"stale_generation", "wrong_token"} \/ requestToken[w] = claimToken)
    /\ (Mutation = "stale_lifecycle" \/ requestLifecycle[w] = lifecycleVersion)
    /\ (Mutation = "wrong_tenant" \/ requestTenant[w] = TenantID)
    /\ (Mutation = "wrong_installation" \/ requestInstallation[w] = InstallationID)
    /\ IF Mutation = "prelock_time"
          THEN requestPreLockValid[w]
       ELSE IF Mutation = "worker_clock"
          THEN persistenceTime + workerClock[w] < leaseExpiry
       ELSE IF Mutation = "expired_heartbeat" /\ requestOp[w] = "heartbeat"
          THEN TRUE
       ELSE persistenceTime < leaseExpiry

ProtectedMutationRecord(w) ==
    <<w, claimOwner, claimGeneration, claimToken, persistenceTime, leaseExpiry,
      lifecycleVersion, requestGeneration[w], requestToken[w],
      requestLifecycle[w], requestExpectedState[w], workState,
      requestTenant[w], requestInstallation[w], lockAcquireTime[w],
      requestStartTime[w], requestOp[w],
      IF Mutation = "heartbeat_generation" /\ requestOp[w] = "heartbeat"
      THEN claimGeneration + 1 ELSE claimGeneration>>

ApplyProtectedTransition(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState[w] = "locked"
    /\ requestOp[w] \in ProtectedOps
    /\ GuardOK(w)
    /\ mutationCount < 10
    /\ workState' =
         IF requestOp[w] = "start_processing" THEN "processing"
         ELSE IF requestOp[w] = "complete" THEN "completed"
         ELSE IF requestOp[w] = "retry" THEN "ready"
         ELSE IF requestOp[w] = "park" THEN "quarantined"
         ELSE workState
    /\ claimOwner' =
         IF requestOp[w] \in {"retry", "park"} THEN NoOwner ELSE claimOwner
    /\ claimToken' =
         IF requestOp[w] \in {"retry", "park"} THEN 0 ELSE
         IF Mutation = "heartbeat_generation" /\ requestOp[w] = "heartbeat"
         THEN claimToken + 1 ELSE claimToken
    /\ leaseExpiry' =
         IF requestOp[w] = "heartbeat" THEN persistenceTime + LeaseDuration
         ELSE IF requestOp[w] \in {"retry", "park"} THEN 0 ELSE leaseExpiry
    /\ claimGeneration' =
         IF Mutation = "heartbeat_generation" /\ requestOp[w] = "heartbeat"
         THEN claimGeneration + 1 ELSE claimGeneration
    /\ generationHighWater' = generationHighWater
    /\ mutationCount' = mutationCount + 1
    /\ acceptedHistory' = {ProtectedMutationRecord(w)}
    /\ workerGeneration' = workerGeneration
    /\ workerToken' = workerToken
    /\ workerLifecycle' = workerLifecycle
    /\ requestState' = [requestState EXCEPT ![w] = "idle"]
    /\ requestOp' = [requestOp EXCEPT ![w] = "none"]
    /\ lockOwner' = NoOwner
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<lifecycleVersion, persistenceTime, workerClock,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, blockerAvailable, lastFailureMutationCount, claimEvents>>

RejectProtectedTransition(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState[w] = "locked"
    /\ requestOp[w] \in ProtectedOps
    /\ ~GuardOK(w)
    /\ requestState' = [requestState EXCEPT ![w] = "idle"]
    /\ requestOp' = [requestOp EXCEPT ![w] = "none"]
    /\ lockOwner' = NoOwner
    /\ mutationCount' =
         IF Mutation = "guard_mutates" THEN mutationCount + 1 ELSE mutationCount
    /\ lastGuardFailed' = TRUE
    /\ lastFailureMutationCount' = mutationCount
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       blockerAvailable, acceptedHistory, claimEvents>>

Next ==
    \/ \E w \in Workers : \E op \in Ops \ {"none"} : StartRequest(w, op)
    \/ \E w \in Workers : AcquireSerializationPoint(w)
    \/ \E w \in Workers : ReleaseSerializationPoint(w)
    \/ \E w \in Workers : ApplyClaim(w)
    \/ \E w \in Workers : CompetingReclaim(w)
    \/ \E w \in Workers : RejectClaim(w)
    \/ \E w \in Workers : ApplyProtectedTransition(w)
    \/ \E w \in Workers : RejectProtectedTransition(w)
    \/ AcquireSerializationBlocker
    \/ ReleaseSerializationBlocker
    \/ AdvancePersistenceTime
    \/ \E w \in Workers : \E skew \in (-1)..1 : SetWorkerClockSkew(w, skew)
    \/ AdvanceLifecycleVersion
    \/ AuthorizedStartProcessing
    \/ OperatorQuarantine

Spec == Init /\ [][Next]_vars

TypeOK ==
    /\ workState \in WorkStates
    /\ claimGeneration \in (0..MaxGeneration)
    /\ generationHighWater \in (0..MaxGeneration)
    /\ claimOwner \in {NoOwner, "worker-service"}
    /\ claimToken \in (0..MaxGeneration)
    /\ leaseExpiry \in (0..(MaxTime + LeaseDuration))
    /\ lifecycleVersion \in (0..1)
    /\ persistenceTime \in (0..MaxTime)
    /\ workerClock \in [Workers -> ((-1)..1)]
    /\ workerGeneration \in [Workers -> (0..MaxGeneration)]
    /\ workerToken \in [Workers -> (0..MaxGeneration)]
    /\ workerLifecycle \in [Workers -> (0..1)]
    /\ requestState \in [Workers -> RequestStates]
    /\ requestOp \in [Workers -> Ops]
    /\ requestGeneration \in [Workers -> (0..MaxGeneration)]
    /\ requestToken \in [Workers -> (0..(MaxGeneration + 1))]
    /\ requestLifecycle \in [Workers -> (0..1)]
    /\ requestExpectedState \in [Workers -> {"ready", "claimed", "processing"}]
    /\ requestTenant \in [Workers -> {"tenant-A", "tenant-B"}]
    /\ requestInstallation \in [Workers -> {"installation-A", "installation-B"}]
    /\ requestStartTime \in [Workers -> (0..MaxTime)]
    /\ requestPreLockValid \in [Workers -> BOOLEAN]
    /\ lockAcquireTime \in [Workers -> (0..MaxTime)]
    /\ lockOwner \in (Workers \cup {NoOwner, "external"})
    /\ blockerAvailable \in BOOLEAN
    /\ mutationCount \in 0..10
    /\ lastGuardFailed \in BOOLEAN
    /\ lastFailureMutationCount \in 0..10
    /\ acceptedHistory \subseteq
       (Workers \X {"worker-service"} \X (0..MaxGeneration) \X (0..MaxGeneration) \X
        (0..MaxTime) \X (0..(MaxTime + LeaseDuration)) \X (0..1) \X
        (0..MaxGeneration) \X (0..(MaxGeneration + 1)) \X (0..1) \X
        WorkStates \X WorkStates \X {"tenant-A", "tenant-B"} \X
        {"installation-A", "installation-B"} \X (0..MaxTime) \X (0..MaxTime) \X
        ProtectedOps \X (0..MaxGeneration))
    /\ claimEvents \subseteq ((0..MaxGeneration) \X (1..MaxGeneration) \X Workers)

SingleClaimOwner ==
    /\ (workState = "ready" => claimOwner = NoOwner)
    /\ (workState = "quarantined" => claimOwner = NoOwner)
    /\ (workState \in {"claimed", "processing"} => claimOwner = "worker-service")

GenerationHighWaterNeverRegresses ==
    claimGeneration = generationHighWater

ClaimAdvancesExactlyOnce ==
    \A e \in claimEvents : e[2] = e[1] + 1

HeartbeatDoesNotAdvanceGeneration ==
    \A e \in acceptedHistory :
        e[17] = "heartbeat" => e[3] = e[18]

EveryAcceptedMutationWasAuthorized ==
    \A e \in acceptedHistory :
        /\ e[2] = "worker-service"
        /\ e[3] = e[8]
        /\ e[4] = e[9]
        /\ e[7] = e[10]
        /\ e[11] = e[12]
        /\ e[5] < e[6]
        /\ e[13] = TenantID
        /\ e[14] = InstallationID
        /\ e[15] <= e[5]
        /\ e[16] <= e[15]

GuardFailureHasZeroMutation ==
    ~lastGuardFailed \/ mutationCount = lastFailureMutationCount

LeaseNeverRenewedAfterExpiry ==
    \A e \in acceptedHistory :
        e[17] = "heartbeat" => e[5] < e[6]

NewClaimHasCurrentOwnerAndToken ==
    /\ (claimGeneration = 0 => claimOwner = NoOwner)
    /\ (claimGeneration > 0 /\ workState \in {"claimed", "processing"}
        => claimOwner = "worker-service" /\ claimToken = claimGeneration)

=============================================================================
