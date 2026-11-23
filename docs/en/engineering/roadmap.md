# Lottorito Delivery Roadmap

**Document ID:** LOT-ROAD-001 | **Version:** 0.1.0 | **Status:** Proposed and subject to review

1. **Foundation & Governance:** complete documentation, glossary, ADRs, contribution rules, and parity CI.
2. **Domain & Data Design:** domain model, ERD, data lifecycle, tenant boundaries, and migration strategy.
3. **Platform Skeleton:** select stack; scaffold API/Worker/Web, secure config, logging, health, and baseline CI.
4. **Identity & Tenant:** identity, sessions, RBAC, tenant membership, and isolation tests.
5. **Affiliate & Attribution:** profiles, referral network, tracking links, events, and attribution.
6. **Finance Core:** chart of accounts, ledger, invariants, statements, and reconciliation.
7. **Commission Engine:** versioned rules, CPA/Revenue Share/Hybrid, and reproducible calculations.
8. **Partner Pilot:** obtain actual documentation and sandbox, build adapter, and contract tests.
9. **Admin & Reporting:** dashboards, audit, reports, and withdrawal workflow.
10. **Hardening & Pilot:** threat model, load/security tests, backup recovery, UAT, and legal approval.

## Exit gates
A phase is not complete merely because code was written. Acceptance criteria, tests, security review, bilingual documentation, and evidence must be complete. Production merge/deployment remains subject to owner authorization.