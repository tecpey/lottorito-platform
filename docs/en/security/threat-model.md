# Lottorito Security Threat Model

**Document ID:** LOT-SEC-TM-001 | **Version:** 0.1.0 | **Status:** Proposed baseline; requires security, product and owner review

## 1. Scope and limitations
This is a system-level threat-model proposal for the intended global, multi-tenant Affiliate & Agent and Lottery platform. It is not a penetration test, security audit, certification, legal assessment or evidence that controls exist. Validate every control against the eventual implementation and deployment.

Objectives: confidentiality, integrity, availability, tenant isolation, financial correctness, auditability, privacy, provider resilience and safe operation across jurisdictions.

## 2. Assets
Protect tenant identities, memberships, roles, API credentials and sessions; affiliate/agent hierarchy, campaigns, attribution and commission data; Lottery catalogs, orders, tickets, result evidence, claims and settlement records; ledger entries, account mappings, reconciliation files and approval evidence; personal data and support/audit records; provider credentials, webhook secrets, signing/encryption keys and deployment secrets; source code, build artifacts, CI workflows, dependencies, backups and telemetry.

Classify data before implementation. Do not assume collection of identity documents, payment credentials or sensitive customer information is authorized. Minimize collection and establish legal basis and retention first.

## 3. Principals and trust boundaries
Principals: end users, affiliates/agents, tenant administrators, Lottorito platform operators, support staff, workers, partner/provider systems, deployment identities and third parties.

Boundaries: public client/API edge; authenticated user/tenant services; tenant services/shared control plane; application/database/cache/object storage/queue; provider callbacks/outbound APIs; worker/cron/event replay; support/admin/break-glass; CI/CD/repository/artifact registry/runtime; backup/analytics/observability/export.

Every boundary crossing is an authorization and validation point. Network location alone is not identity.

## 4. Threat register (STRIDE and business abuse)

| Area | Threat | Impact | Required response |
|---|---|---|---|
| Identity | Credential stuffing, session theft, weak recovery, MFA fatigue | Account takeover | Suitable MFA/passkeys, rate limits, session revocation, secure recovery, anomaly detection |
| Authorization | IDOR/BOLA, privilege escalation, confused deputy | Cross-user/tenant access | Deny-by-default object authorization; verify membership and action scope on every request |
| Tenant isolation | Tenant spoofing, missing scope in query/cache/job/export | Data leakage or financial crossover | Trusted context, mandatory scope, isolation tests and database constraints |
| Agent hierarchy | Parent/attribution tampering, unauthorized downline visibility | Commission fraud/privacy breach | Server-authoritative graph rules, immutable attribution history, scoped queries and audit |
| Financial integrity | Duplicate callbacks, races, direct balance mutation, replay | Duplicate/incorrect economic effects | Immutable ledger, unique economic-effect key, atomic posting, reconciliation and reversals |
| Provider integration | Forged webhook, replay, leaked secret, malformed payload | Fraud or incorrect ticket/result/posting | Signature verification, timestamp/nonce window, idempotency, schema validation, rotation |
| Lottery lifecycle | Result manipulation, ticket substitution, claim fraud | Incorrect result/prize handling | Independent evidence, versioned result records, dual control for exceptional correction |
| API abuse | Enumeration, scraping, resource exhaustion | Exposure or outage | Per-tenant/principal quotas, bounded pagination/queries, abuse monitoring |
| Support/admin | Insider misuse, excessive support access | Sensitive-data/financial compromise | Just-in-time access, reason/ticket, approval, time limit, redaction, immutable audit |
| Worker/queue | Lost tenant context, poison message, duplicate execution | Data crossover or repeated side effect | Validated job envelope, explicit tenant context, idempotent handlers, DLQ/replay controls |
| Supply chain | Compromised dependency/action/runner/artifact | Platform compromise | Pinned dependencies/actions, provenance, isolated secrets, scanning, protected releases |
| Data lifecycle | Backup exposure, over-retention, unsafe export | Privacy/regulatory impact | Encryption, access separation, retention/deletion, export audit, restore tests |
| Availability | DDoS, provider outage, queue backlog, database exhaustion | Service disruption | Layered limits, circuit breakers, backpressure, capacity alarms, tested recovery |
| Localization | Wrong jurisdiction/currency/time policy | Legal or financial error | Explicit jurisdiction/currency context; never decide legal eligibility from geolocation alone |

## 5. Tenant isolation
Authenticate a principal, then resolve tenant access through authoritative membership or machine-connection records. Never trust tenant, agent, account or product identifiers supplied by a browser/partner without server-side authorization. Make tenant scope mandatory in data-access APIs. Apply scope to databases, replicas, caches, search, object storage, exports, analytics, logs and background jobs. Use tenant-aware unique keys and relationships where appropriate.

PostgreSQL row-level security may provide defense in depth, not replace application authorization. Define safe connection-pool context reset and test transaction boundaries. Choose pool/bridge/silo according to threat, contract, scale and regulation; no topology is pre-approved.

Negative tests must prove tenant A cannot read, mutate, infer, export, cache-hit, enqueue or receive tenant B data/events. Platform support access uses explicit audited break-glass workflows, never silent impersonation.

## 6. API and webhook security
Use TLS and modern edge protocol policy. Separate credentials and scopes by principal, integration and environment. Enforce object- and function-level authorization on every endpoint. Validate content type, schema, size, encoding, pagination and business invariants. Rate limit by tenant, principal, credential, IP/risk and expensive operation.

Webhook signatures cover raw body and relevant metadata; use key IDs, rotation, constant-time comparison, timestamp tolerance and replay protection. Acknowledge only after durable receipt; process asynchronously with idempotency and observable retries. Never expose stack traces, secrets or cross-tenant existence signals.

## 7. Financial and high-risk controls
Separate calculation, posting, approval, reconciliation, payout initiation and payout approval. Apply maker-checker to configured high-risk actions, amount/velocity limits, immutable audit, reason codes and reconciliation. A client-side balance or partner callback alone cannot authorize value transfer.

This model does not approve custody, payout, prize disbursement or regulated payment operations.

## 8. Secrets and cryptography
Store secrets in an approved secret manager; never commit or expose them in logs, prompts, tickets or client bundles. Separate development, test, staging and production credentials. Use envelope encryption and managed KMS/HSM-backed controls where justified; define key ownership, rotation, revocation, backup and recovery. Hash passwords with a current memory-hard scheme and vetted library. Encrypt sensitive data in transit/at rest, classify fields and minimize retention. Separate signing keys from application runtime where feasible. Define emergency rotation/revocation before provider onboarding.

## 9. Privacy and data governance
Per activated market, define data inventory, purpose, lawful basis, subject rights, retention/deletion, residency, cross-border transfer, subprocessors and breach notification. Use synthetic data in development/test. Mask or tokenize personal identifiers in logs/analytics. Do not collect identity documents or payment credentials until product and legal need is approved.

## 10. Secure development and supply chain
Threat-model material features before implementation. Require peer review and protected branches when repository controls are approved. Pin/review dependencies, build actions and container bases; generate and retain an SBOM. Scan source, dependencies, secrets, containers and infrastructure configuration. Sign/attest artifacts where supported. Separate build and deployment permissions. Review backward-compatible migrations and test rollback/forward-fix. Keep production data out of developer environments.

## 11. Logging, detection and incident response
Security logs record actor/service, tenant scope, action, target reference, decision, outcome, timestamp, correlation ID and source context—without secrets or unnecessary personal data.

Alert on cross-tenant denial patterns, privilege changes, unusual exports, webhook signature failures, replay conflicts, posting anomalies, reconciliation breaks, credential abuse and unusual support access.

Prepare runbooks for account takeover, tenant data exposure, provider compromise, ledger integrity incident, key leakage, ransomware, data loss and outage. Include containment, evidence preservation, notification decision, recovery, post-incident review and control improvements. Test backup restoration.

## 12. Minimum verification matrix
Before a production-readiness claim, require tenant isolation tests across APIs/DB/cache/storage/queues/analytics/support; object/function/field authorization tests; webhook signature/replay/timestamp/duplicate/key-rotation tests; concurrent financial idempotency, ledger balance and reversal tests; maker-checker/audit tests; secret scanning and dependency/SBOM evidence; backup restore and disaster-recovery exercise; rate-limit/abuse/resource-exhaustion tests; privacy retention/deletion/export tests; and independent penetration test/remediation evidence appropriate to risk and market.

## 13. Risk acceptance and open decisions
Every residual high/critical risk needs a named owner, rationale, compensating control, expiry/review date and explicit acceptance. Open decisions: initial jurisdictions, identity assurance, support model, data residency, retention, KMS/HSM design, isolation topology, incident notification duties, provider trust requirements and payout/custody boundary.

This document is not a certification or proof of implemented security controls.
