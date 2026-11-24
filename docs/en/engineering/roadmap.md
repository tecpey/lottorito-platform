# Lottorito Delivery Roadmap

**Document ID:** LOT-ROAD-001 | **Version:** 0.3.0 | **Status:** Proposed sequence; owner approval required for product gates

1. **Foundation & Governance:** bilingual agent handbook, decision register, stable document IDs, glossary, contribution rules and automated documentation checks; keep the finance, security and API baselines explicitly proposed until reviewed.
2. **Cross-product Domain & Data Design:** review LOT-DOM-001; approve independent Affiliate and Lottery bounded contexts, shared capability ownership, logical ERD, data lifecycle, tenant boundaries and migration strategy.
3. **Tenant & Security Architecture:** review LOT-TEN-001 and LOT-SEC-TM-001; complete identity/membership, worker context, trust-boundary analysis, abuse cases, isolation verification, support access and incident-response controls.
4. **API & Event Foundation:** review LOT-API-001 and LOT-EVENT-001; finalize resource/auth conventions, schema compatibility, inbox/outbox, idempotency, webhook signatures and replay controls.
5. **Technology & Platform ADRs:** select stack and deployment model through evidence-backed ADRs; define secure configuration, logging, health, reliability and baseline CI.
6. **Identity & Tenant Implementation:** identity, sessions, RBAC, tenant membership and isolation tests.
7. **Affiliate & Attribution:** profiles, referral network, tracking links, events and attribution.
8. **Finance Core:** review LOT-FIN-POST-001; approve account ownership, chart of accounts, immutable posting, balance semantics, statements, reconciliation and payout gates.
9. **Commission Engine:** versioned rules, CPA/Revenue Share/Hybrid and reproducible calculations.
10. **Affiliate Partner Pilot:** obtain actual partner documentation and sandbox, build the Affiliate adapter and contract tests.
11. **Lottery Provider Discovery & Certification:** legal/provider due diligence, capability profile, sandbox evidence, lifecycle adapter and result/settlement reconciliation; only after owner approval.
12. **Admin, Reporting & Operations:** operator/agent/customer surfaces, audit, reporting, support and controlled financial workflows.
13. **Hardening & Pilot:** load/security tests, backup recovery, UAT, operational readiness and jurisdiction-specific legal approval.

## Exit gates
A phase is not complete merely because code was written. Owner decisions, acceptance criteria, tests, security review, bilingual documentation and evidence must be complete. Production merge/deployment remains subject to explicit owner authorization.