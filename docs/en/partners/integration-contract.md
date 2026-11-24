# Partner Integration Contract

**Document ID:** LOT-INT-001 | **Version:** 0.2.0 | **Status:** Draft; RaidenBet is the initial customer; its actual API contract is not received/verified

## Integration principle
The core uses only its internal canonical model. Each partner has a dedicated adapter; partner-specific logic must not leak into the Commission Core or Ledger.

## Adapter responsibilities
Authenticity/signature validation; event intake and reconciliation; external-ID mapping; currency/time/status normalization; deduplication and idempotency; API version handling; retry, dead-letter, and controlled replay; provenance and trace IDs.

## Potential events
Registration, deposit, withdrawal, qualified activity, NGR adjustment, reversal, and blocking. Existence and meaning must be verified against actual partner documentation.

## Security
TLS; webhook signatures or agreed authentication; secure secret storage/rotation outside Git; timestamp and replay protection; rate and payload-size limits; never log tokens or sensitive data.

## Initial customer status
RaidenBet is the owner-confirmed initial customer for Advanced Affiliate & Agent and Live Chat Widget only. Do not classify it as a provider or infer a signed contract. No customer endpoint, credential, sandbox, webhook schema, or actual API behavior has been received or verified; no operational integration may be claimed. Customer review and explicit approval of the versioned handoff contract must precede connection to its existing script. See LOT-CUSTOMER-PILOT-001.