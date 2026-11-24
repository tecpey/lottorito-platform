# Partner Integration Contract

**Document ID:** LOT-INT-001 | **Version:** 0.2.0 | **Status:** Draft; actual RaidenBet contract not received/verified

## Integration principle
The core uses only its internal canonical model. Each partner has a dedicated adapter; partner-specific logic must not leak into the Commission Core or Ledger.

## Adapter responsibilities
Authenticity/signature validation; event intake and reconciliation; external-ID mapping; currency/time/status normalization; deduplication and idempotency; API version handling; retry, dead-letter, and controlled replay; provenance and trace IDs.

## Potential events
Registration, deposit, withdrawal, qualified activity, NGR adjustment, reversal, and blocking. Existence and meaning must be verified against actual partner documentation.

## Security
TLS; webhook signatures or agreed authentication; secure secret storage/rotation outside Git; timestamp and replay protection; rate and payload-size limits; never log tokens or sensitive data.

## Pilot status
### Proposed delivery contract and acceptance cases (LOT-004)

| Case | Required result |
|---|---|
| Concurrent redelivery; worker crash after posting but before acknowledgment | Persist authenticated intake before acknowledging receipt. Commit each financial effect and its unique processing key atomically. On retry, return the recorded outcome; exactly one posting survives. |
| Same key, changed economic content | Compare normalized business fields, excluding transport metadata. Quarantine conflict; retain both receipt references for reconciliation. Never overwrite the original posting. |
| Same external ID on two connections | Derive Tenant and connection from authenticated credentials. Each connection uses its own contracted identity scope; reject conflicting payload Tenant before effects. |
| Reversal arrives before original | Hold unresolved reference; reconcile against the original in the same connection. After matching, apply approved reversal policy once; never infer chronology from receipt order. |
| No guaranteed identity scope or unknown schema version | Quarantine with a reason. No financial effects until mapping and identity rules are verified. Authorized replay uses original effect identity, not a fresh key. |

Design evidence: [Stripe webhook delivery](https://docs.stripe.com/webhooks) documents duplicates and unordered delivery; [AWS on idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/) distinguishes retries from changed intent. These motivate the cases above; neither establishes RaidenBet behavior. Obtain signed sample fixtures, ID scope, retry horizon, reconciliation feed and correction semantics before approving a partner adapter.

### Evidence available
RaidenBet is the proposed pilot partner. No endpoint, credential, sandbox, webhook schema, or actual API behavior has been verified in this repository; no operational integration may be claimed.
