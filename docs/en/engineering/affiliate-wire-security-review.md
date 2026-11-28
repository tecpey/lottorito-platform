# Affiliate Wire Contract Security Review

**Document ID:** LOT-AFFILIATE-SEC-001 | **Version:** 0.1.0 | **Status:** Proposed security review; not a production security approval | **Reviewed:** 2026-11-27

## 1. Purpose and review boundary

This review assesses the proposed LOT-AFFILIATE-WIRE-001 OpenAPI 3.2.1, AsyncAPI 3.0.0 and CloudEvents 1.0.2 artifacts against the current threat model and public security guidance. It is a design review, not a penetration test, implementation audit, legal opinion, partner certification or production authorization.

Evidence reviewed:
- `contracts/openapi/affiliate-management.v1.json`
- `contracts/openapi/partner-event-ingestion.v1.json`
- `contracts/asyncapi/affiliate-domain-events.v1.json`
- `scripts/validate_affiliate_contract_payloads.mjs`
- LOT-AFFILIATE-WIRE-001 and its bilingual status/decision records.

External reference baseline:
- OWASP API Security Top 10 (2023): BOLA, broken authentication, object-property/function authorization, resource consumption, sensitive business flows, SSRF, misconfiguration, inventory and unsafe API consumption.
- RFC 9700: OAuth 2.0 Security Best Current Practice, including audience restriction and sender-constrained access tokens where feasible.
- CloudEvents JSON format: extension attributes are top-level JSON properties; runtime allowlisting remains necessary.
- RFC 8785: JSON Canonicalization Scheme (JCS), an Informational RFC, for deterministic hashing/signing representations. It requires duplicate object member names to be rejected before canonicalization.

## 2. Findings and required disposition

| ID | Risk / area | Evidence and assessment | Required control / disposition |
|---|---|---|---|
| SEC-AFF-01 | Broken Object-Level Authorization (high) | Management routes read resources by opaque IDs. The contract requires object-level authorization but no implementation exists. | Every read/write query MUST be scoped by authenticated tenant, product entitlement, membership/role and resource ownership in the same authorization path. Never authorize by ID or scope alone. Add cross-tenant and cross-membership negative tests for every object route. Release blocker for runtime. |
| SEC-AFF-02 | Authentication profile and token replay (high) | Both APIs use separate HTTP bearer schemes, but issuer, audience, token format, lifetime, revocation and client authentication are intentionally unresolved. | Keep human/delegated management credentials separate from partner machine credentials. Before runtime, define issuer trust, exact audience, expiry/not-before, subject/client binding, key rotation/revocation, scope semantics and credential lifecycle. Prefer audience-restricted and sender-constrained machine tokens (mTLS or DPoP) where the deployment supports them, following RFC 9700. Do not assume JWT. |
| SEC-AFF-03 | Non-standard scope declaration (medium) | `x-required-scopes` is a custom OpenAPI operation extension; the HTTP bearer security scheme itself does not encode OAuth scopes for generated clients. | Treat this extension as a normative contract field only after its schema, enforcement semantics and generator behavior are documented. Runtime MUST enforce each listed scope. Keep final names and OAuth issuer/profile open until LOT-API-PLATFORM-001 is decided. Add a contract test that every secured operation has a non-empty scope extension. |
| SEC-AFF-04 | Source identity and duplicate/conflict handling (high) | Ingress distinguishes CloudEvents source + id, request Idempotency-Key and economic-effect identity; the uniqueness boundary is tenant + product + installation + source + id. | Enforce this boundary with a durable unique constraint. Exact duplicate + identical fingerprint returns the original receipt and creates no new job. Same identity + different fingerprint is a recorded integrity conflict (409), quarantined without side effects. Atomic Inbox + Job commit must precede 202. Add concurrent duplicate and crash/retry tests. |
| SEC-AFF-05 | Payload fingerprint ambiguity (high) | The wire document requires a payload fingerprint but does not yet define byte-level or semantic canonicalization. | Proposed default: reject duplicate JSON object member names during strict parsing, validate the envelope, canonicalize the complete accepted CloudEvents object with RFC 8785 JCS, then hash the UTF-8 canonical bytes (e.g. SHA-256). Preserve the original raw bytes/hash separately under restricted retention. Do not silently coerce types or normalize Unicode. This is a proposal requiring an implementation ADR and cross-language test vectors before use. |
| SEC-AFF-06 | CloudEvents extension and schema trust (high) | The generic partner envelope permits top-level extension properties and `data.additionalProperties=true`; CloudEvents JSON places extensions at top level. This is necessary for extensibility but not an allowlist. | Runtime MUST allow only core attributes plus installation-specific registered extension names/types; reject reserved-name collisions, unknown extensions, unknown event types and unregistered source namespaces. Validate `data` against the exact versioned integration schema with strict unknown-field policy before normalization. Never fetch `dataschema` from an arbitrary URL. |
| SEC-AFF-07 | SSRF through schema references (high) | `dataschema` is a URI-reference and its description prohibits arbitrary fetching, but schema resolution is a runtime behavior. | Schema identifiers MUST resolve only to pre-registered immutable schema IDs or locally pinned artifacts. No network dereference, redirects, DNS resolution or URL-based schema loading from event data. Test private/link-local/loopback destinations and redirect chains are unreachable because no fetch is attempted. |
| SEC-AFF-08 | Unbounded resource consumption (high) | Page size is capped at 100 and partner `data` has maxProperties 64, but no hard request-body, nesting-depth, string, array, extension-count, parsing-time or integration quota ceiling is fixed. Some response arrays/role lists are also unbounded in the schema. | Before runtime, define configurable per-installation quotas plus non-overridable platform ceilings for body bytes, JSON depth, total nodes, string lengths, array lengths, extension count, parsing time, concurrency and rate. Reject oversized requests before expensive work; enforce response page bounds. Numeric limits require product/operations approval and load testing, not guesses. |
| SEC-AFF-09 | Object/property mass assignment and data minimization (medium) | Management response/request schemas are mostly closed objects; generic event data is intentionally open until provider-specific validation. | Keep management objects closed by default. Do not bind request JSON directly to domain/database models. Use explicit allowlisted DTO-to-command mapping. Enforce property-level authorization and data minimization for attribution/affiliate outputs. |
| SEC-AFF-10 | Idempotency-Key semantics (medium) | Referral-link creation requires Idempotency-Key and documents principal/tenant/operation/fingerprint binding; the referenced IETF document is still a draft. | Store key, scope, request fingerprint, result reference and state durably with concurrency-safe uniqueness. Define retention and in-progress conflict behavior before runtime. Reject same key with different fingerprint. Keep the current draft reference explicitly non-final and re-evaluate when standardized. |
| SEC-AFF-11 | Error and information disclosure (medium) | Problem Details allows extension members; `detail` is unbounded and free-form in the schema. | Use stable machine-readable error codes; never echo provider payloads, credentials, SQL, internal hostnames or cross-tenant existence. Bound and sanitize detail; use generic 404/403 policy consistently. Keep correlation IDs non-secret. |
| SEC-AFF-12 | Audit, privacy and operational evidence (high) | Wire docs require provenance/hash and prohibit raw payloads in ordinary logs, but retention, access, encryption, deletion and audit policy are not fully specified. | Define purpose-based retention, encryption at rest/in transit, restricted raw-payload access, audited break-glass, redaction, deletion/legal-hold handling, and access review. Audit privileged membership/program/link changes and all event quarantine/replay/identity-conflict actions. Never log bearer tokens or raw sensitive payloads. |
| SEC-AFF-13 | Response collection bounds (medium) | `ProgramPage.data` is an array but does not currently declare `maxItems`, despite the request limit max of 100. | **Addressed in the current draft:** `ProgramPage.data.maxItems=100` now matches the request limit and positive-at-100 / negative-at-101 fixture cases were added. The updated CI run must confirm these cases. Review every other array (including role lists) for an explicit domain-approved bound before runtime. |

## 3. Security invariants

1. Authentication identifies a principal or integration; authorization is re-evaluated for every operation and resource.
2. Tenant, product, environment, source namespace and integration installation are derived from trusted server-side bindings, never from partner claims.
3. The path `integrationId`, opaque resource IDs, event extensions and `dataschema` do not grant authority.
4. No partner event directly mutates Wallet, Ledger, Payment, Settlement or Payout.
5. Event acceptance means durable receipt only; business qualification and financial effects are separate domain decisions.
6. At-least-once delivery is expected. Durable uniqueness, transactional Inbox/Job creation and idempotent downstream effects are mandatory.
7. No arbitrary network fetch is permitted while validating schemas, URLs or partner-controlled references.
8. No production readiness claim follows from document/schema CI.

## 4. Release gates

### Required before application implementation
- Approve the authentication trust model and exact management/machine principal separation.
- Approve the normative scope extension semantics and initial permission matrix.
- Decide strict JSON parser behavior, duplicate-member rejection and canonical fingerprint algorithm.
- Define event/source/extension/schema allowlist ownership and schema pinning.
- Approve resource ceilings and quota dimensions.
- Define retention, encryption, raw payload access and audit requirements.
- Add cross-tenant, object-level, property-level, scope, duplicate-concurrency, conflict, SSRF-no-fetch and resource-boundary tests.

### Required before production
- Threat-model update, independent security review and penetration testing.
- Runtime evidence for tenant isolation, token revocation/audience/sender binding, atomic persistence, retry/replay and failure recovery.
- Operational dashboards/alerts, incident response, key rotation, backup/restore and evidence retention.
- Actual partner contract, approved schema mapping and authorized sandbox evidence.

## 5. Current validation evidence

On PR #76 head `5877746173cbc83e715a7134426d2c086c0181b8`:
- Documentation Governance run `46054085669` (#930): PASS.
- Affiliate Contract Validation run `46054085685` (#32): PASS.
- Redocly 2.83.0: both OpenAPI documents valid; each reports one non-blocking missing-license warning.
- AsyncAPI CLI 6.2.2: AsyncAPI 3.0.0 document valid; one informational recommendation suggests 3.1.0.
- Ajv 8.17.1 / ajv-formats 3.0.1: 31 positive/negative assertions passed across OpenAPI 3.2.1 (2020-12 instance subset) and AsyncAPI 3.0.0 (Draft 07).

These are document and schema-instance checks only. They do not implement or verify any runtime security control in this review.

## 6. Decision status

This review proposes controls and identifies implementation gates. It does not select an OAuth provider, token format, partner, jurisdiction, schema registry, numeric quota, retention period or production security architecture. Those remain open decisions under the relevant platform/domain owners.
