# Lottorito Lottery Product Requirements

**Document ID:** LOT-LOT-PRD-001 | **Version:** 0.1.0 | **Status:** Proposed; product-owner, legal and operator approval required  
**Scope:** Independent Lottery product domain; global product direction  
**Evidence date:** 24 November 2026

## 1. Purpose and positioning

Define the product requirements for a provider-neutral Lottery infrastructure domain that can be adopted independently, combined with Affiliate & Agent through explicit contracts, or exposed through APIs and white-label experiences.

Lottorito is the technology platform in this model. It must not be implicitly described as the licensed lottery operator, game owner, ticket issuer, payment institution, custodian, or prize guarantor. Those roles belong to the legally authorized operator, supplier, payment provider, or other contracted party, as applicable.

This document defines a target product, not shipped functionality, a launch authorization, a provider commitment, or legal advice.

## 2. Product boundaries and terminology

The word “Lottery” covers materially different operating models. Each game and market must be classified before configuration or sale.

- **Draw-based lottery:** entries are accepted for a scheduled draw and evaluated against an authoritative result.
- **Instant / scratch-style lottery:** outcome is determined through a separately controlled game mechanism; it is not equivalent to a scheduled draw.
- **Fixed-odds number game:** payout may be determined by a published payout table and selected bet type rather than a shared prize pool.
- **Pool / pari-mutuel game:** prize allocation depends on the eligible pool and applicable rules.
- **Results/data service:** supplies catalog, schedules, results, jackpots or historical data; does not necessarily sell tickets or operate games.
- **Ticketing / transaction provider:** accepts or issues entries and provides authoritative transaction references and ticket state.
- **Turnkey / managed platform:** may combine several capabilities, subject to contract, licensing, certification and responsibility boundaries.

These categories are not interchangeable. Product configuration must record the model and its source of authority.

### Explicit exclusions from this domain

Sportsbook, live betting, casino, poker, slots, e-gaming, peer-to-peer games and social casino are not Lottery features. They require separate product domains, risk assessments, provider contracts, legal classification and release approval. A shared identity or ledger foundation does not make their rules or balances interchangeable.

## 3. Users and operating actors

- **Platform operator:** governs the Lottorito platform, tenants, global controls and technical operations.
- **Licensed business operator / tenant:** owns the market-specific commercial operation and its regulatory responsibilities.
- **Lottery operations manager:** configures approved games, draw calendars, sales windows, limits and operational workflows.
- **Finance and reconciliation operator:** reviews settlements, exceptions, prize liabilities and financial reports.
- **Compliance / risk officer:** manages market eligibility, controls, evidence, alerts and escalations.
- **Customer / player:** uses an operator-authorized experience where legally eligible.
- **Provider:** supplies game content, ticketing, results, payment, identity, location or other contracted services.

The same organization may hold more than one role, but permissions and accountability must remain explicit.

## 4. Product goals

1. Support independently deployable Lottery capabilities without requiring the Affiliate product.
2. Normalize heterogeneous provider contracts behind versioned adapters.
3. Preserve the full lifecycle and provenance of a game, draw, order, ticket, result, claim and settlement.
4. Prevent duplicate ticket issuance, duplicate financial effects and silent result mutation.
5. Make market, operator, provider and game eligibility enforceable before a transaction.
6. Support audit, reconciliation, operational review and customer transparency.
7. Allow a tenant to use an external operator/provider while retaining Lottorito's platform-level control and traceability.

## 5. Non-goals and release exclusions

Unless separately approved, the first Lottery release does not assume:

- Lottorito itself holds an operating license or runs a consumer lottery.
- Direct custody of customer money, banking, payment processing or payout execution by Lottorito.
- A specific provider, exclusive supplier, signed commercial agreement or available sandbox.
- Universal access to every game or country.
- Automated winner approval or irreversible prize payment without authorized controls.
- Cross-tenant or cross-product pooling of tickets, funds, liabilities or prize balances.
- Prediction, guaranteed returns, or claims that historical number statistics improve winning probability.
- Casino, sportsbook, poker, slots, live casino or other non-Lottery gaming.

## 6. Core capability requirements

### 6.1 Market, operator and product eligibility

The platform must support a versioned eligibility policy evaluated before registration, browsing where required, ticket creation, payment authorization and ticket issuance. Inputs may include tenant/operator authorization, game availability, customer residency, verified age, current location, sanctions and other jurisdiction-specific restrictions.

- Deny by default when required eligibility evidence is missing, stale or contradictory.
- Record the policy version, decision, evidence references, timestamp and reason code.
- Support market-specific allow/deny lists and emergency suspension.
- Re-evaluate at transaction-critical points; a prior browsing decision is not a purchase authorization.
- Do not infer legal availability from provider catalog presence.

### 6.2 Game catalog and configuration

A normalized catalog should represent game identity, operator, provider, jurisdiction, game model, currency, ticket structure, number pools, bonus fields, price, payout model, draw schedule, sales cutoff, rules version, publication status and effective dates.

Provider-specific fields must be retained as mapped extension data with provenance. Unknown fields must not be silently discarded where they affect ticket validity, pricing or settlement.

Configuration changes require authorization, effective-time rules, version history and audit records. Existing tickets remain bound to the applicable rules version.

### 6.3 Draw lifecycle and schedule

Represent scheduled and irregular draws with explicit time zone, scheduled instant, sales close, operational status and provider references. Daylight-saving transitions must not create ambiguous draw identities or duplicate cutoffs.

A proposed draw state model is:

`draft → scheduled → sales_open → sales_closed → awaiting_result → provisional_result → confirmed_result`

Exceptional states include `suspended`, `cancelled`, `postponed`, `result_disputed` and `corrected`. The actual allowed transitions are game/provider-specific and must be defined in an approved state machine.

### 6.4 Order and ticket lifecycle

A ticket/order must have a Lottorito identifier, tenant, operator, customer reference, game and draw, rules version, selections or opaque provider-issued selection reference, stake/price, currency, idempotency key, timestamps and provider correlation identifiers.

A proposed transaction lifecycle:

`created → eligibility_checked → price_locked → payment_pending → provider_submission_pending → accepted`

Alternative terminal or exception states include `rejected`, `payment_failed`, `submission_unknown`, `cancelled`, `refunded` and `expired`.

- Do not report a ticket as accepted until authoritative acceptance is established.
- Treat timeout after provider submission as an unknown outcome, not an automatic failure. Query/reconcile before retrying.
- Use a stable idempotency key and provider-supported idempotency or reference lookup. Never blindly resubmit an uncertain purchase.
- Preserve the immutable accepted ticket snapshot and provider receipt/reference.
- Define cancellation/refund eligibility from the applicable game and operator rules; do not assume a universal refund right.

### 6.5 Results ingestion and verification

Results must carry source provider, source event/result ID, game and draw identity, observed/published times, received time, result status, raw payload reference or protected evidence, normalization version and integrity metadata.

- Distinguish provisional, confirmed, corrected, withdrawn and disputed results.
- Preserve every revision with before/after values, source, reason and timestamps.
- Never overwrite a confirmed result without a traceable correction event.
- Define the authoritative source hierarchy per game and operator.
- Reconcile provider feeds with official/operator sources where required.
- Missing, late or contradictory results must create visible operational exceptions, not fabricated outcomes.

### 6.6 Ticket validation, winner calculation and claims

Ticket validation must use the exact game rules version, draw identity, accepted ticket snapshot and authoritative result revision. The calculation must be deterministic and reproducible.

Winner calculation produces a result record; it does not by itself authorize a claim or payout. Claim eligibility, identity checks, deadlines, withholding, documentation, review and approval depend on jurisdiction and operator policy.

A prize claim must retain the ticket, draw, result revision, calculation version, gross amount, currency, deductions/withholding where applicable, net amount, claim status, evidence references, reviewer actions and settlement reference.

### 6.7 Settlement and financial boundaries

Lottery financial records must be distinct from Affiliate commissions and promotional credits. Any cross-product transfer requires an explicit, approved, auditable transaction contract.

- Use exact decimal/fixed-precision amounts and explicit currency.
- Model customer payment, provider settlement, operator revenue, prize liability, prize payable, refunds, fees and adjustments as distinct economic events/accounts as applicable.
- Use immutable double-entry journal postings; never mutate a balance as the source of truth.
- Link every posting to its source event, economic effect, order/ticket/claim, provider statement and rule version.
- Support idempotency, reversals, reconciliation, maker-checker controls and exception queues.
- Do not treat provider-reported balances as Lottorito ledger balances without reconciliation and an approved accounting mapping.
- Keep payment authorization/capture/refund and prize disbursement behind authorized payment-provider contracts and operator controls.

## 7. Cross-cutting requirements

- **Tenant isolation:** tenant context comes from authenticated membership or machine identity and is enforced across APIs, workers, caches, files, reports and support tooling.
- **Authorization:** least privilege, role separation and sensitive-operation step-up/dual control.
- **Security:** secrets outside source control, signed/authenticated webhooks, replay protection, rate limits, payload validation, encryption and auditable privileged access.
- **Privacy:** data minimization, purpose limitation, retention/deletion policy and restricted access to identity and transaction evidence.
- **Responsible operation:** configurable limits, cooling-off/self-exclusion and customer-protection controls where required by the market and operating model.
- **Localization:** language, currency, number format, local calendar if required, time zone and jurisdiction-aware copy.
- **Availability:** explicit provider health, stale-data and degraded-mode states; no silent fallback to an unverified source.
- **Observability:** correlation IDs across customer action, Lottorito transaction, provider request, result, ledger and settlement.

## 8. API and event contract direction

The canonical API should expose versioned resources rather than leak provider schemas. Candidate resource families:

- `markets`, `operators`, `eligibility-decisions`
- `games`, `game-rules-versions`, `draws`, `sales-windows`
- `orders`, `tickets`, `ticket-validations`
- `results`, `result-revisions`, `winner-calculations`
- `prize-claims`, `settlements`, `reconciliation-cases`

Candidate events include `TicketSubmissionRequested`, `TicketAccepted`, `TicketRejected`, `DrawStatusChanged`, `ResultPublished`, `ResultCorrected`, `TicketValidated`, `PrizeClaimOpened`, `PrizeApproved`, `SettlementReceived` and `ReconciliationExceptionRaised`.

Names are illustrative, not approved schemas. Contracts must define producer, consumer, tenant scope, event identity, occurrence/receipt/processing times, schema version, idempotency semantics, ordering expectations, signature/authentication, retention and replay behavior.

## 9. Operational controls and exception handling

Provide queues and workflows for: provider outage; unknown purchase outcome; duplicate or mismatched ticket; late/missing result; result correction/dispute; schedule change; eligibility evidence failure; settlement variance; unclaimed/expired prize; refund exception; and suspicious or unauthorized activity.

Every exception must have severity, owner, state, timestamps, evidence, permitted actions and a complete audit history. Manual override must be permissioned, reason-coded and independently reviewable.

## 10. Acceptance criteria for a first approved release

A release candidate is not acceptable until the selected market, operator and provider model are approved and the following are demonstrated in a controlled environment:

1. A tenant cannot access another tenant's games, customers, tickets, results, claims or financial records.
2. An ineligible customer or unavailable game cannot proceed to ticket issuance.
3. A retry or duplicate event cannot create a second ticket or financial effect.
4. An uncertain provider submission is reconciled before any retry.
5. A ticket can be reconstructed from its accepted immutable snapshot and rules version.
6. A result correction creates a revision and recomputation trail; it does not erase history.
7. Winner calculation is deterministic and testable against approved fixtures.
8. Claim approval and payout authorization are separated and auditable.
9. Ledger entries balance per currency and reconcile to provider/operator statements.
10. Provider outage, stale results, late results and settlement variance are visible and actionable.
11. Security, privacy, market eligibility and responsible-operation controls pass documented tests.
12. English and Persian requirements, examples, status labels and acceptance criteria remain semantically equivalent.

## 11. Open decisions — no assumptions permitted

- Initial commercial operating model: software supplier, platform provider, managed service, or another structure.
- First market and the legal entity/operator responsible there.
- Whether the first release is data/results only, ticketing orchestration, or a broader operator platform.
- Initial game types and game-rule ownership.
- Provider shortlist, API documentation, sandbox, certification, SLAs and commercial terms.
- Customer identity, age, residency and geolocation evidence requirements.
- Payment, refund, prize claim and payout responsibilities.
- Prize accounting, taxes, unclaimed prizes, currency conversion and reconciliation rules.
- Responsible-play and customer-support obligations.
- Data residency, retention, RPO/RTO and operational support model.
- Whether and how Lottery connects to Affiliate; no shared balances or automatic commission entitlement is assumed.

## 12. External reference points

These sources inform the requirements; they do not certify Lottorito or establish a provider relationship.

- [UK Gambling Commission — Lottery sector guidance](https://www.gamblingcommission.gov.uk/licensees-and-businesses/sectors/sector/lotteries)
- [UK Gambling Commission — Licensing requirements](https://www.gamblingcommission.gov.uk/licensees-and-businesses/guide/page/licensing-requirements)
- [World Lottery Association — Code of Conduct](https://www.world-lotteries.org/volumes/downloads/Download_Center/Legal/Code_of_Conduct/202103_EN_WLA_Code_of_Conduct.pdf)
- [Lottevo — API reference (results/data service example)](https://lottevo.com/docs/reference)

## 13. Change control

This is a proposed product requirements document. Product-owner approval, legal review for the selected market, operator responsibility mapping, provider due diligence and architecture review are required before implementation scope is baselined.
