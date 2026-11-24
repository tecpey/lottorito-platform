# Unified Multi-Tenant B2B2C Platform Architecture

**Document ID:** LOT-PLATFORM-001 | **Version:** 0.1.0 | **Status:** Proposed architecture baseline for owner and specialist review; not an implementation or launch approval

## 1. Purpose, authority and scope

This document consolidates the target platform direction into one cross-product architecture. It defines how Lottorito can serve independent B2B operators, white-label businesses, affiliates/agents and direct B2C customers through one modular platform foundation.

The owner has explicitly directed: Affiliate first, Lottery second, then separately validated Sportsbook/Betting, Live Casino and E-Gaming; a dedicated first-party B2C application must be a first-class tenant capable of consuming every approved module; and the platform must provide live chat/widget, wallet, deposits, withdrawals, Iranian and international payment-provider integrations, and role-specific dashboards.

This is an architecture proposal. It does not prove software, API, wallet, payment, chat, dashboard, provider or tenant implementation. It does not grant a licence, approve a jurisdiction, authorize custody or movement of funds, select a payment provider, or authorize real-money gaming. All regulated capabilities remain gated by exact legal entity, role, product, jurisdiction, customer eligibility, provider and operating model.

## 2. Product and experience model

### 2.1 Four primary experience families

1. **Lottorito Platform Administration** — platform governance, tenant lifecycle, module catalogue, global policies, operational health, security and audit.
2. **B2B Operator Console** — operator organization, product configuration, integrations, customer operations, finance views, compliance workflows and reporting.
3. **White-Label Console and branded surfaces** — delegated administration, brand/domain/theme/content configuration, enabled products, payment options and support configuration within platform policy.
4. **Affiliate / Agent Portal** — campaigns, attribution, referrals, downline hierarchy where enabled, commission statements, disputes, eligible wallet views and support.
5. **First-party B2C Consumer App** — Lottorito's own consumer-facing tenant and reference implementation of the customer experience. It uses the same product APIs and shared services as other tenants; it is not a fork of module business logic.
6. **Customer surfaces for external tenants** — web, mobile, embedded and API experiences operated under the relevant tenant brand.

These are experience boundaries, not necessarily separate deployable applications. Consolidate or split frontends based on product usability, security boundaries, release ownership and measured operational needs.

### 2.2 First-party B2C as a reference tenant

The Lottorito B2C tenant must be a normal tenant under the same tenant contracts, entitlements, ledger isolation, audit and release controls as external tenants. It may receive first-party product integrations and privileged operational support, but must not bypass tenant-scoped APIs or mutate another tenant's records.

It should provide one coherent application shell with independently enabled product areas. Customers should not need separate apps for every product. Navigation, discovery, account, responsible-use controls, support, wallet and history should feel consistent while each regulated product retains its own lifecycle, eligibility and disclosures.

### 2.3 Product module roadmap

- **Affiliate & Agent:** first delivery priority; industry-neutral core with configurable iGaming pilot needs.
- **Lottery:** second independent product domain.
- **Sportsbook / Betting:** later discovery and separately gated product.
- **Live Casino:** distinct streamed studio/table/round domain.
- **RNG / E-Gaming:** slots, RNG tables, video poker, bingo, crash/instant and jackpots as separately classified capabilities.
- **Poker, P2P and skill/social games:** separate classification and risk review; not implicitly part of RNG or sportsbook.
- **Shared extensions:** loyalty/rewards, promotions, notifications, chat, analytics and customer engagement. Each needs a defined owner, liability/funding model and entitlement policy.

No module is automatically available in every tenant or jurisdiction. Entitlement, legal eligibility, age/identity, geolocation, self-exclusion, limits and provider readiness are evaluated at the appropriate scope.

## 3. Tenant, organization and white-label model

### 3.1 Concepts that must not be conflated

- **Platform:** Lottorito's control plane and shared service contracts.
- **Tenant:** an independently governed customer/business boundary with isolated configuration, data, users, financial books and entitlements.
- **Organization:** a legal or operational entity within a tenant; may have branches or business units.
- **White-label brand:** a presentation and distribution identity owned/operated under a tenant or delegated organization; it is not automatically a separate tenant or legal operator.
- **Product instance:** a tenant-scoped activation/configuration of a product domain.
- **Installation:** a specific deployment of a widget, SDK or embedded surface with origin, tenant, environment and permissions bound.
- **User identity:** a principal that may hold memberships in more than one tenant; every action must resolve an explicit authorized membership and active context.
- **Affiliate/agent node:** a domain relationship inside a tenant's affiliate network, not a tenant boundary by itself.

### 3.2 Tenant hierarchy and isolation

Proposed hierarchy: Platform → Tenant → Organization/Brand → Product Instance → operational resources. Affiliate hierarchy exists inside the Affiliate domain and cannot grant cross-tenant access.

Tenant context must be established from verified authentication/session or machine credentials and server-side membership resolution. Never trust tenant_id, role, wallet_id, account_id, brand_id or product_id supplied by an untrusted client as authority. Re-check authorization at every API, job, event consumer, export, report, cache, file, support tool and administrative action.

Isolation must cover database queries, object storage, search indexes, cache keys, queues, event topics, analytics, logs, backups, support access and observability. Define pooled, bridge or dedicated deployment profiles from threat, data residency, workload and contract requirements; do not assume a single topology suits all tenants. Test negative cross-tenant access, confused deputy, cache leakage, job replay and support impersonation.

### 3.3 White-label governance

Allow scoped configuration for brand name/assets, domains, theme tokens, locale defaults, product navigation, permitted content, support routing, approved payment methods and tenant-owned legal disclosures. Maintain platform identity and technical traceability in internal metadata, audit, API contracts and operational tooling. Do not permit white-label configuration to override platform security, product eligibility, ledger controls, mandatory disclosures, self-exclusion or regulator-required content.

Custom domains require verified ownership, TLS lifecycle, DNS validation, domain-to-tenant binding, anti-takeover controls, redirect policy and safe preview/staging environments. Brand assets require provenance, rights and version history.

## 4. Identity, access and administrative control plane

Use centralized identity with tenant-scoped memberships and delegated administration. Separate authentication (who is acting) from authorization (what they may do, where, for which tenant/product/resource and under which conditions).

Proposed authorization model: RBAC for understandable role bundles plus ABAC/policy checks for tenant, organization, product, jurisdiction, resource ownership, status, risk and transaction limits. Apply least privilege, deny by default, separation of duties and time-bound elevation.

Minimum role families:
- Platform Owner / Super Admin
- Platform Security Administrator
- Platform Operations / SRE
- Platform Tenant Success / Support
- Platform Finance Operations
- Platform Compliance / Risk
- Tenant Owner / Tenant Administrator
- Tenant Product Manager / Operator
- Tenant Finance Maker / Finance Approver
- Tenant Compliance / Risk Officer
- Tenant Support Supervisor / Support Agent
- White-Label Owner / Brand Administrator
- Affiliate Program Manager
- Affiliate / Master Agent / Agent / Publisher
- B2C Customer
- Read-only Auditor / External Auditor
- Machine Client / Provider Adapter identity

Roles are templates, not unlimited grants. Sensitive actions require scoped permissions, maker-checker approval, reason codes and audit. Platform staff access to tenant data must be just-in-time, purpose-bound, approved where appropriate, visible to tenant audit and automatically expire. Break-glass access is exceptional, logged and reviewed.

## 5. Dashboard and portal requirements

### 5.1 Platform administration dashboard

Tenant lifecycle and status; legal entity and jurisdiction metadata; product/module catalogue and entitlements; tenant isolation profile; integration/provider registry; service health; payment-provider status; risk/compliance escalations; global incident view; audit search; usage/limits; release compatibility; support access approvals; billing/contract metadata; configuration drift. No dashboard control may silently bypass domain APIs or ledger invariants.

### 5.2 Tenant operator dashboard

Business KPIs; enabled product status; customer lifecycle; operational queues; deposit/withdrawal status (permission-gated); affiliate performance; lottery/gaming domain reports when enabled; chat queue and SLA; payment methods; reconciliation exceptions; risk cases; responsible-use controls; staff and role management; tenant configuration; API/webhook health; exports and audit trail.

### 5.3 White-label dashboard

Brand/domain/theme management; product availability and navigation; locale/content settings; approved payment options; customer support configuration; delegated roles; tenant-scoped analytics; release preview; legal disclosure configuration. It cannot edit platform-level policies, provider credentials, other brands or accounting history.

### 5.4 Affiliate / Agent dashboard

Personal profile and verification state; tracking links/codes; campaign assets; clicks and attribution diagnostics; referred customers subject to privacy policy; conversion funnel; commission policy version; pending/approved/held/reversed/paid earnings; statements; disputes; hierarchy and permitted downline views; payout eligibility/status; responsible marketing rules; chat/support. Do not expose other agents' personal data or infer commission from mutable balance.

### 5.5 B2C customer dashboard / app

Registration and secure sign-in; profile and verification; locale/time zone; account security and sessions; product discovery; jurisdiction/age eligibility; wallet and transaction history; deposit/withdrawal journeys where lawful; receipts and statements; product-specific history; notifications and preferences; support/chat; privacy controls; limits, cooling-off, self-exclusion and account closure where applicable. Avoid dark patterns, misleading balances, hidden fees or friction around safer-use controls.

### 5.6 Finance, compliance and support workspaces

Finance: ledger views, statements, reconciliation, settlement batches, exceptions, approvals and exports. Compliance: case management, KYC/AML workflow integrations, sanctions/PEP screening where applicable, source-of-funds reviews, jurisdiction and exclusion controls. Support: tenant-bound customer context, conversation timeline and approved actions. Each workspace must redact secrets and minimize personal data.

## 6. Wallet, ledger and financial domain

### 6.1 Ledger is the financial source of truth

Use an immutable, append-only, double-entry ledger with exact decimal/minor-unit representation, explicit currency, account ownership, tenant, product, legal entity, posting time, effective time, reference, idempotency key and audit provenance. Posted entries are never edited or deleted; corrections use linked reversals and adjustments. Enforce balanced postings atomically.

A displayed wallet balance is a derived projection from posted ledger entries and clearly identified holds/reservations. It is not an independently mutable source of truth. Distinguish available, pending, held, reserved, withdrawable, promotional and restricted funds only where the legal/accounting model supports those classifications. Do not present a sum across currencies as a single spendable amount without explicit FX and valuation context.

### 6.2 Account and ownership boundaries

Every financial account is bound to a legal owner, tenant, product/domain, currency and account purpose. No implicit pooling across tenants, brands, products, customers, agents or currencies. Customer wallet, agent commission payable, operator settlement, provider clearing, PSP clearing, fee revenue, tax payable, bonus liability and safeguarded/segregated funds are distinct conceptual account classes; final chart of accounts and legal treatment require finance/legal approval.

### 6.3 Deposit lifecycle

Illustrative states: initiated → awaiting customer action → provider pending → confirmed / failed / expired / cancelled / under review → ledger posted or rejected. Provider status and ledger posting are separate facts. A callback alone is not proof until signature, merchant/account mapping, amount, currency, reference, freshness, replay and finality rules are verified. Support polling/query and settlement reports for ambiguous outcomes. Never credit twice. Handle late success after expiry using explicit exception/reconciliation workflow.

### 6.4 Withdrawal lifecycle

Illustrative states: requested → eligibility checks → risk/compliance review → approved / rejected → reserved → submitted to provider → pending → paid / failed / returned / cancelled → reconciled. Reserve funds atomically; enforce available balance and limits; apply maker-checker to sensitive thresholds; verify destination ownership where required; record fees and FX separately; never mark paid solely from a client screen. Reversal/re-credit rules must handle provider return and partial failure without rewriting history.

### 6.5 Payment orchestration and adapters

Build a provider-neutral orchestration layer with versioned adapters. Each adapter declares supported countries, currencies, payment methods, legal entities, settlement model, refund/chargeback behavior, webhook authentication, idempotency support, limits, fees, payout support, data residency and operational SLA. Route only among providers that pass exact tenant/entity/jurisdiction/product gates.

Iranian and international payment integrations must be evaluated separately. Do not assume a gateway supports the target legal entity, business category, cross-border flow, currency, gambling-related activity or payout. Iranian domestic rails, international PSPs, bank transfer, cards and alternative methods have distinct rules, sanctions exposure, settlement semantics and availability. No provider is selected by this document.

### 6.6 Reconciliation, disputes and financial controls

Reconcile internal ledger ↔ payment orchestration ↔ provider transaction/settlement reports ↔ bank settlement. Use deterministic matching, suspense accounts, exception queues, ageing, ownership and escalation. Support refunds, reversals, chargebacks, disputes, reserves, fees, taxes, FX and manual adjustments only with reason, evidence and approval. Separate operational status from accounting finality. Define close periods, correction windows, audit exports and dual control.

## 7. Product lifecycle and financial isolation

Do not impose one universal transaction state machine. Affiliate attribution/commission, Lottery ticket/draw/prize, sportsbook bet/market/settlement, live-casino round and RNG spin each have separate lifecycle and correction semantics. Domain events may request ledger postings through an explicit financial contract; the ledger remains authoritative for posted money. Every posting includes tenant, product, domain reference, currency, event version and idempotency scope.

Wallet integration patterns (seamless, transfer, provider-managed) must be explicitly chosen per provider/product and reconciled. A provider's internal balance is not automatically the Lottorito wallet. Define source-of-truth and failure recovery before pilot.

## 8. Live chat and embeddable widget

Provide one shared conversation service and a tenant-bound widget/SDK. First-party B2C and external tenant deployments consume the same versioned contracts, with configuration and branding scoped to installation.

Capabilities: pre-chat consent and identity mode; anonymous-to-authenticated handoff; customer and agent presence; queues/routing; skills/language; business hours; conversation assignment; transfer/escalation; attachments with malware scanning; canned responses; internal notes; customer timeline; searchable transcripts; tags; CSAT; SLA; bot/automation integration with human escalation; multilingual UI; accessibility; retention/export/deletion policy; audit and abuse controls.

Security: short-lived signed bootstrap token bound to tenant, installation, origin, environment, audience and permitted actions; server-side session exchange; strict origin allowlist; CSP/frame controls; no long-lived secret in browser; rate limits; spam/bot controls; attachment isolation; tenant-bound transcript access; redaction; key rotation; replay defense. A browser-provided tenant ID is never authorization. Widget must fail safely if configuration or token is invalid.

## 9. Notifications, content, analytics and engagement

Shared notification service supports durable inbox, preferences, consent, quiet hours, deduplication, frequency/fatigue controls, templates, locale, channel adapters and delivery receipts. Separate transactional/security messages from marketing. Content/growth tools require editorial approval, evidence, claim provenance and market-specific advertising rules. Analytics must use tenant-aware access, data minimization, retention and export controls; distinguish operational metrics from financial reports.

Loyalty and promotions need liability owner, funding source, eligibility, accrual, expiry, redemption, reversal, fraud and accounting semantics before launch. No reward is a liability-free UI counter.

## 10. API, events and integration contracts

Expose versioned APIs with explicit tenant context derived from credentials, OAuth/OIDC or approved service identity; scoped permissions; idempotency; pagination; correlation IDs; stable error taxonomy; rate limits; webhook signatures, timestamp tolerance, replay protection and retry semantics. Use outbox/inbox patterns for reliable event delivery. Events are at-least-once unless proven otherwise; consumers must be idempotent. Schema evolution must be backward compatible or versioned. Keep secrets in managed secret storage and rotate/revoke credentials.

Integrations include payment providers, gaming/lottery providers, KYC/identity, geolocation, sanctions/risk, CRM/support, messaging, analytics, SSO/IdP and tenant-owned systems. Each integration follows LOT-PROVIDER-EVAL-001 and a named decision unit.

## 11. Security, privacy, safety and compliance

Threat model must cover tenant escape, privilege escalation, payment fraud, callback spoofing, replay, account takeover, agent collusion, commission manipulation, insider abuse, chat injection/attachment malware, data exfiltration, provider compromise, bot abuse, API scraping and denial of service.

Controls include MFA/passkeys where appropriate; secure sessions; device/session revocation; encryption in transit/at rest; key management; least privilege; secrets isolation; immutable audit; secure SDLC; vulnerability management; backup/restore; incident response; data minimization; purpose limitation; retention/deletion; data subject rights; vendor/subprocessor oversight; residency and cross-border transfer review.

For regulated gaming/payment activity, require market-specific legal analysis, operator/provider role clarity, licence and permitted product scope, age/identity checks, geolocation where required, AML/sanctions controls, responsible-gaming controls, self-exclusion propagation, limits, advertising/affiliate restrictions, regulator reporting and independent technical certification as applicable. A platform feature toggle is not a legal permission.

## 12. Reliability, operations and observability

Define service objectives by customer journey and domain: sign-in, wallet read, deposit confirmation, withdrawal status, chat delivery, affiliate attribution, lottery order, game round and reporting. Set SLO/SLI thresholds only after workload and risk profiles are approved under LOT-QA-001. Trace requests across tenant, product, provider and ledger references without logging secrets or unnecessary personal data.

Require tenant-aware dashboards, alert routing, provider health, queue lag, webhook delivery, reconciliation ageing, error budgets, runbooks, incident severity, status communications, backups, tested restore, RTO/RPO and disaster recovery. Tenant-specific noisy-neighbor protection and quotas are required. Provider outages must degrade safely; never infer success from timeout.

## 13. Data architecture and core logical entities

Candidate entities (logical only; not physical schema): Platform, Tenant, LegalEntity, Organization, Brand, Domain, TenantMembership, Principal, Role, Permission, Policy, ProductModule, ModuleEntitlement, ProductInstance, JurisdictionProfile, Provider, ProviderContract, ProviderAdapterConfig, WidgetInstallation, WalletAccount, LedgerTransaction, LedgerEntry, Hold, Deposit, Withdrawal, PaymentAttempt, SettlementBatch, ReconciliationCase, AffiliateProgram, AgentNode, AttributionTouch, CommissionRuleVersion, CommissionAccrual, Conversation, Message, Notification, Consent, AuditEvent, SupportAccessGrant, RiskCase, LimitProfile, SelfExclusion and ReportDefinition.

Every tenant-owned entity needs explicit ownership and authorization rules. Shared reference data must be distinguished from tenant data. Avoid putting every domain in one giant table or treating a logical entity list as a migration plan.

## 14. Architecture decision principles

- Start with bounded contexts and modular contracts; do not prematurely split every module into microservices.
- Separate control plane (tenant, entitlement, policy, provider configuration) from data plane (customer/product transactions), with strong authorization between them.
- Use a shared platform identity and ledger capability without sharing business lifecycle state.
- Use adapter boundaries for providers; provider-specific semantics remain at the edge.
- Keep product domains independently releasable and commercially adoptable.
- Use event-driven integration where it improves decoupling, with explicit consistency and replay contracts.
- Prefer boring, operable technology; select stack only after ADR and prototype evidence.
- Preserve data portability and exit options.

## 15. Non-functional quality attributes and acceptance evidence

For each journey define measurable targets for availability, latency percentiles, throughput, isolation, durability, recovery, accessibility, localization, privacy, security, operability and provider resilience. Numeric targets are TBD until workload, jurisdiction and service tier are approved.

Minimum acceptance evidence:
- automated tenant-isolation tests across API, jobs, events, cache, files, analytics and support tooling;
- role/permission matrix tests including negative and delegated access;
- ledger property tests: balanced entries, atomicity, idempotency, reversals and currency isolation;
- payment contract tests: duplicate, forged, late, reordered and ambiguous callbacks; settlement reconciliation;
- widget security tests: origin, token expiry, replay, cross-tenant transcript and attachment isolation;
- domain lifecycle tests per Affiliate/Lottery/Sportsbook/Live Casino/RNG as each is separately approved;
- localization and accessibility tests for all owner-directed launch languages;
- restore/DR, incident and provider-outage exercises;
- semantic Persian/English documentation review.

## 16. Delivery sequence and work packages

Preserve owner roadmap: Affiliate → Lottery → Sportsbook/Betting → Live Casino → E-Gaming. Architecture work is cross-cutting and begins now, but does not authorize building later regulated domains ahead of sequence.

Proposed work packages:
- **WP-01 Product/operating model:** legal entities, target jurisdictions, operator roles, customer segments, B2B/B2C/white-label commercial model.
- **WP-02 Tenant and identity:** tenant hierarchy, membership, RBAC/ABAC, support access, domain/brand binding.
- **WP-03 Core ledger:** account ownership, chart of accounts, holds, reversals, reconciliation and finance approvals.
- **WP-04 Payment orchestration:** payment capability matrix, adapter contract, deposit/withdrawal state machines, provider RFI and sandbox evidence.
- **WP-05 Affiliate vertical slice:** campaign → attribution → commission accrual → statement → approval → payout eligibility, without assuming real-money payout approval.
- **WP-06 B2C reference tenant:** app shell, account, product catalogue, profile, support, wallet views and module entitlements.
- **WP-07 Operator/white-label dashboards:** tenant setup, branding, module activation, staff permissions and operational reporting.
- **WP-08 Chat/widget:** shared conversation core, secure installation and human support operations.
- **WP-09 Observability/security/compliance:** audit, threat model, SLO, incident, risk and jurisdiction gates.
- **WP-10 Lottery domain:** only after Affiliate-first gate and Lottery scope/provider/legal approvals.
- **WP-11 Future gaming domains:** separate discovery, provider evaluation and approval per product/jurisdiction.

## 17. Open decisions and accountable owners

Do not fabricate answers. Record each decision with owner, options, evidence, due date and impacted documents:
1. Contracting and operating legal entity/entities; platform provider vs licensed operator vs technology supplier roles.
2. Initial launch jurisdiction(s), permitted customer locations and data residency.
3. Whether Lottorito B2C tenant is operated by Lottorito entity or a separately licensed/contracted operator.
4. Customer fund ownership, custody/segregation model, safeguarding, bank accounts and legal treatment.
5. Supported currencies, FX source, rounding and fees.
6. Iranian domestic payment scope and legal/technical eligibility; international PSP availability and restrictions.
7. Deposit/withdrawal methods, limits, cutoffs, reserves, chargebacks and payout approvals.
8. KYC/AML, sanctions, geolocation, age assurance and responsible-use responsibility split.
9. Tenant topology and data residency tiers.
10. Role catalogue, separation-of-duties matrix and support impersonation policy.
11. White-label contracting, domain ownership, brand approval and disclosure responsibility.
12. B2C app platform scope (web, iOS, Android, PWA), store policy and distribution model.
13. Chat retention, hosting, agent staffing, service hours and bot/human responsibility.
14. Wallet/ledger chart of accounts and domain-to-ledger posting contracts.
15. Affiliate commission basis, NGR definition, attribution window, reversals and payout rules.
16. Loyalty/promotion funding, liability, expiry and fraud policy.
17. Service objectives, workload profiles, recovery objectives and support coverage.
18. Provider choices and exact legal-entity/jurisdiction/product decision units.

## 18. Decision and implementation status

Owner-directed requirements recorded here: first-party B2C as a first-class tenant; unified modular app experience; shared live chat/widget; wallet and deposit/withdrawal capabilities; Iranian and international payment-provider support as a target; and role-specific dashboards spanning platform admin, tenant/operator, white-label, affiliate/agent and customer.

Architecture details in this document remain **Proposed** pending specialist review and owner decisions. No runtime implementation, payment connection, provider approval, licence, real-money operation, production dashboard, physical schema or release is claimed. Link any approved decisions to the decision register; update Persian and English together.
