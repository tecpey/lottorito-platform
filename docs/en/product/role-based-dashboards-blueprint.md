# Role-Based Dashboards and Workspace Product Blueprint

**Document ID:** LOT-DASH-001 | **Version:** 0.1.0 | **Status:** Proposed product/UX and operations blueprint; owner review required

## 1. Purpose and relationship
This blueprint translates LOT-PLATFORM-001 and LOT-IAM-TENANT-001 into role-specific workspaces for Platform, Tenant/Operator, White-Label, Affiliate/Agent, Support, Finance, Compliance/Audit and B2C Customer experiences. It describes navigation, information architecture, key journeys, operational controls and acceptance evidence. It is not a UI implementation, approved permission grant, or proof that any dashboard exists.

## 2. Shared workspace shell
Every workspace uses a consistent application shell, but its navigation and data are generated from server-authorized capabilities:
- Tenant/workspace switcher only when the principal has multiple active memberships; show legal/business context and active brand clearly.
- Product switcher limited to enabled and eligible product instances.
- Global search constrained to the current tenant and permissions; platform-wide search requires separate platform grant.
- Notification center with category preferences, unread state and action-safe deep links.
- Profile, security, sessions, MFA and recovery settings.
- Contextual help, support and status/incident information.
- Locale, timezone, number/currency display and accessibility preferences.
- Visible environment marker (production/sandbox) and tenant/brand identity.
- Breadcrumbs and resource ownership context on sensitive pages.

Do not use a common mega-menu that exposes every module to every user. Navigation is a projection of authorized capabilities, not the source of authorization.

## 3. Dashboard design principles
1. Role-specific information density: executives need outcomes and exceptions; operators need queues and actionable work; customers need clarity and self-service.
2. Every KPI has a definition, owner, source, refresh/freshness indicator, timezone, currency basis and drill-down permission.
3. Never combine balances or performance across legal entities, tenants, currencies or products unless the aggregation is explicitly approved and labeled.
4. Separate operational status from financial finality. A provider callback or pending transaction is not settled cash.
5. Surface exceptions and next actions, not vanity metrics.
6. All charts and exports preserve tenant, product, date, currency and filter scope.
7. Avoid exposing personal data in overview widgets; reveal minimum data only on authorized detail screens.
8. Mobile layouts prioritize urgent actions and compact summaries; destructive/financial approvals require deliberate confirmation and step-up authentication.
9. Empty, loading, stale, partial, restricted and error states must be designed explicitly.
10. Dashboard widgets never perform privileged actions merely because the user can view the page.

## 4. Workspace catalogue and detailed requirements

### 4.1 Platform Super Admin
**Purpose:** Govern the platform, not operate every tenant's customer records by default.

Navigation: Overview; Tenants; Organizations/Brands; Product Catalogue; Entitlements; Provider Registry; Global Policies; Platform Workforce; Security & Audit; Operations; Incidents; Usage & Billing; Release Controls.

Overview widgets:
- Active/restricted/suspended tenant counts with change history.
- Product-instance adoption and entitlement state.
- Provider availability and integration incident summary.
- Platform service health, queue lag and critical error trends.
- Security alerts, privileged access and unresolved audit exceptions.
- Usage/capacity and tenant onboarding funnel.

Actions: provision/restrict tenant under approved workflow; manage global catalog and policy versions; assign platform workforce; initiate controlled incident response; view scoped audit trails. High-risk actions require dual control and immutable reason records.

Must not show: unrestricted customer PII, full payment credentials, tenant financial balances across all tenants as a pooled total, or raw game/customer activity without explicit purpose and permission.

### 4.2 Platform Operations / SRE
Navigation: Service Health; Deployments; Queues & Jobs; Webhooks; Provider Health; Incidents; Runbooks; Capacity; Audit.

Widgets: availability/SLO burn, latency percentiles, error rates, queue age/depth, dead-letter counts, callback failure/duplicate rates, provider circuit state, deployment versions and incident timeline.

Actions: acknowledge/assign incident, execute approved runbook, pause/replay eligible jobs with idempotency safeguards, annotate events, escalate provider outage. No direct ledger edits or customer impersonation.

### 4.3 Platform Finance
Navigation: Ledger Explorer; Reconciliation; Settlement; Fees & FX; Provider Statements; Exceptions; Approval Queue; Financial Reports.

Widgets: unreconciled amount/count by currency and provider, aged breaks, pending settlement, payout queue by risk tier, reversal/refund exceptions, ledger integrity alerts.

Actions: review and resolve reconciliation cases; approve only within mandate; create adjustment request (not silently mutate balances); export controlled evidence. Separate preparer, approver and executor. A finance overview must not imply that a pending provider settlement is available cash.

### 4.4 Platform Compliance / Risk
Navigation: Jurisdiction & Eligibility; Tenant Due Diligence; KYC Casework; AML/Risk Alerts; Responsible Gaming; Provider Compliance; Policy Decisions; Audit Evidence.

Widgets: expiring documents, open high-risk cases, blocked/held operations, jurisdiction policy exceptions, self-exclusion and safer-gambling control alerts, overdue reviews.

Actions: review cases, record decisions with rationale, apply authorized restrictions, request evidence and escalate. Sensitive data is purpose-bound and masked until needed. Compliance decisions do not automatically create financial postings.

### 4.5 Tenant Owner / Tenant Admin
Navigation: Business Overview; Products; Customers; Workforce & Roles; Brands; Integrations; Payments (if approved); Finance Views; Affiliate; Support; Reports; Settings; Audit.

Widgets: enabled products and readiness; customer/account growth; product usage; deposit/withdrawal status by currency and provider; support backlog; affiliate performance; compliance tasks; provider health; revenue/commission summaries only where definitions and access are approved.

Actions: invite/suspend workforce, assign tenant-scoped roles, configure permitted products, manage brand settings, review business exceptions, request payout/settlement approvals. Cannot change platform-global policy, inspect another tenant or grant unapproved regulated products.

### 4.6 Tenant Operator / Operations Staff
Navigation: Work Queue; Customers; Product Operations; Transactions (scoped); Support Cases; Risk Tasks; Reports.

Widgets: assigned work, aging queue, pending customer actions, transaction exceptions, product-specific operational status and SLA.

Actions: process assigned workflows, request approvals, add case notes and escalate. No broad tenant configuration or self-approval of sensitive actions unless separately authorized.

### 4.7 White-Label Administrator
Navigation: Brand Overview; Domains; Theme & Assets; Localization; Content; Product Presentation; Customer Communications; Support Routing; Brand Analytics; Change History.

Widgets: domain verification, brand asset completeness, locale coverage, active product presentation, widget/chat health, customer journey conversion and pending brand changes.

Actions: configure assigned theme, logo assets, domain, content and permitted navigation; preview in sandbox; submit changes for approval and publish through controlled release. Payment routing, legal entity, custody, eligibility and regulated product controls remain outside default brand-admin authority.

### 4.8 Affiliate / Agent
Navigation: Overview; Tracking Links; Campaigns; Referrals; Network (if enabled); Commission Statements; Wallet/Payments (only if approved); Assets; Support; Profile.

Widgets: visits/clicks with attribution window, qualified referrals, conversion funnel, pending/approved/reversed commission, statement period, network performance within allowed visibility and campaign health.

Actions: create approved tracking links, manage permitted campaigns, download own statements, submit disputes and update profile. Do not expose another agent's private customers, raw personal data, platform margin or unapproved commission formulas. Network views follow explicit hierarchy edges and anti-collusion/privacy controls.

### 4.9 Support Agent
Navigation: Inbox; Assigned Conversations; Customer Cases; Knowledge Base; Escalations; SLA; Quality Review.

Widgets: queue by language/product/priority, first-response and resolution timers, waiting customer, escalations, reopen rate and satisfaction.

Actions: claim/assign, reply, use approved macros, add internal notes, attach permitted evidence and escalate. Sensitive customer details are revealed only when case assignment and purpose justify them. Support cannot edit ledger or approve payouts by default.

### 4.10 B2C Customer Application
Primary navigation: Home; Products; Wallet; Activity; Rewards (when enabled); Support; Account/Security.

Home: personalized eligible products, account status, safe-to-display wallet summary, recent activity, relevant notifications, support entry and responsible-use tools where applicable.

Wallet: separate available, pending and held amounts; currency selector; deposit and withdrawal entry points only when the customer, product, jurisdiction and provider are eligible; clear fee/limit/processing disclosures; receipts and status timeline.

Activity: chronological transaction and product history with filters, details, status definitions and dispute/help route. Product activity is isolated by domain and not represented as a generic bet/game transaction.

Account/Security: identity/KYC status where relevant, sessions/devices, MFA, recovery, communication preferences, privacy controls, limits, self-exclusion/safer-use controls where applicable.

Support: authenticated live chat, case history, attachment controls and escalation. Customer can see only their own conversations and records.

Customer UX must distinguish available, pending, held, failed, reversed and settled states. Avoid dark patterns, urgency pressure, misleading near-miss messaging or reward mechanics that encourage harmful play. Product availability must be eligibility-aware, not merely hidden in the UI.

## 5. Cross-workspace workflow contracts
- Tenant onboarding: request → due diligence → provisioning → owner invitation → configuration → acceptance tests → activation.
- Product activation: entitlement request → jurisdiction/provider/legal gates → configuration → sandbox validation → approval → controlled release.
- Payment exception: event detection → idempotency and signature verification → case creation → authorized review → correction/reversal path → reconciliation closure.
- Withdrawal: customer request → eligibility/limits → risk review → funds reservation → approval where required → provider execution → final status → reconciliation.
- Support escalation: customer conversation → queue assignment → identity/context check → case escalation → specialist decision → customer update → closure/feedback.
- Brand change: draft → preview → approval → publish → audit and rollback option.

Each workflow has explicit states, actor permissions, timeouts, retry policy, compensation/reversal semantics and audit evidence. Do not model every product transaction with one generic state machine.

## 6. KPI dictionary requirements
Before a KPI is displayed, define:
- Stable metric ID and business owner.
- Formula, numerator/denominator and exclusions.
- Source-of-truth event/table and calculation version.
- Currency and FX policy; no implicit cross-currency sum.
- Tenant, product, brand and jurisdiction dimensions.
- Event-time versus processing-time semantics.
- Freshness target and late-arrival handling.
- Permission scope and privacy threshold.
- Drill-down and export behavior.

Examples requiring separate definitions: registered customers, active customers, funded customers, first deposit, deposit success rate, withdrawal completion time, net gaming revenue (only if legally and commercially applicable), affiliate attributed conversions, commission payable, reconciliation breaks, support first response and product uptime. Do not label gross deposits as revenue or pending commission as payable.

## 7. Notifications and action safety
Notifications are tenant/product/locale-aware and preference-controlled. Deep links re-authorize on destination. Never place full account numbers, secrets, sensitive KYC data or payment credentials in push/email previews. High-risk approvals require authenticated in-app review; email/SMS links must not approve a payout.

## 8. Accessibility, localization and responsive behavior
- WCAG 2.2 AA is a proposed target, subject to audit.
- Full RTL/LTR layout, locale-aware dates/numbers and currency formatting.
- Translation keys, pluralization and text expansion tested in all launch locales.
- Keyboard navigation, screen-reader labels, focus management and non-color status cues.
- Responsive layouts with equivalent permission behavior on mobile and desktop.
- Timezone and reporting period clearly shown; store canonical timestamps and render per user/tenant preference.

## 9. Analytics, exports and privacy
All reporting queries are server-scoped. Exports require explicit permission, purpose, field-level minimization, audit event, expiration and secure delivery. Protect against spreadsheet formula injection. Aggregates should suppress small cohorts where re-identification is possible. Support and platform dashboards must not become cross-tenant data-browsing tools.

## 10. Acceptance and test scenarios
| ID | Test | Expected result |
|---|---|---|
| DASH-01 | Switch between two tenant memberships | Data, filters, links and cache remain isolated |
| DASH-02 | Open a deep link after role revocation | Server denies and records the attempt |
| DASH-03 | White-label admin edits payment route | Denied or routed to separate approved workflow |
| DASH-04 | Agent queries unrelated agent/customer | No disclosure, including counts and exports |
| DASH-05 | Customer sees pending deposit | Clearly labeled pending; no available-balance credit |
| DASH-06 | Provider outage | Status and retry guidance visible; no false success |
| DASH-07 | Finance approver initiates own payout | Separation-of-duties blocks or requires independent approver |
| DASH-08 | Export contains cross-tenant rows | Export rejected; security event recorded |
| DASH-09 | RTL locale and long translations | No clipped controls or reversed financial semantics |
| DASH-10 | Mobile customer flow | Equivalent authorization and safe confirmation |
| DASH-11 | KPI combines currencies | Blocked unless approved FX methodology is explicit |
| DASH-12 | Product entitlement is suspended | New entry points disabled; existing workflow handled safely |

## 11. Open decisions
- Exact initial role catalogue and delegated organization structure.
- Whether Tenant Owner, Finance, Compliance and Support are separate workspaces or role-composed areas.
- KPI definitions and reporting latency targets.
- Which customer wallet functions are in first commercial release.
- White-label change approval and rollback ownership.
- Initial supported locales, accessibility audit scope and mobile delivery channels.
- Customer support hours, languages, staffing, SLA and escalation model.
- Data export, retention and regulatory reporting obligations by jurisdiction.

## 12. Related documents and change control
Related: LOT-PLATFORM-001, LOT-IAM-TENANT-001, LOT-CHAT-WIDGET-001, LOT-FIN-POST-001, LOT-PROVIDER-EVAL-001, LOT-I18N-001, LOT-NOTIF-001 and LOT-QA-001.

This is a proposed product blueprint. Any change to data visibility, approval authority, financial action or cross-tenant reporting requires an IAM/security review and synchronized Persian/English update. No dashboard or workflow is claimed implemented.
