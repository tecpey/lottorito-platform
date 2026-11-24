# First-Party B2C Application Product Requirements

**Document ID:** LOT-B2C-PRD-001 | **Version:** 0.1.0 | **Status:** Proposed product requirements; owner, product, legal, finance, security and operations review required

## 1. Product intent and authority

Lottorito's first-party B2C application is a dedicated first-party tenant and a first-class customer-facing product experience. It consumes eligible Lottorito modules through the same versioned domain contracts, authorization policies, event boundaries and operational controls offered to external B2B tenants. It is not a separate codebase, privileged bypass or a reason to weaken tenant isolation.

The owner has explicitly directed a dedicated B2C application as a tenant that can consume all modules that are approved, entitled, available and legally eligible for that tenant and customer. This is an owner-directed product requirement. The detailed requirements below remain Proposed pending review. No customer app, runtime, wallet, payment gateway, chat provider, licence, product launch or real-money capability is claimed as implemented or approved.

## 2. Product principles and experience boundaries

1. One coherent Lottorito customer experience, composed from independently governed modules.
2. First-party B2C uses the same contracts and security boundaries as B2B; no hard-coded privileged path.
3. Customer experience is distinct from Platform Admin, Tenant Operator, White-Label Admin, Affiliate/Agent and Support workspaces.
4. Show only products enabled for the tenant, customer's eligibility, jurisdiction, age (where relevant), policy and service availability.
5. A module being present in the platform does not mean it is entitled, enabled, legal or visible to every customer.
6. Customer money, commission, promotion, loyalty points and demo units remain visibly and financially distinct.
7. Customer-facing status is truthful: requested, pending, processing, paid, settled, failed and unknown are not interchangeable.
8. Persian and English documentation and the 12-language experience target require semantic and operational parity, not just translated labels.
9. Privacy, security, accessibility, responsible-use and support are core product requirements.
10. No launch or market activation without named owner, legal, provider, finance, security and operations gates.

## 3. Tenant and product model

The first-party B2C business is provisioned as a dedicated tenant with:
- its own tenant identity, legal/operating context and lifecycle;
- its own brands/domains and product instances as approved;
- customer profiles and tenant-scoped relationships;
- tenant-scoped policies, localization, currencies, payment configurations and service settings;
- product entitlements, jurisdiction rules and customer eligibility;
- dedicated provider credentials/configurations and audit/reporting scopes;
- clear ownership of customer support, data, liabilities and operational responsibilities.

The B2C tenant consumes shared module contracts. It must not fork Affiliate, Lottery, wallet, payment, chat, notification or identity logic. Common services may be shared technically, but customer records, funds, credentials, events, queues, exports and permissions remain tenant-scoped.

A customer may have a principal across multiple tenants only under the approved identity/account-linking model. Shared authentication does not imply shared profile, wallet, transaction history, consent or eligibility. Tenant switching must never silently combine data.

## 4. Customer segments, roles and access

Primary customer roles:
- visitor/anonymous user;
- registered customer;
- verified customer where a product or jurisdiction requires verification;
- restricted/suspended customer;
- customer requiring support or dispute handling.

The same human may separately be an Affiliate/Agent or workforce principal under a different membership and workspace. Customer UI must not expose administrative capabilities merely because the principal has another role. Workspace/context switching is explicit and authorization is re-evaluated server-side.

Customer self-service permissions are limited to own profile, preferences, sessions, eligible product actions, own wallet views, own payment/payout requests, own statements and own conversations. Support access is case/queue/purpose-bound, least-privilege and audited. No customer can enumerate other customers or infer their existence through IDs, search, errors or timing.

## 5. Navigation and information architecture

Proposed primary navigation:
- **Home:** personalized overview, eligible products, service notices and next best actions.
- **Explore/Products:** only enabled and eligible modules, with clear descriptions and terms.
- **Wallet:** separate cash-value, commission (if customer is also an agent in the correct workspace), rewards, promotions and demo units; no ambiguous combined total.
- **Activity:** product-specific history and canonical transaction status.
- **Support:** live chat, help content, cases and contact preferences.
- **Profile & Security:** identity, verification status, sessions, privacy, consent, language, accessibility and account controls.

Navigation is responsive and accessible across web/mobile surfaces. Product cards must explain availability, jurisdiction restrictions, eligibility and whether a module is informational, simulated or real-money only where legally approved. Do not advertise a disabled/future regulated module as currently available.

## 6. Onboarding, identity and account lifecycle

Proposed customer journey:
1. Discover the B2C app and review its operator identity, market availability, terms and privacy notice.
2. Register using a jurisdiction-appropriate method with anti-enumeration and abuse controls.
3. Verify contact details and complete additional identity checks only when required for the requested product/market.
4. Accept versioned terms, privacy and relevant product-specific disclosures; record consent purpose and timestamp.
5. Establish secure recovery, session inventory and optional/required MFA according to risk.
6. Complete eligibility checks and display only available modules.
7. Enter a module with a clear transition and return path.

Do not force passkeys as the only customer sign-in method. Authentication and recovery must work for the supported customer population, devices and jurisdictions. KYC is not a generic profile badge: requirements, data, retention and access are purpose- and jurisdiction-specific.

Account lifecycle must cover active, restricted, suspended, closure requested, closing and closed states. Suspension/closure must preserve open transactions, funds/claims, disputes, support access, statutory retention and legal holds. Provide customer-facing explanations and appeal/contact routes where appropriate.

## 7. Product catalog, entitlements and module composition

A catalog entry is visible only when all required gates pass:
- tenant entitlement and commercial plan;
- product instance enabled and healthy;
- jurisdiction and operating-entity permission;
- customer eligibility and required verification;
- age/responsible-use policy where relevant;
- product/provider availability and operational status;
- customer consent and product-specific terms.

Modules use independent bounded contexts and APIs. Affiliate/Agent infrastructure is primarily B2B; customer-facing referral or loyalty experiences require a separately defined customer entitlement and must not expose agent commissions or network data. Lottery, Sportsbook, Live Casino, RNG/E-Gaming and P2P/skill games remain distinct domains and future horizons. Their presence in platform strategy does not authorize B2C exposure, onboarding, deposits, wagers, gameplay or prizes. Each needs separate product, provider, jurisdiction, responsible-use, finance, security and owner release gates.

## 8. Wallet and customer balance experience

The Wallet screen follows LOT-WALLET-001:
- show only wallet classes the customer is entitled and eligible to use;
- separate available, pending, held/reserved, payable and withdrawable where applicable;
- show currency/unit, as-of time, restrictions and source freshness;
- distinguish fiat from crypto-assets, promotional credits, loyalty points and demo units;
- provide transaction history and statement export only for the customer's authorized scope;
- explain holds, pending status, expiries and restrictions in plain language.

Never display a single combined “total balance” across incompatible units or legal treatments. A positive amount is not automatically spendable, payable or withdrawable. The UI does not create or edit balances. Corrections, refunds and reversals appear as linked historical entries, not overwritten transactions.

## 9. Deposit and payment journeys

Deposit/collection follows LOT-PAYMENT-001:
1. Customer chooses an enabled amount, currency and method.
2. Server validates tenant, customer, purpose, amount, currency, limits, method and jurisdiction.
3. Platform creates an immutable Payment Intent and a provider-specific Attempt.
4. Customer completes provider-hosted or approved payment interaction.
5. Return page shows provisional status; server verifies authoritative provider status.
6. Wallet/ledger credit occurs only after approved evidence and posting policy.
7. Settlement and reconciliation proceed independently; customer sees truthful status and support reference.

Iranian and international payment methods are market/provider configurations, not one global switch. The product must show only legally approved methods for the first-party tenant's exact entity, customer location, currency and payment purpose. Never promise availability before merchant onboarding and provider due diligence. Do not collect or store sensitive card/bank credentials outside an approved, assessed method. Fees, FX, currency aliases (including IRR/IRT), expiry, refund terms and payee identity are disclosed before confirmation.

## 10. Withdrawal and payout journeys

Withdrawal follows LOT-PAYOUT-001 and is separate from deposit:
1. Customer selects an eligible withdrawable amount and verified beneficiary.
2. Server recalculates available/withdrawable eligibility, source of funds, limits, risk, KYC/AML/sanctions and jurisdiction.
3. Platform creates a payout request and reserves funds atomically.
4. Required screening and maker-checker approval occur outside the customer's ability to self-approve.
5. Approved provider/rail receives one idempotent payout instruction.
6. Unknown outcomes retain the hold and enter status query/reconciliation; no blind retry.
7. External settlement/return is verified, reconciled and reflected through controlled ledger posting.
8. Customer receives status, reference, fee, expected processing window only when supported by provider evidence, and an escalation route.

Do not show withdrawal as available until the exact wallet class, liability, legal entity, funding source, beneficiary, jurisdiction and provider/rail are approved. Commission payouts, prize disbursements and refunds are not customer withdrawal variants; they have separate roles and flows.

## 11. Live chat, support and case management

Use LOT-COMMS-001 and LOT-CHAT-WIDGET-001 as the shared communications foundation. The B2C app may expose an in-app chat widget backed by the same conversation core as first-party support and external embeds.

Required customer behavior:
- authenticated chat session bound to tenant, customer, app and installation;
- clear bot/automation disclosure and human handoff;
- language and RTL/LTR continuity;
- visible conversation history, attachments subject to quarantine/scanning and privacy controls;
- case/reference linkage for payment, wallet, identity or product issues;
- status and expected response information only when operationally supported;
- export/delete/access handling under applicable policy.

Support agents see only assigned cases and minimum necessary context. A chat message is not payment authorization, a beneficiary-change approval, a KYC decision or a financial ledger instruction. Sensitive actions must use dedicated authenticated workflows.

## 12. Notifications, preferences and customer communications

Use LOT-NOTIF-001 for policy-gated notifications. Support an in-app inbox and approved channels only after provider, consent, privacy and market review. Notification categories include security, identity, payment, payout, product activity, service/maintenance, support and optional marketing.

- Separate transactional/security notices from marketing consent.
- Deduplicate by economic/business event and notification purpose.
- Respect locale, timezone, quiet hours, channel preferences and legal requirements.
- Count pending and delivered notifications for fatigue controls; retries do not create new user-visible events.
- Do not leak amounts, balances, sensitive identity details or transaction information in lock-screen previews by default.
- Provide preference controls without allowing customers to suppress legally required security/transaction notices where prohibited.

## 13. Localization, accessibility and design system

The target is 12 launch languages under LOT-I18N-001, with equal product, content and support quality: English, Simplified Chinese, Spanish, Hindi, Russian, Arabic, French, Brazilian Portuguese, Japanese, German, Persian and Turkish. The exact locale variants, legal availability and launch order remain subject to approval.

Support RTL/LTR, locale-aware numbers/dates/calendars/timezones, currency display, pluralization, long strings, text expansion, accessible validation and localized support. Never use machine translation as the only quality gate for legal, financial, responsible-use or safety-critical content.

Conform to WCAG 2.2 AA as a proposed accessibility target, subject to review: keyboard operation, screen-reader semantics, focus order, contrast, reduced motion, scalable text, touch targets, captions/transcripts and error recovery. Avoid inaccessible financial charts or color-only status.

## 14. Security, privacy and responsible-use

- Server-side tenant and object authorization for every request; deny by default.
- Secure sessions, recovery, MFA/step-up for sensitive operations, device/session revocation and anti-account-takeover controls.
- Rate limiting, bot/credential-stuffing defenses, abuse reporting and anomaly detection.
- Minimize personal data; purpose limitation, consent, retention, correction, export, deletion and legal hold by jurisdiction.
- Protect wallet, payment, beneficiary and support data with encryption, access audit and least privilege.
- No provider secret or privileged operational note in customer-facing APIs.
- Responsible-use controls for any regulated product: eligibility, limits, self-exclusion/time-outs, risk notices, complaint handling and market-specific requirements before exposure.
- Separate sandbox/demo from production with unmistakable labels, isolated credentials and no cross-crediting.
- Incident communication and account recovery must not reveal whether another customer exists.

## 15. Product analytics, service levels and operational readiness

Measure customer journeys without collecting unnecessary sensitive content:
- registration/verification completion and abandonment;
- module discovery-to-activation, eligibility denial reasons and availability;
- deposit intent/attempt success, unknown outcome, refund and reconciliation rates;
- withdrawal request, approval, processing, return and resolution times;
- wallet projection freshness and statement access;
- chat response/handoff and case resolution;
- notification delivery, deduplication, preference and fatigue outcomes;
- accessibility/localization defects, support contacts and customer complaints.

Define event taxonomy, consent, retention, aggregation and KPI owners before analytics activation. Never use a raw balance, wager volume or deposit total as a stand-alone measure of customer well-being or product quality. Availability, latency, recovery and support SLOs remain TBD until workload profiles and accountable owners approve them.

Operational readiness includes support playbooks, incident response, provider escalation, reconciliation ownership, customer communication templates, status page, backup/recovery, accessibility review, localization QA, privacy review and jurisdiction-specific launch checklist.

## 16. Acceptance criteria, release gates and open decisions

| ID | Acceptance scenario | Expected result |
|---|---|---|
| B2C-01 | First-party B2C tenant is provisioned | Own tenant/legal/product context; no privileged bypass |
| B2C-02 | Customer accesses another tenant's profile/wallet | Server denies; no existence/data leakage |
| B2C-03 | Customer has another Agent/workforce role | Customer workspace remains least-privilege and context-explicit |
| B2C-04 | Module is not entitled or jurisdictionally eligible | Hidden/blocked with safe explanation; no API bypass |
| B2C-05 | Product/provider is unavailable | Accurate service state; no false availability claim |
| B2C-06 | Customer views multiple wallet classes | Units and legal treatment remain separate |
| B2C-07 | Pending/held funds are viewed | Not shown as spendable/withdrawable |
| B2C-08 | Deposit browser redirect claims success | Provisional only until server-side verification |
| B2C-09 | Payment callback duplicates or conflicts | One economic effect; exception is traceable |
| B2C-10 | Withdrawal exceeds eligibility | Rejected before reservation |
| B2C-11 | Beneficiary changes after approval | Reverification and reapproval required |
| B2C-12 | Payout provider times out | Unknown outcome; hold retained; no blind retry |
| B2C-13 | Customer starts chat from payment issue | Conversation linked to authorized case context; no financial action via chat |
| B2C-14 | Support opens unrelated customer | Denied or requires approved assignment/purpose workflow |
| B2C-15 | User changes language/RTL direction | Navigation, amounts, forms and support remain coherent |
| B2C-16 | Customer requests data export/deletion | Scope, legal retention and legal hold rules applied |
| B2C-17 | Marketing consent is withdrawn | Marketing stops; required transactional/security notices follow law |
| B2C-18 | Account is suspended with open transaction | Funds, claims, support and audit remain safely handled |
| B2C-19 | Demo units appear beside fiat | Explicit labels and no conversion/cross-credit |
| B2C-20 | Regulated future module is not approved | No customer exposure, deposit, wager or gameplay path |

Release gates:
- Owner approves product scope, brand, target markets and staged module list.
- Legal/compliance approves entity, jurisdiction, customer terms, payment/payout model and regulated-product eligibility.
- Finance approves wallet classes, account mapping, funding, reconciliation and liabilities.
- Security/privacy approves threat model, IAM, data lifecycle, payment scope and independent testing.
- Providers pass LOT-PROVIDER-EVAL-001 and authorized sandbox tests for the exact decision unit.
- Product/UX, accessibility and native-language reviewers approve customer journeys and critical copy.
- Operations approves support, incident, refund/payout, reconciliation and recovery runbooks.
- Automated tests prove tenant isolation, idempotency, concurrency, lifecycle and customer data rights.

Open decisions include initial market and legal entity; B2C brand/domain/apps; launch module sequence; customer identity/account-linking; age/KYC requirements; supported currencies/payment methods; wallet class and custody/funding model; withdrawal availability; chat/support staffing and SLA; language locale variants; customer analytics/privacy; and commercial pricing/fees.

This PRD is Proposed. No launch, app store publication, payment/payout processing, custody, regulated product or customer-data migration is authorized by this document.
