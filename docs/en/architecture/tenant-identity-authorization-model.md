# Tenant, Identity, Membership and Authorization Model

**Document ID:** LOT-IAM-TENANT-001 | **Version:** 0.1.0 | **Status:** Proposed contract; owner and specialist review required

## 1. Purpose and authority
This document decomposes LOT-PLATFORM-001 into a proposed tenant, identity and authorization contract for first-party B2C, external B2B operators, white-label brands, affiliate/agent organizations and customers. Global modular multi-tenancy, a first-party B2C tenant and role-specific workspaces are owner-directed. This model is proposed; it does not prove an implemented identity service, tenant database, SSO, authorization engine or security certification.

## 2. Non-negotiable security invariants
1. Deny by default; every protected operation requires an explicit allow decision.
2. Tenant context is established and verified server-side. Never trust a tenant, role, wallet or product identifier supplied only by a client.
3. Every resource has an explicit owner scope: platform-global, tenant, organization, brand, product instance or principal-owned.
4. Membership in one tenant grants no authority in another.
5. Identity is distinct from membership. A principal may have multiple scoped memberships.
6. Roles are scoped grants, not permanent user attributes. The same human may be a customer in one tenant and a workforce member in another.
7. Privileged actions are attributable to actor, effective subject, tenant, resource, action, reason, policy decision and correlation ID.
8. Background jobs, webhooks and provider adapters use scoped machine identities, never shared human credentials.
9. Revocation of memberships, sessions, grants and tenant access must take effect within a measured, approved propagation objective.
10. UI visibility is not a security boundary; server-side authorization is mandatory.

## 3. Domain vocabulary
- **Platform:** Lottorito's global governance and control boundary.
- **Tenant:** A commercial/operational customer boundary with its own policies, entitlements, data and service configuration. Lottorito's direct B2C business is a dedicated first-party tenant.
- **Legal Entity:** Legally accountable entity; its relationship to tenants and brands requires explicit legal review.
- **Organization:** Workforce/business grouping used for delegated administration and membership.
- **Brand:** Customer-facing identity. A tenant may own multiple brands; a brand is not automatically a tenant or legal entity.
- **Product Instance:** Enabled and configured instance of a product domain for a tenant/brand and operating model.
- **Workspace:** User-facing administrative or operational context; not a security boundary by itself.
- **Principal:** Human user, service account or external machine identity.
- **Membership:** Time-bounded principal-to-tenant/organization relationship with status and scoped grants.
- **Customer Profile:** Tenant-scoped customer relationship. A shared login does not imply globally shared customer data.
- **Resource:** Any protected object: wallet, ledger entry, ticket, bet, game session, commission statement, conversation, report, API credential or export.

Conceptual relationships: Platform → Tenant → Organizations, Brands, Product Instances and Policies. Legal entities may relate to multiple tenants or brands only under approved contracts. Principals may hold multiple memberships. Physical cardinalities remain open.

## 4. Principal and experience classes
| Experience | Principal | Default scope |
|---|---|---|
| Platform administration | Lottorito workforce | Explicit platform-global grants; privileged and audited |
| Tenant owner/admin | Tenant workforce | Assigned tenant/organization |
| Tenant operator | Tenant workforce | Assigned products and operational functions |
| White-label administrator | Delegated workforce | Assigned brand and delegated settings only |
| Affiliate/agent | Partner principal | Own profile, permitted campaigns, referrals, statements and explicitly scoped network |
| B2C customer | Customer principal | Own profile and self-service resources in the selected tenant |
| Support agent | Workforce/contractor | Assigned queue/case and minimum customer context |
| Auditor/compliance reviewer | Specialist principal | Purpose-bound, read-limited and logged |
| Service principal | Machine identity | Specific service, tenant, audience, operation and expiry |

A human may use several experiences. Switching workspace changes context; it must never silently elevate privileges.

## 5. Authentication and session contract
Authentication answers who controls a credential; authorization answers what that principal may do to a resource in context. Keep these decisions separate.

Required capabilities:
- Verified email/phone and recovery policies appropriate to risk and jurisdiction.
- MFA for workforce, privileged roles and sensitive customer actions; phishing-resistant methods preferred where supported.
- Passkeys/WebAuthn as an option, not the only customer authentication route.
- Session inventory, device/session revocation, suspicious-session controls and re-authentication for sensitive actions.
- Secure recovery, anti-enumeration responses, credential-stuffing protection and rate limits.
- OIDC/OAuth 2.1 Authorization Code with PKCE for supported clients.
- OIDC/SAML federation for eligible B2B tenants; protect tenant discovery and account linking.
- Short-lived access credentials, secure refresh-token storage and documented rotation/revocation.
- Machine credentials scoped by audience, tenant, environment and permission, with key rotation and emergency revocation.

A session may select a tenant/workspace, but the server must revalidate membership and policy on protected requests or use a documented cache with bounded revocation delay. Client claims are never authoritative for role, tenant status, product entitlement, jurisdiction or financial eligibility.

## 6. Authorization model
Use RBAC for understandable job roles plus ABAC/policy evaluation for contextual constraints. A single hard-coded role enum is insufficient.

Every decision evaluates, as applicable:
- Principal and authentication assurance.
- Active membership and membership scope.
- Tenant, organization, brand and product-instance status.
- Action, resource type, resource owner and tenant relationship.
- Product entitlement and feature state.
- Jurisdiction, customer eligibility and risk restrictions.
- Amount, currency, limits and approval thresholds for financial actions.
- Time, device/network signals and step-up authentication.
- Separation-of-duties and dual-control requirements.

Illustrative stable permission namespaces (not approved grants):
- platform.tenant.read / platform.tenant.provision / platform.policy.manage
- tenant.member.invite / tenant.member.suspend / tenant.settings.manage
- brand.theme.manage / brand.domain.verify / product_instance.configure
- customer.profile.read_assigned / customer.profile.update_self
- wallet.balance.read_self / wallet.deposit.create_self / wallet.withdrawal.request_self
- finance.ledger.read_scoped / finance.reconciliation.review
- affiliate.campaign.manage_scoped / affiliate.statement.read_self
- support.conversation.assign / support.conversation.reply
- audit.record.read_scoped / report.export_scoped

Role principles:
- Compose workspace-specific role templates; separate platform workforce roles from tenant roles.
- Separate configuration, operation, approval and audit responsibilities.
- Tenant admins never receive platform-global permissions.
- White-label admins manage assigned brand presentation and delegated operations only.
- Agent visibility follows explicitly approved network edges and fields; no unrestricted recursive visibility.
- Support access is case/queue/purpose-bound, time-limited where practical and audited.
- Auditor access is read-only by default; export requires separate permission and purpose.
- Customer self-service is object-owned and cannot be expanded by changing resource IDs.

## 7. Tenant and membership lifecycle
Proposed tenant states: prospect → provisioning → active → restricted → suspended → offboarding → archived.
Proposed membership states: invited → pending acceptance → active → restricted/suspended → revoked/expired.

Every transition requires an authorized actor, reason, timestamp and audit event. Activation requires applicable legal, security, operational, payment and product gates. Suspension must define treatment of customer access, open transactions, funds, withdrawals, support and statutory retention; it must not silently erase records or strand liabilities. Membership removal revokes grants and sessions within the approved propagation objective. Re-invitation does not silently restore old grants.

Provisioning workflow:
1. Record request, accountable legal entity, intended role and target jurisdictions.
2. Complete due diligence and product-specific approval gates.
3. Create inactive tenant with isolated identifiers and default-deny policies.
4. Invite verified initial owner; require strong authentication.
5. Assign minimum bootstrap permissions; require MFA and recovery setup.
6. Configure legal profile, brands, domains, locales, currencies and data residency.
7. Enable only approved product instances and provider connections.
8. Run isolation, authorization, operations and recovery acceptance tests.
9. Record named approvals and activate through an auditable release event.

## 8. Delegation and privileged access
- Platform operators provision/support tenants only with explicit platform permissions.
- Tenant owners delegate only within their tenant; they cannot create platform roles or change global security policy.
- White-label admins manage assigned brand assets, domains, localized content and allowed product presentation. Payment routing, legal entity, custody and regulated-product settings require separate grants and potentially platform/operator approval.
- High-risk actions require step-up authentication, dual control or four-eyes approval according to risk.
- Break-glass access is time-limited, justified, alerted, narrowly scoped and reviewed after use.
- Impersonation is disabled by default. If approved later, it must be visible, narrow, time-limited, non-financial by default and audited. Prefer delegated support sessions over credential impersonation.

## 9. Tenant isolation across technical layers
Isolation covers more than SQL queries:
- Database rows/schemas/databases according to approved threat and workload model; RLS where appropriate, with non-bypass application roles and safe connection-pool context.
- Cache keys, search indexes, object storage, exports and analytics partitions.
- Queues, scheduled jobs, event topics, webhook deliveries and dead-letter queues.
- Logs, traces, metrics and support tooling; avoid sensitive payload leakage.
- Idempotency keys, rate limits, secrets, encryption keys and provider credentials.
- Backups, restores, data exports, deletion and retention workflows.

Never rely only on caller-supplied tenant IDs. Background events carry authenticated tenant/resource context and are revalidated when consumed. Cross-tenant analytics require explicit privacy controls and approved aggregation.

## 10. Dashboard and workspace access matrix
“Scoped” means limited to assigned tenant, organization, brand, product, queue, customer relationship or network edge.

| Workspace | Read | Operate | Approve | Configure | Export |
|---|---|---|---|---|---|
| Platform Admin | Global metadata and permitted tenant records | Tenant lifecycle under policy | High-risk platform actions with dual control | Global policies/catalog | Audited and purpose-bound |
| Tenant Owner | Own tenant and permitted aggregates | Delegated tenant operations | Assigned approvals only | Tenant settings and memberships | Tenant-scoped |
| Tenant Operator | Assigned operational records | Assigned customer/product workflows | Explicitly delegated approvals | No global security/legal settings | Scoped |
| White-label Admin | Assigned brand/product views | Brand operations | No financial/legal approval by default | Theme, domain, content, allowed product presentation | Brand-scoped |
| Affiliate/Agent | Own and explicitly visible network data | Own campaigns/profile and permitted referrals | No ledger posting or payout approval by default | Limited campaign/profile settings | Own statements |
| Support Agent | Assigned cases and minimum customer context | Conversation/case handling | No financial approval by default | Queue preferences | Case-scoped |
| Finance | Scoped financial records | Reconciliation and permitted finance operations | Dual-control thresholds | Finance workflows within mandate | Audited |
| Compliance/Auditor | Purpose-bound scoped records | Case review; no routine mutation | Formal decisions only where authorized | No product/finance configuration | Controlled evidence export |
| B2C Customer | Own profile, transactions and permitted product history | Own settings and self-service requests | Confirm own sensitive requests | Own preferences | Own records subject to law |

This matrix grants no permissions by itself. Each cell must map to stable permission IDs, resource scopes, workflow conditions and policy tests.

## 11. Financial and sensitive operations
Do not create a broad wallet.manage permission. Viewing available/pending/held/history amounts, initiating a deposit, verifying a provider result, posting ledger, refunding, reversing, reconciling, approving withdrawal, executing payout and changing payment routing are distinct actions.

Where separation of duties is required, one role must not both initiate and approve its own high-risk payout or ledger adjustment. Displayed balance is a projection of authoritative ledger state, not an editable source of truth. Amount/currency, legal owner, funding source, jurisdiction and transaction state are validated server-side. Duplicate, late, failed or out-of-order callbacks must not duplicate postings or release holds incorrectly.

## 12. Audit, privacy and data-subject controls
Audit events include event ID, timestamp, actor, effective subject, tenant/org/brand, action, resource reference, decision, reason, authentication assurance, correlation ID, source and outcome. Never log credentials, payment secrets or unnecessary personal data.

Retention/deletion is defined by data category and jurisdiction. Legal holds and financial/audit retention may override ordinary deletion where required; record basis and scope. Provide access, correction, export and deletion workflows where applicable. Cross-border access and residency require explicit policy and vendor review.

## 13. Threat scenarios and test evidence
| ID | Scenario | Expected control/evidence |
|---|---|---|
| IAM-01 | Client changes tenant ID | Server denies without active membership; no data leak |
| IAM-02 | Cached role survives revocation | Measured revocation objective; protected action denied |
| IAM-03 | Agent guesses another agent/customer ID | Object-level authorization denies |
| IAM-04 | Support opens unrelated customer | Assignment/purpose/step-up policy denies or requires approved workflow |
| IAM-05 | Job consumes forged tenant event | Authenticated provenance and resource ownership checks reject |
| IAM-06 | White-label admin changes payment/legal settings | Separate permission and approval gates deny by default |
| IAM-07 | Tenant suspended during open transaction | Defined safe funds/transaction handling; no silent loss |
| IAM-08 | Export crosses tenant boundary | Export rechecks scope; immutable audit evidence |
| IAM-09 | Platform break-glass used | Alert, reason, expiry, narrow scope and post-use review |
| IAM-10 | Service credential leaks | Audience/scope limits, rotation, revocation and anomaly detection |
| IAM-11 | User belongs to multiple tenants | Context switch does not mix profiles, sessions or resources |
| IAM-12 | Product entitlement revoked | New operations blocked; existing transactions follow domain-specific safe completion |

## 14. Acceptance criteria before implementation approval
- Principal/tenant/membership/resource model approved by architecture and security owners.
- Threat model covers horizontal/vertical privilege escalation, confused deputy, IDOR/BOLA, session/token theft, cache/queue leakage and privileged insiders.
- Automated tests prove cross-tenant denial across API, database, cache, object storage, jobs, webhooks, search and exports.
- Permission matrix is versioned/tested; no undocumented wildcard grants.
- Membership/session revocation has a measured objective.
- Privileged and financial actions have attributable approvals and immutable audit.
- Provisioning, restriction, suspension, offboarding and restore runbooks are tested.
- Privacy, residency, retention and legal holds reviewed per jurisdiction.
- Authentication/recovery localization and accessibility tested.
- Security review and independent penetration test completed before production exposure.

Numeric SLOs, retention periods, MFA details and jurisdictional rules remain open pending threat/workload analysis and accountable approval.

## 15. Open decisions and reviewers
1. One global login across tenants versus isolated identity realms; assess privacy, account linking and legal requirements.
2. Legal-entity-to-tenant and brand-to-tenant cardinalities.
3. OIDC, SAML and SCIM requirements by B2B tier.
4. Workforce identity provider and privileged-access management.
5. KYC/customer identity separation and profile reuse across tenants.
6. Database isolation strategy and RLS-bypass/connection-pool threat model.
7. Support access and break-glass policy.
8. Permission catalog ownership, versioning and emergency revocation.
9. Jurisdiction-specific privacy, retention and cross-border transfer.
10. Measurable revocation, availability and audit durability objectives.

Required reviewers: owner/product, enterprise architecture, application security, IAM, data/privacy, finance, legal/compliance, support operations and SRE.

## 16. Related documents
LOT-PLATFORM-001 (unified B2B2C architecture); LOT-SEC-TM-001 (threat model); LOT-TEN-001 (tenant isolation); LOT-DOM-001 (domain ownership); LOT-API-001 (API contracts); LOT-FIN-POST-001 (financial posting); LOT-QA-001 (quality attributes).

## 17. Change control
Changes to security invariants, permission semantics, tenant ownership or cross-tenant access require a decision-register entry, threat-model impact review and synchronized Persian/English update. Examples are not approved policy.
