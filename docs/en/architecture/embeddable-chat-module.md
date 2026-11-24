# Embeddable Chat Module Architecture

**Document ID:** LOT-CHAT-WIDGET-001 | **Version:** 1.0.0 | **Status:** Proposed product and architecture contract; no widget runtime, SDK, API or provider verified

## 1. Purpose and product boundary

Lottorito Chat is a reusable, independently adoptable module—not a UI fragment coupled to one Lottorito application. One governed conversation platform must support: (1) first-party use in Lottorito operator, affiliate/agent and customer experiences; (2) embedding in third-party websites and later native mobile applications; and (3) separate commercialization through documented APIs, integration tooling, lifecycle controls and support boundaries.

The host owns its customer relationship and business workflows; Lottorito owns the chat service contract and platform-side controls. Affiliate & Agent and Lottery can enable Chat independently. Host branding must not erase Lottorito ownership, auditability or technical traceability.

This extends LOT-COMMS-001. It does not select a vendor, approve pricing/SLA, authorize processing in any jurisdiction or claim implementation exists.

## 2. Product surfaces and deployment modes

Keep one conversation domain and policy core behind multiple surfaces:

- First-party Lottorito UI using the same public contracts and authorization rules as external clients; no privileged first-party shortcut.
- Hosted web widget: default embed, preferably an isolated cross-origin iframe loaded by a small versioned bootstrap script. This reduces CSS/DOM collisions and host-page access.
- Web SDK/component: thin developer wrapper around the hosted-widget contract; no second conversation engine or session bypass.
- Native mobile SDK: future capability, outside the first web-widget release, reusing the same session and messaging contracts.
- Headless API: for hosts building their own UI while using Lottorito conversation, routing and delivery services.

Do not execute arbitrary third-party JavaScript in the host page by default. A Web Component is not a security boundary. Keep the default embed sandboxed and cross-origin. Any sandbox relaxation requires a capability-specific threat review.

## 3. Logical architecture and trust boundaries

Separate: (1) chat domain service for conversations, participants, messages, state transitions, assignment and audit; (2) widget configuration service for installation identity, allowed origins, locale, theme, features and config versions; (3) integration control plane for tenant-scoped API clients, credentials, scopes, rotation, revocation, quotas and webhooks; (4) session broker for exchanging trusted host-server assertions or permitted anonymous bootstrap into short-lived scoped sessions; (5) realtime gateway using authenticated WebSocket with SSE/HTTPS polling fallback and cursor-based recovery; (6) agent console/routing; (7) attachment quarantine/scanning/delivery; and (8) audit, policy and privacy-safe analytics.

Trust boundaries include host backend ↔ Lottorito control plane; host browser ↔ widget origin; widget ↔ session/realtime APIs; chat ↔ identity/tenant directory; chat ↔ notifications, knowledge, AI and agent systems. Every boundary needs explicit authentication, authorization, validation, rate limits and observability.

## 4. Tenant, installation and identity model

Proposed hierarchy: Tenant (contractual/data boundary) → product entitlement (independent Chat activation) → registered application/environment → named widget installation → conversation → participants.

A tenant may have multiple applications and installations. Test and production installations are distinct. Client-supplied tenant, product, principal, queue, agent role or scope identifiers never grant authority; the server derives them from the authenticated integration credential and session.

Anonymous visitor identity is opaque and installation-scoped. Linking an anonymous conversation to an authenticated account requires an explicit, server-authorized, auditable flow. Never merge solely on email, phone, IP or browser fingerprint.

## 5. Secure installation and session bootstrap

1. Tenant admin creates an installation and registers exact allowed origins. Wildcards are denied by default; localhost is an explicit development-only exception.
2. Host backend authenticates server-to-server with a tenant-scoped integration credential. OAuth 2.0 client credentials with asymmetric client authentication is a candidate, not an approved choice.
3. Host backend requests a session for a verified principal or anonymous visitor, sending only permitted claims and a unique idempotency key.
4. Lottorito validates entitlement, installation state, origin policy, scopes, principal mapping and rate limits.
5. Lottorito issues a short-lived, audience- and installation-bound session token, returned through the trusted host backend. Long-lived integration secrets never reach browser code.
6. Widget uses the session and connects to realtime APIs. Renewal is explicit; revocation must take effect within a defined and tested bound.

Security invariants:
- Never place client secrets, signing keys, provider credentials or long-lived API tokens in HTML, browser bundles, mobile binaries or public repositories.
- Session tokens are short-lived, narrowly scoped, audience/installation-bound and non-transferable where feasible; define expiry, rotation, revocation and clock-skew behavior.
- Validate exact Origin/Host as defense-in-depth, not as cryptographic authentication. CORS is not authorization.
- Protect bootstrap against CSRF, replay, confused-deputy attacks and cross-tenant principal substitution.
- Audit secret storage, asymmetric signing/key exchange, rotation and emergency revocation.
- postMessage requires exact target origin, strict schema, allowlisted message types and origin validation; never use wildcard target origin for sensitive messages.
- Define CSP, iframe sandbox, frame-ancestors, connect-src, referrer policy and navigation behavior.
- Hidden fields and client-supplied tenant/user/product/locale/queue claims are not authorization.

## 6. API, SDK and compatibility contract

Versioned provider-neutral API resource groups should cover installations/configuration; server-to-server session issuance/revocation; conversations/participants/messages; read cursors, typing/presence and delivery acknowledgements; attachments/download grants; privileged agent operations; webhook subscriptions/delivery/replay; health, usage and quotas.

Contract requirements: explicit versioning and deprecation window; stable errors, correlation IDs, pagination and bounded payloads; idempotency keys for retryable mutations; same key with changed canonical payload returns conflict; at-least-once transport plus deduplication (never promise exactly-once network delivery); monotonic conversation sequence/cursors and reconnect recovery; signed webhooks with timestamp, delivery ID, replay window, key rotation, retry and dead-letter/replay controls; least-privilege scopes separated by operation. SDKs are thin wrappers and contain no privileged business logic or credentials.

## 7. Message and conversation invariants

Every message has immutable tenant, conversation, sender, visibility, creation time, message ID and sequence identity. Customer-visible messages, agent-only notes, system events and AI suggestions are distinct server-enforced types. A host cannot access another installation's conversations without explicit tenant policy and authorization. Browser retries cannot duplicate messages. Realtime is a notification of durable state, not the source of truth; clients recover the canonical timeline by cursor. Ownership and participant changes are audited. Chat text never authorizes account ownership changes, financial approval, payouts, KYC/AML bypass or changes to responsible-use restrictions.

## 8. Embed UX, accessibility and localization

Support responsive desktop/mobile layouts, keyboard-only use, screen readers, focus management, reduced motion, high contrast and accessible status announcements. Avoid trapping host-page focus; open/close behavior must be deterministic.

Support all 12 launch locales in LOT-I18N-001, including RTL/LTR, locale timestamps, plural rules, input direction and mixed-script content. Locale precedence must be documented: installation policy, authenticated preference, explicit user choice, then browser hint. Browser hints never silently override explicit choice. Disclose fallback language before conversation starts.

Theme configuration is restricted to validated design tokens: color, typography scale, radius, spacing, launcher placement and light/dark mode. Reject arbitrary CSS/HTML/script injection. Preserve Lottorito attribution/ownership where contractually required; white-label is a separately approved entitlement, not an implicit widget setting.

## 9. Privacy, data governance and attachments

Define controller/processor roles, purpose, lawful basis, residency, retention, deletion, export and legal hold per market/contract before activation. Minimize host claims and transcript content. Provide tenant-scoped export/deletion with audit evidence. Encrypt in transit/at rest; separate key and privileged-access boundaries by tenant/data class where risk requires. Redact credentials and sensitive values from logs, traces, analytics and AI prompts.

Attachments remain quarantined until scanning/validation complete. Enforce size/type limits, content sniffing, malware scanning, private object storage and short-lived download grants. No transcript reuse for model training or cross-tenant analytics without documented legal basis, appropriate notice/consent and explicit approval. Apply abuse, spam, rate, concurrency, quota and denial-of-service protections per installation and tenant.

## 10. Operations and commercial readiness

Control plane exposes installation health, credential status, allowed origins, usage/quota, webhook failures, configuration version and audit history. Separate sandbox/test from production, provide safe test identities and reproducible integration guides.

Require regional failure handling, reconnect/backoff with jitter, bounded queues, backpressure, durable message writes, attachment isolation, webhook retry/reconciliation and emergency revocation. SLOs, limits, retention, pricing, support tiers and SLA remain TBD pending workload evidence and owner/commercial approval. Do not promise third-party availability before onboarding, support ownership, data-processing terms, security review, metering and version/deprecation policy exist.

## 11. Adversarial acceptance scenarios

Test: cross-tenant and cross-installation ID substitution; expired/revoked/wrong-audience session replay; unregistered, wildcard, hostile-subdomain and null origins; forged postMessage and malformed payloads; secrets leaked into browser source/log/referrer/telemetry; webhook replay/body/signature/timestamp tampering and key rotation; concurrent duplicate message requests and changed-payload idempotency conflicts; reconnect cursor recovery without loss/duplicates; customer access to internal notes/AI hidden data/other-tenant attachments; oversized, malformed, polyglot and malware test attachments; quota exhaustion and connection floods without cross-tenant impact; keyboard, screen-reader, RTL/LTR, mobile, zoom and reduced-motion checks in every release locale.

## 12. Release gates and open decisions

Pilot gates: approve data-processing/jurisdiction scope; threat-model review; prove session/origin security; tenant-isolation tests; message idempotency/reconnect proof; attachment pipeline; accessibility/localization QA; integration documentation; named operational owner and revocation/rollback runbook.

General-availability gates: independent security assessment appropriate to risk; tested key rotation and incident response; support/SLA model; metering/billing policy; export/deletion evidence; API compatibility/deprecation policy; partner onboarding/contracts; capacity and recovery evidence.

Open decisions: authentication mechanism, iframe domain topology, regional hosting/residency, API version policy, attachment types, anonymous identity retention, SDK languages, commercial packaging and support tiers. Record only after evidence and owner review.

## 13. Related documents

LOT-COMMS-001; LOT-API-001; LOT-TEN-001; LOT-SEC-TM-001; LOT-I18N-001; LOT-NOTIF-001; LOT-QA-001; LOT-TECH-ADR-001.

**Status reminder:** proposed architecture and acceptance contract only. No widget, SDK, API, credential flow, provider, security certification or production service is verified.
