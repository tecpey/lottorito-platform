# P-03 — Provider Failure and Event Delivery Prototype

**Document ID:** LOT-PROT-P03-001 | **Version:** 0.3.0 | **Status:** Prototype CI passed; full P-03 remains partial | **Review date:** 2026-11-24

## Purpose and decision boundary

P-03 tests provider-neutral event ingestion and delivery reliability needed for Affiliate/Agent integrations and future product providers. It focuses on authenticated inbound webhooks, replay and duplicate handling, durable inbox processing, leases, retries, dead-letter behavior, outbound webhook delivery and reconciliation.

No partner/provider is selected or connected. RaidenBet's actual API documentation, authentication scheme, event contract, sandbox and authorized test credentials remain prerequisites for a real adapter. The HMAC fixture is a synthetic Standard Webhooks-style signing implementation, not evidence that any current partner supports that protocol.

## Implemented experiment slice

- Installation scope is supplied as trusted server-side configuration. Tenant, product and provider identity are never taken from caller-controlled payload fields.
- Inbound signature verification uses exact raw request bytes, a signed event ID and attempt timestamp, HMAC-SHA-256, constant-time comparison, a bounded freshness window and multiple configured verification keys for rotation.
- Synthetic secrets use a base64-prefixed whsec_ form. Production key storage/rotation through a KMS or secrets manager is not implemented.
- Payload size, JSON validity, signed header/payload event-ID consistency and required event type are checked before durable acceptance.
- Provider-specific payloads are adapted to a compact CloudEvents 1.0-style canonical envelope. Tenant identity is kept in the database scope, not copied into the public event context.
- Inbound events are durably written to a tenant/product-scoped inbox before returning 202. The exact raw body is hashed for conflict detection; only the canonical event is persisted.
- A repeated provider event ID with the same payload hash is acknowledged as a duplicate. The same ID with a different payload hash creates a conflict record and returns 409; the original event is not overwritten.
- Inbox workers use transaction-scoped claims with FOR UPDATE SKIP LOCKED, leases, attempt counters, stale-ack rejection, bounded exponential retry delay and dead-letter status.
- Optional provider sequence values are retained, but the prototype does not assume global or timestamp-based event ordering.
- Outbound delivery records are idempotent by tenant/product/endpoint/event identity. Attempt records preserve response classification; 2xx completes, selected transient classes retry, permanent 4xx fails, and exhausted retries dead-letter.
- Outbound messages can be signed with the same synthetic signature helper; no network transport is invoked.
- A reconciliation view compares independently seeded provider-event expectations with inbox status and surfaces missing or not-yet-processed events.
- Tenant/product RLS applies to inbox, conflicts, expectations, outbound deliveries and delivery attempts.

## Acceptance matrix

| ID | Scenario | Expected result |
|---|---|---|
| P03-EVENT-01 | Valid signed inbound event | Durable inbox row and 202 response |
| P03-EVENT-02 | Raw-body tampering | Signature rejected |
| P03-EVENT-03 | Stale or future attempt timestamp | Signature rejected |
| P03-EVENT-04 | Missing or unsupported signature | Rejected |
| P03-EVENT-05 | Previous key during rotation | Accepted only while previous key remains configured |
| P03-EVENT-06 | Same event ID and same payload | Idempotent duplicate acknowledgement |
| P03-EVENT-07 | Same event ID with changed payload | Conflict recorded; original row preserved |
| P03-EVENT-08 | Caller forges tenant/product in payload | Trusted installation scope remains authoritative |
| P03-EVENT-09 | Oversized, invalid JSON or mismatched event ID | Rejected before durable acceptance |
| P03-EVENT-10 | Unknown or inactive installation | Rejected |
| P03-EVENT-11 | Provider-specific adapter | Canonical CloudEvent envelope produced |
| P03-EVENT-12 | Inbox worker claim and completion | Durable event reaches processed state |
| P03-EVENT-13 | Concurrent inbox workers | SKIP LOCKED yields distinct claims |
| P03-EVENT-14 | Expired lease and stale acknowledgement | New attempt can reclaim; old worker cannot ack |
| P03-EVENT-15 | Retry delay | Bounded exponential schedule is applied |
| P03-EVENT-16 | Maximum attempts | Event reaches dead-letter state |
| P03-EVENT-17 | Provider-event reconciliation | Missing/unprocessed expected event is surfaced |
| P03-EVENT-18 | Outbound event/endpoint replay | Same payload returns existing delivery; drift conflicts |
| P03-EVENT-19 | Outbound signing | Signature verifies during configured key rotation |
| P03-EVENT-20 | Outbound HTTP result classes | Transient response retries; permanent response fails |
| P03-EVENT-21 | Outbound lease expiry | Stale sender acknowledgement is rejected |
| P03-EVENT-22 | Missing tenant/product context | RLS returns no inbox rows |

## Verified CI evidence

- P-03 integration run [45418365951](https://github.com/tecpey/lottorito-platform/actions/runs/45418365951) passed on PR head 20f0903f4d996ed2b5fece6730b53f908579ddfd: 22 tests passed, 0 failed, 0 skipped, using npm ci, the committed lockfile, Node.js 26.13.0 and PostgreSQL 18.7.
- Documentation Governance run [45418367980](https://github.com/tecpey/lottorito-platform/actions/runs/45418367980) passed on the bilingual documentation head.
- No local execution or real provider integration has been performed. Passing CI proves only the defined synthetic cases.

## Local reproduction

Use only a disposable local database. The setup script drops and recreates P-03 fixture tables; never point it at shared, staging or production databases.

    cd prototypes/p03-provider-event-delivery
    docker compose up -d
    export ADMIN_DATABASE_URL='postgres://postgres:p03-admin-only-not-production@127.0.0.1:55434/lottorito_p03'
    export RUNTIME_DATABASE_URL='postgres://event_runtime:p03-runtime-not-for-production@127.0.0.1:55434/lottorito_p03'
    npm ci --ignore-scripts --no-audit --no-fund
    npm test
    docker compose down -v

All keys, identities, payloads and data are synthetic.

## Security and operational limitations

- The prototype exercises a Standard Webhooks-style HMAC scheme, not every provider-specific webhook signature protocol. Each real adapter must follow the partner's exact signing contract and be tested against official fixtures.
- There is no HTTP server/router, API gateway, WAF, IP allowlist, mTLS configuration, production KMS/secrets manager, key revocation workflow or external broker.
- The outbound sender is a state machine only; it does not open network connections. DNS rebinding, SSRF, endpoint allowlisting, redirect policy, TLS verification, response-body limits and network timeouts remain untested.
- A 202 response is returned only after inbox persistence commits. Delivery and processing are at-least-once; exactly-once side effects are not claimed. Downstream financial effects must use P-02 business-effect idempotency.
- Retry classification and limits are synthetic defaults; real retry behavior, Retry-After handling, partner rate limits and disablement policy must be negotiated per provider contract.
- Optional provider sequence values are recorded but not used to infer event order. Timestamps alone are not an ordering guarantee.
- Reconciliation uses synthetic expected-event rows, not a partner API or provider statement.
- No load, chaos, failover, disaster recovery, privacy-retention, legal review or production readiness is claimed. Full P-03 remains partial.

## Research references

- OWASP — [Webhook Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Webhook_Security_Cheat_Sheet.html): raw-body signatures, replay protection, duplicate event handling, rate limiting, fail-secure responses and sensitive logging.
- Standard Webhooks — [Webhook signature specification](https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md): signed message ID/timestamp/body, constant-time verification, timestamp freshness and zero-downtime key rotation.
- IETF — [RFC 9421 HTTP Message Signatures](https://www.rfc-editor.org/rfc/rfc9421.html): standardized HTTP component signing, covered-component requirements, key identifiers, timestamps and nonce-based replay mitigation. P-03 does not claim RFC 9421 implementation.
- CloudEvents — [Core specification](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md) and [JSON event format](https://github.com/cloudevents/spec/blob/main/cloudevents/formats/json-format.md): provider-neutral event context attributes and data separation.
- AWS Prescriptive Guidance — [Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html): atomic persistence, at-least-once delivery and idempotent consumers.
- Stripe — [Manage webhook endpoints](https://docs.stripe.com/webhooks): raw request body signature verification, duplicate events and provider-specific delivery behavior. This is an example, not a provider selection.
- PostgreSQL 18 — [SELECT locking clause](https://www.postgresql.org/docs/18/sql-select.html): SKIP LOCKED behavior for queue-like multi-consumer claims.

## Stack

This PR is stacked on P-02 branch spike/p02-financial-ledger. It does not merge PR #38, change main, deploy or connect to RaidenBet or any external provider.
