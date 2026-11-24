# Wallet Domain and Balance Contract

**Document ID:** LOT-WALLET-001 | **Version:** 0.1.0 | **Status:** Proposed contract; owner, finance, legal and security review required

## 1. Purpose, scope and authority

This document decomposes the wallet and balance concerns identified in LOT-PLATFORM-001 and LOT-FIN-POST-001 into an explicit domain contract. It defines wallet ownership, wallet classes, unit/currency handling, balance projections, holds, lifecycle boundaries, authorization, ledger integration and acceptance evidence.

The owner has directed that Lottorito target a wallet experience for its first-party B2C tenant and eligible B2B product experiences. This is a product direction, not approval to issue stored value, custody customer funds, provide payment services, operate a bank-like account, or launch any real-money flow. The design remains Proposed until owner and specialist approval. No wallet runtime, database schema, accounting policy, custody model, payment rail or payout capability is claimed.

## 2. Non-negotiable invariants

1. The immutable double-entry ledger and approved external evidence are financial sources of truth; a mutable wallet balance is never authoritative.
2. A wallet is a product-facing account container/projection, not itself proof of legal custody, a bank account, safeguarded funds or a payable obligation.
3. Every wallet and economic effect has explicit owner, tenant, product, legal-entity/operating context, unit and policy scope.
4. No implicit pooling, transfer, netting or cross-subsidy across tenants, products, legal entities, currencies or unit classes.
5. Fiat, crypto-assets, promotional credits, loyalty points and game/demo units are different instrument classes. Never silently convert or label one as another.
6. Posted ledger entries are immutable. Corrections use linked reversals or new adjustments with authorization and evidence.
7. Every money-moving command and provider event is idempotent at the economic-effect level, not merely delivery ID.
8. Available, pending, held, payable, withdrawable and settled are distinct semantics; a displayed positive amount is not automatically spendable or withdrawable.
9. Wallet reads and mutations are object-authorized and tenant-scoped server-side. Client-supplied wallet, tenant, owner, currency or role claims are untrusted.
10. All balance-changing state transitions are attributable, auditable, explainable and reconcilable.

## 3. Domain boundaries and vocabulary

- **Wallet:** A customer/product-facing container that groups balances and transaction history for one owner and a defined purpose.
- **Wallet owner:** The principal, organization, tenant or legal entity to which the wallet is explicitly assigned. The owner type is fixed by policy; it cannot be inferred from who can view the wallet.
- **Wallet account:** A reference to one or more controlled ledger accounts/subaccounts and their dimensions. It is not a mutable amount column.
- **Ledger account:** An accounting account in a controlled chart of accounts. It may represent an asset, liability, income, expense, clearing or suspense position as approved by finance.
- **Balance projection:** A rebuildable read model derived from posted ledger entries plus explicit reservation/hold records and pending operational state.
- **Economic effect:** The uniquely identified financial consequence of a business event, scoped to its tenant, product, legal context and unit.
- **Unit:** A typed value denomination such as a fiat currency, crypto-asset, promotional credit, loyalty point or demo unit.
- **Hold/reservation:** An explicit, auditable restriction against a defined amount for a defined reason and lifecycle.
- **Funding source:** The external or internal source that economically funds a credit. It must be evidenced and classified.
- **Wallet transfer:** A separately authorized economic movement between eligible wallet owners. It is not a direct balance edit.

A wallet may aggregate several balance buckets only when they share a compatible owner, unit, legal treatment and product policy. Different unit classes must remain separately visible and separately accounted for.

## 4. Wallet classes and ownership boundaries

The following classes are candidate domain types, not automatic permissions or approved commercial products:

| Candidate class | Intended owner | Typical contents | Prohibited assumption |
|---|---|---|---|
| Customer cash-value wallet | A customer profile within one tenant and legal operating context | Eligible customer funds/claims only where legally approved | Does not imply custody, stored-value authorization or withdrawability |
| Affiliate/Agent commission wallet | A specific Affiliate/Agent account under its contract and tenant | Calculated, matured and approved commission entitlements | Commission is not payable or withdrawable merely because it is displayed |
| Agent operational/promotional wallet | A defined agent or campaign beneficiary under an approved promotion | Restricted promotional allocation with explicit rules | The discussed USD 100 example is not approved funding or a default balance |
| Rewards/loyalty wallet | Customer or member under a loyalty program | Non-cash points or rewards with explicit unit and redemption rules | Points are not fiat, cash-equivalent or transferable unless explicitly approved |
| Promotional credit wallet | Eligible beneficiary and campaign | Restricted bonus/credit units with source, expiry and wagering/use constraints if applicable | Bonus credit is not customer cash or withdrawable funds |
| Demo/simulation wallet | Demo user or training environment | Non-monetary simulated units | Must never be represented as real funds or cross into production cash balances |
| Tenant/operator treasury view | Authorized legal entity/tenant finance scope | Reconciled operational positions and liabilities | Not a customer wallet and not an unrestricted pooled balance |

A wallet class must declare: owner type; beneficiary; tenant; product; legal entity/operating context; unit class; permitted source and destination; allowed operations; expiry/forfeiture rules; transferability; redemption; withdrawal eligibility; dispute treatment; accounting mapping; retention and support policy.

The USD 100 Agent credit remains Open under LDR-016. Do not instantiate it as a default, promise it to users, treat it as commission, or assume it is funded by Lottorito.

## 5. Wallet identity and dimensional key

A logical wallet identity should include or resolve immutably to:
- wallet_id (opaque, non-semantic identifier);
- owner_type and owner_id;
- tenant_id and product_domain/product_instance_id;
- legal_entity_id or an explicitly approved non-regulated operating context;
- wallet_class and unit_id;
- status and policy_version;
- created_at and lifecycle/audit references.

Uniqueness rules must prevent two active wallets from ambiguously representing the same owner, purpose and unit in the same scope. Multiple wallets may exist where purpose, legal treatment, product or unit differs. A wallet must not be moved to a different owner or tenant by editing its identity; migration requires an audited transfer/offboarding procedure with liabilities preserved.

The authenticated server context determines tenant and membership. Ownership and scope are checked on every read, mutation, export and background operation.

## 6. Units, currency metadata and precision

Use a versioned, effective-dated unit registry. Each unit defines:
- stable unit_id and canonical code;
- class: fiat, crypto-asset, promotional_credit, loyalty_point, demo_unit or another explicitly approved class;
- issuer/asset identity where relevant;
- display name and localization metadata;
- decimal precision and minimum increment;
- status, effective dates and permitted tenant/product/jurisdiction scope;
- accounting treatment and conversion policy, if any.

Fiat amounts use exact decimal or integer minor units. Binary floating point is prohibited for financial amounts. Crypto-asset precision is asset-specific and must not be inferred from fiat currency conventions. Points and credits use integer or exact fixed-point units with their own unit identity. Unknown units, unsupported precision, overflow, NaN/infinity and silent rounding are rejected.

A conversion between units is a separate FX/conversion operation with explicit source and destination amounts, rate, source, timestamp, fee, rounding policy, approvals and ledger effects. No implicit conversion occurs when displaying or transferring balances. FX never balances a journal by mixing currencies.

## 7. Balance semantics and projection

At minimum, expose separate values where applicable:

| Balance bucket | Meaning | May customer spend it? |
|---|---|---|
| Pending | Observed or requested, not yet finally validated/posted | No |
| Available | Eligible for permitted internal use under the wallet policy | Only for explicitly allowed operations |
| Held/reserved | Temporarily blocked for a withdrawal, dispute, review or other defined purpose | No |
| Payable | A validated obligation owed under contract and applicable law | Not necessarily |
| Withdrawable | Eligible for an approved payout flow after all jurisdiction, identity, funding and risk gates | Only through the approved payout workflow |
| Settled/paid | External settlement confirmed with independent evidence and reconciliation state | No; historical state |
| Expired/forfeited | Promotional/reward units invalidated under a disclosed and approved policy | No |

Do not derive one bucket by subtracting arbitrary UI totals. Define each bucket as a deterministic query over posted ledger entries and separately persisted hold/reservation states. The projection must disclose unit, as-of time, source freshness and restrictions. A projection is rebuildable and can be compared with a full ledger replay.

The exact accounting mapping for each bucket is a finance decision. UI labels must not imply legal entitlement or cash value beyond the approved product/jurisdiction policy.

## 8. Ledger integration and posting boundary

Wallet services orchestrate wallet-specific commands and read projections; a dedicated posting boundary controls journal creation under LOT-FIN-POST-001.

A wallet operation does not directly update a balance. A successful economic effect follows:
1. Authenticate the principal or machine identity.
2. Resolve and verify tenant, product, owner, legal context and wallet policy server-side.
3. Validate wallet status, unit, operation, limits, eligibility and required approvals.
4. Persist an idempotent command/operation record and any required hold/reservation.
5. Obtain authoritative business/provider evidence where the operation depends on an external event.
6. Ask the controlled posting service to validate account mapping and create a balanced journal, idempotency record and outbox event atomically.
7. Update/rebuild the wallet projection from authoritative records.
8. Emit an auditable state transition and notify only through approved notification policy.
9. Reconcile external movement independently; do not equate a successful API response with settlement.

Pending requests and provider observations are not posted money. Posting, release of a hold, reversal and external settlement are separate effects with their own identifiers and evidence.

## 9. Holds, reservations and concurrency

A hold is a first-class record, not a negative balance mutation. It includes hold_id, wallet_id, unit, amount, reason_code, source_operation_id, created_by/system_actor, created_at, expiry/review deadline, state, release/posting references and audit trail.

Candidate states: requested, active, partially_consumed, released, expired, disputed and cancelled. State transitions require explicit rules and compare-and-set/transactional concurrency control. A hold cannot exceed the policy-eligible amount at the moment it is placed. Concurrent spend/hold attempts must serialize or use an equivalent atomic reservation mechanism so the same available amount cannot be consumed twice.

A hold release is permitted only for its original scope and remaining amount. Expiry must not silently credit or debit money; it triggers a controlled state transition and, where needed, a ledger posting/reversal. Dispute or compliance holds require reason, review owner and escalation.

## 10. Transfers and internal movements

Transfers are disabled by default until the relevant wallet classes, legal model and product policy are approved. If enabled, require:
- both wallets active and eligible for the same permitted transfer scheme;
- same approved tenant/legal context unless a separately approved cross-context arrangement exists;
- compatible unit or an explicit conversion transaction;
- source ownership/authorization and destination eligibility;
- limits, velocity, sanctions/fraud/risk checks as applicable;
- explicit fee and beneficiary disclosure;
- idempotency, immutable journal, audit and reconciliation.

No direct peer-to-peer transfer, agent-to-customer transfer, promotional-credit conversion, cross-product netting or tenant-to-tenant movement is inferred from the existence of a wallet. A transfer is a linked debit/credit journal and workflow, not a database update.

## 11. Lifecycle and failure handling

Proposed wallet lifecycle: provisioning → active → restricted → frozen → closing → closed. The exact state set and transitions require product/legal/finance approval.

- Provisioning creates identity and policy bindings, not a funded balance.
- Restricted limits specified operations while preserving permitted read, support, refunds or withdrawal handling as legally required.
- Frozen blocks specified movements and requires reason, authority, review and release criteria.
- Closing requires zero unresolved holds/operations or a documented liability/claims migration; closure must not erase history.
- Closed wallets are immutable historical references.

Provider timeout is an unknown outcome until reconciled. Do not blindly retry with a new economic-effect ID. Query provider status or reconcile using the original operation identity. Late, duplicated, out-of-order or contradictory events enter quarantine/exception handling. A ledger reversal does not prove an external refund or payout occurred.

## 12. Authorization, audit and privacy

Separate permissions for wallet.read_self, wallet.read_scoped, wallet.create, wallet.restrict, wallet.freeze, wallet.close, wallet.operation.initiate, wallet.hold.create, wallet.hold.release, wallet.transfer.initiate, wallet.statement.export and finance.ledger.post/reverse/approve. These are illustrative namespaces, not approved grants.

The wallet service must enforce object ownership, tenant/product scope, purpose, unit, operation and risk context on the server. Finance posting, adjustment, withdrawal approval, payment routing and privileged support access are distinct capabilities. Maker-checker applies where required; no actor approves their own high-risk operation.

Audit records include actor, effective subject, tenant, product, wallet, operation/economic-effect IDs, action, reason, policy version, approval, correlation ID, timestamp and outcome. Do not put secrets or unnecessary personal data in ledger metadata or logs. Retention, access, correction and deletion are jurisdiction-specific and must preserve required financial/audit records and legal holds.

## 13. Statements, history and customer transparency

A statement line should identify date/time and timezone, operation type, direction, exact amount and unit, status, available/pending/held effect, reference, fee where applicable, source/beneficiary description safe for the viewer, reversal/adjustment relationship and explanation. Distinguish requested, authorized, posted, externally submitted, externally confirmed, reconciled, failed, reversed and expired states.

Customer history is tenant-scoped and object-authorized. Internal ledger account IDs, other tenants' data, provider secrets, fraud rules and privileged notes are never exposed in a customer statement. Download/export must re-check scope and be audited.

## 14. Observability and operational controls

Measure, with tenant-safe dimensions: projection lag, ledger-to-projection drift, unbalanced/rejected posting attempts, duplicate/replay rate, hold age and expiry, unresolved provider outcomes, reconciliation exceptions, wallet state transitions, authorization denials and manual adjustments. Avoid high-cardinality or personal-data leakage.

Provide controlled runbooks for projection rebuild, stuck holds, provider ambiguity, wallet restriction, account takeover, erroneous posting, reversal, statement correction and tenant offboarding. Projection rebuild must never create new ledger effects. Manual correction requires linked evidence and approved posting path.

## 15. Acceptance and adversarial test matrix

| ID | Scenario | Expected result/evidence |
|---|---|---|
| WAL-01 | Client changes wallet_id or tenant_id | Server denies; no metadata or balance leakage |
| WAL-02 | Same owner has cash and promotional units | Separate unit/class projections and accounting; no implicit conversion |
| WAL-03 | Duplicate command/provider callback | One economic effect and one journal; duplicate delivery is traceable |
| WAL-04 | Same idempotency key, changed amount or unit | Conflict; no second posting |
| WAL-05 | Two concurrent spends exceed available amount | At most policy-eligible amount succeeds; no overspend |
| WAL-06 | Hold is partially consumed/released twice | State/amount invariants hold; no duplicate release |
| WAL-07 | Projection is deleted and rebuilt | Rebuilt values equal deterministic ledger/hold replay |
| WAL-08 | Wallet frozen during in-flight operation | Operation follows defined safe transition; no silent posting |
| WAL-09 | Tenant or product suspended with unresolved funds | Liability and claim handling preserved; no cross-scope migration |
| WAL-10 | Unsupported precision, overflow or unknown unit | Request rejected before posting |
| WAL-11 | FX conversion is requested | Explicit rate/source/time/fee/rounding and two-sided accounting evidence |
| WAL-12 | Agent attempts to transfer commission or promo credit | Denied unless exact class, contract and legal policy allow it |
| WAL-13 | Customer exports statement | Own scoped records only; access and export audited |
| WAL-14 | Projection drift or provider timeout | Alert/exception workflow; no invented settlement or duplicate retry |
| WAL-15 | Privileged operator adjusts wallet | No direct balance edit; approval, reason and linked journal required |

## 16. Open decisions and release gates

1. Legal entity, operating model, initial jurisdiction and whether any wallet class constitutes regulated stored value, payment account, custody or another regulated activity.
2. Which wallet classes are in the first Affiliate release versus later B2C/Lottery releases.
3. Owner type and legal liability for customer balances, Affiliate commissions, rewards and promotions.
4. Chart of accounts, accounting basis, funding sources, safeguarding/segregation requirements and external settlement evidence.
5. Whether customer cash wallet, internal transfer, redemption, withdrawal or crypto-asset support is permitted in each jurisdiction.
6. USD 100 Agent credit terms, source, budget, transferability, expiry, clawback and cash-equivalence (LDR-016 remains Open).
7. Unit registry governance, supported currencies/assets, precision, FX and rounding.
8. Hold policy, expiry, dispute and account-freeze rules.
9. KYC/AML/sanctions, fraud, responsible-use and customer disclosure requirements by product and market.
10. Data residency, retention, statement format, reconciliation frequency and operational SLOs.

Before implementation, obtain accountable owner, product, finance/accounting, legal/compliance, security/privacy and operations approval. Any regulated-money activity additionally requires jurisdiction-specific legal opinion, licensed operating model, provider/rail due diligence and documented release authorization.

## 17. Related documents and change control

- LOT-PLATFORM-001 — unified B2B2C platform architecture.
- LOT-IAM-TENANT-001 — tenant, identity, membership and authorization.
- LOT-DASH-001 — role-based dashboards and workspace blueprint.
- LOT-FIN-POST-001 — financial posting and reconciliation.
- LOT-PROVIDER-EVAL-001 — provider evaluation and RFI governance.
- LOT-API-001 — API resource and webhook contract.
- LOT-SEC-TM-001 — security threat model.

Changes to wallet ownership, unit classes, balance semantics, posting boundaries, transfers or withdrawal eligibility require an LDR update, financial/security/legal impact review and synchronized Persian/English changes. This contract is Proposed and does not authorize a wallet, payment, custody or payout implementation.
