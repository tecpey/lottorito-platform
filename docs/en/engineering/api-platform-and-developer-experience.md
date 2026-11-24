# API Platform and Developer Experience

**Document ID:** LOT-API-PLATFORM-001 | **Version:** 0.1.0 | **Status:** Proposed platform contract; owner, architecture, security, finance, legal and operations review required

## 1. Purpose, authority and relationship to existing contracts

This document defines the platform layer required to expose Lottorito capabilities as governed, discoverable, operable and commercially packageable APIs for first-party applications, external B2B tenants, white-label operators, approved partners and internal product teams.

It extends, and does not replace:
- **LOT-API-001:** resource-oriented API conventions, authentication audiences, tenant/product context, errors, pagination, idempotency, rate limits, webhook signing, versioning, observability, OpenAPI and contract tests.
- **LOT-EVENT-001:** canonical event envelope and event delivery semantics.
- **LOT-IAM-TENANT-001:** principal, tenant, membership and authorization model.
- **LOT-PROVIDER-EVAL-001:** provider role, evidence, due diligence and approval process.
- Domain contracts including LOT-WALLET-001, LOT-PAYMENT-001, LOT-PAYOUT-001, LOT-CHAT-WIDGET-001 and product-specific contracts.

The API Platform is a control and enablement plane, not a bypass around domain services. It does not own product truth, wallet balances, payment state, commission calculations, lottery outcomes, chat messages or provider state. Each domain remains the authoritative owner of its own invariants and state transitions.

This is a proposed target contract. No API gateway, Developer Portal, SDK, sandbox, API key, OAuth client, public endpoint, usage billing, provider or runtime is claimed as implemented or approved.

## 2. Goals, non-goals and product audiences

Goals:
1. One consistent, versioned integration experience across independently deployable product domains.
2. Self-service discovery and onboarding with explicit human approval gates for sensitive capabilities.
3. Strong isolation between tenants, environments, applications, credentials and product entitlements.
4. Reproducible sandbox testing with synthetic data and deterministic fixtures.
5. Reliable event/webhook delivery with replay, observability and support evidence.
6. SDKs and examples generated from reviewed canonical contracts.
7. Metering, quotas and commercial entitlements that are transparent and cannot silently change financial or security policy.

Audiences and distinct experiences:
- **First-party B2C app:** server-side application integration under the dedicated first-party tenant; browser/mobile clients do not receive privileged partner credentials.
- **B2B tenant developers:** tenant administrators and developers integrating eligible Lottorito modules into their own systems.
- **White-label operators:** scoped applications and branded experiences while Lottorito ownership, service provenance and audit remain traceable.
- **Affiliate/Agent partners:** narrow integration credentials and domain-specific scopes; no implied access to Lottery or future gaming APIs.
- **Lottery and future domain partners:** separate product and legal eligibility, provider-specific adapters behind canonical Lottorito contracts.
- **Internal product teams:** workload identities and service-to-service contracts; no reuse of human or external partner credentials.
- **Platform operations/security/finance:** governed control-plane workspaces, not customer API credentials.

Non-goals: replacing the canonical domain APIs; exposing database schemas or provider-native payloads as public contracts; granting cross-tenant access; offering unrestricted generic RPC; allowing customers to mint their own privileges; or declaring future regulated products available.

## 3. Logical platform architecture and planes

Separate the platform into two cooperating planes.

**Control plane**
- Developer organization, tenant and application registration.
- Product entitlements, environment setup and integration approval.
- OAuth client registration, credential lifecycle and scopes.
- Webhook endpoint/subscription configuration and signing-key lifecycle.
- API catalog, contract/specification publication and version lifecycle.
- Sandbox fixtures, test identities and reset controls.
- Usage metering, quota policy, audit, support and integration health.

**Data plane**
- API edge/gateway and request authentication.
- Tenant/product context resolution and policy enforcement.
- Domain API routing and service-to-service authorization.
- Event publication, webhook delivery and asynchronous job status.
- Rate limiting, payload validation, correlation and telemetry.

The control plane configures and observes the data plane but does not become a source of domain truth. Gateway policy is defense-in-depth; each domain service must enforce authorization and business invariants independently. A gateway route or catalog entry does not prove a backend capability is implemented.

Logical request path:

`Client → API Edge → Authentication → Tenant/Product Policy → Domain API → Domain-owned state`

For asynchronous events:

`Domain transaction → transactional outbox → canonical event → subscription dispatcher → signed delivery → consumer inbox`

The transactional outbox/inbox and event contract are governed by LOT-EVENT-001; delivery attempts are not economic effects.

## 4. Tenant, organization, application and environment model

The proposed control-plane hierarchy is:

- Platform account and platform operators.
- Tenant and its legal/operating context.
- Developer organization or integration team associated with that tenant.
- Application representing a distinct integration purpose and owner.
- Environment: sandbox, staging where approved, and production.
- OAuth client / machine identity attached to one application and environment.
- Product entitlements and explicit scopes.
- Webhook endpoint and event subscriptions.

A tenant may own multiple applications; an application may have separate environment clients. Credentials must never be shared across tenants, products, applications or environments. Sandbox credentials cannot call production; production credentials cannot call sandbox. White-label brand is presentation metadata, not a security principal or tenant substitute.

The first-party B2C application is registered as an application under its dedicated first-party tenant and follows the same contract, approval and audit rules as an external integration. It does not receive global platform credentials or an authorization bypass.

The principal's current membership and the application's approved tenant binding determine context. Client-supplied tenant/product IDs are selectors only when explicitly supported and must be checked server-side. Missing, ambiguous, stale or conflicting context is rejected.

## 5. API catalog, product packaging and entitlement

The catalog is organized by product domain and capability, not by internal microservice or database table. Each entry must identify:
- Stable API/capability ID and owning domain.
- Business purpose and allowed audience.
- Availability state: planned, preview, active, deprecated, sunset or unavailable.
- Required tenant/product entitlement and jurisdiction/operating eligibility.
- Required OAuth scopes and object-level authorization conditions.
- Environment availability and data classification.
- API version, schema links, examples and changelog.
- Rate/usage class and async/sync behavior.
- Webhook event types and retention/replay semantics.
- Support owner, escalation path and known limitations.

Product packages may bundle capabilities, but entitlement must be explicit and independently revocable. Commercial packaging cannot override legal eligibility, customer eligibility, security policy, domain state or provider availability. A tenant entitled to Affiliate does not automatically receive Lottery, Wallet, Payment, Payout, Chat or future gaming APIs. Each capability has its own gates and dependencies.

The public catalog must not advertise planned or legally unavailable regulated capabilities as active. Preview access is invitation- and scope-limited, time-bounded and explicitly non-production unless separately approved.

## 6. Identity, OAuth and credential lifecycle

Authentication and authorization follow LOT-API-001 and LOT-IAM-TENANT-001. The following is a candidate integration model, not an approved OAuth profile:
- Server-to-server integrations use a narrowly scoped machine identity and short-lived access tokens.
- OAuth 2.0 Client Credentials with asymmetric client authentication (for example, private-key JWT or mutual TLS) may be evaluated for confidential clients.
- Authorization Code with PKCE may be evaluated for delegated user-facing integrations where user consent and identity delegation are required.
- Browser/mobile apps must not embed client secrets or long-lived platform API keys.
- API keys, if used for limited identification or legacy compatibility, are not a substitute for scoped, revocable authorization.

Credential records bind to tenant, application, environment, client identity, allowed audience, scopes, creation actor, owner, expiry and status. Lifecycle includes issuance, secure one-time display or delivery, rotation, overlap, revocation, emergency disablement, expiry and audit. Secrets are stored only as protected verifier/material appropriate to the chosen mechanism; raw secret values are never retrievable after issuance.

Use least privilege, short token lifetime, audience restriction, scope restriction and server-side membership/entitlement checks. Scope names do not replace object ownership or business-policy checks. Privileged financial, identity, payout, beneficiary, tenant administration and key-management operations require stronger authentication/approval and immutable audit.

## 7. Webhook subscriptions, delivery and replay

Webhook subscription is a control-plane resource. A tenant administrator registers an HTTPS endpoint, verifies endpoint control using a challenge, chooses only entitled event types and environment, and configures delivery policy within platform limits.

Each subscription binds to tenant, application, environment, endpoint, event allowlist, signing-key version, status, creation actor and delivery policy. Do not allow arbitrary cross-tenant event filters or wildcard access to sensitive event families.

Delivery semantics:
- At-least-once delivery; consumers deduplicate by stable event identity.
- Delivery ID identifies an attempt; event ID identifies the canonical event; neither alone authorizes an economic posting.
- Sign the documented canonical bytes and include key ID, timestamp, event ID and delivery ID.
- Consumers verify signature and timestamp before processing, persist to an inbox, then acknowledge durable receipt.
- Retry with bounded exponential backoff and jitter; classify retryable and permanent responses.
- Expose delivery history, attempt count, next retry, last response class and dead-letter state without exposing secrets or another tenant's events.
- Manual replay is an audited, scoped action and must not mint a new economic event.
- Support pause, endpoint disablement, secret rotation with overlap and emergency revocation.

A successful HTTP response means accepted delivery, not successful business processing or settlement. The sender cannot promise exactly-once network delivery. The consumer must handle duplicate, delayed, reordered and conflicting events according to the domain contract.

## 8. SDKs, code generation and integration samples

SDKs are thin, typed clients generated from reviewed OpenAPI and event schemas. They must not contain privileged business logic, embedded secrets, hidden policy overrides or direct database/provider access.

Candidate initial language set should be selected from verified partner demand and team capability. A proposed shortlist for evaluation is TypeScript/JavaScript, Python, Java and PHP; this is not a launch commitment. Additional languages (including Go, .NET, Swift and Kotlin) require demand and maintenance ownership.

Each SDK release should publish:
- API major compatibility and SDK semantic version.
- Supported runtime/language versions and dependency policy.
- Typed request/response models and pagination helpers.
- Safe retry behavior that respects idempotency and Retry-After.
- Correlation/request ID access and structured error types.
- Webhook signature verification helpers with secure defaults.
- Examples for authentication, tenant context, async operations and event consumption.
- Changelog, migration guide, deprecation notice and security reporting channel.

Generated code must be reproducible, reviewed and traceable to the exact canonical contract commit. Never silently regenerate and publish a breaking SDK. Sample apps use synthetic data and safe local configuration; no real credentials or production customer records.

## 9. Developer Portal, documentation and onboarding

The Developer Portal is the external developer-facing surface of the control plane, not the Platform Admin dashboard.

Proposed capabilities:
- Organization and application registration with verified ownership.
- Tenant association and entitlement visibility (without revealing internal controls).
- API catalog, interactive reference and downloadable OpenAPI/event schemas.
- Quickstarts, architecture guides, authentication walkthroughs and working examples.
- Environment/client management and credential rotation/revocation.
- Webhook endpoint registration, verification, subscriptions and delivery logs.
- Sandbox test data, fixtures, scenario runner and reset controls.
- API usage, quota, latency/error summaries and incident notices.
- Version changelog, deprecation/sunset calendar and migration guidance.
- Support tickets, integration diagnostics and status page.

Onboarding stages:
1. Discover capability and verify product/jurisdiction availability.
2. Register organization and application; verify ownership and authorized administrator.
3. Request the minimum product entitlement and scopes.
4. Complete required legal, privacy, security and commercial reviews.
5. Provision isolated sandbox credentials and synthetic fixtures.
6. Execute contract, security, webhook and domain acceptance tests.
7. Request production enablement; complete maker-checker approval where risk requires.
8. Issue production credentials, monitor initial traffic and retain rollback/revocation path.

Self-service must not automatically approve regulated, financial, identity, payout, sensitive data or provider capabilities. Approval status and outstanding requirements must be explicit.

## 10. Sandbox, test fixtures and environment isolation

Sandbox is a deterministic integration environment, not a mirror containing production customer data. It must use synthetic principals, tenants, wallets, payment instruments, provider responses and event fixtures. Test balances/credits are non-cash and non-transferable to production.

Sandbox behavior should support:
- Success, validation failure, denial, duplicate, timeout, unknown outcome, delayed callback, out-of-order event and provider-unavailable scenarios.
- Idempotency replay and same-key/different-payload conflict.
- Webhook signature verification, retry, replay and key rotation.
- Tenant/object isolation and entitlement denial.
- Payment authorization, failure, refund and settlement simulations without real funds.
- Payout eligibility, hold, approval, unknown provider outcome and return simulations without real disbursement.
- Chat session expiry, reconnect, duplicate message and attachment quarantine test cases.
- Deterministic reset with fixture version and documented side effects.

Sandbox and production use separate credentials, encryption keys, data stores/partitions, queues, webhook endpoints, rate limits and provider configurations. No sandbox fixture may create real ledger value, trigger real payment or payout, or contact real customers. A staging environment is separately governed and must not become an informal production substitute.

## 11. Metering, quotas, pricing and commercial controls

Metering must be transparent, auditable and separated from security enforcement. Candidate dimensions include request count, weighted operation units, webhook deliveries, concurrent connections, message volume, storage/egress and asynchronous job consumption. The authoritative usage event, aggregation window, timezone, correction process and dispute path must be defined before billing.

Quota enforcement:
- Apply limits by tenant, application, credential, route, product and operation cost.
- Return documented rate-limit headers and Retry-After where applicable.
- Use fair-use budgets and burst controls; protect shared platform capacity.
- Separate hard safety limits from commercial soft limits.
- Provide warnings and usage views before predictable exhaustion.
- Never silently drop financial or security-critical events due to quota; use durable queueing, explicit rejection or controlled backpressure with alerts.
- Quota exhaustion must not reveal another tenant's usage.

Pricing, billing unit, free tier, overage, grace periods, support tier and tax treatment remain open commercial decisions. Billing metering cannot be inferred from request logs alone and must not modify domain balances or ledger entries. No price or SLA is approved by this document.

## 12. Reliability, observability and support operations

For each API capability, define owner, criticality, dependency map, timeout, retry policy, concurrency budget, idempotency behavior, degradation mode, status reporting and recovery evidence.

Required telemetry:
- Request/correlation/trace ID, tenant and application pseudonymous identifiers, API version, route template, outcome, latency and quota decision.
- No access tokens, client secrets, full payment details, raw identity documents, chat transcripts or sensitive request bodies in routine telemetry.
- Per-tenant and per-application dashboards with strict authorization and safe aggregation.
- Webhook delivery state, retry queue depth, dead-letter counts and endpoint health.
- SDK/API version adoption and deprecation exposure.
- Audit trails for credential, entitlement, subscription, quota and production enablement changes.

Support model must define severity, response ownership, support access controls, evidence collection, provider escalation and incident communication. Support staff receive time-bound, purpose-bound, least-privilege access; emergency access is logged and reviewed. API status page must distinguish platform edge, domain service and external provider incidents.

Numeric SLOs, RTO/RPO, quotas, support hours and response targets remain TBD until workload evidence and accountable owner approval.

## 13. API and SDK lifecycle governance

The canonical contract is the reviewed source of truth. Proposed release pipeline:
1. Domain owner authors contract change with stable resource/event semantics.
2. Security, tenant, privacy and finance reviewers assess impact.
3. OpenAPI and event schemas validate; examples are executable or schema-checked.
4. Automated compatibility analysis identifies breaking and risky changes.
5. Consumer/provider contract tests and sandbox scenarios pass.
6. SDKs and documentation are generated from the pinned contract revision.
7. Release notes, migration guide and deprecation window are published.
8. Production rollout is observable, reversible and approved for the relevant capability.

Breaking changes require a new major API version, migration plan and parallel support window. Additive changes must still respect strict-client compatibility and security semantics. Never change units, enum meaning, defaulting, authorization, event ordering assumptions or financial semantics silently.

Deprecation policy must define announcement, replacement, minimum support window, sunset date, usage reporting, exception process and final disablement approval. Emergency security disablement may be faster but requires incident governance and customer communication. API version, SDK version, webhook schema version and provider adapter version are separate axes.

## 14. Security, privacy and compliance controls

- Threat-model control-plane and data-plane separately, including confused deputy, credential theft, tenant substitution, privilege escalation, webhook SSRF, endpoint abuse and supply-chain compromise.
- Validate webhook endpoints against SSRF, DNS rebinding, private/link-local/metadata addresses and unsafe redirects; revalidate resolution at connection time and enforce egress controls.
- Protect credentials with KMS/HSM-backed key management where approved; document custody, rotation, access and recovery. Do not claim certification by architecture alone.
- Enforce tenant/application/environment binding on every credential and resource lookup.
- Use CSRF protection for browser control-plane actions; secure cookies, CSP and step-up authentication for sensitive changes.
- Apply data minimization, retention, deletion/export, residency and processor-contract requirements by jurisdiction.
- Keep secrets and personal/sensitive data out of logs, traces, examples, SDK fixtures and public issue reports.
- Maintain dependency inventory, SBOM, signed release artifacts and vulnerability disclosure/response process for SDKs and portal assets.
- Regulated product/payment/payout capabilities require separate legal-entity, jurisdiction, licence, provider, financial and responsible-use gates.

## 15. Acceptance scenarios and release gates

| ID | Scenario | Expected result |
|---|---|---|
| API-PLAT-01 | First-party B2C registers an application | Dedicated tenant binding; same controls as external apps; no platform master credential |
| API-PLAT-02 | Credential is used in another tenant/environment | Denied; no cross-scope data leakage |
| API-PLAT-03 | App requests an unentitled product API | Denied by edge and domain service |
| API-PLAT-04 | Browser bundle contains partner secret | Build/security scan blocks release |
| API-PLAT-05 | OAuth token has wrong audience or expired membership | Request denied after server-side context validation |
| API-PLAT-06 | Credential rotation occurs | Overlap, expiry and revocation are auditable; old credential stops working |
| API-PLAT-07 | Webhook endpoint targets metadata/private network | Registration or delivery blocked by SSRF controls |
| API-PLAT-08 | Webhook delivery is duplicated/reordered | Consumer inbox deduplicates; domain semantics remain correct |
| API-PLAT-09 | Manual webhook replay is requested | Authorized, audited replay; no new economic effect |
| API-PLAT-10 | Webhook key rotates during retries | Both valid overlap keys work only within approved window |
| API-PLAT-11 | SDK retries a timed-out financial action | Same idempotency key; one economic effect |
| API-PLAT-12 | OpenAPI introduces a breaking change | CI blocks release or requires new major and migration plan |
| API-PLAT-13 | Sandbox payment/payout fixtures execute | Synthetic only; no real funds, customer or provider side effect |
| API-PLAT-14 | Sandbox credential calls production | Denied; separate trust and storage boundaries |
| API-PLAT-15 | Tenant exceeds quota | Correct tenant-scoped response/backpressure; no cross-tenant signal |
| API-PLAT-16 | Financial/security event volume exceeds normal quota | Durable controlled processing or explicit alert/rejection; never silent loss |
| API-PLAT-17 | Developer downloads generated SDK | Traceable to reviewed contract revision and compatible API major |
| API-PLAT-18 | Support investigates an integration | Purpose-bound temporary access; sensitive payloads masked and audited |
| API-PLAT-19 | API is deprecated | Consumers receive notice, usage visibility, replacement and sunset path |
| API-PLAT-20 | Regulated product is not legally enabled | Catalog and runtime deny production entitlement despite technical route existence |

Pilot release gates:
- Approve API audience, ownership, tenant/application model and initial resource inventory.
- Approve authentication profile, key management, scopes and revocation objectives.
- Complete SSRF/webhook threat review and tenant-isolation tests.
- Validate canonical OpenAPI/event schema and compatibility workflow.
- Demonstrate sandbox isolation, deterministic fixtures and no-real-funds guarantee.
- Assign domain owners, support escalation, incident and rollback procedures.
- Complete privacy, legal, commercial and data-residency review for exact markets/entities.

General availability additionally requires load/recovery evidence, independent security review appropriate to risk, SDK supply-chain controls, support model, usage metering accuracy, customer documentation and approved production enablement.

## 16. Open decisions and related documents

Open decisions:
- API edge/gateway and control-plane hosting topology.
- OAuth/OIDC profile, asymmetric client authentication and token format/lifetime.
- Initial API audience and capability inventory; public versus partner/private boundary.
- Developer organization verification and production approval workflow.
- SDK language order and long-term maintenance ownership.
- Sandbox topology, fixture reset policy and provider simulation scope.
- Webhook retry/retention windows, replay permissions and SSRF egress architecture.
- Metering dimensions, pricing, free tier, overage and support tiers.
- API/SDK deprecation windows, SLO, RTO/RPO and data residency.
- Initial Affiliate pilot API set and the separately gated B2C/Wallet/Payment/Chat exposure.

Related: LOT-API-001, LOT-EVENT-001, LOT-IAM-TENANT-001, LOT-PROVIDER-EVAL-001, LOT-WALLET-001, LOT-PAYMENT-001, LOT-PAYOUT-001, LOT-B2C-PRD-001, LOT-CHAT-WIDGET-001, LOT-QA-001, LOT-SEC-TM-001 and LOT-TECH-ADR-001.

This document is Proposed. It does not publish APIs, issue credentials, approve providers, select prices, authorize production access or implement a Developer Portal, SDK, sandbox or API gateway.
