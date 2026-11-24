# Lottorito Delivery Roadmap

**Document ID:** LOT-ROAD-001 | **Version:** 0.1.0 | **Status:** Proposed and subject to review

1. **Foundation & Governance:** bilingual agent handbook, decision register, document indexes, glossary, ADRs, contribution rules and automated parity CI.
2. **Cross-product Domain & Data Design:** independent Affiliate and Lottery bounded contexts, shared capability ownership, domain model, ERD, data lifecycle, tenant boundaries and migration strategy.
3. **Platform Skeleton:** select stack; scaffold API/Worker/Web, secure config, logging, health, and baseline CI.
4. **Identity & Tenant:** identity, sessions, RBAC, tenant membership, and isolation tests.
5. **Affiliate & Attribution:** profiles, referral network, tracking links, events, and attribution.
6. **Finance Core:** chart of accounts, ledger, invariants, statements, and reconciliation.
7. **Commission Engine:** versioned rules, CPA/Revenue Share/Hybrid, and reproducible calculations.
8. **Affiliate Partner Pilot:** obtain actual partner documentation and sandbox, build the Affiliate adapter and contract tests.
9. **Lottery Provider Discovery & Certification:** legal/provider due diligence, capability profile, sandbox evidence, lifecycle adapter and result/settlement reconciliation; only after owner approval.
10. **Admin, Reporting & Operations:** operator/agent/customer surfaces, audit, reporting, support and controlled financial workflows.
11. **Hardening & Pilot:** threat model, load/security tests, backup recovery, UAT, operational readiness and jurisdiction-specific legal approval.

## Exit gates
A phase is not complete merely because code was written. Acceptance criteria, tests, security review, bilingual documentation, and evidence must be complete. Production merge/deployment remains subject to owner authorization.