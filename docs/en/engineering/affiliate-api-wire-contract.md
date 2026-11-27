# Affiliate API Wire Contract and Event Ingestion Profile

**Document ID:** LOT-AFFILIATE-WIRE-001 | **Version:** 0.1.0 | **Status:** Proposed wire-contract draft; not approved, published or implemented

## 1. Purpose and authority

This document turns the capability inventory in LOT-AFFILIATE-API-001 and the shared conventions in LOT-API-001 / LOT-EVENT-001 into a narrow, machine-readable wire-contract proposal. It does not replace those documents, define the full Affiliate product surface, or assert that an API endpoint exists.

The first scope is Affiliate & Agent. Live Chat remains a separate later module and is not part of these API artifacts. The contract is provider-neutral. No customer API, event catalogue, credentials, legal entity, jurisdiction, sandbox or partner mapping has been received and verified for this work.

## 2. Two independent API boundaries

| Boundary | Purpose | Caller identity | Contract artifact |
|---|---|---|---|
| Affiliate Management API | Tenant administration and Affiliate/Agent self-service resources | User/delegated or authorized application identity | `contracts/openapi/affiliate-management.v1.json` |
| Partner Event Ingestion API | Server-to-server submission of source events from an approved integration | Dedicated machine identity bound to one integration installation | `contracts/openapi/partner-event-ingestion.v1.json` |

These boundaries MUST NOT share credentials, scopes, rate-limit budgets or implicit trust. The integration path parameter is a selector, not proof of tenant or integration authority. The authenticated machine identity is mapped server-side to exactly the permitted integration installation, tenant, product and environment.

The management API MUST NOT accept partner event assertions as a substitute for domain authorization. The ingestion API MUST NOT expose general Affiliate administration or financial mutation.

## 3. Narrow management API surface

The OpenAPI file defines only the first wire-contract slice:

- `GET /v1/affiliate/programs` — list programs visible to the caller.
- `GET /v1/affiliate/me` — resolve the caller's current Affiliate membership-scoped profile.
- `POST /v1/affiliate/referral-links` — create a referral link using an allowlisted destination key.
- `GET /v1/affiliate/referral-links/{referralLinkId}` — read an authorized link.
- `GET /v1/affiliate/attributions/{attributionId}` — read an authorized, privacy-minimized attribution decision.

This is intentionally not the complete capability inventory. Program publication, membership approval, Agent hierarchy mutation, campaign administration, commission calculation, statements, adjustments, exports and payout workflows remain outside this first wire slice. Their inclusion requires the relevant domain and policy decisions.

A referral request uses a registered `destinationKey`, not an arbitrary redirect URL. This prevents the API from becoming an open-redirect primitive. Opaque resource IDs do not replace object-level authorization.

## 4. Authentication and authorization profile

All operations require HTTPS and a bearer access token. The OpenAPI contract deliberately does not invent an issuer URL, token format, token lifetime or OAuth deployment. Candidate server-to-server issuance is OAuth 2.0 Client Credentials with strong confidential-client authentication (for example, private-key JWT or mutual TLS), subject to an explicit LOT-API-PLATFORM-001 decision and RFC 9700 review.

Scopes are necessary but not sufficient. Every request MUST additionally enforce current tenant membership or integration binding, product entitlement, object ownership, role, resource state and any applicable policy. Tenant and product context MUST be resolved from trusted server-side identity/configuration. A caller-supplied tenant identifier is never authority.

Suggested minimum scopes are recorded as operation extensions in the OpenAPI file. Final scope names, consent/delegation behavior and privileged step-up requirements remain open.

## 5. Partner event ingress profile

The ingress operation is:

`POST /v1/integrations/{integrationId}/events`

It accepts one CloudEvents structured-mode JSON event per request using `Content-Type: application/cloudevents+json`. The selected profile is CloudEvents 1.0.2. The path's `integrationId` is not a secret and does not grant access. The token must be bound to that integration installation and its tenant, product and environment.

Ingress rules:

1. Resolve the integration, tenant, product, environment and permitted source namespace from the authenticated machine identity.
2. Require the incoming CloudEvents `source` to match a source namespace registered for that installation; require `type` to match its explicit event allowlist.
3. Treat CloudEvents `source + id` as the source-event identity. The source namespace must be allowlisted and bound to the authenticated integration installation. Enforce the durable uniqueness boundary at `tenant_id + product_id + integration_installation_id + source + id`.
4. Treat `data` as untrusted provider input. Validate it against the exact, versioned provider schema configured for the integration before normalization. The generic OpenAPI object schema is a transport boundary only; it is not permission to accept arbitrary fields or unknown event types.
5. Do not trust tenant, product, affiliate, currency, amount, role, commission or payable status asserted in provider payloads. Map and verify these values using server-owned configuration and domain rules.
6. Preserve provenance and a payload integrity hash under approved retention and access controls. Raw payload access is restricted and raw payloads must not be copied into ordinary logs.
7. Persist the inbox receipt and durable processing job atomically before returning `202 Accepted`.
8. Process at least once. Consumers and downstream effects must be idempotent; the platform does not promise exactly-once network delivery.

No partner-specific event type, payload field, signature format or mapping is approved by this generic profile. Those details remain blocked on the actual partner contract and sandbox evidence.

## 6. Identity model: request, source event and economic effect

Three identities remain separate:

- **HTTP request idempotency:** identifies a retry of a mutating API request. Use the `Idempotency-Key` header where the operation contract requires it; bind it to the authenticated principal/integration, tenant, operation and normalized request fingerprint.
- **Source event identity:** CloudEvents `source + id`; identifies one source assertion. A new delivery attempt MUST NOT create a new source-event identity.
- **Economic effect identity:** a domain-owned identity scoped at minimum by tenant, product, effect type and canonical economic identity. It is evaluated only after source validation and business qualification.

A source event may produce zero, one or multiple separately governed effects. A source event ID is not an economic-effect ID and neither is a ledger journal ID. Corrections and reversals are new linked records; never mutate or reuse the original event identity.

For HTTP request idempotency, the current IETF draft-ietf-httpapi-idempotency-key-header-09 is a design input, not a final RFC. Its Structured Field string syntax is reflected in the examples. The proposed response profile is: same key and same fingerprint returns the original result/current operation; same key with a different fingerprint returns `422`; a concurrent request still in progress returns `409`. Revisit this profile when the IETF document is finalized. A CloudEvents source/id collision with a different payload fingerprint returns `409`, because it is a source identity integrity conflict, not an HTTP Idempotency-Key mismatch.

## 7. Acceptance and HTTP response semantics

For event ingress:

| Condition | Response | Required behavior |
|---|---:|---|
| New event durably accepted and queued | 202 | Inbox and processing job committed atomically before ACK |
| Exact duplicate source + id + payload fingerprint | 200 | Return the existing receipt; do not enqueue another job |
| Same source + id but different payload fingerprint | 409 | Quarantine/record the identity collision; no side effect |
| Invalid or unsupported event schema/type | 422 | Reject or quarantine according to the configured contract; no economic effect |
| Oversized body | 413 | Reject before expensive parsing |
| Unsupported content type | 415 | Reject |
| Rate/tenant quota exhausted | 429 | Return retry guidance; never silently drop |
| Temporary service unavailability before durable receipt | 503 | Caller may retry with the same source + id |

A successful HTTP response means durable receipt only. It does not mean business qualification, attribution, commission assessment, ledger posting, payment, settlement or payout.

Errors use RFC 9457 Problem Details with `application/problem+json`. Error details MUST NOT reveal cross-tenant resource existence, secrets, raw provider payloads, SQL, internal hosts or sensitive mapping rules. A server-generated request/correlation identifier is returned for support.

## 8. Canonical event mapping

LOT-EVENT-001 remains the Lottorito semantic source of truth. CloudEvents is the interoperable wire envelope, not a replacement for domain identity or accounting semantics.

At ingress, the partner's CloudEvents `source + id` is stored as source provenance. After acceptance and normalization, an internal canonical event receives a new platform-generated event ID:

| LOT-EVENT-001 concept | Internal CloudEvents mapping |
|---|---|
| `event_id` | CloudEvents `id` (platform-generated; not the partner's ID) |
| platform event producer | CloudEvents `source` (domain-owned URI/URN) |
| `event_type` | CloudEvents `type` |
| aggregate type/id | CloudEvents `subject` |
| `occurred_at` | CloudEvents `time` |
| `tenant_id` | `tenantid` extension, set only by trusted platform context |
| `product_domain` | `productdomain` extension |
| `correlation_id` / `causation_id` | `correlationid` / `causationid` extensions |
| original `source_system` / `source_event_id` | `sourcesystem` / `sourceeventid` provenance extensions |
| `received_at` / `recorded_at` | `receivedat` / `recordedat` extensions |
| domain payload | CloudEvents `data` |

CloudEvents extension attribute names use lowercase alphanumeric names; the compact names above are deliberate. The logical AsyncAPI channel is `affiliate.canonical-events`. It does not select Kafka, RabbitMQ, HTTP callbacks or another transport.

## 9. Data and financial semantics

- Timestamps preserve distinct meanings: source occurrence, platform receipt, durable recording and any later business/financial recognition or posting.
- Currency values are never JSON floating-point numbers. If an event schema requires money, use an integer minor-unit string with an explicit ISO 4217 currency and documented exponent/rounding policy. The initial registration-oriented fixture contains no money field.
- Unknown currency, ambiguous amount, unsupported event type, malformed source identity or conflicting external mapping is never coerced to zero or silently accepted.
- An authenticated event is not automatically a valid business fact. A valid fact is not automatically attributable, commissionable, payable or posted.
- No partner event may directly mutate a wallet, ledger balance, payout or payment state.

## 10. Required contract and failure tests

The wire-contract test suite MUST cover at least:

1. valid event accepted only after durable Inbox + Job commit;
2. exact duplicate source/id/body returns the original receipt and creates no second job;
3. same source/id with changed body is quarantined and returns 409;
4. same event delivered under a different attempt still deduplicates by source/id;
5. unknown source namespace or event type is rejected;
6. wrong tenant/product/environment binding is denied;
7. tenant identifiers supplied in payload cannot override trusted context;
8. malformed CloudEvents required attributes are rejected;
9. unsupported media type and oversized body are rejected;
10. stale/future source timestamps follow an explicit configured tolerance policy;
11. concurrent duplicate delivery produces one durable receipt and one processing job;
12. database failure before commit returns no success acknowledgement;
13. worker crash/retry does not duplicate downstream effects;
14. event ordering violations are detected or quarantined according to domain policy;
15. raw provider data is redacted from logs and restricted in evidence storage;
16. bearer token with wrong scope or integration binding is denied;
17. revoked/expired credentials are rejected;
18. management API cross-tenant and object-level access is denied;
19. referral destination keys are allowlisted and cannot create arbitrary redirects;
20. Idempotency-Key replay, payload mismatch and concurrent-in-progress cases follow the documented response profile;
21. backward compatibility and schema-version changes are contract-tested;
22. errors carry correlation IDs and disclose no protected data.

These are acceptance requirements, not evidence that tests have already run.

### Machine-checked schema-instance suite

The contract CI also runs `scripts/validate_affiliate_contract_payloads.mjs` against representative positive and negative instances:

- OpenAPI 3.2.1 component schemas are instance-checked with an Ajv 2020-12 instance. The current schemas use JSON Schema 2020-12 keywords; Redocly remains the validator for the complete OpenAPI document and its OAS dialect.
- AsyncAPI 3.0.0 message payload is instance-checked with a separate Draft 07 Ajv instance, matching the AsyncAPI 3.0.0 Schema Object baseline.
- Local component references, required fields, types, enums, bounds, date-time/URI formats, uniqueness, closed objects and RFC 9457 extension members have representative positive/negative cases.
- CloudEvents top-level extension properties remain structurally accepted by the envelope schema. This does **not** authorize arbitrary extensions: the runtime must enforce an integration-specific extension/event/source allowlist before normalization.
- The suite does not prove runtime authentication, tenant binding, durable Inbox/Job atomicity, deduplication, replay handling, ledger effects, or provider compatibility.

The two dialect validators are deliberately separate. Do not move AsyncAPI payloads into the 2020-12 instance or infer that Ajv instance validation replaces Redocly/AsyncAPI document validation.

## 11. Standards and version governance

- OpenAPI Specification 3.2.1 for HTTP API contracts.
- AsyncAPI 3.0.0 for the logical event interface.
- CloudEvents 1.0.2 for the interoperable event envelope.
- JSON Schema Draft 2020-12 for standalone payload constraints where supported by the selected validators.
- RFC 9457 for HTTP Problem Details.
- RFC 9700 for OAuth 2.0 security review.
- IETF draft-ietf-httpapi-idempotency-key-header-09 as a non-final reference only.
- OWASP Webhook Security guidance for replay, signature, duplicate and SSRF threat review.

Toolchain compatibility for these exact versions MUST be tested before CI enforcement. A contract file is not proof of an implemented endpoint or a provider's compatibility. Breaking changes require explicit versioning and consumer impact review.

## 12. Open decisions and release gates

Still open: actual partner and legal entity; jurisdiction; integration ownership; token issuer/profile and client authentication; exact source namespace; provider event catalogue and schemas; timestamp tolerance; payload retention; event size and rate limits; retry window; event allowlist; attribution policy; commission semantics; and any financial recognition rules.

Before a partner adapter or production API is approved, obtain the partner's official API/event documentation and authorized sandbox; map every field and event; agree authentication, replay and retry behavior; pass contract, tenant-isolation, concurrency and reconciliation tests with synthetic data; and complete product, finance, legal, security, privacy and operations review.

**Authority:** Proposed only. No customer endpoint, partner schema, OAuth profile, transport, event catalogue, commission formula, financial posting or production access is approved by this document.
