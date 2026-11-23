# Lottorito Product Vision & Requirements

**Document ID:** LOT-PROD-001 | **Version:** 0.1.0 | **Status:** Draft; product-owner approval required

## Vision
Build independent, extensible infrastructure for affiliate programs, agent networks, influencers, acquisition attribution, commissions, wallets, loyalty, and operational reporting, with a partner-independent core and standard APIs.

## Principles
- Partner/operator-independent core.
- Multi-tenancy with strict data and access isolation.
- API-first, versioned contracts.
- Full auditability of events and financial operations.
- Configurable, versioned commission and progression rules.
- Change history and reproducible calculations.
- Incremental delivery backed by tests and evidence.

## Roles
Platform owner, Tenant/Partner administrator, affiliate program manager, Affiliate/Publisher, Agent/network manager, finance operator, support/fraud reviewer, and read-only auditor. Authorization must be checked on every request and within tenant scope.

## Proposed MVP scope
1. Identity, sessions, and RBAC.
2. Tenant and Partner management.
3. Affiliate and Agent profiles.
4. Referral hierarchy with configurable depth; L1–L10 is an initial stated need requiring partner confirmation.
5. Tracking links/codes and attribution.
6. Intake and validation of partner events.
7. CPA, Revenue Share, and Hybrid models.
8. Segregated wallets and double-entry ledger.
9. Performance, commission, and discrepancy reporting.
10. Withdrawal requests and finance-approval workflow.
11. Admin portal, audit, and versioned API/Webhooks.

## Out of scope until separately decided
Custody of end-user funds, banking services, direct payouts without a provider and legal review, guaranteed API compatibility before partner documentation/sandbox access, and automated fraud decisions without human review.

## Acceptance criteria
- Every event has tenant, partner, unique identity, occurrence time, and verifiable source.
- Duplicate events cannot create duplicate financial effects.
- Every calculation references specific inputs and a rule version.
- Statements can be reconstructed from the ledger.
- Cross-tenant access is prevented and proven with negative tests.
- Financial corrections use reversal/adjustment entries, never history edits.
- Every documentation change is made in both languages in the same change.

## Open questions
NGR definition and components; commission recognition time; reversal, chargeback, and negative-carry rules; level progression criteria; ownership, usage, expiry, and withdrawability of the initial USD 100 promotional credit; and legal/geographic restrictions. None may be treated as a fixed implementation rule until documented.