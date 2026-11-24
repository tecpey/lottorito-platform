# Payout, Withdrawal and Disbursement Contract

**Document ID:** LOT-PAYOUT-001 | **Version:** 0.1.0 | **Status:** Proposed contract; owner, finance, legal, security and operations review required

## 1. Purpose, scope and authority

This document defines a provider-neutral control plane for outbound disbursements: customer withdrawals where permitted, matured Affiliate/Agent commission payouts, approved prize disbursements and other separately authorized obligations. It decomposes the payout/withdrawal target in LOT-PLATFORM-001 and must be read with LOT-WALLET-001, LOT-PAYMENT-001, LOT-FIN-POST-001, LOT-PROVIDER-EVAL-001 and LOT-IAM-TENANT-001.

The owner has directed that wallet, deposits and withdrawals are target capabilities. This does not approve custody, money transmission, stored value, banking, payout execution, a licensed operating model, a jurisdiction, a provider, a beneficiary account or any real-money flow. No payout runtime or live disbursement is claimed. The contract remains Proposed pending accountable review and explicit release authorization.

## 2. Payout domain boundaries

Payout is not the reverse of deposit and must not share one universal state machine with payment collection. Distinguish at least:
- customer withdrawal from an eligible customer wallet;
- Affiliate/Agent commission payout after contractual calculation, maturation and approval;
- Lottery prize disbursement after validated result, claim, legal eligibility and liability approval;
- refund to original payment source, which remains a payment-domain operation in LOT-PAYMENT-001;
- operator treasury movement, which requires separate treasury governance and is not a customer payout.

Each payout purpose has separate eligibility, legal basis, funding source, accounting mapping, limits, beneficiary rules, approvals, evidence and reconciliation. No purpose inherits another's permission. A commission balance is not automatically withdrawable; a prize result is not automatically payable; a positive wallet balance is not proof of payout eligibility.

## 3. Non-negotiable payout invariants

1. Payout creates an external obligation/movement; it is not a mutable balance update.
2. The immutable ledger, approved liability record and independent provider/bank evidence are authoritative.
3. No payout without verified owner, beneficiary, tenant, product, legal entity, jurisdiction, funding source and approved purpose.
4. Funds must be eligible, matured, available for payout and reserved atomically before submission.
5. One economic payout effect can be executed at most once; duplicate requests, callbacks, retries and worker restarts cannot duplicate disbursement.
6. Ambiguous submission timeout is unknown, not failed; never retry to another rail until the first outcome is resolved.
7. Initiation, approval, execution, settlement confirmation, reconciliation and audit are separated according to risk and maker-checker policy.
8. Beneficiary changes, high-risk payout, manual override and ledger adjustment require step-up controls and auditable authorization.
9. Tenant, product, legal entity, currency and payout purpose are isolated; no implicit netting or pooling.
10. No production disbursement before legal, provider, finance, security, operations and owner gates pass for the exact decision unit.

## 4. Payout parties and ownership model

A payout record identifies:
- **Obligor:** legal entity responsible for the payment under contract/law.
- **Payout owner/payee:** customer, Affiliate/Agent, prize claimant or other approved beneficiary.
- **Tenant/product:** originating business and entitlement context.
- **Funding account/source:** approved bank/PSP/treasury source and evidence of available funds.
- **Payout provider/rail:** licensed/contracted bank, PSP, local rail or other approved disbursement provider.
- **Beneficiary instrument:** verified bank account, local account alias, wallet address or other method-specific destination.
- **Approver(s):** authorized humans/systems distinct from the initiator where dual control applies.

The wallet owner, contractual creditor, verified payee, beneficiary account holder and legal recipient may differ. That mismatch must be resolved by documented policy and evidence; never assume that a wallet profile is the lawful beneficiary.

## 5. Payout purposes and eligibility

| Purpose | Preconditions | Prohibited shortcut |
|---|---|---|
| Customer withdrawal | Withdrawable balance, source-of-funds trace, customer eligibility, KYC/AML/sanctions and jurisdiction permission | Available balance alone |
| Affiliate/Agent commission | Partner event evidence, versioned contract/rate/NGR, maturation, dispute/chargeback window and approved statement | Calculated or pending commission alone |
| Lottery prize | Verified result, valid ticket/claim, identity and jurisdiction eligibility, provider/operator liability and funding evidence | Provider win notification alone |
| Refund to source | Original captured payment and refundable amount under provider/method rules | Treating refund as a generic payout |
| Operator treasury disbursement | Separate treasury mandate, approved payee, purpose, budget and dual control | Using customer or agent wallet funds |

Eligibility is recalculated at initiation and before execution. A change in sanctions/risk status, legal eligibility, beneficiary, account status, source funds, tenant state or payout policy can block or pause the request.

## 6. Payout request and execution objects

- **Payout Request:** Canonical request to discharge a defined obligation to a verified beneficiary.
- **Payout Instruction:** Immutable approved execution parameters: amount, currency, purpose, payee, destination reference, funding source, fees and policy version.
- **Payout Attempt:** One submission to one provider/rail with its own idempotency key and provider reference.
- **Beneficiary Instrument:** Encrypted/tokenized, verified destination with ownership and verification evidence.
- **Payout Hold/Reservation:** Atomic restriction against the eligible source wallet/account pending execution.
- **Approval Record:** Maker-checker decision with actor, scope, reason, threshold, policy and timestamp.
- **Provider Event:** Authenticated payout status, return, rejection or settlement notification.
- **Settlement Evidence:** Provider/bank statement, transaction reference and confirmation of external movement.
- **Return/Recall Case:** Durable case for returned, rejected, recalled, disputed or misdirected payout.
- **Reconciliation Case:** Match/exception record across liability, ledger, attempt, provider statement and bank evidence.

Do not overwrite destination or amount after approval. A material change requires cancellation before submission and a new instruction/approval, or a separately audited amendment if the provider contract safely supports it.

## 7. Request and attempt lifecycle

Suggested request states:
- draft
- submitted
- screening
- pending_approval
- approved
- reserved
- queued
- processing
- paid_pending_reconciliation
- paid_reconciled
- rejected
- cancelled
- expired
- failed
- returned
- recalled
- disputed
- unknown_outcome
- reconciliation_required

Suggested attempt states:
- created
- submitted
- accepted
- pending
- processing
- succeeded
- rejected
- failed
- timed_out
- unknown
- returned
- recalled

These are normalized candidates. Retain raw provider status/code, event time, observation time and evidence. A provider's “accepted” response means accepted for processing, not necessarily paid. Mark paid only with authoritative evidence under the approved rail's settlement-finality policy. Reconcile before treating a payout as closed.

## 8. Beneficiary onboarding and change control

Beneficiary data is high-risk. Store only the minimum necessary destination details, encrypted or tokenized with access logging and masking. Do not expose full bank/account/card identifiers in routine UI, logs, support tools or exports.

Verification may require account-holder name matching, bank/provider confirmation, micro-deposit or other approved proof depending on method and jurisdiction. Verification evidence, source, date, method, confidence and expiry are retained.

A beneficiary change requires:
- authenticated account owner and step-up authentication;
- re-verification and ownership checks;
- risk/sanctions screening;
- notification to existing trusted channels where appropriate;
- a cooling-off period or manual review based on risk;
- re-evaluation of pending payouts and active holds;
- immutable audit history; no silent replacement.

Support staff cannot edit beneficiary instruments or bypass verification. A newly added destination must not inherit a previous destination's verification state.

## 9. Holds, reservation and funding sufficiency

Before payout submission, create an explicit hold/reservation against the eligible source under LOT-WALLET-001 and the approved ledger policy. Reservation and payout instruction must be atomic or recoverably coordinated so concurrent requests cannot spend the same funds.

The reserved amount must account for payout amount, known fees, FX/rounding and any required buffer. The system must distinguish source balance, payout liability, reserved amount, provider-submitted amount and final settled amount.

Release a hold only when:
- request is cancelled before external submission;
- provider confirms definitive rejection/failure and no debit occurred;
- an authorized reconciliation case proves no external movement; or
- a controlled reversal/return process restores funds with evidence.

Timeout or missing callback is not a reason to release the hold. Partial execution and provider fee deductions require explicit ledger entries and residual-liability handling. Never create funds to cover a payout shortfall.

## 10. Approval, limits and separation of duties

Use risk-based maker-checker and configurable approval thresholds. Separate:
- request initiation;
- eligibility/screening;
- payout approval;
- beneficiary verification;
- funding/treasury authorization;
- provider submission;
- reconciliation;
- exception resolution and audit.

No user may approve their own request or beneficiary change where dual control applies. High-value, unusual, first-time, cross-border, changed-beneficiary, manually overridden or risk-flagged payouts require stronger approval. Platform support, Tenant Admin, White-Label Admin and Agent roles receive no implicit payout approval authority.

Limits may include per-transaction, daily, rolling-window, beneficiary, customer, tenant, currency, jurisdiction and aggregate exposure controls. Limit changes are versioned, effective-dated and audited. No numerical thresholds are set here; accountable owners must approve them from risk/workload evidence and legal requirements.

## 11. Provider adapter and execution contract

Each payout adapter exposes versioned capabilities:
- validate beneficiary/method eligibility;
- validate payout instruction and limits;
- submit payout with stable idempotency;
- query status by stable provider reference;
- cancel/recall where supported;
- retrieve return/rejection reason;
- verify signed/authenticated callbacks and replay protection;
- retrieve/import settlement and return reports;
- expose fees, limits, cut-off times, supported currencies and capability version.

Provider-specific payloads/statuses are normalized while raw evidence references remain immutable. The adapter cannot decide legal eligibility, approve a payout, mutate wallet balances or post directly to the ledger. Unsupported cancellation/recall is explicit; do not promise it in UI.

## 12. Idempotency, ambiguous outcomes and returns

Create a platform payout operation ID and stable economic-effect key before submission. Persist the normalized instruction hash, approval references, source reservation, provider account, attempt ID, submission time, provider reference and result.

On timeout after submission:
1. retain the reservation and mark unknown_outcome;
2. query the same provider using the original reference/idempotency key;
3. ingest and authenticate late callbacks;
4. compare provider reports and bank evidence;
5. resolve through an authorized reconciliation case;
6. only then permit retry, cancellation or release under policy.

Never send a second payout through another provider while the first attempt may have succeeded. A return/recall is a new linked event and accounting effect, not deletion of the original payout. Returned funds are not available until external receipt is evidenced and the ledger/hold treatment is approved.

## 13. Fees, FX, tax and accounting

Keep exact payout amount, unit, payee net amount, payer gross amount, provider fee, intermediary fee, FX rate/source/time, tax/withholding, rounding, settlement currency, bank reference and actual settled amount distinct.

Use exact decimal/minor units. Do not infer currency from locale, bank country or a display label. Do not silently convert IRR/IRT or any other currency. FX requires an explicit approved rate source, timestamp, spread/fee, rounding rule, customer disclosure and ledger treatment.

Payout accounting must distinguish:
- recognition of the underlying liability;
- reservation/hold;
- provider submission/clearing;
- confirmed external settlement;
- fee/tax/FX effects;
- rejection, cancellation, return and reversal.

A payout instruction does not itself discharge the liability. Only approved evidence and accounting policy determine when the obligation is settled. Reversal of an internal journal does not prove returned cash.

## 14. Security, privacy and compliance

- Encrypt/tokenize beneficiary instruments and restrict decryption to narrowly scoped payout services.
- Use MFA/step-up for sensitive beneficiary and payout actions; protect account recovery and session revocation.
- Apply KYC/KYB, AML, sanctions, fraud, source-of-funds, responsible-use and jurisdiction eligibility controls as applicable.
- Screen payee, beneficial owner, bank/rail and destination at onboarding and before execution according to policy.
- Protect callbacks, provider credentials, API access and admin workflows with signatures, scopes, rotation and audit.
- Apply rate limits, velocity checks, anomaly detection, dual control, four-eyes approval and break-glass review.
- Minimize personal data in logs, exports, statements and support access; apply residency, retention, legal hold and data-subject rights.
- Review local payout licensing, cross-border transfer, tax reporting, safeguarding and consumer disclosure for each legal entity/market.
- No payout launch based only on a provider's marketing statement or generic global configuration.

## 15. Operations, reconciliation and exception handling

Operate a controlled payout queue with aging, priority, ownership, SLA targets (to be approved), reason codes and escalation. Monitor queued/processing/unknown requests, provider latency, failed/returned rate, holds aging, beneficiary changes, approval delays, settlement variance and unresolved liabilities.

Reconcile each payout against:
- approved request/instruction and source liability;
- wallet/ledger reservation and posting;
- provider attempt and authenticated events;
- provider settlement/return report;
- bank account statement or equivalent independent evidence.

Classify unmatched, duplicate, partial, late, returned, recalled, wrong-beneficiary, fee/FX and amount/currency discrepancies. Never auto-close a material exception or release a hold solely from timeout. Manual repair requires maker-checker, evidence, linked adjustment/reversal and audit. Define incident runbooks for duplicate payout, compromised beneficiary, wrong destination, provider outage, bank return and tenant offboarding with open liabilities.

## 16. Acceptance and adversarial test matrix

| ID | Scenario | Expected result/evidence |
|---|---|---|
| OUT-01 | Customer requests more than withdrawable amount | Reject before reservation; no negative balance |
| OUT-02 | Commission is pending/disputed/not matured | No payout eligibility |
| OUT-03 | Prize claim lacks verified result/legal eligibility | Block; no payout instruction |
| OUT-04 | Same request is submitted twice | One economic payout effect |
| OUT-05 | Provider timeout after submission | Unknown outcome; hold retained; no blind retry/failover |
| OUT-06 | Provider callback is replayed or forged | Reject/dedupe; no duplicate paid state |
| OUT-07 | Beneficiary is changed after approval | Invalidate approval/instruction; reverify and reapprove |
| OUT-08 | Initiator attempts self-approval | Deny under separation-of-duties policy |
| OUT-09 | Concurrent withdrawals exceed source balance | Atomic reservation prevents overspend |
| OUT-10 | Provider accepts but settlement is not confirmed | Not marked reconciled/closed |
| OUT-11 | Payout is returned by bank | Linked return case; funds unavailable until evidenced |
| OUT-12 | Partial payout or unexpected fee | Explicit residual liability/fee posting and exception |
| OUT-13 | Tenant A tries to pay using Tenant B funding source | Deny; no cross-tenant movement |
| OUT-14 | Currency precision/FX metadata is invalid | Reject before provider submission |
| OUT-15 | Sanctions/risk status changes before execution | Pause/block and record screening decision |
| OUT-16 | Operator manually repairs a payout | Dual control, reason, evidence and linked journal required |

## 17. Open decisions, release gates and related documents

Open decisions:
1. Legal entity/merchant of record, operating model and initial jurisdiction for each payout purpose.
2. Whether customer withdrawals, Affiliate/Agent commission payouts and prize payouts are all in the first release or staged separately.
3. Custody/funding model, safeguarding/segregation, treasury ownership and proof of funds.
4. Beneficiary verification standard, KYC/KYB/AML/sanctions rules and risk owner.
5. Provider/rail, settlement finality, return/recall capabilities, cut-off times and currencies for each market.
6. Approval thresholds, maker-checker matrix, limits, cooling-off and exception ownership.
7. Tax/withholding, FX, fees, disclosures, statements and retention.
8. Reconciliation owner, cadence, escalation and operational SLOs.

No payout may enter production before named owner, legal/compliance, finance/treasury, security/privacy, provider and operations approvals for the exact legal entity, jurisdiction, purpose and funds-flow model.

Related documents: LOT-PLATFORM-001, LOT-WALLET-001, LOT-PAYMENT-001, LOT-FIN-POST-001, LOT-PROVIDER-EVAL-001, LOT-IAM-TENANT-001 and LOT-SEC-TM-001.

Changes to eligibility, beneficiary, funding, approvals, execution, settlement or return semantics require an LDR update, financial/security/legal review and synchronized Persian/English change. This Proposed contract does not authorize custody, banking, payment services or any real-money disbursement.
