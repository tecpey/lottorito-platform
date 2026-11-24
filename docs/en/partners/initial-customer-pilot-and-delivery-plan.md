# RaidenBet Initial Customer Pilot & Delivery Plan

**Document ID:** LOT-CUSTOMER-PILOT-001 | **Version:** 1.0.0 | **Status:** Owner-directed customer scope; delivery and integration plan proposed; no implementation or customer acceptance verified

## 1. Purpose and authority

This document records the owner-confirmed initial customer scope for Lottorito and defines a controlled path from product readiness to customer review, technical approval, sandbox integration and acceptance.

The named initial customer is **RaidenBet**. This is an owner-provided commercial/project fact for planning. It does not by itself establish a signed contract, legal-entity identity, jurisdiction, commercial terms, production authorization or verified technical compatibility.

This plan complements LOT-AFFILIATE-API-001, LOT-CHAT-WIDGET-001 and LOT-API-PLATFORM-001. It does not replace their domain contracts.

## 2. Initial customer scope — strict boundary

The initial RaidenBet delivery contains exactly two Lottorito modules:

1. **Advanced Affiliate & Agent** — an independently operable affiliate/agent capability with its own authorized management experience and versioned API.
2. **Live Chat Widget** — an independently configurable embeddable customer-support widget and its associated agent/operations experience.

RaidenBet receives access only to these contracted/approved modules and their explicitly entitled capabilities. The initial handoff does not include the whole Lottorito platform, Lottery, Casino, Live Casino, Sportsbook/Betting, poker, E-Gaming, a general-purpose customer wallet, payment/payout services or unrelated platform administration.

Future modules remain separate product horizons and are not implied by this pilot.

## 3. Product ownership and delivery model

Lottorito remains the platform owner and operator of the two delivered modules, their shared contracts, tenant isolation, service-side auditability and technical traceability. RaidenBet remains the owner/operator of its existing host script and customer-facing business workflows except for explicitly contracted Lottorito module responsibilities.

The delivery model is **module access plus controlled API/widget integration**, not transfer of the Lottorito platform or a fork of its source code.

- The customer-facing host script remains under RaidenBet's control.
- Lottorito exposes only approved, tenant-scoped capabilities.
- The customer does not receive unrelated modules or platform-wide privileges.
- Customer-specific mappings and presentation settings belong in an isolated RaidenBet adapter/configuration layer, never in the reusable Affiliate or Chat core.
- No direct customer database or source-code access is assumed or required by this plan.

## 4. Customer review and approval sequence

The intended sequence is mandatory:

1. Complete and internally verify the initial Affiliate and Chat module releases against their own acceptance gates.
2. Prepare the customer handoff package: product walkthrough, scope matrix, versioned API/OpenAPI contract, widget installation guide, security/authentication profile, sandbox credentials, synthetic fixtures, test cases, error/retry behavior, operational contacts and known limitations.
3. Present only the two in-scope modules to RaidenBet.
4. RaidenBet's authorized support and technical representatives review the product behavior, API contract, event mappings, widget installation, security model and operational responsibilities.
5. Record comments, requested changes, unresolved questions and approval status in a traceable review record. Silence or receipt is not approval.
6. Resolve blocking findings and publish a revised, versioned handoff package.
7. Obtain explicit technical approval of the relevant API/widget contract before connecting the customer's existing script.
8. Build or configure the narrow customer adapter only against the approved contract and actual customer documentation.
9. Complete sandbox contract, security, tenant-isolation, failure/retry and reconciliation tests with both parties.
10. Obtain customer acceptance and separate owner/legal/operations authorization before any controlled production activation.

No production credential or production endpoint is issued merely because a sandbox review passed.

## 5. Affiliate integration boundary

The Affiliate module is the system of record for its own affiliate programs, memberships, Agent hierarchy, campaigns, referral resources, attribution records, commission evaluations/statements and audit history, subject to approved ownership and financial contracts.

The existing RaidenBet script is an external host/partner system. It may provide authenticated business events through the approved API contract after mapping and approval. An inbound event is an assertion until authenticated, validated, normalized, deduplicated and reconciled.

Required integration properties:

- Tenant- and application-bound credentials with least-privilege scopes.
- Explicit resource and event allowlists; no generic unrestricted event ingestion.
- Versioned schemas and documented field meaning, timezone, currency, identifier and event-finality semantics.
- Stable external event identity, idempotency and replay protection.
- Authenticated webhook delivery where outbound events are required.
- Durable delivery attempts, bounded retries, dead-letter handling and controlled replay.
- Quarantine/rejection for unknown, malformed, late, contradictory or unauthorized events.
- Traceable mapping from source event to canonical event, attribution result and commission calculation.
- No direct API capability to mutate wallet balances, post ledger journals, approve payouts or transfer funds.

Commission rates, NGR definition, attribution windows, hierarchy depth, qualification rules, negative carryover, funding and payout terms remain open until supported by actual customer requirements and explicit commercial/finance approval.

## 6. Live Chat integration boundary

The Chat module is a separate entitlement and integration surface. The initial widget may be embedded in RaidenBet's existing website/script only after installation registration and technical approval.

Minimum integration controls:

- A tenant-bound application and named widget installation, with test and production environments separated.
- Exact allowed-origin registration; wildcard origins denied by default.
- Host-server-mediated session bootstrap; no long-lived integration secret in browser code.
- Short-lived, audience-, installation- and scope-bound widget sessions with tested revocation.
- Server-side authorization for every conversation, participant, message, attachment and agent operation.
- Strict postMessage source/origin/schema validation if cross-frame messaging is used.
- Durable message timeline with cursor-based reconnect/recovery; realtime transport is not the source of truth.
- Separation of customer-visible messages, internal notes, system events and AI suggestions.
- Attachment quarantine, type/size validation, malware scanning and short-lived download grants before attachments are enabled.
- Tenant-scoped transcript access, export, retention and deletion rules.
- Defined escalation, support ownership, business hours and incident contacts before production.

The customer host page must not be trusted to assert tenant, agent role, queue, authorization scope or another user's identity.

## 7. Customer handoff package

The handoff is versioned and contains, at minimum:

| Artifact | Required content |
|---|---|
| Product scope & walkthrough | Included modules, roles, screens, exclusions and known limitations |
| Affiliate API contract | OpenAPI document, auth/scopes, resources, event schemas, errors, idempotency and compatibility policy |
| Chat installation package | Bootstrap snippet/SDK instructions, installation ID, allowed origins, session flow and configuration reference |
| Security profile | Trust boundaries, credential handling, rotation/revocation, tenant isolation and incident contacts |
| Sandbox kit | Environment details, synthetic identities/events/conversations, deterministic fixtures and reset procedure |
| Test & acceptance pack | Positive, negative, duplicate, replay, concurrency, isolation, failure and recovery scenarios |
| Operations guide | Health signals, support escalation, delivery retries, audit, retention and change notification |
| Change record | Contract version, release notes, deprecation policy, known issues and customer approval record |

Secrets are delivered through an approved secret-sharing channel, never embedded in documentation, source control, email bodies or browser code.

## 8. API contract and compatibility governance

The customer-facing contract is versioned independently of internal implementation. Breaking changes require a new major contract version or an explicitly approved migration plan; additive changes must still be assessed for generated-client and strict-schema compatibility.

Every operation documents authentication, authorization, tenant derivation, request/response schema, error model, idempotency behavior, rate/size limits, audit effects and retry safety. OpenAPI is the machine-readable API description candidate; the exact version and generation toolchain remain subject to repository/API governance review.

Customer approval applies to a named contract version and environment. It does not approve unrelated APIs or future modules.

## 9. Security, privacy and financial release gates

Before sandbox credentials are issued, verify tenant/app binding, least privilege, secret handling, event authenticity, replay resistance, rate limits, logging redaction and test-data isolation.

Before production activation, require:
- Legal entity, jurisdiction, data-controller/processor roles and contractual processing terms to be reviewed.
- Data residency, retention, deletion, transcript access and incident-notification responsibilities to be agreed.
- Tenant isolation across API, database access, jobs, caches, files, logs, reports and support tooling to be tested.
- Affiliate event authenticity, deduplication, attribution reproducibility and commission reconciliation to pass.
- Chat session revocation, origin restrictions, message privacy, attachment controls and abuse limits to pass.
- Operational ownership, monitoring, backup/recovery, rollback and customer escalation to be documented.
- Finance/legal approval for any commission liability, wallet, payment or payout behavior. This pilot does not independently authorize money movement.

Reference security baselines: OWASP API Security Top 10 (2023), IETF RFC 9700 (OAuth 2.0 Security Best Current Practice) and OWASP Webhook Security Cheat Sheet. These are design/test references, not certification.

## 10. Acceptance and evidence model

Acceptance is recorded separately for each module and for the combined integration. A single successful happy-path demo is insufficient.

| ID | Acceptance scenario |
|---|---|
| CUST-01 | RaidenBet can access only the two approved module entitlements |
| CUST-02 | Affiliate and Chat are independently configurable and independently testable |
| CUST-03 | Customer technical team can review the exact versioned API/widget contract |
| CUST-04 | No customer connection is enabled before explicit contract approval |
| CUST-05 | Customer credentials cannot access another tenant or unapproved resource |
| CUST-06 | Duplicate and replayed Affiliate events create no duplicate economic effect |
| CUST-07 | Unknown or malformed Affiliate events are quarantined/rejected with traceable reasons |
| CUST-08 | Attribution and commission statements are reproducible from accepted source events and versioned rules |
| CUST-09 | Affiliate API cannot mutate wallet/ledger or approve payout operations |
| CUST-10 | Chat sessions are short-lived, installation-bound and revocable |
| CUST-11 | Unregistered origins and forged cross-frame messages are rejected |
| CUST-12 | Customer-visible messages and internal agent notes remain access-separated |
| CUST-13 | Reconnect/retry does not lose or duplicate durable chat messages |
| CUST-14 | Tenant-scoped transcript, retention, export and deletion controls are verified |
| CUST-15 | Both parties complete sandbox failure, security and operational scenarios |
| CUST-16 | Production activation has separate customer acceptance and owner/legal/operations authorization |

Evidence must identify the contract version, environment, test data set, test result, defect disposition, reviewer and timestamp. Synthetic fixtures are used until lawful, authorized test data is explicitly approved.

## 11. Change management and support

Any requested feature outside the two-module boundary is handled as a separately scoped change request. A change may not silently expand entitlements, data access, financial permissions or the customer's delivery scope.

Define severity, support hours, escalation path, maintenance windows, incident notification, API deprecation, widget release compatibility and customer communication before production. SLA, uptime target, pricing, support tier and service credits remain unapproved until separately agreed.

## 12. Explicit exclusions and unresolved inputs

This plan does not assert that RaidenBet's API, source code, database, sandbox, legal entity, jurisdiction, credentials or contract have been inspected or verified.

Required customer inputs before adapter implementation:
- Current API documentation and version, or an authorized technical walkthrough.
- Authentication/signature method, credential issuance and rotation process.
- Registration, deposit, withdrawal and qualified-activity event catalogue with field definitions and finality semantics.
- Stable customer/player/affiliate identifiers and mapping constraints.
- Webhook/API rate limits, retry policy, delivery guarantees and sandbox access.
- Existing script integration points and deployment/change-control process.
- Widget host domains, CSP/frame constraints, identity/session expectations and support workflow.
- Legal entity, jurisdiction, data-processing terms, retention and operational contacts.

No database access, source-code modification or direct production connection is assumed. Any need for those must be separately justified, scoped and approved.

## 13. Future product horizons

Lottery remains the next separately validated product horizon after the initial Affiliate and Chat customer delivery. Casino, Live Casino, Sportsbook/Betting and other E-Gaming remain later independent product domains with their own providers, lifecycle models, jurisdictional gates, financial semantics, security evidence and customer approvals.

They are not included in the RaidenBet initial handoff and must not be represented as available because they appear in the Lottorito roadmap.

## 14. Related contracts and references

- LOT-AFFILIATE-API-001 — Affiliate & Agent API capability contract.
- LOT-CHAT-WIDGET-001 — Embeddable Chat module architecture.
- LOT-API-PLATFORM-001 — API platform and developer experience.
- LOT-IAM-TENANT-001 — Tenant, identity and authorization model.
- LOT-PROVIDER-EVAL-001 — Provider evaluation and RFI standard.
- LOT-SEC-TM-001 — System threat model.
- OWASP API Security Top 10: https://owasp.org/API-Security/
- IETF RFC 9700: https://www.rfc-editor.org/rfc/rfc9700.html
- OWASP Webhook Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Webhook_Security_Cheat_Sheet.html

**Status reminder:** this is a customer-specific delivery and acceptance plan based on owner-provided scope. It is not proof of a signed contract, API compatibility, implementation, customer approval, legal authorization or production readiness.
