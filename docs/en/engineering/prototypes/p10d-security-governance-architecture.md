# P-10D — Security, Tenant Isolation, Privacy and Governance Architecture

**Document ID:** LOT-PROT-P10D-001 | **Version:** 0.1.0 | **Status:** Source-neutral architecture proposal; not an implementation assessment or compliance attestation | **Reviewed:** 2026-11-26

## 1. Purpose and assurance boundary

This document defines security and governance controls for the future Lottorito multi-tenant platform and any eventual data migration. It covers platform operators, tenant administrators, white-label operators, affiliates/agents, B2C customers, support, developers, CI/CD, application workloads, workers, payment/provider adapters and migration identities.

This is an architecture baseline, not evidence that controls exist or pass in the current repository, staging or production. No production endpoint, credentials, customer/player/payment data, tenant roster, legal entity, provider contract, jurisdiction, cloud KMS or deployed IAM/RLS configuration was inspected. No penetration test, privacy impact assessment, legal opinion, certification or compliance attestation is claimed. Do not infer legal or regulatory applicability from the product category alone.

## 2. Security principles

1. Resource-centric Zero Trust: network location, internal status, ownership or prior authentication grants no implicit access.
2. Deny by default and least privilege: no matching policy means deny; grants are limited by action, object, tenant, product, environment and time.
3. End-to-end tenant isolation: enforce verified scope across APIs, services, databases, caches, queues, object storage, search, analytics, exports, logs, backups and support tools.
4. Separate authentication from authorization: identity does not imply permission.
5. Explicit trust boundaries: platform, tenant, product/domain, user, financial/legal entity, environment and provider scopes are distinct.
6. Fail closed for protected operations: missing identity, malformed context, policy failure, stale entitlement or unavailable mandatory audit must not silently allow.
7. Verifiable controls: each control needs negative tests, evidence, an owner and an exception process.
8. Minimize data and blast radius.
9. Separate duties across development, approval, release, financial authorization and audit.
10. Preserve immutable financial accountability; privileged access must not silently rewrite posted accounting history.

## 3. Trust domains and principal model

| Domain | Examples | Default authority |
|---|---|---|
| Platform control plane | tenant provisioning, global configuration, platform security | Explicit platform-scoped grants |
| Tenant plane | tenant users, settings and reports | One verified tenant and permitted product scopes |
| Product/domain plane | affiliate, chat, wallet, marketplace, future gaming integrations | Domain-specific actions and objects |
| Financial/legal-entity plane | ledger, commissions, settlements, payment instructions | Narrow finance roles; dual control for high-impact actions |
| User/customer plane | B2C account, profile, wallet view, support conversation | Own resources and approved delegated access |
| Workload plane | APIs, workers, schedulers, adapters, migration jobs | Workload identity with explicit audience and scope |
| Human operator plane | support, SRE, DBA, security, developers | Named individual, just-in-time, approved and audited |
| External provider plane | payment, gaming and identity providers | Per-provider identity; no platform authority |

A platform administrator is not automatically a tenant business operator or finance approver. A tenant administrator is not a platform administrator. Support impersonation is not a normal role and must not silently inherit customer authority.

Each protected request should use a server-verified context containing, as applicable: subject type and immutable ID; actor and delegated actor; authentication strength and MFA/re-authentication time; workload identity, issuer, audience and environment; current tenant membership; requested tenant selector and its validation; product/domain and legal-entity scope; resource and action; purpose and data classification; ownership/relationship; policy version; request/trace ID and time.

Client-supplied tenant IDs, roles, headers, object IDs and JWT claims are inputs to validate, not proof of authority. Never trust a caller to assert its own tenant, role, product, finance status or legal entity. Re-check membership/revocation for long-lived sessions and delayed jobs where stale authorization can cause harm.

## 4. Authorization architecture

### 4.1 Hybrid authorization model

Use RBAC for coarse job functions, ABAC for context (tenant, product, legal entity, environment, data class, transaction state, risk and time), and relationship/object checks for ownership, delegated access, support and affiliate hierarchy where appropriate. RBAC alone is too coarse for a multi-tenant hierarchy. Model grants as scoped tuples: subject + action + resource/domain + tenant/product/legal-entity scope + constraints + validity + approver/evidence.

### 4.2 Policy decision and enforcement

Use the conceptual separation of Policy Administration Point (PAP), Policy Information Point (PIP), Policy Decision Point (PDP) and Policy Enforcement Point (PEP). The PEP must enforce at every protected resource boundary even if the PDP is centralized. A gateway check alone is insufficient. PDP outage, timeout, malformed response or unknown policy version must deny protected operations. If decisions are cached, bind the cache key and TTL to subject, action, object, tenant, relevant attributes and policy version; revocation must invalidate or bound stale permits.

### 4.3 Required checks on every protected operation

- identity authenticated; credential not expired or revoked;
- session/workload audience and environment correct;
- current tenant membership or explicit cross-tenant grant;
- product/domain and legal-entity scope matches resource;
- object ownership/relationship valid;
- action allowed for current resource state;
- step-up authentication, approval or dual control for sensitive actions;
- fields/exports within data-classification permissions;
- mandatory audit obligation can be fulfilled.

Use deny-by-default and consistent server-side enforcement. UI hiding, unguessable IDs, route obscurity and gateway-only checks are not authorization controls.

## 5. Tenant and product isolation

Every tenant-owned resource needs an enforceable ownership boundary, whether via tenant_id, separate schema/database, storage policy or another verifiable mechanism. Product/domain and legal-entity scope are separate dimensions; do not overload tenant_id. Classify data as platform-global, tenant-owned, user-owned, product-owned or intentionally shared.

Legacy shared, null, unknown, conflicted, orphaned and duplicate identities are not canonical scope. Keep them quarantined until an accountable owner adjudicates them with evidence. Never infer that shared means affiliate, lottery, platform-global or another product.

Apply controls across all planes:

- **HTTP/API:** derive tenant context from verified identity and membership; authorize every object/action; reject cross-tenant IDOR.
- **Service-to-service:** authenticate workload identity and constrain audience, tenant set, product, environment and action. Internal network location is not authorization.
- **Database:** for shared-table designs use non-owner runtime roles, least-privilege grants and RLS as defense in depth. Inventory every tenant-owned table and test all operations. Table owners normally bypass RLS; superusers and BYPASSRLS roles always bypass. FORCE RLS changes owner behavior but does not neutralize superuser/BYPASSRLS. Separate migration/admin identities from request-serving roles.
- **Connection pools:** set tenant context transaction-locally and for every transaction. Never leak session-scoped tenant state across pooled requests. Test reuse after success, exception, rollback, timeout and cancellation.
- **RLS policies:** deliberately define USING and WITH CHECK for SELECT/INSERT/UPDATE/DELETE; test reads and writes, missing context, nulls, role inheritance and policy combination. RLS does not cover every operation (TRUNCATE is outside row-policy enforcement); restrict table-level privileges separately.
- **Views/functions:** review SECURITY DEFINER ownership, search_path, grants and row-scope behavior. Do not expose privileged functions that bypass intended checks.
- **Cache:** include verified tenant and relevant authorization/policy dimensions in keys; prevent cross-tenant collisions and stale permits.
- **Queues/events:** classify jobs as global, tenant-scoped or explicitly cross-tenant. Authenticate producer, integrity-protect scope metadata, re-authorize at consumer time, and scope idempotency, retry, DLQ and ordering. A tenant_id field in a message is not authorization proof.
- **Object storage/files:** enforce ownership in authorization and storage policy; prefixes alone are not a security boundary. Authorize signed URLs for the exact object/action and required short lifetime; account for versions, replicas and backups.
- **Search/analytics/export:** apply tenant/product filters at query and materialization boundaries; validate exports and scheduled reports; prevent cross-tenant aggregate leakage.
- **Backups/restores:** treat backup access as privileged cross-scope access. Restrict, encrypt, audit and test tenant-scoped recovery without overwriting live data or exposing other tenants.
- **Support/admin tools:** tenant selection must be explicit and re-authorized; no hidden global bypass. Support access is time-bound, purpose-bound and audited.

Choose shared tables with RLS, separate schemas, separate databases or a hybrid only after evaluating sensitivity, legal/contractual obligations, blast radius, operational capacity, restore granularity, cost and scale. There is no universal best strategy.

## 6. Human identity, sessions and privileged access

- Unique named human accounts; no shared administrator accounts.
- Central identity lifecycle with joiner/mover/leaver, prompt revocation and periodic access review.
- MFA for privileged and sensitive actions; choose factors using threat model, usability, local availability and recovery risk.
- Step-up/re-authentication for credential/MFA/recovery changes, payout destination changes, high-value financial actions, sensitive exports, role grants and privileged support.
- Define inactivity timeout, absolute session lifetime, concurrent-session behavior, refresh-token rotation/reuse detection, revocation propagation and session/device inventory by risk analysis.
- Use secure cookie/session properties and CSRF protection for cookie-authenticated state changes.
- Privileged access is just-in-time, time-bound, ticket/purpose-bound and least-privileged; sensitive production access needs independent approval.
- Break-glass is exceptional: separately protected credentials, narrow scope, short duration, immediate alert, reason/ticket, full audit, post-event review and periodic test.
- Support impersonation must be explicit, justified, visible, narrow and fully audited; read-only by default. High-risk actions are prohibited or separately approved.

## 7. Workload identities, API credentials and integrations

Give each service, worker, scheduler, migration job and external integration a distinct identity; no universal shared service secret. Prefer short-lived, audience-bound workload credentials and native identity federation where supported. If static secrets are unavoidable, scope, store, monitor, rotate and revoke them.

Bind credentials to environment, tenant set, product, audience, permitted actions, expiry and owner. Separate inbound and outbound credentials. Provider responses must never directly grant platform roles or change tenant ownership.

For provider webhooks, verify signatures over the exact raw payload and security-relevant request context, timestamp and replay window as supported. Use constant-time comparison for MAC/signature checks where applicable, deduplicate events and reject stale/replayed messages. API keys are not user sessions; store verifier/hash material where feasible, show the secret once, support rotation/revocation and never log it.

Migration identities are read-only by default for inventory. Separate read and write identities; the write identity remains unavailable until a specific migration plan is approved.

## 8. Secrets, encryption and key governance

### 8.1 Secret lifecycle

Use a designated secrets manager or equivalent protected facility, not source code, plain configuration, tickets, chat, CI logs or developer laptops as a shared secret store. Track owner, purpose, consumers, environment, type, creation, access, rotation, revocation, expiry, recovery and deletion metadata.

Apply least-privilege access at secret/version level; automate provisioning and rotation where feasible; practice emergency revocation; separate secrets across environments, tenants/providers and workloads where risk warrants. Never log plaintext secrets, tokens, private keys, passwords, recovery codes or database connection strings. Scan repository history, build artifacts and logs. Revoke/rotate exposed credentials before considering history rewriting. Keep high-value long-lived credentials out of CI/CD; untrusted pull-request workflows must not access production secrets.

### 8.2 Encryption and key management

Define encryption in transit and at rest based on data classification and threat model. Prefer managed KMS/HSM custody where available and justified; document provider, region, owner, purpose, rotation, access policy, backup/recovery and destruction.

Consider envelope encryption for sensitive fields or tenant-scoped data. Per-tenant keys can improve isolation and cryptographic erasure but increase lifecycle, backup, recovery and operational complexity; do not require them by default without risk assessment. Separate data-encryption keys from key-encryption keys; never store plaintext KEK beside ciphertext.

Rotation must support versioned decryption during transition, re-encryption plan, audit and recovery. Key destruction is irreversible and must respect retention/legal holds and backup lifecycle. Test KMS outage, denied key access, rotation, revoked keys, restore with historical key versions and tenant offboarding. Hash passwords with a suitable adaptive algorithm; never encrypt passwords for later recovery or log them.

## 9. Audit, logging and evidence

For privileged, security-relevant, financial and cross-scope actions, capture: immutable event ID; timestamp and trustworthy time source; actor, subject, workload/client and delegation chain; server-verified tenant/product/legal-entity scope where applicable; action, resource reference, decision and policy version/reason; authentication strength and approval/ticket; request/trace ID, source and outcome; before/after reference or digest where justified (not raw sensitive payload); event schema version and integrity metadata.

Use append-only or tamper-evident storage, restricted writer/reader roles, protected retention and independent monitoring. Hash chaining/signing can detect tampering but does not itself prevent privileged deletion; combine with separate administration, immutable retention/WORM or independent copies where warranted. Tenant administrators must not gain platform-wide audit access. Log denied cross-tenant attempts and privilege changes, but minimize PII and never log secrets, payment credentials, auth tokens or unnecessary message bodies.

Define coverage, retention, deletion/legal hold, export and access review per log class. Security audit, financial ledger and application diagnostics are distinct records; none substitutes for another.

## 10. Privacy and data governance

Before collecting or migrating personal data, document:
- data inventory and classification;
- purpose and necessity for each field and processing activity;
- controller/processor/tenant roles and contractual responsibilities, as determined by counsel;
- data-subject categories and relevant jurisdictions;
- applicable legal authority, transparency/notice and consent requirements where applicable;
- retention, deletion/erasure workflow, legal hold and backup expiry;
- access, correction, export/portability and deletion handling as applicable;
- cross-border transfer, subprocessors, residency and provider dependencies;
- security/privacy incident notification responsibilities and timelines as legally determined.

Do not select a jurisdiction or claim GDPR/PCI DSS/gaming-license compliance without facts and qualified legal/compliance review. Minimize card-data handling using suitable provider tokenization/hosted components; determine actual PCI scope through qualified assessment. Do not store sensitive authentication data or full card credentials unless explicitly permitted and properly scoped.

Deletion must propagate to derived stores, caches, search indexes, exports and providers according to approved policy, while accounting for legal holds, immutable financial records and backup retention. A deletion request does not authorize destruction of records that must lawfully be retained; retain only the required minimum and restrict access.

## 11. Threat model and abuse cases

Maintain a living threat model for each major domain and integration. Analyze STRIDE plus business abuse cases:

| Threat | Required controls and tests |
|---|---|
| Cross-tenant IDOR / tenant-context injection | Verified membership, object checks, RLS/data boundary, negative tests on every route |
| Privilege escalation / role confusion | Scoped grants, deny-by-default, separation of duties, approval and privilege-change audit |
| Compromised service/API key | Unique workload identity, short lifetime, narrow audience/scope, revocation and blast-radius tests |
| Queue/webhook replay or forgery | Signature validation, replay window, deduplication, producer auth, consumer re-authorization |
| Cache/storage/search leakage | Scope-aware keys/policies, exact object authorization, isolation and deletion tests |
| Insider abuse / support impersonation | JIT, purpose-bound access, dual control, visible impersonation and independent audit |
| RLS bypass / pool leakage | Role/ownership audit, deny BYPASSRLS, transaction-local context, pool reuse tests |
| Secret/key compromise | Secret manager, rotation/revocation, KMS policy, incident drill and historical-key recovery |
| Audit tampering / repudiation | Append-only/tamper evidence, independent copies, restricted admin and integrity verification |
| Over-retention / unauthorized transfer | Data inventory, purpose/retention, residency review and deletion tests |
| Noisy-neighbor / resource exhaustion | Per-tenant quotas, concurrency/queue controls, global caps and abuse monitoring |
| Migration identity misuse | Read-only default, approved window, scoped role, query limits, evidence and independent review |

For each threat record trust boundaries, assets, entry points, data flows, abuse cases, assumptions, mitigations, residual risk and owner. Revisit after material changes to tenancy, payments, identity, providers or data flows.

## 12. Security verification and CI gates

Use OWASP ASVS 5.0 as a verification catalogue and risk-tailor applicable requirements. Referencing ASVS does not establish a level or certification. Map each selected requirement to implementation, automated test, manual evidence, owner and exception.

Minimum verification suite:
- authorization matrix tests for every role × action × resource × tenant/product/legal entity;
- negative tests for missing, null, malformed, stale, revoked and forged tenant context;
- cross-tenant object-ID substitution on API, GraphQL, search, export and support paths;
- RLS coverage for every classified tenant-owned table and CRUD path, including owner/BYPASSRLS/SECURITY DEFINER and TRUNCATE privilege review;
- pooled-connection context leakage after commit, rollback, exception, timeout and cancellation;
- cache, queue, DLQ, scheduled worker, signed URL and search-index isolation tests;
- service identity audience/scope/revocation and provider signature/replay tests;
- MFA/step-up, session rotation/revocation, CSRF and recovery-flow tests;
- secret scanning and prevention of exposure in logs/artifacts;
- audit completeness, access restriction, integrity and retention tests;
- KMS/key rotation/revocation/restore tests;
- privacy retention/deletion propagation tests;
- abuse/rate-limit/noisy-neighbor and fail-closed behavior under PDP/IdP/audit outage.

CI should block release on critical authorization bypass, cross-tenant access, secret leakage, unreviewed privilege expansion, missing mandatory audit or failed security regression tests. Exceptions require named owner, rationale, compensating controls, expiry, risk acceptance and review; no undocumented permanent bypass.

## 13. Incident response and governance

Define incident handling for detection, triage, containment, eradication, recovery, communication, evidence preservation and lessons learned. Maintain playbooks for compromised user/session, API key, workload identity, provider signing secret, KMS key, cross-tenant exposure, malicious insider, RLS misconfiguration, audit tampering and privacy incident.

Each playbook identifies decision owner, technical responders, legal/privacy contact, provider escalation, evidence location, credential revocation, tenant/customer communication decision, recovery validation and post-incident review. Do not prescribe legal notification deadlines without jurisdiction and counsel review.

Name control owner, system owner, tenant/data owner, security reviewer, privacy/legal reviewer, DBA/platform operator, finance approver and release authority. Review privileged access, service identities, provider integrations, exceptions, retention and threat model periodically and after material change.

## 14. Acceptance criteria and deliverables

P-10D design is ready for implementation planning only when:
1. trust domains, principal types and scoped authorization are documented;
2. roles are decomposed into explicit actions/resources/scopes;
3. tenant/product/legal-entity ownership and shared quarantine are preserved;
4. API, DB, cache, queue, storage, search, analytics, backup and support have enforceable isolation designs and negative tests;
5. RLS roles, owner/BYPASSRLS behavior, pooled context and privileged functions are covered;
6. human/workload/migration identities and secret/key lifecycle have owners and revocation paths;
7. audit contract, privacy inventory, retention/deletion and cross-border review process are defined;
8. threat model, abuse cases, verification matrix and incident playbooks have owners;
9. unresolved legal, jurisdiction, provider, KMS and operational decisions are explicit blockers;
10. Security, Privacy/Legal, Platform/DBA, Finance and product owners review the source-specific implementation plan.

Required outputs before implementation: security architecture ADR; role/action/scope matrix; data-flow and trust-boundary diagrams; tenant-isolation matrix; RLS/database-role design; workload identity and secret/key inventory; audit event schema; privacy/retention register; threat model; ASVS verification mapping; incident playbooks; exception register and named approvals.

## 15. Non-goals and current status

This document does not implement authentication, authorization, RLS, KMS, audit storage, privacy workflows or CI gates. It does not select a vendor or jurisdiction, establish compliance, authorize production access, approve migration or permit privileged access. No production system was inspected and no credentials or personal data were accessed.

P-10B remains an unexecuted read-only inventory protocol pending explicit owner-approved source scope and authorization. P-10C remains a source-neutral migration framework. P-10D is a source-neutral security/governance design baseline only.

## 16. Research references

- NIST SP 800-207, Zero Trust Architecture: https://csrc.nist.gov/pubs/sp/800/207/final
- NIST SP 800-53 Rev. 5, Security and Privacy Controls (Release 5.2.0 update): https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final
- OWASP Application Security Verification Standard (ASVS) 5.0.0: https://asvs.owasp.org/
- OWASP Authorization Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- OWASP Authorization Patterns Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Patterns_Cheat_Sheet.html
- OWASP Multi-Tenant Application Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html
- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- OWASP ASVS Session Management: https://github.com/OWASP/ASVS/blob/master/5.0/en/0x16-V7-Session-Management.md
- PostgreSQL Row Security Policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- PostgreSQL FORCE ROW LEVEL SECURITY: https://www.postgresql.org/docs/current/sql-altertable.html
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

These references inform design; they do not imply implementation, certification, legal applicability or a security assessment of a deployed Lottorito environment.
