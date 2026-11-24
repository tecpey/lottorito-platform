# P-02 — Financial Ledger and Reconciliation Prototype

**Document ID:** LOT-PROT-P02-001 | **Version:** 0.5.0 | **Status:** Prototype CI passed; full P-02 remains partial | **Review date:** 2026-11-24

## Purpose and decision boundary

P-02 is a synthetic-data experiment for the financial recordkeeping foundation needed by Affiliate/Agent operations. It tests exact amounts, double-entry posting, tenant/product/currency boundaries, idempotency, immutability, reversals, atomic outbox writes and reconciliation.

This is not a wallet product, payment integration, payout service, customer balance feature or approval of any commercial commission policy. Source-event amounts are supplied as synthetic upstream inputs. No NGR definition, commission rate, eligibility rule, network depth, FX rate, Agent credit or settlement rule is invented or approved.

## Implemented experiment slice

- PostgreSQL 18.7 with a dedicated ledger_runtime role (NOSUPERUSER, NOBYPASSRLS, not table owner).
- Tenant and product scope is carried through accounts, source events, journals, effects, entries and outbox events; RLS requires both transaction-local tenant and product context.
- Currency registry carries decimal scale; the fixture uses USD (2), USDT (6), and BTC (8).
- Monetary values use exact PostgreSQL NUMERIC(38,18) and the Node boundary accepts decimal strings only. No JavaScript floating-point arithmetic is used for amounts.
- A journal must contain at least two entries and balance debit/credit totals independently for each currency before it can transition from draft to posted.
- Account-currency composite foreign keys prevent posting a USD entry to a USDT account.
- Currency scale is enforced at source-event and ledger-entry insertion boundaries; account-currency composite foreign keys prevent currency substitution.
- Posted journal headers and entries are immutable. Corrections use a new reversal journal whose entries must exactly invert the original; a unique constraint prevents a second full reversal.
- An economic effect is protected by both a stable business-effect identity and an idempotency key. A request fingerprint prevents key reuse with a different financial payload.
- Concurrent duplicate delivery is serialized by database uniqueness; only one posted journal/effect/outbox event should survive.
- The journal, economic effect, entries and outbox event are written in one PostgreSQL transaction. Deferred constraint triggers require effect/outbox references to point to a posted journal at commit. Source-event existence is verified inside the same tenant/product transaction.
- Reconciliation compares independently recorded source-event expectations with posted affiliate-payable entries and reports missing or mismatched postings.
- Account balances are derived from posted ledger entries; no mutable balance column is used as the source of truth.
- Synthetic tests cover tenant and product RLS, exact numeric behavior, duplicate/concurrent idempotency, unbalanced journals, currency precision, per-currency balancing, immutability, reversals and reconciliation drift.

## Acceptance matrix

| ID | Scenario | Expected result |
|---|---|---|
| P02-LEDGER-01 | Post a two-line commission accrual | Posted journal; debit equals credit; one outbox event |
| P02-LEDGER-02 | Replay the same business effect | Existing journal returned; no duplicate effect or outbox |
| P02-LEDGER-03 | Deliver the same effect concurrently | Exactly one journal/effect is committed |
| P02-LEDGER-04 | Reuse identity/key with a different fingerprint | Conflict; no extra journal |
| P02-LEDGER-05 | Attempt an unbalanced journal | Posting rejected; all writes roll back |
| P02-LEDGER-06 | Post beyond a currency's decimal scale | Database rejects the amount |
| P02-LEDGER-07 | Offset USD debit with USDT credit | Rejected; currencies cannot net against each other |
| P02-LEDGER-08 | Update/delete posted journal or entries | Rejected; correction requires reversal |
| P02-LEDGER-09 | Reverse a posted journal | New exact inverse journal; original remains unchanged |
| P02-LEDGER-10 | Reverse the same journal twice | Second reversal rejected |
| P02-LEDGER-11 | Reconcile missing or duplicated posting | Missing/mismatched source event is surfaced |
| P02-LEDGER-12 | Update/delete source event or economic effect | Rejected |
| P02-LEDGER-13 | Insert a journal directly as posted | Rejected; draft-to-posted transition is mandatory |
| P02-LEDGER-14 | Read another tenant/product's ledger | RLS returns no foreign rows |
| P02-LEDGER-15 | Perform exact decimal arithmetic and post a token amount | Decimal string is preserved without JavaScript float conversion |
| P02-LEDGER-16 | Inspect runtime role and query without tenant/product context | Runtime is non-owner/non-BYPASSRLS; missing context returns no rows |
| P02-LEDGER-17 | Pair a USD entry with a USDT account | Composite account/currency foreign key rejects substitution |
| P02-LEDGER-18 | Post an event absent from the tenant/product source-event scope | Posting is rejected before journal creation |
| P02-LEDGER-19 | Commit an effect/outbox row referencing a draft journal | Deferred commit-time constraint rejects the transaction |

## Verified CI evidence

- P-02 integration run [45415806446](https://github.com/tecpey/lottorito-platform/actions/runs/45415806446) passed on PR head 003551df55921413ccff3bfe746a2f671d8d35bd: 19 Node tests passed, 0 failed, 0 skipped, using npm ci, the committed lockfile, Node.js 26.13.0 and PostgreSQL 18.7.
- Documentation Governance run [45415805992](https://github.com/tecpey/lottorito-platform/actions/runs/45415805992) passed on the bilingual documentation head before this evidence annotation.
- Local execution has not been performed in this environment. Passing CI proves only the defined synthetic test cases, not production readiness.

## Local reproduction

Use only a disposable local database. The setup script drops and recreates the P-02 fixture objects; never point it at a shared, staging or production database.

    cd prototypes/p02-financial-ledger
    docker compose up -d
    export ADMIN_DATABASE_URL='postgres://postgres:p02-admin-only-not-production@127.0.0.1:55433/lottorito_p02'
    export RUNTIME_DATABASE_URL='postgres://ledger_runtime:p02-runtime-not-for-production@127.0.0.1:55433/lottorito_p02'
    npm ci --ignore-scripts --no-audit --no-fund
    npm test
    docker compose down -v

All credentials and data in this experiment are synthetic and must never be reused.

## Security and accounting limitations

- P-02 reuses the shared-role custom-GUC pattern for tenant/product RLS. P-01 already demonstrates that a compromised shared application role can change a custom GUC; this prototype is not an adversarial tenant-isolation proof.
- The prototype does not yet model a production chart-of-accounts governance workflow, pending/available/held funds, account overdraft locks, high-contention account serialization, multi-ledger consolidation, FX conversion, tax, rounding policy, chargebacks, payout settlement or external bank/provider reconciliation.
- Reconciliation is a synthetic source-event comparison, not a production bank or partner statement integration. Source-event expected amounts are treated as independent inputs; this prototype does not calculate or approve the upstream commission amount.
- The outbox is persisted atomically but no external broker, publisher retry, dead-letter queue or consumer deployment is selected.
- No load, failover, backup/restore, disaster-recovery, penetration test, legal/accounting review or production readiness is claimed.
- Full P-02 remains partial until these boundaries are researched and tested.

## Research references

- PostgreSQL 18 — [Numeric Types](https://www.postgresql.org/docs/18/datatype-numeric.html), [Constraints](https://www.postgresql.org/docs/18/ddl-constraints.html), [CREATE TRIGGER and deferred constraint triggers](https://www.postgresql.org/docs/18/sql-createtrigger.html), [INSERT / ON CONFLICT](https://www.postgresql.org/docs/18/sql-insert.html), [Transaction Isolation](https://www.postgresql.org/docs/18/transaction-iso.html), and [Serialization Failure Handling](https://www.postgresql.org/docs/18/mvcc-serialization-failure-handling.html).
- AWS Prescriptive Guidance — [Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html), including atomic database/outbox writes and idempotent handling of at-least-once delivery.
- Modern Treasury — [Ledger guarantees](https://docs.moderntreasury.com/ledgers/docs/ledgers-guarantees), [Ledger transaction overview](https://docs.moderntreasury.com/ledgers/docs/ledger-transactions-overview), and [Transaction status and balances](https://docs.moderntreasury.com/ledgers/docs/transaction-status-and-balances). These are industry design references, not a vendor recommendation or selection.
- Martin Fowler — [Patterns for Accounting](https://martinfowler.com/eaaDev/AccountingNarrative.html) and [Accounting Transaction](https://martinfowler.com/eaaDev/AccountingTransaction.html); the latter is explicitly draft historical material and is used only for foundational concepts.

## Stack

This PR is stacked on the P-01 branch spike/p01-tenant-isolation. It does not merge PR #36, change main, deploy, connect to RaidenBet or integrate a payment provider.
