# Lottery Provider Integration Contract

**Document ID:** LOT-LOTINT-001 | **Version:** 0.1.0 | **Status:** Proposed canonical contract; no provider API verified

## 1. Purpose and boundary
Define the boundary between the Lottery domain and an external provider. This is provider-neutral; it does not claim compatibility with a named vendor. Provider-specific endpoints, authentication, schemas, states, SLAs, limits and certification must live in an adapter profile backed by vendor documentation and sandbox evidence.

## 2. Adapter responsibilities
Authentication/signature validation and credential lifecycle; mapping canonical tenant/product/draw/order/ticket references; translating provider payloads/states into versioned canonical events; idempotency, deduplication, replay protection and payload limits; timeout/retry/rate-limit/pagination/outage handling; querying ambiguous submissions; preserving raw evidence references, provenance, timestamps and correlation IDs; reconciling catalog, orders, tickets, draws, results, claims and settlement; exposing provider health without secrets.

The domain core must not call provider endpoints directly or treat provider-specific state as its only source of truth.

## 3. Canonical operations (capability-dependent)
1. Catalog/product discovery and synchronization.
2. Rules, schedule, price, currency and limits retrieval.
3. Order/ticket submission with client idempotency reference.
4. Order/ticket status query.
5. Cancellation/refund request and query, if supported and approved.
6. Draw schedule/status retrieval.
7. Result retrieval and verification evidence.
8. Ticket validation.
9. Claim/settlement status retrieval, if supported.
10. Statement/report retrieval and reconciliation.

Unsupported capabilities must be declared; never simulate success.

## 4. Canonical event envelope
Each inbound event carries or is enriched with: event_id; versioned event_type; schema_version; provider_id; trusted tenant_id resolved from authenticated connection configuration; external_object_id; occurred_at preserving source timezone/offset; received_at; correlation_id; idempotency_key for the business/economic effect; verifiable source_reference; payload_hash; and validated, minimized, versioned canonical payload.

Never trust tenant_id solely from a payload. Resolve tenant from authenticated provider connection and configured mapping; reject mismatches.

## 5. Submission and timeout safety
Create a stable client request/idempotency identity and persist intent before external submission. On timeout/disconnect, set outcome UNKNOWN; do not blindly submit a new order. Query provider using the same reference or reconcile through a verified feed/statement. Retry only when documented provider idempotency semantics make it safe. Record attempts, response classes, timeouts, reconciliation and operator overrides.

## 6. Results and corrections
A result identifies provider, product, draw, rules version where available, source event time, receipt time, source reference, verification state and normalization version. The adapter transports evidence; Lottery owns approval and publication. Conflicts/corrections are new versioned facts. Preserve original payload/hash and all corrections; never silently replace published data.

## 7. Security
TLS; authenticated provider channels; signature/timestamp verification where supported; replay protection; secrets outside Git/logs; scoped credentials, rotation and revocation; justified allowlists; rate/payload limits; schema validation; egress controls; adapter dependency review.

A provider lacking adequate authenticity, provenance, replay protection or reconciliation must not be enabled for financial or customer-impacting actions.

## 8. Reliability and reconciliation
Bounded exponential backoff with jitter and provider-specific rate limits; distinguish transient, permanent and ambiguous failures; quarantine poison messages and controlled replay with original identity; periodically reconcile catalog, orders, tickets, draws, results, claims and statements; alert on stale feeds, unmatched records, duplicate IDs, unexplained state regressions and financial gaps; use durable inbox/outbox patterns across transaction boundaries.

## 9. Provider certification profile
Record legal entity/role/jurisdiction evidence/contract scope; API documentation version/date; sandbox and test-account ownership; authentication/signature; supported and unsupported capabilities; state mapping/idempotency/retry/rate limits; source-of-truth and result correction policy; availability/support/incident escalation; data location/privacy/security/retention; settlement/fees/liability/reconciliation/disputes; contract and negative tests; evidence, approver and review date.

## 10. Current status
No Lottery provider, API, sandbox, credentials, endpoint, callback schema or certification is verified in the repository. The previously mentioned new-lotto.net/api.php is a research lead, not a validated integration specification. RaidenBet is a proposed Affiliate pilot partner, not a Lottery provider absent separate evidence and approval.