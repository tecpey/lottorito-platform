# Wallet and Ledger Architecture

**Document ID:** LOT-FIN-001 | **Version:** 0.1.0 | **Status:** Sensitive draft; finance/product approval required

## Foundational rule
An immutable double-entry ledger is the financial source of truth. Displayed balances are derived from postings for an account and currency; directly mutating a balance is not a financial operation.

## Account separation
Promotional credit, pending commission, approved commission, held funds, withdrawal-eligible amounts, and settlement clearing accounts must be distinguished. These need not be separate physical wallets; the chart of accounts and transfer rules define them.

## Double-entry posting
Each journal entry has at least two balanced lines; debits equal credits per currency. Posted entries are never edited or deleted; corrections use reversal and replacement entries.

## Mandatory controls
Decimal/fixed precision and explicit currency; never floating point for money. Idempotency keys; concurrency control; permitted state transitions; actor, time, reason, source, correlation ID, and rule version; currency separation; periodic reconciliation; and dual control for sensitive operations.

## USD 100 example
USD 100 is an initial example only, not a default or financial commitment. Ownership, allowed usage, transferability, withdrawability, expiry, clawback, allocator, and budget cap must be decided. Until then, keep it separate from withdrawable commission.

## Tests
Test balancing, idempotency, concurrency, reversals, permitted/prohibited negatives, rounding, multi-currency behavior, tenant isolation, and statement reconstruction.