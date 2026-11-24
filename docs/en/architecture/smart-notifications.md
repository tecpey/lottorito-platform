# Smart Notification Policy and Delivery Architecture

**Document ID:** LOT-NOTIF-001 | **Version:** 1.0.0 | **Status:** Proposed architecture; no notification runtime/channel provider verified

## 1. Purpose

Provide a policy-governed notification system for service, security, transactional and consented marketing communication across the Lottorito platform. Use the TecPey notification design lessons as a reference pattern—server-owned notification creation, durable inbox/read state, deduplication, secure deep links, preferences, priority and fatigue control—not as evidence that TecPey code or infrastructure has been inspected or can be copied.

## 2. Notification classes

- Security: login/security events, credential changes and account protection.
- Transactional: attributable lifecycle updates for a user-initiated action, where legally and operationally permitted.
- Service: support replies, service incidents, account/document status and operational notices.
- Product/engagement: opt-in education, feature discovery and relevant product updates.
- Marketing: campaigns, promotions and affiliate communications requiring applicable consent and market/channel approval.

Each class has separate eligibility, consent, urgency, retention and delivery rules. Marketing consent must not be bundled with service or security notifications. Legal classification and user rights vary by jurisdiction.

## 3. Core policy: decision before creation

Only an authorized server-side policy decision may create a notification and its delivery outbox record. Domain events are evidence/input; they are not themselves permission to notify.

The policy decision evaluates:
- authenticated recipient and tenant/product scope;
- event authenticity, provenance, relevance and freshness;
- user preferences, language, timezone, quiet hours and channel consent;
- legal basis, suppression lists, age/market restrictions and channel rules;
- priority, urgency, expiry and whether the event is still actionable;
- deduplication identity and pending/in-flight deliveries;
- per-user, per-channel and per-class fatigue budget, including concurrent sends;
- template version, locale completeness and secure destination.

If a guard is unresolved, stale or unavailable, non-essential/marketing notifications fail closed. Security-critical exceptions must be explicitly defined, narrowly scoped and audited.

## 4. Durable notification center

The in-app center is the canonical user-facing inbox:
- server-persisted notification records and read/unread state;
- stable notification ID and idempotency key;
- unread count derived from persisted state;
- cursor pagination and filtering by class/date/product;
- expiry and archive behavior;
- secure deep link resolved and authorized server-side;
- multi-device consistency and real-time refresh without making WebSocket delivery the source of truth;
- accessibility, locale formatting and RTL/LTR rendering.

Client local storage may cache presentation state but must never be the source of truth for notification existence, read state, consent or delivery history.

## 5. Channel delivery adapters

Potential channels include in-app, web push, native mobile push, email, SMS and approved messaging platforms. Each adapter must support:
- provider capability and market availability checks;
- recipient/consent validation;
- locale-aware templates and preview;
- idempotent send request and provider idempotency where supported;
- rate limits, retries, bounded backoff and dead-letter handling;
- provider message ID, accepted/delivered/bounced/failed receipts where available;
- unsubscribe and suppression synchronization;
- credential isolation, rotation and audit.

No provider or channel is selected by this document. Delivery receipts are not proof that a human read or understood the message.

## 6. Priority, relevance and fatigue

Define priority classes (for example critical, high, normal and low) with explicit policy. Do not let a campaign or content score override a security or consent decision.

Fatigue control must:
- count pending and in-flight notifications, not only completed sends;
- be concurrency-safe across workers and channels;
- support per-class and per-channel caps, quiet hours and user-selected frequency;
- collapse repeated state updates into one current notification where appropriate;
- expire stale events and suppress notifications that are no longer actionable;
- reserve narrow emergency paths for defined security/service events;
- expose suppression reason and policy version for audit.

No universal numeric cap is assumed; thresholds require owner approval and measurement.

## 7. Multilingual, accessibility and time behavior

All 12 locales in LOT-I18N-001 require approved templates for every enabled class. Critical security and transactional templates cannot fall back to unreviewed machine translation.

Render timestamps in the recipient's selected timezone and locale; store canonical instants in UTC. Quiet hours use the user's chosen timezone and handle daylight-saving transitions. Respect RTL/LTR, screen readers, concise subject/body structure, text scaling and accessible action labels.

Language preference, notification consent and legal country are separate attributes. Changing language must not silently change consent or market eligibility.

## 8. Security and privacy

- Verify recipient ownership and authorization at creation and at deep-link resolution.
- Do not place secrets, full financial details or sensitive personal data in push previews, URLs or lock-screen text.
- Use opaque, short-lived or server-resolved references in deep links; never trust client-supplied resource IDs.
- Prevent cross-tenant delivery and test account changes, revocation and shared-device cases.
- Minimize payloads, encrypt sensitive records and apply retention/deletion rules.
- Audit preference/consent changes, privileged sends, template approvals and suppression overrides.
- Protect against notification phishing, spoofed sender identity and malicious links.

## 9. Analytics and reliability

Measure eligible, created, suppressed, queued, accepted, delivered, bounced, failed, expired, opened and actioned states only where channel telemetry supports them. Distinguish provider acceptance from delivery and delivery from open/read. Avoid collecting more behavioral data than necessary.

Use transactional outbox or equivalent durable handoff so domain commit and notification intent cannot silently diverge. Consumers must be idempotent. Reconciliation must identify stuck outbox rows, missing receipts, duplicate provider messages and delayed delivery. Notification failure must not roll back a valid financial or product transaction; critical domain events remain durable for later recovery.

## 10. Acceptance scenarios

- A raw domain event cannot create a notification without a policy decision.
- Duplicate and concurrent events create at most one notification per defined deduplication identity.
- Pending/in-flight sends count toward fatigue limits under concurrency.
- Revoked consent and suppression rules prevent eligible marketing sends.
- Stale/non-actionable events expire without sending.
- Unread count and read state remain consistent across devices and retries.
- Deep links re-authorize access and cannot cross tenant boundaries.
- A provider timeout after acceptance does not cause uncontrolled duplicate sends.
- All 12 locale templates pass native review and RTL/LTR/accessibility checks.
- Security/transactional notifications remain distinguishable from marketing and have separate consent handling.

## 11. Related documents

LOT-I18N-001; LOT-COMMS-001; LOT-GROWTH-001; LOT-EVENT-001; LOT-TEN-001; LOT-SEC-TM-001; LOT-FIN-POST-001; LOT-QA-001.

**Status reminder:** proposed policy and architecture only. No notification implementation, push provider, email/SMS gateway or campaign send is verified.
