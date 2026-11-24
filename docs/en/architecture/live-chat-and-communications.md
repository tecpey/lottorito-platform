# Live Chat and Customer Communications Architecture

**Document ID:** LOT-COMMS-001 | **Version:** 1.0.0 | **Status:** Proposed architecture; no chat runtime/provider verified

## 1. Purpose and product boundary

Provide a consistent, multilingual support and conversation capability for the three distinct Lottorito experiences: B2B operator, affiliate/agent and end customer. The capability must be independently usable by Affiliate & Agent and Lottery; one product must not require the other to be enabled.

Live chat is a support and service channel, not an implicit financial approval, transaction command channel or substitute for formal account-security verification. Agents must not ask users to send passwords, one-time codes, private keys, full payment credentials or sensitive identity documents through ordinary chat.

## 2. Core capabilities

- In-app and web live chat entry points with persistent conversation history.
- Pre-chat language selection and automatic locale-aware routing.
- Queue, skills, team, priority, business hours, availability and escalation.
- Agent console with assignment, transfer, internal notes, canned responses and supervisor review.
- Asynchronous messaging when no agent is online; clear response-time expectation.
- Secure attachments with type/size limits, malware scanning and controlled retention.
- Conversation tags, issue categories, product context and linked support cases.
- Customer satisfaction and service-quality feedback with abuse controls.
- Searchable, auditable history with retention and access policies.
- Human handoff from an AI assistant; clear disclosure when a response is automated.
- Operational analytics: first response, resolution time, reopen rate, backlog, transfer and satisfaction—segmented by locale, product and tenant where privacy permits.

## 3. Conversation lifecycle

Suggested lifecycle: Created → Triaged → Queued → Assigned → Active → Waiting on customer/third party → Resolved → Closed. Reopen and escalation are explicit transitions. State changes must record actor, timestamp, reason and relevant policy version.

A conversation may be linked to an authenticated account, tenant, product and support case. Such context is server-resolved, scoped and minimized; a client-supplied account or tenant ID must never grant access. Anonymous pre-sales chat remains isolated until the user authenticates and explicitly links the conversation under a safe verification process.

## 4. AI assistant and human control

AI may classify intent, detect language, summarize history, suggest a response, retrieve approved help-center content and route to a team. It must:
- identify itself as automated where required;
- ground answers in approved, current knowledge and show source references to agents;
- abstain or hand off when evidence is missing, conflicting, stale or high risk;
- never promise a payout, approve a financial adjustment, change account ownership, bypass KYC/AML, override responsible-use controls or decide legal eligibility;
- never expose another tenant's conversation or internal notes;
- keep human-only internal notes out of customer-visible responses;
- preserve transcript and source references for quality review under policy.

Human agents retain authority for account actions only through separately authorized, audited workflows. Chat text alone is not authorization.

## 5. Privacy, security and abuse controls

- Apply tenant, product, role and conversation-level authorization on every read/write and attachment download.
- Encrypt transport and stored content; define key ownership and access boundaries.
- Redact secrets and sensitive data from telemetry; warn users not to share credentials.
- Malware-scan attachments, restrict executable formats and use expiring, access-controlled download links.
- Apply rate limits, spam/abuse detection, bot controls and escalation for threats or fraud.
- Define retention, deletion, legal hold and export policies per data class and jurisdiction.
- Audit privileged transcript access, exports, assignment changes and account-linked actions.
- Separate customer-visible messages, agent-only notes, system events and AI suggestions by type and permission.
- Prevent unauthorized transcript use for model training; any secondary use requires documented legal basis, consent where required and owner approval.

## 6. Multilingual service parity

All 12 launch locales in LOT-I18N-001 require:
- language-aware routing and queue coverage or an explicitly disclosed fallback language;
- translated help content and response templates with domain review;
- native QA for automated classification, sentiment/urgency detection and AI responses;
- locale-aware timestamps, date formats and RTL/LTR transcript rendering;
- an escalation route when no qualified agent is available.

A fallback language must be disclosed before the user continues. Financial, legal, security and consent instructions must not be machine-translated on the fly and shown as authoritative without approved content.

## 7. Integration boundaries

- Identity and tenant membership: read only through authorized identity interfaces.
- Affiliate and Lottery domains: expose minimal support context through explicit APIs/events; chat must not become a cross-domain data bypass.
- Finance: read-only, permissioned display of selected references/statuses; no direct journal mutation or payout initiation.
- Notifications: use LOT-NOTIF-001 for conversation assignment, agent reply and SLA events, respecting preferences and channel rules.
- Knowledge/content: retrieve approved localized articles from LOT-GROWTH-001 / help-center publishing workflow.
- External chat/CRM providers: adapter boundary, exportable transcript and migration plan; no vendor selected.

## 8. Acceptance scenarios

- A user cannot read or download another tenant's transcript or attachment by changing IDs.
- An agent can access only assigned/authorized queues and cases; privileged access is audited.
- Offline messages persist and are delivered once to the conversation timeline despite retries.
- Assignment, transfer, escalation, resolution and reopen are auditable.
- AI abstains and hands off for missing evidence and high-risk financial/security/legal requests.
- Internal notes and hidden context never appear in customer-visible messages.
- Language, RTL/LTR, keyboard access and mobile responsive tests pass for all 12 locales.
- Attachment scanning, retention, deletion and export controls pass their tests.
- Service analytics do not leak message content or create uncontrolled personal-data exposure.

## 9. Operational metrics and service policy

Define service hours, priority taxonomy, response/resolution targets, staffing and escalation owners per supported service tier. Numerical SLA commitments remain TBD until capacity and commercial support model are approved. Do not advertise 24/7 human support unless staffing evidence supports it.

## 10. Related documents

LOT-I18N-001; LOT-NOTIF-001; LOT-GROWTH-001; LOT-TEN-001; LOT-SEC-TM-001; LOT-API-001; LOT-QA-001.

**Status reminder:** target architecture only. No chat provider, live agent operation or AI support integration is verified.
