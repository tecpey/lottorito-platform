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
              "wrong_token", "wrong_tenant", "wrong_installation",
              "stale_lifecycle", "stale_state", "expired_heartbeat",
              "heartbeat_generation", "guard_mutates"}

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
    requestWorker,
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
      workerGeneration, workerToken, workerLifecycle, requestState, requestWorker,
      requestOp, requestGeneration, requestToken, requestLifecycle,
      requestExpectedState, requestTenant, requestInstallation, requestStartTime,
      requestPreLockValid, lockAcquireTime, lockOwner, blockerAvailable,
      mutationCount, lastGuardFailed, lastFailureMutationCount,
      acceptedHistory, claimEvents>>

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
    /\ requestState = "idle"
    /\ requestWorker = NoOwner
    /\ requestOp = "none"
    /\ requestGeneration = 0
    /\ requestToken = 0
    /\ requestLifecycle = 0
    /\ requestExpectedState = "ready"
    /\ requestTenant = TenantID
    /\ requestInstallation = InstallationID
    /\ requestStartTime = 0
    /\ requestPreLockValid = FALSE
    /\ lockAcquireTime = 0
    /\ lockOwner = NoOwner
    /\ blockerAvailable = TRUE
    /\ mutationCount = 0
    /\ lastGuardFailed = FALSE
    /\ lastFailureMutationCount = 0
    /\ acceptedHistory = {}
    /\ claimEvents = {}

(* Processing remains lease-bearing; expired processing claims are reclaimable.
   This is an explicit refinement requiring ADR-001 owner reconciliation. *)
ClaimEligible ==
    \/ workState = "ready"
    \/ (workState \in {"claimed", "processing"} /\ persistenceTime >= leaseExpiry)

StartRequest(w, op) ==
    /\ w \in Workers
    /\ op \in Ops \ {"none"}
    /\ requestState = "idle"
    /\ requestWorker = NoOwner
    /\ (op = "claim" => ClaimEligible)
    /\ (op \in ProtectedOps => workState \in {"claimed", "processing"})
    /\ (op = "claim" \/ workerGeneration[w] > 0)
    /\ requestState' = "waiting"
    /\ requestWorker' = w
    /\ requestOp' = op
    /\ requestGeneration' = workerGeneration[w]
    /\ requestToken' =
         IF Mutation = "wrong_token" /\ op \in ProtectedOps
         THEN workerToken[w] + 1 ELSE workerToken[w]
    /\ requestLifecycle' = workerLifecycle[w]
    /\ requestExpectedState' = workState
    /\ requestTenant' =
         IF Mutation = "wrong_tenant" /\ op \in ProtectedOps
         THEN "tenant-B" ELSE TenantID
    /\ requestInstallation' =
         IF Mutation = "wrong_installation" /\ op \in ProtectedOps
         THEN "installation-B" ELSE InstallationID
    /\ requestStartTime' = persistenceTime
    /\ requestPreLockValid' = (persistenceTime + workerClock[w] < leaseExpiry)
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
       workerGeneration, workerToken, workerLifecycle, requestState, requestWorker,
       requestOp, requestGeneration, requestToken, requestLifecycle,
       requestExpectedState, requestTenant, requestInstallation, requestStartTime,
       requestPreLockValid, lockAcquireTime, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

ReleaseSerializationBlocker ==
    /\ lockOwner = "external"
    /\ lockOwner' = NoOwner
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestState, requestWorker,
       requestOp, requestGeneration, requestToken, requestLifecycle,
       requestExpectedState, requestTenant, requestInstallation, requestStartTime,
       requestPreLockValid, lockAcquireTime, blockerAvailable, mutationCount,
       lastGuardFailed, lastFailureMutationCount, acceptedHistory, claimEvents>>

AcquireSerializationPoint(w) ==
    /\ w \in Workers
    /\ lockOwner = NoOwner
    /\ requestState = "waiting"
    /\ requestWorker = w
    /\ lockOwner' = w
    /\ requestState' = "locked"
    /\ lockAcquireTime' = persistenceTime
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestWorker, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       blockerAvailable, mutationCount, lastGuardFailed, lastFailureMutationCount,
       acceptedHistory, claimEvents>>

ReleaseSerializationPoint(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState = "locked"
    /\ requestWorker = w
    /\ lockOwner' = NoOwner
    /\ requestState' = "idle"
    /\ requestWorker' = NoOwner
    /\ requestOp' = "none"
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerClock,
       workerGeneration, workerToken, workerLifecycle, requestGeneration,
       requestToken, requestLifecycle, requestExpectedState, requestTenant,
       requestInstallation, requestStartTime, requestPreLockValid, lockAcquireTime,
       blockerAvailable, mutationCount, lastGuardFailed, lastFailureMutationCount,
       acceptedHistory, claimEvents>>

(* The competing claimant can win the serialization point while the old
   request is still waiting. This atomic action models lock acquisition,
   reclaim commit and lock release as one linearized transition. *)
CompetingReclaim(w) ==
    /\ w \in Workers
    /\ requestState = "waiting"
    /\ requestWorker \in Workers \ {w}
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
       requestWorker, requestOp, requestGeneration, requestToken, requestLifecycle,
       requestExpectedState, requestTenant, requestInstallation, requestStartTime,
       requestPreLockValid, lockAcquireTime, lockOwner, blockerAvailable,
       lastFailureMutationCount, acceptedHistory>>

ApplyClaim(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState = "locked"
    /\ requestWorker = w
    /\ requestOp = "claim"
    /\ ClaimEligible
    /\ claimGeneration < MaxGeneration
    /\ mutationCount < 10
    /\ requestTenant = TenantID
    /\ requestInstallation = InstallationID
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
    /\ requestState' = "idle"
    /\ requestWorker' = NoOwner
    /\ requestOp' = "none"
    /\ lockOwner' = NoOwner
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<lifecycleVersion, persistenceTime, workerClock,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, blockerAvailable, lastFailureMutationCount, acceptedHistory>>

RejectClaim(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState = "locked"
    /\ requestWorker = w
    /\ requestOp = "claim"
    /\ (~ClaimEligible \/ claimGeneration = MaxGeneration
        \/ requestTenant # TenantID \/ requestInstallation # InstallationID)
    /\ requestState' = "idle"
    /\ requestWorker' = NoOwner
    /\ requestOp' = "none"
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
       workerToken, workerLifecycle, requestState, requestWorker, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, lockOwner, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

SetWorkerClockSkew(w, skew) ==
    /\ w \in Workers
    /\ skew \in (-1)..1
    /\ workerClock' = [workerClock EXCEPT ![w] = skew]
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, lifecycleVersion, persistenceTime, workerGeneration,
       workerToken, workerLifecycle, requestState, requestWorker, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, lockOwner, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

AdvanceLifecycleVersion ==
    /\ lifecycleVersion < 1
    /\ lifecycleVersion' = lifecycleVersion + 1
    /\ UNCHANGED <<workState, claimGeneration, generationHighWater, claimOwner,
       claimToken, leaseExpiry, persistenceTime, workerClock, workerGeneration,
       workerToken, workerLifecycle, requestState, requestWorker, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, lockOwner, blockerAvailable, mutationCount, lastGuardFailed,
       lastFailureMutationCount, acceptedHistory, claimEvents>>

CompetingStartProcessingRecord(w) ==
    <<w, claimOwner, claimGeneration, claimToken, persistenceTime, leaseExpiry,
      lifecycleVersion, workerGeneration[w], workerToken[w], workerLifecycle[w],
      workState, workState, TenantID, InstallationID, persistenceTime,
      persistenceTime, "start_processing", claimGeneration, mutationCount + 1>>

(* An independently authorized current claimant wins the serialization point
   while an older request waits. This atomic acquire/guard/mutate/release action
   records the competing mutation in the same authorization history oracle. *)
CompetingAuthorizedStartProcessing(w) ==
    /\ w \in Workers
    /\ requestState = "waiting"
    /\ requestWorker \in Workers \ {w}
    /\ lockOwner = NoOwner
    /\ workState = "claimed"
    /\ claimOwner = PrincipalOf(w)
    /\ workerGeneration[w] = claimGeneration
    /\ workerToken[w] = claimToken
    /\ workerLifecycle[w] = lifecycleVersion
    /\ persistenceTime < leaseExpiry
    /\ mutationCount < 10
    /\ workState' = "processing"
    /\ mutationCount' = mutationCount + 1
    /\ acceptedHistory' = acceptedHistory \cup {CompetingStartProcessingRecord(w)}
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<claimGeneration, generationHighWater, claimOwner, claimToken,
       leaseExpiry, lifecycleVersion, persistenceTime, workerClock, workerGeneration,
       workerToken, workerLifecycle, requestState, requestWorker, requestOp,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, lockOwner, blockerAvailable, lastFailureMutationCount,
       claimEvents>>

GuardOK(w) ==
    /\ claimOwner = PrincipalOf(w)
    /\ (Mutation = "stale_state" \/ requestExpectedState = workState)
    /\ workState \in {"claimed", "processing"}
    /\ (Mutation = "stale_generation" \/ requestGeneration = claimGeneration)
    /\ (Mutation \in {"stale_generation", "wrong_token"} \/ requestToken = claimToken)
    /\ (Mutation = "stale_lifecycle" \/ requestLifecycle = lifecycleVersion)
    /\ (Mutation = "wrong_tenant" \/ requestTenant = TenantID)
    /\ (Mutation = "wrong_installation" \/ requestInstallation = InstallationID)
    /\ IF Mutation = "prelock_time"
          THEN requestPreLockValid
       ELSE IF Mutation = "worker_clock"
          THEN persistenceTime + workerClock[w] < leaseExpiry
       ELSE IF Mutation = "expired_heartbeat" /\ requestOp = "heartbeat"
          THEN TRUE
       ELSE persistenceTime < leaseExpiry

ProtectedMutationRecord(w) ==
    <<w, claimOwner, claimGeneration, claimToken, persistenceTime, leaseExpiry,
      lifecycleVersion, requestGeneration, requestToken, requestLifecycle,
      requestExpectedState, workState, requestTenant, requestInstallation,
      lockAcquireTime, requestStartTime, requestOp,
      IF Mutation = "heartbeat_generation" /\ requestOp = "heartbeat"
      THEN claimGeneration + 1 ELSE claimGeneration, mutationCount + 1>>

ApplyProtectedTransition(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState = "locked"
    /\ requestWorker = w
    /\ requestOp \in ProtectedOps
    /\ GuardOK(w)
    /\ mutationCount < 10
    /\ workState' =
         IF requestOp = "start_processing" THEN "processing"
         ELSE IF requestOp = "complete" THEN "completed"
         ELSE IF requestOp = "retry" THEN "ready"
         ELSE IF requestOp = "park" THEN "quarantined"
         ELSE workState
    /\ claimOwner' =
         IF requestOp \in {"retry", "park", "complete"} THEN NoOwner ELSE claimOwner
    /\ claimToken' =
         IF requestOp \in {"retry", "park", "complete"} THEN 0 ELSE
         IF Mutation = "heartbeat_generation" /\ requestOp = "heartbeat"
         THEN claimToken + 1 ELSE claimToken
    /\ leaseExpiry' =
         IF requestOp = "heartbeat" THEN persistenceTime + LeaseDuration
         ELSE IF requestOp \in {"retry", "park", "complete"} THEN 0 ELSE leaseExpiry
    /\ claimGeneration' =
         IF Mutation = "heartbeat_generation" /\ requestOp = "heartbeat"
         THEN claimGeneration + 1 ELSE claimGeneration
    /\ generationHighWater' = generationHighWater
    /\ mutationCount' = mutationCount + 1
    /\ acceptedHistory' = acceptedHistory \cup {ProtectedMutationRecord(w)}
    /\ workerGeneration' = workerGeneration
    /\ workerToken' = workerToken
    /\ workerLifecycle' = workerLifecycle
    /\ requestState' = "idle"
    /\ requestWorker' = NoOwner
    /\ requestOp' = "none"
    /\ lockOwner' = NoOwner
    /\ lastGuardFailed' = FALSE
    /\ UNCHANGED <<lifecycleVersion, persistenceTime, workerClock,
       requestGeneration, requestToken, requestLifecycle, requestExpectedState,
       requestTenant, requestInstallation, requestStartTime, requestPreLockValid,
       lockAcquireTime, blockerAvailable, lastFailureMutationCount, claimEvents>>

RejectProtectedTransition(w) ==
    /\ w \in Workers
    /\ lockOwner = w
    /\ requestState = "locked"
    /\ requestWorker = w
    /\ requestOp \in ProtectedOps
    /\ ~GuardOK(w)
    /\ requestState' = "idle"
    /\ requestWorker' = NoOwner
    /\ requestOp' = "none"
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
    \/ \E w \in Workers : RejectClaim(w)
    \/ \E w \in Workers : CompetingReclaim(w)
    \/ \E w \in Workers : ApplyProtectedTransition(w)
    \/ \E w \in Workers : RejectProtectedTransition(w)
    \/ AcquireSerializationBlocker
    \/ ReleaseSerializationBlocker
    \/ AdvancePersistenceTime
    \/ \E w \in Workers : \E skew \in (-1)..1 : SetWorkerClockSkew(w, skew)
    \/ AdvanceLifecycleVersion
    \/ \E w \in Workers : CompetingAuthorizedStartProcessing(w)

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
    /\ requestState \in RequestStates
    /\ requestWorker \in (Workers \cup {NoOwner})
    /\ requestOp \in Ops
    /\ requestGeneration \in (0..MaxGeneration)
    /\ requestToken \in (0..(MaxGeneration + 1))
    /\ requestLifecycle \in (0..1)
    /\ requestExpectedState \in {"ready", "claimed", "processing"}
    /\ requestTenant \in {"tenant-A", "tenant-B"}
    /\ requestInstallation \in {"installation-A", "installation-B"}
    /\ requestStartTime \in (0..MaxTime)
    /\ requestPreLockValid \in BOOLEAN
    /\ lockAcquireTime \in (0..MaxTime)
    /\ lockOwner \in (Workers \cup {NoOwner, "external"})
    /\ blockerAvailable \in BOOLEAN
    /\ mutationCount \in (0..10)
    /\ lastGuardFailed \in BOOLEAN
    /\ lastFailureMutationCount \in (0..10)
    /\ acceptedHistory \subseteq
       (Workers \X {"worker-service"} \X (0..MaxGeneration) \X
        (0..MaxGeneration) \X (0..MaxTime) \X (0..(MaxTime + LeaseDuration)) \X
        (0..1) \X (0..MaxGeneration) \X (0..(MaxGeneration + 1)) \X
        (0..1) \X WorkStates \X WorkStates \X {"tenant-A", "tenant-B"} \X
        {"installation-A", "installation-B"} \X (0..MaxTime) \X
        (0..MaxTime) \X ProtectedOps \X (0..MaxGeneration) \X (1..10))
    /\ claimEvents \subseteq ((0..MaxGeneration) \X (1..MaxGeneration) \X Workers)

RequestLockCoherence ==
    /\ (requestState = "idle" => requestWorker = NoOwner /\ requestOp = "none")
    /\ (requestState = "waiting" => requestWorker \in Workers)
    /\ (requestState = "locked" => requestWorker \in Workers /\ lockOwner = requestWorker)

SingleClaimOwner ==
    /\ (workState \in {"ready", "completed", "failed", "quarantined"}
        => claimOwner = NoOwner /\ claimToken = 0 /\ leaseExpiry = 0)
    /\ (workState \in {"claimed", "processing"}
        => claimOwner = "worker-service" /\ claimToken = claimGeneration)

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
