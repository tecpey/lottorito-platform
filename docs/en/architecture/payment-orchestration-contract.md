# Payment Orchestration and Provider Adapter Contract

**Document ID:** LOT-PAYMENT-001 | **Version:** 0.1.0 | **Status:** Proposed contract; owner, finance, legal, security and operations review required

## 1. Purpose, scope and authority

This document defines a provider-neutral orchestration boundary for inbound customer payment/collection flows and payment-related refunds where legally and operationally approved. It decomposes the payment target in LOT-PLATFORM-001 and must be read with LOT-WALLET-001, LOT-FIN-POST-001, LOT-PROVIDER-EVAL-001 and LOT-IAM-TENANT-001.

The owner has directed that Lottorito target Iranian and international payment integrations for its first-party B2C tenant and eligible B2B tenants. This is a product requirement, not evidence that a provider, gateway, merchant account, acquiring relationship, licence, legal entity, jurisdiction, bank account or payment flow is available or approved. No provider is selected and no payment runtime or real-money operation is claimed.

This contract does not define customer withdrawals, Affiliate payouts, prize payouts, treasury disbursement or general outbound transfers. Those belong to a separately governed payout domain (LOT-PAYOUT-001). A payment gateway response is not a ledger posting or proof of settlement.

## 2. Design principles and hard boundaries

1. Provider-neutral core; provider-specific protocol, status and payload semantics stay inside versioned adapters.
2. A payment intent, provider attempt, authorization/capture, refund, ledger posting and settlement are separate facts with linked identifiers.
3. Every intent is scoped to tenant, product instance, legal entity/merchant context, jurisdiction, customer, currency and payment purpose.
4. No cross-tenant merchant credential, routing policy, transaction, settlement, fee or reconciliation pooling.
5. Amounts use exact decimal/minor-unit representation and a controlled currency registry; no binary floating point.
6. Client redirects and browser/mobile claims are untrusted. Confirm outcomes through authenticated server-side provider evidence and reconciliation.
7. Duplicate, replayed, delayed, out-of-order or contradictory callbacks cannot create duplicate economic effects.
8. Ambiguous timeout is an unknown outcome, not a failure. Do not blindly retry or route to another provider.
9. Payment authorization/capture is not customer wallet credit; wallet credit occurs only through the controlled posting boundary after the configured evidence and policy gates.
10. No provider or market activation before legal, commercial, security, finance, operational and owner approval for the exact decision unit.

## 3. Provider roles and payment method taxonomy

Classify each counterparty by its actual contractual and technical role; a marketing label such as “gateway” is insufficient.

| Role | Responsibility | Due-diligence focus |
|---|---|---|
| Gateway/technical processor | Checkout/API connectivity and message routing | API semantics, availability, security, data handling, retries |
| PSP/payment facilitator | Merchant onboarding, payment acceptance and/or sub-merchant services | Legal entity, acquiring chain, funds flow, reserves, prohibited businesses |
| Acquirer/merchant bank | Acquiring and settlement relationship | Merchant eligibility, settlement accounts, chargebacks, scheme rules |
| Aggregator | Access to multiple payment methods/providers | Underlying provider identity, routing transparency, liability, portability |
| Bank/open-banking provider | Account-based payment initiation or account information where permitted | Licensing, consent, strong authentication, revocation and data access |
| Local payment network/method | Domestic rails, instant payments, QR, bank transfer or local method | Jurisdiction, currency, settlement finality, reversals and operating windows |
| International card/wallet method | Card or wallet acceptance through an authorized chain | Scheme rules, tokenization, 3DS/SCA where applicable, PCI responsibilities |

Each payment method is separately configured by tenant, legal entity, jurisdiction, currency, customer eligibility, product, amount range and risk policy. “Iranian” and “international” are geographic/market requirements, not interchangeable provider categories. No provider list or compatibility claim is approved by this document.

## 4. Decision unit, merchant context and tenant isolation

Provider evaluation uses the LOT-PROVIDER-EVAL-001 decision unit: product/domain, supplier role, contracting legal entity, jurisdiction, operating model, tenant/deployment, payment purpose, currency and funds-flow model.

For each enabled payment configuration, retain:
- tenant_id, product_instance_id and brand/application context;
- accountable legal entity and merchant/sub-merchant identifiers;
- provider legal entity, role, contract and approved service scope;
- jurisdiction, customer eligibility and permitted payment method;
- supported currency/unit, precision, amount limits and fee schedule;
- settlement destination/beneficiary ownership and settlement currency;
- credential reference, environment, rotation state and access scope;
- routing policy version, risk policy and effective dates.

Tenant admins may configure only explicitly delegated settings. Legal entity, merchant ownership, settlement destination, provider credential, regulated method and routing changes require separate permission and approval. Secrets are isolated by tenant, provider account, environment and purpose; never expose them to browser/mobile clients or reuse a shared master credential.

## 5. Core domain objects

- **Payment Intent:** Canonical request to collect a defined amount for a specific customer, order/purpose, tenant and product.
- **Payment Attempt:** One submission to one provider/method. An intent may have multiple attempts only under controlled retry/failover rules.
- **Provider Session:** Short-lived redirect, hosted checkout, QR, deeplink or tokenized session created by the adapter.
- **Authorization:** Provider/acquirer confirmation that an amount is authorized, where the method supports it.
- **Capture/Collection:** Provider-side request/confirmation to collect authorized or directly paid funds.
- **Refund:** A separately identified request to return all/part of a prior captured payment; not the same as a wallet debit or payout.
- **Provider Event:** Authenticated or otherwise verified external status notification with raw evidence reference and normalized interpretation.
- **Settlement Batch/Line:** Provider/bank evidence of funds settlement, fees, reserves, chargebacks and net amount.
- **Reconciliation Case:** Durable match/exception record comparing intent, attempt, provider events, ledger and external settlement.
- **Payment Method Configuration:** Versioned tenant/legal-entity/method policy and credential reference.

Persist immutable identifiers and relationships. Do not collapse the intent and attempt into one row/state or let provider IDs become globally trusted identifiers.

## 6. Payment intent and attempt lifecycle

Suggested intent states:
- created
- requires_customer_action
- processing
- authorized
- captured
- partially_refunded
- refunded
- failed
- cancelled
- expired
- disputed
- unknown_outcome
- reconciliation_required

Suggested attempt states:
- created
- submitted
- pending
- requires_action
- authorized
- captured
- declined
- failed
- timed_out
- unknown
- reversed

These are normalized candidate states; adapters map provider-specific statuses without losing original status/code, event time, observation time or evidence. State transitions are guarded and monotonic where appropriate, but late authoritative evidence may require an explicit correction/reconciliation transition. Never infer captured from a browser success page.

A payment intent may not be silently repurposed for a different customer, amount, currency, tenant, order or legal entity. Amount changes require cancellation/expiry and a new intent or an explicitly supported amendment with full audit.

## 7. Checkout and customer experience

Support payment-method-specific interaction patterns such as hosted checkout, redirect, embedded controlled fields, QR, deeplink, bank transfer instructions or tokenized recurring consent only after legal/security review.

Prefer provider-hosted entry for sensitive card/account credentials to reduce exposure. Do not store full PAN, CVV, PIN, online banking password or provider authentication secrets. Tokenization does not automatically remove PCI or other compliance obligations; scope must be determined with the acquirer/provider and qualified assessor.

Customer-facing UX must disclose amount, currency, payee/merchant identity, fees, method, expiry, refund conditions and next steps. Localized screens must be accessible and support RTL/LTR. A return URL displays a provisional state only; the server retrieves or receives authoritative provider status before showing paid/credited. Protect return URLs against open redirect and tampering.

## 8. Provider adapter contract

Each adapter implements a versioned interface with explicit capabilities:
- create/initialize payment session;
- retrieve/query payment status by stable provider reference;
- authorize/capture where supported;
- cancel/void where supported;
- request refund and query refund;
- verify webhook signature/authenticity and replay window;
- normalize provider events while retaining raw evidence references;
- retrieve settlement reports or support controlled import;
- map errors, retryability, idempotency scope and rate limits;
- expose capability/version metadata and health.

Adapters must not own wallet balances, commission calculation, customer entitlement, tenant authorization or the canonical ledger. Provider-specific SDKs and payloads are isolated behind anti-corruption mappings. Capability absence is explicit; do not emulate unsupported operations with unsafe sequences.

## 9. Idempotency, callbacks and ambiguous outcomes

Generate a platform operation ID and stable idempotency key for each economic effect. The same logical intent retried to the same provider uses the same provider idempotency scope where supported. Persist normalized request hash, provider account, intent/attempt IDs, first submission, response, event IDs and conflict outcome.

Webhook processing:
1. Receive into a durable, size-limited endpoint.
2. Verify signature/authentication, timestamp/replay window and provider account binding.
3. Store raw event evidence securely before acknowledging where operationally feasible.
4. Deduplicate delivery ID and independently deduplicate economic effect.
5. Resolve tenant/provider account from trusted configuration, not callback-supplied tenant IDs.
6. Fetch provider status when the callback is incomplete, contradictory or not authoritative.
7. Normalize and apply a guarded state transition.
8. Trigger posting only when required evidence and policy conditions are satisfied.
9. Route anomalies to quarantine and reconciliation.

A timeout after submission yields unknown_outcome until status query or settlement evidence resolves it. Do not create a second provider attempt or switch provider merely because the first response is late. Failover is allowed only when non-acceptance is established and the method/provider contract makes retry safe.

## 10. Routing, resilience and provider failover

Routing policy is versioned and deterministic for a given decision context. Candidate dimensions include tenant, legal entity, jurisdiction, currency, method, amount, product, customer eligibility, provider capability, availability, risk and cost.

- Hard legal, contractual, customer-eligibility and security constraints run before scoring or routing preference.
- Provider availability is observed from health signals and verified outcomes; never route into an unapproved provider.
- Circuit breakers, bounded timeouts, backoff and queue isolation protect the platform.
- Retry only with stable idempotency and provider-supported semantics.
- Never blind-failover an ambiguous payment to a second provider.
- Record the chosen provider, alternatives considered, policy version and reason for every routing decision.
- Manual routing override is privileged, time-limited, reasoned and audited.

Routing optimization must not bypass sanctions, merchant category restrictions, geography, transaction limits, responsible-use rules or provider terms.

## 11. Fees, FX, settlement and accounting boundary

Keep distinct:
- customer amount and currency;
- provider-presented amount/currency;
- provider fee, scheme fee, tax and other deductions;
- gross captured amount;
- net settlement amount;
- reserves, rolling holds, chargebacks and refunds;
- settlement currency, date and bank reference;
- FX rate, source, timestamp, spread, fee and rounding.

Never silently convert IRR/IRT, USD or another currency. Currency aliases and display conventions require a controlled registry and explicit conversion rules; internal canonical unit and provider-requested unit must be recorded separately.

A successful capture is not proof of bank settlement. The adapter/provider statement and, where applicable, independent bank statement are reconciled to canonical payment and ledger records. Wallet credit or merchant receivable/liability posting occurs only through LOT-FIN-POST-001 with approved account mapping and evidence. Do not post from a browser redirect or unverified callback.

## 12. Refunds, disputes and reversals

Refund is linked to the original captured payment and constrained by captured/refundable amount, provider policy, time limits, method and legal rules. Partial and multiple refunds must not exceed the eligible amount. Refund request, provider acceptance, refund settlement and customer wallet/accounting effect are separate states.

A refund is not an arbitrary wallet debit, withdrawal or payout. Where the provider cannot return to the original source, an alternative route requires explicit legal, finance, fraud and owner approval with beneficiary verification. Chargebacks/disputes require evidence preservation, deadlines, reason codes, provisional/final liability and reconciliation. Reversing a ledger entry does not prove external money was returned.

## 13. Security, privacy and compliance

- TLS and authenticated server-to-server channels; webhook signature verification and replay protection.
- Secrets in an approved vault/KMS, tenant/account/environment-scoped, least privilege and rotation.
- Do not store or log full card/account credentials, CVV, passwords, tokens or unnecessary personal data.
- Strict schema validation, request size limits, rate limits, bot/abuse controls and anomaly detection.
- SSRF/open-redirect protection for provider URLs, redirects and callback destinations.
- Encryption, access logging, retention, deletion/legal hold and data residency by jurisdiction.
- PCI DSS scope, card scheme rules, 3DS/SCA, privacy, AML/sanctions, consumer disclosure and local payment licensing assessed for the actual operating model.
- Provider sub-processors, data transfers, incident notification, audit rights, business continuity and exit/export terms reviewed before production.
- No regulated market activation from a generic global setting; each jurisdiction and legal entity is independently gated.

## 14. Observability and reconciliation operations

Track payment intent conversion, attempt outcomes, provider latency/error rates, unknown outcomes, webhook lag/signature failures, duplicate events, refunds, chargebacks, settlement variance, fee variance, routing distribution and unresolved cases. Dimensions must be tenant-safe and avoid sensitive data/high-cardinality leakage.

Reconciliation compares:
- platform intent/attempt and canonical provider references;
- authenticated provider events and status queries;
- provider transaction and settlement statements;
- acquirer/bank settlement evidence where applicable;
- ledger postings, refunds, fees, reserves and chargebacks.

Import immutable statement batches; validate source, schema, currency, period and totals; match deterministic references; classify missing, duplicate, late, amount/currency mismatch and unexplained fee; review and post adjustments through controlled finance workflow. Material differences cannot be auto-written off. Keep operator, rule version, evidence, timestamps and sign-off.

## 15. Acceptance and adversarial test matrix

| ID | Scenario | Expected result/evidence |
|---|---|---|
| PAY-01 | Customer tampers with amount, currency, tenant or merchant | Server rejects; intent values are immutable and server-authoritative |
| PAY-02 | Browser return says success but provider reports pending/failed | UI remains provisional; no wallet credit or ledger posting |
| PAY-03 | Duplicate/replayed webhook | Authenticated dedupe; one economic effect and one posting at most |
| PAY-04 | Invalid signature or expired timestamp | Reject/quarantine; alert and audit evidence |
| PAY-05 | Provider timeout after submission | unknown_outcome; status query/reconciliation, no blind retry/failover |
| PAY-06 | Same idempotency key with changed payload | Conflict; no second provider operation |
| PAY-07 | Two providers are configured for same method | Deterministic eligible routing; chosen policy/provider recorded |
| PAY-08 | Provider A outcome is ambiguous | Do not send same payment to Provider B |
| PAY-09 | Tenant A attempts to use Tenant B credentials | Deny; no secret or transaction cross-access |
| PAY-10 | Callback supplies forged tenant/provider account ID | Resolve from trusted mapping; reject mismatch |
| PAY-11 | Partial and repeated refunds | Cumulative refund never exceeds eligible captured amount |
| PAY-12 | Settlement amount differs from captured amount | Reconciliation exception; no silent adjustment |
| PAY-13 | IRR/IRT alias or FX is ambiguous | Reject or require explicit canonical unit/conversion policy |
| PAY-14 | Provider reports captured but bank settlement is absent | Capture and settlement remain separate; exception/aging workflow |
| PAY-15 | Provider credential rotation or compromise | Scoped rotation/revocation; no downtime-induced duplicate payment |
| PAY-16 | Provider is suspended or contract expires | New attempts blocked; in-flight and refund obligations follow approved runbook |

## 16. Open decisions and market activation gates

1. Initial operating legal entity, merchant of record, acquiring model and target jurisdiction(s).
2. Domestic Iranian and international market eligibility, permitted payment purposes and any cross-border restrictions.
3. Exact provider role, legal entity, licence/registration, contract, acquiring chain, settlement bank and funds flow for each candidate.
4. Whether the first release accepts only inbound deposits/collections or also merchant checkout for other product purchases.
5. Supported currencies, canonical IRR/IRT handling, FX, fees, settlement currency and tax treatment.
6. Refund, dispute, chargeback, reserve and settlement finality policy.
7. Customer verification, AML/sanctions, fraud, limits, velocity and step-up authentication.
8. Data residency, PCI scope, 3DS/SCA, tokenization and security-assessment requirements.
9. Provider routing, retry/failover, uptime/latency targets, support escalation and exit/portability.
10. Wallet credit conditions and finance-approved chart-of-accounts mapping.
11. Payment operations roles, reconciliation ownership, dual control and incident response.

Apply LOT-PROVIDER-EVAL-001 separately to each exact provider decision unit. No provider may be selected by brand reputation or a generic country label alone. Obtain documentary evidence from the provider and relevant official registers, review contracts and funds flow, test an authorized sandbox with synthetic data, and secure owner/legal/finance/security/operations approval before production.

## 17. Related documents and change control

- LOT-PLATFORM-001 — unified B2B2C platform architecture.
- LOT-WALLET-001 — wallet domain and balance contract.
- LOT-FIN-POST-001 — financial posting and reconciliation.
- LOT-PROVIDER-EVAL-001 — provider evaluation and RFI standard.
- LOT-IAM-TENANT-001 — tenant identity and authorization.
- LOT-API-001 — API resources and webhook conventions.
- LOT-PAYOUT-001 — future payout and withdrawal contract (separate domain).

Changes to provider trust, routing, funds flow, callback verification, posting triggers, refund behavior or jurisdiction eligibility require an LDR update, threat/finance/legal review and synchronized Persian/English change. This is a Proposed contract, not a provider selection, payment integration, licence or authorization to process real money.
