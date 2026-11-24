# Lottorito Lottery Product Requirements

**Document ID:** LOT-LOTTERY-001 | **Version:** 0.1.0 | **Status:** Proposed discovery baseline; not approved for implementation or launch

## 1. Purpose and boundary
Define a provider-neutral Lottery domain adoptable and commercializable independently of Affiliate & Agent. Integration with Affiliate, if any, uses explicit versioned contracts; neither domain depends on the other's business rules or availability.

This is a discovery baseline, not authorization to operate lotteries, offer gambling, accept stakes, custody funds, award prizes or enter any market. Each jurisdiction and product mechanic requires separate legal, compliance, provider, finance and owner approval.

## 2. Intended outcomes
- Authorized operators configure a permitted catalog of provider-backed products.
- Customers receive accurate availability, rules, schedules, price/currency, limits and responsible-use information approved for their market.
- Orders and ticket intents are traceable and reconciled to provider-confirmed states.
- Draw results are ingested and verified from authoritative provider sources.
- Result publication, ticket validation, prize claims, settlement records and support are auditable.
- Operator, customer and partner workflows are exposed through secure APIs and appropriate interfaces.
- Provider portability and tenant isolation are preserved.

## 3. Personas and authorization
- **Platform operator:** governs platform configuration, provider certification records, security and tenant lifecycle; no unrestricted tenant data access.
- **Tenant/operator admin:** manages only its permitted products, provider connections, market settings, limits, staff and reports.
- **Operations/draw reviewer:** monitors orders, callbacks, draw states, exceptions and reconciliation; privileged actions are audited and may require dual control.
- **Finance reviewer:** reviews statements, liabilities, adjustments, claims and settlement; cannot silently change results or posted ledger entries.
- **Customer:** sees only their eligible orders, ticket status, published results and claim status.
- **Provider system:** external authority only for fields and states defined by its contract; all data requires authentication, validation and reconciliation.

Authorize every API, UI, worker, export and support boundary. Resolve tenant context from authenticated membership or machine identity, not a client-supplied tenant ID alone.

## 4. Capability groups

### 4.1 Catalog and configuration
Maintain canonical product/provider identifiers and tenant-facing metadata. Configure market availability only after recorded approval. Version provider rules, game mechanics, schedule, price, currency, sales cut-off and limits with effective periods and provenance. Block offering when approval, provider health, rules version or required configuration is absent or expired.

### 4.2 Order and ticket lifecycle
Distinguish an order request from a provider-confirmed ticket. Proposed internal states:

DRAFT → VALIDATION_PENDING → SUBMISSION_PENDING → ACCEPTED / REJECTED / UNKNOWN → CONFIRMED / CANCELLED / EXPIRED

Actual provider states may differ. Do not call an order a valid ticket before required provider confirmation. UNKNOWN is mandatory for timeouts where the provider may have accepted the request; resolve by idempotent query/reconciliation, not blind resubmission.

Record tenant, customer reference, provider, product/rules version, draw, amount/currency where applicable, client request identity, provider order/ticket IDs, timestamps, status history, provenance and correlation IDs. Minimize sensitive personal data.

### 4.3 Draws and results
Model scheduled, open, sales-closed, draw-pending, result-pending, published, corrected, cancelled and disputed as governed states. Never infer results from unofficial or unverified messages. Preserve source identity, source event time, receipt time, raw evidence reference, normalization version, verification, reviewer and correction history. Corrections append a new fact; they never overwrite published evidence. Bind each result to provider, product, draw ID, rules version and market.

### 4.4 Validation, claims and settlement
Make ticket validation reproducible against applicable provider rules and verified result version. Prize entitlement, claim eligibility, identity checks, deadlines, taxes, payout route and unclaimed prizes are jurisdiction/provider-specific and require approval. Distinguish claim submitted, under review, approved, rejected, expired, settled and disputed as applicable. Reconcile provider liabilities/statements to orders, outcomes, claims and postings. Never create entitlement from an unverified result or client assertion.

### 4.5 Operations and communications
Provide exception queues for unknown submissions, duplicate callbacks, result conflicts, stale feeds, unmatched statements and disputed claims. Notifications are idempotent and based on verified transitions. Customer history distinguishes submitted, provider-confirmed, rejected, cancelled and unresolved. Operator views expose provider health, stale data, reconciliation gaps and privileged actions.

## 5. Shared platform integration
Lottery may consume shared identity, tenant, policy/configuration, API gateway, event processing, notifications, audit, observability and finance. Shared capabilities do not imply shared business rules or pooled balances.

Any Lottery–Affiliate integration must define qualifying event, attribution evidence, applicable consent/legal basis, event version, delivery guarantees, correction semantics and economic effect. Ticket creation/purchase alone implies no referral or commission entitlement.

## 6. Non-functional requirements
- Isolation across APIs, workers, caches, storage, analytics, exports and support.
- Idempotency for submission, callbacks, results, claims and postings; explicit UNKNOWN state and reconciliation.
- Availability objectives set only after business impact and provider dependency are assessed.
- Append-only lifecycle audit with actor, timestamps, source, reason, correlation and rule versions.
- Authenticated provider channels, secret management, replay protection, least privilege, encryption, rate limits and threat modeling.
- Data minimization, retention and access/export/deletion handling as legally applicable; regional review.
- Locale, timezone, calendar, currency and number formats must not alter canonical events or amounts.
- Accessible journeys, clear errors, no dark patterns or misleading urgency.
- Provider-specific schemas stay in adapters; core uses canonical contracts.

## 7. Future implementation acceptance criteria
1. Cross-tenant access to catalog, orders, tickets, claims, reports and provider secrets is prevented.
2. Duplicate/replayed messages create no duplicate tickets, claims, notifications or economic effects.
3. Timed-out submissions remain UNKNOWN until provider query/reconciliation resolves them.
4. Confirmed tickets link to provider identity and exact product/rules/draw version.
5. Result publication requires configured source verification and recorded authorization.
6. Corrections preserve original results and full audit trail.
7. Financial records balance per currency and reconcile to provider statements.
8. Every lifecycle transition is authorized, observable and concurrency-tested.
9. English and Persian customer/operator content has equivalent meaning and legal disclosures.
10. Market activation is blocked until jurisdictional approval and provider evidence are recorded.

## 8. Explicit exclusions
No game mechanics, odds, ticket price, prize pool, winner algorithm, custody model, payment rail, tax rule, identity threshold, provider SLA, licensing status or launch market is assumed. Casino, sportsbook, poker and other gambling products are outside this PRD.

## 9. Open decisions and required evidence
Initial product types/mechanics; launch jurisdiction and legal classification; licensing/operating model; responsible-use requirements; provider shortlist, API docs, sandbox, certification and source-of-truth hierarchy; acceptance/cancellation/refund/timeout semantics; draw timezone and result quorum/correction process; claims, identity, tax, settlement, payout and unclaimed-prize policy; currency, fees, limits and liability; data residency, retention and support access; and whether initial release includes customer purchase or operator-side integration only.

## 10. Traceability
Map each requirement to an owner decision, API/event contract, data model, test, operational control and bilingual document. Nothing is an approved release requirement until its decision owner and acceptance evidence are recorded.