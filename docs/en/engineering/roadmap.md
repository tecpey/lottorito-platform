# Lottorito Delivery Roadmap

**Document ID:** LOT-ROAD-001 | **Version:** 1.0.0 | **Status:** Proposed sequence; owner approval required for product gates

1. **Foundation & Governance:** bilingual agent handbook, decision register, stable document IDs, glossary, contribution rules and automated documentation checks; keep the finance, security and API baselines explicitly proposed until reviewed.
2. **Cross-product Domain & Data Design:** review LOT-DOM-001; approve independent Affiliate and Lottery bounded contexts, shared capability ownership, logical ERD, data lifecycle, tenant boundaries and migration strategy.
3. **Tenant & Security Architecture:** review LOT-TEN-001 and LOT-SEC-TM-001; complete identity/membership, worker context, trust-boundary analysis, abuse cases, isolation verification, support access and incident-response controls.
4. **API & Event Foundation:** review LOT-API-001 and LOT-EVENT-001; finalize resource/auth conventions, schema compatibility, inbox/outbox, idempotency, webhook signatures and replay controls.
5. **Architecture Quality Baseline:** review LOT-QA-001; define critical journeys, workload profiles, measurable scenarios, invariants and evidence methods. Keep numeric thresholds TBD until accountable owners approve them.
6. **Technology & Platform ADRs:** review LOT-TECH-ADR-001 against LOT-QA-001 and LOT-PROT-001; approve owners and experiment scope, then execute P-01 through P-08 in isolated synthetic environments and obtain owner/security/finance/legal acceptance before selecting stack, hosting, regions or numeric SLO/RPO/RTO.
7. **Global Experience Foundation:** review LOT-I18N-001, LOT-COMMS-001, LOT-GROWTH-001 and LOT-NOTIF-001; establish 12-language parity, live-chat support, approved content/channel workflows and policy-governed smart notifications before implementation.
8. **Identity & Tenant Implementation:** identity, sessions, RBAC, tenant membership and isolation tests.
9. **Affiliate & Attribution:** profiles, referral network, tracking links, events and attribution.
10. **Finance, Wallet, Payment & Payout Core:** review LOT-FIN-POST-001, LOT-WALLET-001, LOT-PAYMENT-001 and LOT-PAYOUT-001 together while preserving their bounded contexts; approve legal/account ownership, unit classes, chart of accounts, immutable posting, balance projections, holds, payment intent/attempt, provider evidence, refunds, payout eligibility, beneficiary controls, settlement and reconciliation. Do not infer custody, stored value or withdrawal permission.
11. **Commission Engine:** versioned rules, CPA/Revenue Share/Hybrid and reproducible calculations.
12. **Provider Evaluation & RFI Governance:** adopt LOT-PROVIDER-EVAL-001 as the common evidence and due-diligence process before supplier selection; confirm accountable reviewers and the exact decision unit. This creates no provider selection or integration authorization.
13. **Affiliate Partner Pilot:** apply the standard to the first Affiliate pilot decision unit; obtain actual partner documentation and an authorized sandbox, then build the Affiliate adapter and contract tests only after approvals.
14. **Lottery Provider Discovery & Certification:** apply the same standard to a separately scoped Lottery decision unit; legal/provider due diligence, capability profile, sandbox evidence, lifecycle adapter and result/settlement reconciliation only after owner approval.
15. **Future regulated gaming discovery (not an MVP delivery commitment):** maintain separate Sportsbook, Live Casino and RNG/E-Gaming discovery tracks; apply the standard for provider RFIs, jurisdiction matrices, domain state machines, wallet/ledger semantics, certification and risk proofs only after Affiliate and Lottery priorities and their gates. See LOT-GAMING-STRATEGY-001.
16. **Admin, Reporting & Operations:** operator/agent/customer surfaces, audit, reporting, support and controlled financial workflows.
17. **First-party B2C application:** review LOT-B2C-PRD-001; implement the dedicated B2C tenant through shared contracts and release only modules passing entitlement, jurisdiction, provider, finance, security, privacy and operational gates.
18. **Hardening & Pilot:** load/security tests, backup recovery, UAT, operational readiness and jurisdiction-specific legal approval.

## Exit gates

A phase is not complete merely because code was written. Owner decisions, acceptance criteria, tests, security review, bilingual documentation and evidence must be complete. Production merge/deployment remains subject to explicit owner authorization.
