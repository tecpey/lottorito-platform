# Affiliate & Agent API Capability Contract

**Document ID:** LOT-AFFILIATE-API-001 | **Version:** 0.1.0 | **Status:** Proposed domain API contract; owner, product, finance, legal, security and partner review required

## 1. Purpose and authority

This document defines the first product-domain API capability inventory for Lottorito's Affiliate & Agent infrastructure. It translates the shared API rules (LOT-API-001 and LOT-API-PLATFORM-001) into a provider-neutral, tenant-isolated contract for program administration, affiliate/agent operations, referral attribution, partner event intake, commission transparency and reporting.

Affiliate & Agent is the first delivery priority in the owner-directed sequence. This document does not select or verify a partner, define commercial commission rates, approve a legal entity or market, authorize custody/payment, or prove that any endpoint or integration exists. LOT-INT-001 remains a thin draft; actual partner API documents, sandbox, credentials, event semantics and field mappings must be obtained and verified before adapter implementation.

This is an API capability boundary, not a database schema. Domain services own their state and invariants. API Gateway, SDK, partner adapter and dashboard must not independently calculate or mutate canonical financial truth.

## 2. Product boundary and API audiences

The Affiliate domain supports independently adoptable B2B programs and Agent/Affiliate networks. Audiences:
- Tenant owners and authorized program administrators.
- Tenant operations and compliance roles.
- Affiliate/Agent members within their authorized organization and hierarchy scope.
- Approved external operator/partner systems sending source events or requesting permitted reports.
- First-party Lottorito B2C only where a separate customer-facing referral/loyalty entitlement is defined.

Affiliate APIs do not automatically grant Lottery, Sportsbook, Casino, Live Casino, E-Gaming, Wallet custody, payment execution, payout approval or cross-tenant access. Affiliate commission is not customer wallet cash. Customer, Agent, Tenant, legal entity and partner are separate identities/ownership scopes.

Distinct API audiences:
1. Tenant-facing management APIs: program configuration, membership and authorized reporting.
2. Affiliate/Agent self-service APIs: own profile, links, scoped network and statements.
3. Partner ingestion APIs: authenticated server-to-server source events.
4. Internal domain APIs: workload-identity-only operations between bounded contexts.
5. Platform control-plane APIs: application, entitlement, credential and webhook administration under LOT-API-PLATFORM-001.

## 3. Domain ownership and source-of-truth boundaries

| Capability | Authoritative owner | Affiliate API responsibility |
|---|---|---|
| Tenant, principal, membership, role | Identity/Tenant domain | Resolve and enforce authorized context; do not duplicate identity truth |
| Program and commercial terms | Affiliate domain / approved contract | Versioned configuration and read model |
| Affiliate/Agent profile and hierarchy | Affiliate domain | Scoped profile and relationship operations |
| Click/referral tracking | Attribution domain | Issue links/tokens and expose attributable outcomes |
| Partner activity | Partner adapter + canonical event intake | Authenticate, validate, normalize, deduplicate and trace source facts |
| Commission calculation | Commission domain | Request/observe calculation and expose explanations; never recalculate in client |
| Wallet balance and ledger | Finance/Wallet domain | Authorized read views only through wallet contract |
| Payment and settlement | Payment/finance domains | Reference verified payment facts; do not infer from redirect or partner claims |
| Payout and beneficiary | Payout domain | Reference approved status through payout contract; no direct disbursement |
| Chat and notifications | Communications domains | Link to support/preferences; no domain-state mutation |

A partner event is a source assertion, not automatically a verified financial fact. Registration, deposit, withdrawal, qualified activity or NGR adjustment must be validated against partner contract, tenant mapping, provenance, idempotency identity, currency and applicable commercial rule before downstream use.

## 4. Resource inventory and proposed API surface

Paths below are illustrative candidates under shared /v1 conventions, not published endpoints or a final URL inventory. Exact schemas, fields, filters, scopes and lifecycle transitions require domain-owner review.

| Resource family | Candidate operations | Audience | Boundary |
|---|---|---|---|
| Programs | GET/POST /v1/affiliate/programs; GET/PATCH /v1/affiliate/programs/{program_id} | Tenant admin | Create/update requires admin scope, effective date and audit |
| Program versions | GET/POST /v1/affiliate/programs/{program_id}/versions | Tenant admin / finance | Published versions immutable; changes create a new effective-dated version |
| Memberships | GET/POST /v1/affiliate/memberships; GET/PATCH /v1/affiliate/memberships/{membership_id} | Tenant admin / Agent | Tenant-scoped invitation, status and role; no client-selected privilege |
| Affiliate profile | GET/PATCH /v1/affiliate/me; GET /v1/affiliate/affiliates/{affiliate_id} | Affiliate / Agent / admin | Self-service own record; admin view requires scoped authorization |
| Agent hierarchy | GET /v1/affiliate/network; GET /v1/affiliate/network/{node_id}/children | Agent / admin | Authorized descendants/fields only; bounded depth and page |
| Campaigns | GET/POST /v1/affiliate/campaigns; GET/PATCH /v1/affiliate/campaigns/{campaign_id} | Tenant admin / Agent | Approval, status, dates and eligible channels governed |
| Referral links | GET/POST /v1/affiliate/referral-links; GET /v1/affiliate/referral-links/{link_id} | Affiliate / Agent | Opaque identifier; revocation and expiry supported |
| Attribution | GET /v1/affiliate/attributions; GET /v1/affiliate/attributions/{attribution_id} | Affiliate / admin | Explain status/source; no other affiliate PII |
| Partner event intake | POST /v1/partner-events/affiliate or dedicated partner ingress | Approved partner system | Separate machine identity, schema, signature, idempotency and adapter |
| Activity records | GET /v1/affiliate/activity; GET /v1/affiliate/activity/{activity_id} | Affiliate / admin | Normalized facts with provenance and pending/verified/rejected state |
| Commission summaries | GET /v1/affiliate/commissions/summary; GET /v1/affiliate/commissions/{commission_id} | Affiliate / admin | Calculation output and explanation; not a mutable balance |
| Commission statements | GET /v1/affiliate/statements; GET /v1/affiliate/statements/{statement_id} | Affiliate / finance | Period, currency, rule version, status and adjustments |
| Calculation runs | POST /v1/affiliate/calculation-runs; GET /v1/affiliate/calculation-runs/{run_id} | Authorized finance/ops | Async, idempotent, approval-controlled; no client-side formulas |
| Adjustments | GET/POST /v1/affiliate/adjustments | Finance / compliance | Proposed adjustment only; maker-checker and ledger gates |
| Reporting | GET /v1/affiliate/reports/... | Tenant admin / Agent | Predefined scoped reports; async, bounded, audited exports |

Use /me only for the authenticated principal's own membership-scoped representation. A user-supplied affiliate ID is never a substitute for authorization. Avoid deeply nested paths and unrestricted graph endpoints.

## 5. Program, membership and hierarchy semantics

A program is scoped to tenant, product purpose, partner agreement, effective period, currency and immutable version. Draft, review, approved, active, suspended and retired states are distinct. A published version cannot be edited in place; correction creates a new version and preserves prior calculation references.

Membership and affiliate profile are distinct. One principal may have multiple memberships, but each membership has one tenant, organization, program eligibility and role scope. Invitation acceptance, activation, suspension, termination and reinstatement require explicit transitions and audit.

Hierarchy is a relationship graph, not a permission shortcut. An Agent sees only nodes and fields allowed by program visibility policy. The initially discussed L1–L10 depth is not approved; maximum depth, cycles, parent changes, effective dating, historical attribution and commission allocation remain open. Prevent cycles and unauthorized re-parenting. Historical periods retain the hierarchy/attribution snapshot used at calculation time.

## 6. Referral links, tracking and attribution

Referral link creation binds to tenant, program, affiliate membership, campaign, allowed destination and expiry/revocation policy. Link IDs are opaque and resistant to enumeration. Do not encode PII, commission rates, tenant secrets or trusted identity in URLs.

Tracking events may include impression, click, landing, registration and qualified conversion, subject to consent, privacy, fraud and jurisdictional rules. A click is not a registration; registration is not a deposit; a deposit is not qualifying activity; qualifying activity is not automatically payable commission.

Attribution policy must define eligible touchpoints, windows, priority, first/last/multi-touch model, direct traffic, self-referral, cross-device identity, referrer change, duplicate conversion, fraud, consent withdrawal and dispute handling. No attribution model is selected here.

Store attribution decision, rule version, source evidence, timestamps, status, override actor/reason and related conversion identity. Manual override requires permission and immutable audit. Client-reported conversions cannot directly create payable commission.

## 7. Partner event ingestion and adapter contract

Partner integrations use dedicated adapters and credentials under LOT-INT-001, LOT-API-001 and LOT-API-PLATFORM-001. The adapter translates provider-specific payloads into canonical facts; it does not decide commercial eligibility or write ledger entries.

Ingestion pipeline:
1. Authenticate partner and verify signature/mTLS or approved mechanism.
2. Enforce tenant, partner, product and environment binding.
3. Validate schema version, payload size, timestamp, currency and required identifiers.
4. Preserve encrypted/raw evidence under retention policy and store provenance/hash.
5. Normalize external IDs, event type, amount, currency, timezone and status without discarding original values.
6. Deduplicate using stable source-event and economic-effect identities; delivery ID is not effect identity.
7. Quarantine unknown, malformed, conflicting, late or unsupported events.
8. Emit canonical event through durable inbox/outbox only after acceptance.
9. Reconcile against independent partner reports/statements; record exceptions.

Candidate event types: registration, deposit, withdrawal, qualified activity, NGR adjustment, reversal, account restriction and status change. These are candidates only: existence, semantics, required fields, reversibility and ordering must be verified from the actual partner contract. Never infer NGR components or qualifying activity from a generic amount field.

## 8. Commission calculation and financial API boundary

The Commission domain owns rule versioning, calculation and explanation. Inputs include verified qualifying facts, program/partner agreement, effective hierarchy and attribution snapshot, currency, exclusions, adjustments and policy version. The API exposes calculation state and reproducible explanation, not a client-side recalculation.

CPA, Revenue Share and Hybrid remain conceptual models. No universal NGR formula, 20–40% rate, network share, L1–L10 depth, minimum, cap, negative carryover, monthly progression or agent credit is approved. Each commercial rule requires an approved agreement, effective date, version and finance/legal acceptance.

Calculation states should distinguish requested, queued, processing, completed, completed_with_exceptions, failed, reviewed and approved. Completion does not mean payable, posted, settled or withdrawable.

Statements distinguish estimated, pending, approved, payable, reserved, paid/settled, reversed and disputed amounts where supported. Do not collapse them into one total without explicit unit/status semantics.

Wallet, ledger, payment and payout mutations remain in their own domains. Affiliate APIs may return authorized references/read models but must not:
- set or edit an Agent wallet balance;
- create ledger journals directly;
- mark a deposit paid from a browser redirect;
- mark a commission paid based only on a partner callback;
- change a beneficiary or approve a payout;
- transfer value between customer, Agent, promotion, prize or treasury accounts.

Any future payout request must use LOT-PAYOUT-001 eligibility, reservation, approval, provider execution and reconciliation workflows.

## 9. Authorization scopes and data visibility

Candidate scope families (final names require review):
- affiliate.programs.read / affiliate.programs.manage
- affiliate.memberships.read / affiliate.memberships.manage
- affiliate.profile.read / affiliate.profile.write
- affiliate.network.read
- affiliate.campaigns.read / affiliate.campaigns.manage
- affiliate.links.read / affiliate.links.manage
- affiliate.attributions.read; affiliate.activity.read
- affiliate.commissions.read
- affiliate.calculations.request / affiliate.calculations.review
- affiliate.adjustments.propose / affiliate.adjustments.approve
- affiliate.reports.read / affiliate.reports.export
- partner.affiliate-events.write

Scopes are necessary but not sufficient. Every request also checks tenant, application, current membership, role, hierarchy visibility, object ownership, product entitlement, jurisdiction and resource state. Separate read, propose, approve and execute privileges. No actor may approve their own privileged financial adjustment where maker-checker is required.

PII minimization applies to lists, search, exports and webhook payloads. Affiliate self-service never returns other members' identity documents, contact details, private notes, risk flags or full customer-level activity unless a separately approved business/legal purpose exists.

## 10. Pagination, filtering, exports and reporting

Use cursor pagination, deterministic ordering and bounded page sizes. Scope authorization before filtering/pagination. Filters are allowlisted and bounded by time range, status and resource count. Do not expose unrestricted hierarchy traversal or arbitrary query expressions.

Exports are asynchronous jobs with requested scope, purpose, requester, expiry, format, row/size limit and audit. Download URLs are short-lived and object-scoped. Exports minimize PII and exclude credentials, provider secrets and internal risk annotations by default.

Reports define timezone, period inclusivity, currency, unit, included statuses, attribution/rule version and freshness. Summary totals must reconcile to detail rows under documented rounding/filter rules. A report is a read model, not a financial posting or proof of external settlement.

## 11. Idempotency, concurrency and error handling

Partner ingestion and mutating operations use scoped Idempotency-Key, normalized payload hash, durable inbox and economic-effect identity. Same key/same payload returns the prior result/current processing state; same key/different payload is conflict. Concurrent duplicates converge to one accepted effect. Late/out-of-order events follow explicit domain rules.

Use ETag/version for concurrent program, campaign, membership and link changes. Stale writes return precondition failure. Async operations return a status resource and correlation ID. Errors follow LOT-API-001 and never reveal cross-tenant existence, partner secrets or internal mapping details.

## 12. Privacy, security, fraud and audit

- Server-side tenant and object authorization on every request and background job.
- Separate partner credentials by partner legal entity, tenant, product, application and environment.
- Validate webhook signature, timestamp, replay, schema and provenance.
- Rate-limit and detect credential abuse, click fraud, self-referral, bot traffic and anomalous conversion patterns.
- Treat IP/device signals as risk evidence, not definitive identity or sole attribution.
- Apply privacy/consent and cookie/tracking rules by jurisdiction; support retention/deletion exceptions and legal holds.
- Encrypt sensitive data, restrict support access and mask PII in logs/exports.
- Immutable audit for program/rule publication, hierarchy changes, manual attribution override, adjustment, approval, credential change and export.
- Partner-provided role, tenant, affiliate, commission rate or payable status never overrides platform authorization or approved contract.

## 13. Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| AFF-API-01 | Agent reads own profile | Only current membership-scoped fields returned |
| AFF-API-02 | Agent substitutes another affiliate ID | Denied or safely undisclosed |
| AFF-API-03 | Tenant admin manages a program | Correct tenant, scope and audit required |
| AFF-API-04 | Published commission rule is edited | Rejected; new version required |
| AFF-API-05 | Hierarchy parent is changed | Cycle/permission checks; historical snapshots preserved |
| AFF-API-06 | Referral link is created | Bound to tenant/program/campaign/membership and revocable |
| AFF-API-07 | Click is reported as conversion | No qualifying commission without verified conversion facts |
| AFF-API-08 | Partner sends duplicate event with new delivery ID | One canonical economic effect |
| AFF-API-09 | Partner event has unknown currency or malformed amount | Quarantined/rejected; never coerced to zero |
| AFF-API-10 | Partner event conflicts with prior source identity | Conflict retained for reconciliation; no silent overwrite |
| AFF-API-11 | Browser redirect claims deposit success | No financial credit or commission posting |
| AFF-API-12 | Commission calculation completes | Does not imply payable, paid or withdrawable |
| AFF-API-13 | Affiliate requests another Agent's statement | Denied by hierarchy/object policy |
| AFF-API-14 | Finance proposes adjustment | Separate approval and immutable evidence required |
| AFF-API-15 | Actor attempts self-approval | Denied where maker-checker applies |
| AFF-API-16 | Report is exported | Scoped, async, audited, minimized and expires |
| AFF-API-17 | Tenant quota is exhausted during event intake | Durable controlled handling or explicit rejection; no silent event loss |
| AFF-API-18 | Partner API contract changes | Adapter/schema compatibility tests block unsafe rollout |

## 14. Open decisions, dependencies and release gates

Open decisions:
- Initial Affiliate program and exact first-pilot partner/legal entity.
- Actual partner API, event catalogue, field semantics, signature/authentication and sandbox evidence.
- Program ownership and administrator roles.
- Attribution model, consent basis, fraud policy and dispute windows.
- Hierarchy depth, re-parenting, historical snapshot and visibility policy.
- Commercial commission model, NGR definition, rates, caps, negative carryover, currency and rounding.
- Agent wallet class, funding, accounting treatment and promotional credit policy.
- Payout eligibility, beneficiary, legal entity, jurisdiction and payment rail.
- Retention, residency, PII fields and reporting permissions.
- API scopes, resource schemas, limits, SDK language and support/SLA.

Dependencies: LOT-API-001; LOT-API-PLATFORM-001; LOT-EVENT-001; LOT-IAM-TENANT-001; LOT-INT-001; LOT-COM-001; LOT-WALLET-001; LOT-FIN-POST-001; LOT-PAYMENT-001; LOT-PAYOUT-001; LOT-PROVIDER-EVAL-001; LOT-QA-001; LOT-SEC-TM-001.

Pilot release gates:
1. Obtain actual partner contract, legal entity, jurisdiction, API docs and authorized sandbox.
2. Map every external event/field to canonical schema with provenance and unknown-field policy.
3. Approve attribution and commission rule versions; unresolved commercial formulas remain disabled.
4. Prove tenant/affiliate isolation, duplicate/concurrent ingestion and reconciliation using synthetic data.
5. Demonstrate statement reproducibility and separation of calculation, ledger posting, payment and payout.
6. Complete security, privacy, fraud, legal, finance and operations review.
7. Approve a narrow resource/event allowlist and production credential issuance independently.

This document is Proposed. It does not select a partner, approve commission rates, publish endpoints, implement an adapter, create wallets, process real payments or authorize payouts.
