# Lottorito API Resource Specification

**Document ID:** LOT-API-001 | **Version:** 0.1.0 | **Status:** Proposed contract baseline; requires architecture and owner review

## 1. Purpose and scope
Define shared API conventions for independently usable Affiliate & Agent and Lottery products. This is a provider-neutral proposal, not an implemented API, published OpenAPI contract, compatibility promise or authorization to expose endpoints. Public, tenant, partner and internal APIs are separate audiences and must not share credentials or trust assumptions.

## 2. Design principles
Use resource-oriented HTTP APIs, explicit domain nouns, JSON over HTTPS for standard request/response, stable semantics, explicit versioning, backward compatibility and deprecation windows. Derive tenant/product context from authenticated authorization, not arbitrary request parameters. Standardize validation, errors, pagination, idempotency, rate limits, observability and audit. Never expose database table names or provider payloads as canonical public contracts. Prefer additive changes; breaking changes require a new major version and migration plan.

## 3. Resource and URL conventions
Proposed pattern: /v1/{resource-collection}/{resource-id}. Nested paths express real ownership/lifecycle relationships, not database joins. Avoid deep nesting.

Use plural collections, lowercase kebab-case path segments, opaque IDs, ISO 8601 timestamps with explicit offset (UTC Z preferred for machine exchange), ISO 4217 codes for fiat and exact decimal strings or integer minor units with exponent metadata. Non-fiat credits/points require explicit unit types. Never place secrets, personal data, mutable permissions or trusted tenant identity in URLs.

## 4. API audiences and authentication
- User APIs: authenticated session or delegated OAuth/OIDC token.
- Tenant administration: tenant-scoped principal and explicit admin scopes.
- Partner APIs: per-partner integration identity, narrow scopes, environment separation and revocable credentials.
- Internal service APIs: workload identity and short-lived credentials; no shared static master token.
- Webhooks: signed messages with replay controls; authenticity does not replace authorization of the resulting action.

Authentication proves identity. Authorization separately checks membership, product entitlement, object ownership, action scope and policy state.

## 5. Tenant and product context
Resolve membership from trusted session, validated token claims/current membership or machine-connection record. Client tenant headers/parameters are selectors only where explicitly supported and must be checked against the principal. Bind every request to a product domain and verify entitlement. Reject missing, ambiguous or conflicting context; never silently choose a default tenant. Propagate context through service calls, DB transactions, events, queues, logs and exports. Partner credentials cannot cross tenant/product boundaries.

## 6. Request and response
Require JSON content type for JSON bodies. Validate UTF-8, length, nesting, numeric bounds, enums and unknown fields according to schema policy. Use POST for creation/actions, GET for safe reads, PATCH for partial updates, PUT only for complete replacement and DELETE only where semantics are safe and lawful. Use 202 Accepted for durable async work with a status resource or callback. Return stable resource representations. Use ETags/version fields for concurrency-sensitive updates; reject stale writes.

## 7. Error model
Use a stable machine-readable envelope with code, localized human message, request/correlation ID and safe field details. Never expose stack traces, SQL, provider secrets, internal hostnames or cross-tenant existence. Suggested statuses: 400 malformed; 401 unauthenticated; 403 unauthorized; 404 absent or intentionally undisclosed; 409 state/idempotency conflict; 412 failed precondition; 422 invalid business input; 429 rate limited; 500 unexpected internal error; 502/503/504 controlled dependency failures.

## 8. Pagination, filtering and sorting
Prefer cursor pagination for large/changing collections. Return data and next_cursor; include has_more only when useful. Do not promise exact totals by default. Enforce maximum page size and bounded filter/sort allowlists. Require deterministic ordering with a unique tie-breaker. Scope before pagination by tenant, product, authorization and visibility. Exports must be bounded or asynchronous, authorized and audited. Document filter operators and time-range inclusivity.

## 9. Idempotency and concurrency
Non-idempotent create/action operations accept an Idempotency-Key with documented scope, retention and payload binding. Scope to tenant, principal/integration, operation and resource. Persist key, normalized request hash, result reference and state. Same key/same payload returns original result or current operation state; same key/different payload is conflict. Concurrent duplicates converge to one effect. API idempotency does not replace source-event/economic-effect identity in finance. Use ETag/If-Match or version fields for optimistic concurrency.

## 10. Rate limits and resource protection
Apply layered quotas by tenant, user/service principal, credential, IP/risk, route and operation cost. Define burst/sustained quotas, response headers, retry guidance and fair use. Expensive reports, graph traversal, exports and provider fan-out need separate budgets and async processing. Do not reveal another tenant's activity through rate-limit behavior.

## 11. Webhook contract
Assume at-least-once delivery unless a specific provider contract proves otherwise. Consumers must be idempotent.

Recommended headers: X-Lottorito-Event-Id, X-Lottorito-Delivery-Id, X-Lottorito-Key-Id, X-Lottorito-Timestamp, X-Lottorito-Signature and Content-Type.

Sign a canonical byte representation of timestamp, key ID, event ID and raw body using a documented algorithm/version. Verify before trusting parsed claims; enforce timestamp tolerance; reject replay outside the allowed window; deduplicate event/economic-effect identities. Rotate keys with overlap and revocation procedures.

Acknowledge only after durable receipt. Use bounded exponential backoff with jitter; define attempts, dead-letter handling, manual replay authorization and delivery observability. Delivery ID identifies an attempt, not the economic effect.

## 12. Versioning and lifecycle
Major version in path (/v1); additive compatible fields may be introduced within a major. Never silently change field meaning, units, enum semantics or authorization behavior. Mark deprecated operations and publish migration guide, sunset date, compatibility window and replacement before removal. Version provider adapters independently. Maintain consumer/provider contract tests; do not claim compatibility without executed tests.

## 13. Observability and audit
Every request gets a server-generated request/correlation ID. Propagate trace context safely across services/jobs. Record principal, tenant, product, route template, outcome, latency and rate-limit decision while excluding secrets/sensitive payloads. Financial, permission, identity and configuration mutations require immutable audit events with actor, reason, target, approval and before/after references.

## 14. OpenAPI governance
Maintain the approved contract as OpenAPI 3.1 or a later explicitly adopted version. Include schemas, examples, reusable errors, authentication/scopes, tenant/product authorization, idempotency/concurrency, pagination/rate limits, webhook signatures/events and deprecation metadata. Generate artifacts only from the reviewed canonical contract. CI should validate schema syntax, breaking changes, examples and implementation parity. An OpenAPI file alone does not prove an endpoint exists.

## 15. Required contract tests
Test authentication/authorization per audience; cross-tenant/product denial; object/function authorization; validation and bounds; cursor stability/order/filter/page limits; idempotency replay/payload conflict/concurrent duplicate; optimistic concurrency; webhook signature/timestamp/replay/duplicate/key rotation; rate limits/fair use/resource exhaustion; backward compatibility/deprecation; error redaction and correlation propagation.

## 16. Open decisions
API gateway/hosting, OAuth/OIDC profile, token format/lifetime, partner credential lifecycle, public/private API boundaries, rate-limit tiers, OpenAPI generation workflow, webhook retention/retry windows, data residency and first-release resource inventory require owner and architecture approval.

This specification does not claim any endpoint is implemented or available.
