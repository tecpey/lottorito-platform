# Canonical Event Envelope and Delivery Contract

**Document ID:** LOT-EVENT-001 | **Version:** 0.1.0 | **Status:** Proposed platform contract; not an implemented API

## 1. Purpose
Define a provider-neutral envelope for events crossing domain, tenant, partner and asynchronous processing boundaries. Domain payload schemas remain owned by their bounded context and are versioned independently.

## 2. Three identities that must never be conflated
- **Source Event ID:** identifies a fact/message at its source within a source namespace.
- **Economic Effect ID:** identifies one intended business/economic consequence after qualification and policy evaluation.
- **Journal Entry ID:** identifies an accounting posting in the ledger.

One source event may produce no economic effect, one effect or multiple separately governed effects. An effect may be non-financial or require multiple journal entries. Replays of the same source event must not duplicate an economic effect; accounting corrections use linked reversals/adjustments, not event ID reuse or ledger edits.

## 3. Canonical envelope

| Field | Meaning |
|---|---|
| event_id | Platform-unique immutable event record ID |
| source_system | Authenticated source/provider identity |
| source_event_id | Source's stable event identity, namespaced by source |
| event_type | Domain-qualified event name |
| schema_version | Payload contract version |
| tenant_id | Trusted tenant scope resolved from authenticated connection or membership |
| product_domain | Affiliate, Lottery or an explicitly shared platform domain |
| aggregate_type / aggregate_id | Domain aggregate affected |
| occurred_at | Source event time with offset/timezone preserved |
| received_at | Platform receipt timestamp |
| recorded_at | Durable persistence timestamp |
| actor_type / actor_id | User, service principal, provider or system actor |
| correlation_id | End-to-end request/workflow trace |
| causation_id | Immediate event/command that caused this event |
| idempotency_key | Stable key for deduplicating the intended operation/effect |
| source_reference | Verifiable provenance reference |
| raw_payload_hash | Integrity hash of preserved raw evidence, where retained |
| payload | Validated, minimized domain payload |
| classification | Data sensitivity and handling classification |

Tenant context must be resolved from trusted connection/session configuration. A payload tenant field is a consistency assertion, never the authority.

## 4. Time semantics
Preserve distinct timestamps:
- occurred_at: when the source says the event happened.
- received_at: when the platform received it.
- recorded_at: when the platform durably stored it.
- recognized_at / posted_at: when a domain/finance policy recognizes or posts its effect, if applicable.

Do not substitute receipt time for source time or financial recognition time. Store UTC instants and preserve original offset/zone where needed for contractual interpretation and audit.

## 5. Ingestion lifecycle
Proposed stages: RECEIVED → AUTHENTICATED → VALIDATED → NORMALIZED → ACCEPTED_FOR_PROCESSING → PROCESSED, with explicit REJECTED, QUARANTINED and RETRY_PENDING outcomes. Persist receipt and evidence before acknowledging durable acceptance where the transport contract requires it.

Authentication, schema validation, business qualification and financial posting are separate steps. An authenticated message is not automatically a valid business event; a valid business event is not automatically commissionable or financially recognized.

## 6. Delivery and idempotency
Assume at-least-once delivery unless a verified transport contract proves otherwise. Use a durable inbox keyed by source namespace and source_event_id, plus operation-specific idempotency keys. Enforce uniqueness transactionally at the point where the business effect is created. Acknowledge only after durable receipt; retries must preserve identity. Use bounded backoff, jitter, dead-letter/quarantine and controlled replay. Replay must preserve original source identity and record replay actor/reason.

## 7. Corrections and late events
A correction is a new event referencing the original source event and correction reason. A reversal is a new business/economic event linked to the original effect and original journal posting. A policy change applies prospectively unless an authorized, explicit recalculation process says otherwise. Late arrival does not change occurred_at; record receipt separately and apply documented period/recognition rules.

## 8. Security and privacy
Authenticate source; validate signatures/timestamps where supported; prevent replay; enforce payload size/schema limits; redact secrets; minimize personal data; encrypt retained evidence; restrict raw payload access; define retention and deletion/legal-hold policy. Record provenance and verification result.

## 9. Observability and operations
Measure received/accepted/rejected/duplicate/late/quarantined counts, processing latency, retry age, dead-letter depth, per-tenant/provider error rates and reconciliation gaps. Alert on sustained backlog, invalid signatures, duplicate storms, unknown outcomes and economic-effect mismatches. Provide safe replay and operator runbooks.

## 10. Acceptance criteria
- Duplicate source deliveries create one source event record and no duplicate economic effect.
- Source event, economic effect and journal entry can be traced bidirectionally.
- Tenant identity is server-resolved and mismatch is rejected.
- All timestamps retain their distinct meanings.
- Corrections and reversals preserve original history.
- Schema evolution is versioned and compatibility-tested.
- Failure/retry/replay/concurrency behavior is tested.
- Personal data and raw evidence follow access and retention controls.

## 11. Open decisions
Transport choices, event naming convention, schema registry, canonical payload per domain, retention period, hashing/signature algorithms, partitioning, replay authorization, exactly which event types can create economic effects and finance recognition policy.