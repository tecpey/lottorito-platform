# Financial Posting and Reconciliation Model

**Document ID:** LOT-FIN-POST-001 | **Version:** 0.1.0 | **Status:** Proposed; requires owner, finance and legal review

## 1. Purpose and authority
This provider-neutral design baseline covers financial controls for Affiliate & Agent and Lottery. It is not an accounting policy, legal opinion, implemented ledger, or authorization for custody, stored value, banking, payment execution or regulated activity. Immutable double-entry is a project design constraint; account mappings, recognition rules, commercial formulas, funding sources and payout permissions remain open decisions.

## 2. Invariants
1. Every posted journal entry balances independently per currency: debits equal credits.
2. Posted entries are append-only. Never update or delete a posted amount, account, currency or effective date.
3. Correct a posted entry through a linked reversal and, where needed, a new replacement entry. Preserve the original.
4. Balances are projections of ledger entries and explicit reservations, never the financial source of truth.
5. Every effect is attributable to tenant, product domain, currency, source event and economic-effect identity; legal entity/operating context becomes mandatory before statutory or regulated posting.
6. No implicit netting or pooling across tenants, product domains, currencies or legal entities.
7. No cross-currency balancing within one journal entry. FX requires explicit legs, rate source/time, rounding policy and approval.
8. Retries, duplicate callbacks, replay and worker restarts must not create a second economic effect.
9. Financial transitions and privileged adjustments are auditable and attributable.
10. A positive balance does not imply it is payable or withdrawable.

## 3. Financial dimensions and account ownership
Every account and journal line resolves, as applicable: tenant; product domain (affiliate_agent, lottery or explicitly approved shared service); legal entity/operating context; currency; controlled account ID/type; source system and source-event ID; economic-effect ID; journal-entry ID; effective, recorded and settled timestamps; and policy/calculation version.

Tenant context must come from trusted authorization, never an untrusted request field. Shared infrastructure does not mean shared economic ownership. Preserve product and tenant dimensions in every posting and report.

## 4. Chart of accounts
Use a controlled, versioned chart of accounts—not arbitrary integration-supplied strings. Candidate classes are assets, liabilities, equity, revenue, expenses, clearing and suspense. Examples such as cash, provider receivable, affiliate payable, prize payable, tax payable, platform revenue, commission expense and chargeback expense may be used only when the underlying ownership, obligation and accounting treatment are established.

Suspense accounts require an owner, aging threshold, reconciliation workflow and escalation. They must not hide unresolved differences indefinitely. Do not create accounts implying custody, safeguarding, prize liability or regulated payment activity before legal and finance approval.

## 5. Amounts, precision and rounding
- Store fiat amounts as exact decimals or integer minor units; never binary floating point.
- Currency exponent and supported precision come from controlled, effective-dated metadata.
- Preserve provider-original amount/currency separately from normalized amount and conversion metadata.
- Define rounding mode, calculation stage and residual treatment per versioned policy.
- Reject unknown currencies, unsupported precision, overflow and non-finite values.
- Never silently convert missing, malformed or unknown amounts to zero.
- Non-fiat credits, points and promotional units need explicit unit type, transferability, redemption, expiry, funding and accounting treatment. Do not label them USD or cash equivalents without evidence.

## 6. Posting lifecycle and atomicity
Proposed lifecycle: received → validated → pending_review (when required) → posted. Exception states may include rejected, quarantined, reversed and reconciliation_required. Pending business events are not posted journals. Holds/reservations must be explicit and have expiry/release rules.

Only a controlled posting service may create posted entries. Persist the journal, balanced lines, idempotency record and outbox event atomically. Preconditions: authenticated source; verified tenant/product context; schema and business validation; supported currency/precision; unique scoped economic-effect key; valid account mapping and policy version; balanced lines; required approvals/evidence; and no unresolved duplicate/conflict. On failure, quarantine or reject—never partially post.

## 7. Identity and idempotency
Keep these identities distinct:
- Source event ID: identity assigned by the source; may be absent or unreliable.
- Economic effect ID: stable identity of the real-world economic effect within tenant/product scope.
- Journal entry ID: immutable accounting record created by this platform.

Enforce uniqueness on the scoped economic-effect key. Persist idempotency key, normalized request hash, source identity, first-seen time, processing result and conflict outcome. Same key with a different payload is a conflict. Provider retries may use new delivery IDs for the same effect; deduplicate by economic effect, not delivery attempt.

## 8. Reversals, adjustments and disputes
A reversal references and reverses the original accounting effect under an approved policy. An adjustment is a new entry with reason, actor, approval, evidence and link to the original. Never rewrite historical commission rules or silently recalculate posted periods. Late partner corrections create new traceable adjustments within policy. Disputes and chargebacks require explicit provisional/final states and liability ownership. A ledger reversal does not prove external cash was returned.

## 9. Balance semantics
Keep separate:
- Pending: recognized but awaiting validation, maturation or partner confirmation.
- Available: eligible for internal allocation under policy; not necessarily payable.
- Payable: established obligation owed under contract and law.
- Reserved: temporarily unavailable due to hold, review, dispute or payout workflow.
- Paid/settled: externally confirmed with evidence and reconciliation state.
- Withdrawable: only after separate approval of payout product, jurisdiction, KYC/AML controls, funding source and payment rail.

User-facing balances disclose category, currency/unit, as-of time and restrictions.

## 10. Affiliate commission accounting
Calculation and posting are separate. Retain qualifying source transactions and identities; attribution decision and policy version; partner contract and schedule version; basis definition including partner-specific NGR components; exclusions, caps, tiers and reversals; inputs, output, currency, rounding and explanation trace; approval state and effective period.

Do not assume a universal NGR formula, 20–40% commission, L1–L10 network depth, monthly progression or default agent credit. These are open owner/partner decisions. Network commissions need explicit allocation, anti-cascade controls, maximum total allocation, eligibility and clawback rules.

## 11. Lottery financial boundary
Order, ticket, draw, result, prize, claim and provider settlement are distinct facts. A provider-reported win is not automatically a platform payable. Before liability posting, validate provider evidence, contractual liability, claim state, legal eligibility and funding/settlement evidence. This document does not authorize prize custody, customer wallets, payouts or safeguarding.

## 12. Reconciliation
Reconciliation compares independent records, not merely recalculated internal balances. Dimensions include tenant, product, legal entity/context, provider, currency, statement period/timezone, transaction/economic-effect identity, gross, fees, net, reversals, adjustments, settlement references, control totals and unmatched/duplicate/missing/late/conflicting items.

Workflow: import an immutable access-controlled statement batch; validate schema, period, currency, totals and authenticity; match by deterministic IDs and documented fallbacks; classify exceptions; prepare reviewed adjustments with evidence; post approved adjustments through the ledger; record outcome, operator, timestamps, rule version, exceptions and sign-off. Material differences must never be auto-written off. Reopening a closed period requires elevated authorization and audit.

Suggested statuses: not_started, in_progress, matched, exceptions, approved, closed.

## 13. Settlement and payout controls
Settlement is external movement/confirmation, not a balance update. Before enabling payout, obtain owner, legal, finance, security and provider approval for jurisdictions, beneficiary eligibility, legal entity, custody/funding model, payment rail, KYC/AML/sanctions controls, maker-checker thresholds, segregation of duties, idempotency, limits, velocity controls, beneficiary-change cooling-off, provider confirmation/returns/failures, reconciliation, safeguarding and treasury treatment.

Until approved, payout is a future integration boundary, not a current feature.

## 14. Access, audit and privacy
Separate roles for calculation, posting, approval, reconciliation, payout initiation, payout approval and audit. Privileged actions record actor, tenant scope, reason, timestamp, correlation ID, target references and approval evidence. Do not place secrets or unnecessary personal data in ledger metadata/logs.

## 15. Required tests
Test balanced/unbalanced journals; duplicate and concurrent replay; same idempotency key with changed payload; cross-tenant/product posting denial; unsupported currency/precision, overflow, rounding and FX residuals; reversal/adjustment/late correction/closed period; partial journal-idempotency-outbox failure; provider mismatches and late/missing records; separation of balance states; authorization and maker-checker; and deterministic recalculation under pinned policy versions.

## 16. Open decisions and release gates
Owner/finance/legal decisions: legal-entity model; accounting basis and chart of accounts; source of funds and custody boundaries; illustrative USD 100 agent credit; commission/NGR schedules; network allocation; promotional liability; tax; permitted jurisdictions; payout authorization; currency/unit policy; retention and audit. No implementation or financial operation is authorized by this document alone.
