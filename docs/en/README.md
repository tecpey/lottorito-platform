# Lottorito — English Documentation

**Document ID:** LOT-DOC-INDEX-EN-001 | **Version:** 2.4.0 | **Status:** Maintained index

This directory is the authoritative English documentation space for Lottorito. The Persian documentation under docs/fa/ is equally authoritative.

## Product direction

Lottorito's strategic direction is a global, modular, API-first, multi-tenant infrastructure platform supporting two independently usable product families:

1. **Affiliate & Agent Infrastructure** — partner programs, affiliate and agent networks, campaign tracking, attribution, commission policies, financial records, reconciliation, and operational reporting.
2. **Lottery Infrastructure** — provider-neutral lottery integrations and lifecycle capabilities for catalogs, tickets, results, validation, claims, prizes and settlement, subject to separate product, legal, provider and implementation gates.

Shared foundations may include identity and access, tenant management, API contracts, partner adapters, event processing, ledger and finance controls, notifications, audit, reporting and operations. This is strategic direction, not proof of implementation or release approval.

## Documentation coverage and maturity

LOT-PROD-001 and LOT-ARCH-001 remain early Affiliate-led drafts, not complete cross-product requirements or approved architecture. LOT-LOTTERY-001 and LOT-LOTINT-001 are discovery proposals, not provider compatibility or launch approval. LOT-DOM-001, LOT-TEN-001 and LOT-EVENT-001 are proposed architecture contracts, not physical schema or implemented services.

LOT-FIN-POST-001 defines proposed financial posting and reconciliation controls; it is not an accounting policy or permission to custody or pay funds. LOT-SEC-TM-001 is a proposed threat model, not a penetration test or security certification. LOT-API-001 is a proposed API contract baseline, not an implemented or published API. LOT-QA-001 defines proposed measurable quality scenarios and release gates; thresholds remain TBD pending approval. LOT-TECH-ADR-001 defines a proposed decision framework for technology, deployment, reliability, observability and data lifecycle; no stack or vendor is approved. LOT-PROVIDER-EVAL-001 defines a proposed cross-product evidence, RFI, due-diligence and provider approval process; no provider is selected.

## Documentation map

| Area | Document | Purpose |
|---|---|---|
| Product | [Vision & PRD](product/vision-and-prd.md) | Initial Affiliate-led requirements draft |
| Product | [Lottery PRD](product/lottery-prd.md) | Proposed Lottery discovery baseline |
| Product | [Glossary](product/glossary.md) | Shared domain terminology |
| Architecture | [System architecture](architecture/system-architecture.md) | Initial architecture proposal |
| Architecture | [Domain model & logical ERD](architecture/domain-model-and-erd.md) | Proposed ownership and logical relationships; not physical schema |
| Architecture | [Tenant isolation model](architecture/tenant-isolation-model.md) | Proposed identity/context and isolation controls |
| Architecture | [Technology, deployment & reliability ADRs](architecture/technology-deployment-adrs.md) | LOT-TECH-ADR-001; proposed decision framework, no stack/provider approved |
| Architecture | [Quality attributes](architecture/quality-attributes.md) | LOT-QA-001; proposed measurable quality scenarios and release gates, thresholds TBD |
| Commission | [Commission engine](commission/commission-engine.md) | Versioned commission concepts and open policy choices |
| Finance | [Wallet & ledger](finance/wallet-and-ledger.md) | Initial ledger principles and open mappings |
| Finance | [Posting & reconciliation model](finance/financial-posting-and-reconciliation.md) | LOT-FIN-POST-001; proposed accounting controls, states and reconciliation |
| Finance | [Wallet domain and balance contract](finance/wallet-domain-contract.md) | LOT-WALLET-001; proposed ownership, wallet classes, typed units, balance projections, holds, transfers and ledger boundary; no custody/payment/payout approval |
| Finance | [Payout, withdrawal and disbursement contract](finance/payout-withdrawal-contract.md) | LOT-PAYOUT-001; proposed customer withdrawal, commission/prize disbursement, beneficiary verification, approvals, holds, provider execution and reconciliation; no payout authorization |
| Partners | [Affiliate integration contract](partners/integration-contract.md) | LOT-INT-001; initial partner-event and adapter boundary; actual partner API and sandbox not verified |
| Partners | [Affiliate & Agent API capability contract](partners/affiliate-agent-api-contract.md) | LOT-AFFILIATE-API-001; proposed program, membership, hierarchy, campaign, referral, attribution, partner-event, commission and reporting API inventory |
| Partners | [Lottery provider contract](partners/lottery-provider-contract.md) | Proposed provider-neutral Lottery lifecycle |
| Partners | [Provider evaluation standard](partners/provider-evaluation-standard.md) | LOT-PROVIDER-EVAL-001; proposed cross-product evidence, RFI, hard gates and decision process |
| Security | [Security baseline](security/security-baseline.md) | Initial security requirements |
| Security | [Threat model](security/threat-model.md) | LOT-SEC-TM-001; proposed trust boundaries, abuse cases and controls |
| Engineering | [API resource specification](engineering/api-resource-specification.md) | LOT-API-001; proposed API, auth, error, pagination and webhook conventions |
| Engineering | [API platform and developer experience](engineering/api-platform-and-developer-experience.md) | LOT-API-PLATFORM-001; proposed control/data planes, app registration, entitlement catalog, credentials, webhooks, SDKs, Developer Portal, sandbox, metering and lifecycle governance |
| Engineering | [Canonical event contract](engineering/canonical-event-contract.md) | LOT-EVENT-001; proposed event envelope and delivery semantics |
| Engineering | [Affiliate API wire contract](engineering/affiliate-api-wire-contract.md) | LOT-AFFILIATE-WIRE-001; proposed OpenAPI/AsyncAPI wire profile and CloudEvents ingress; no endpoint or partner mapping approved |
| Engineering | [Affiliate wire security review](engineering/affiliate-wire-security-review.md) | LOT-AFFILIATE-SEC-001; threat-oriented contract review, findings and pre-implementation/production gates |
| Architecture | [Global localization standard](architecture/global-localization-standard.md) | LOT-I18N-001; 12 launch languages and equal quality gates |
| Architecture | [Live chat and customer communications](architecture/live-chat-and-communications.md) | LOT-COMMS-001; multilingual support and human handoff |
| Architecture | [Unified multi-tenant B2B2C platform architecture](architecture/unified-b2b2c-platform-architecture.md) | LOT-PLATFORM-001; proposed B2B/B2C/white-label experiences, tenants, identity, dashboards, wallet, payments, chat, security and delivery roadmap |
| Architecture | [Payment orchestration and provider adapter contract](architecture/payment-orchestration-contract.md) | LOT-PAYMENT-001; proposed provider-neutral intents/attempts, adapters, callbacks, routing, refunds, settlement and reconciliation; no provider selected |
| Product | [Role-based dashboards and workspace blueprint](product/role-based-dashboards-blueprint.md) | LOT-DASH-001; detailed workspaces for Platform, Tenant, White-Label, Affiliate/Agent, Support, Finance, Compliance and B2C, with journeys, KPIs and acceptance tests |
| Product | [First-party B2C application PRD](product/first-party-b2c-app-prd.md) | LOT-B2C-PRD-001; dedicated B2C tenant, customer journeys, eligible module composition, wallet/payments/payouts, chat, support, localization and release gates |
| Architecture | [Tenant, identity, membership and authorization model](architecture/tenant-identity-authorization-model.md) | LOT-IAM-TENANT-001; tenant lifecycle, principal/membership model, RBAC/ABAC, dashboard access matrix, isolation and security acceptance tests |
| Architecture | [Embeddable chat module](architecture/embeddable-chat-module.md) | LOT-CHAT-WIDGET-001; reusable first-party and third-party widget, secure session bootstrap and API contract |
| Architecture | [Future gaming domains and provider strategy](architecture/future-gaming-domains-and-provider-strategy.md) | LOT-GAMING-STRATEGY-001; future Sportsbook, Live Casino and E-Gaming taxonomy, provider RFI and regulatory gates |
| Architecture | [Growth content automation](architecture/growth-content-automation.md) | LOT-GROWTH-001; multilingual SEO/GEO/AEO and channel workflow |
| Architecture | [Smart notifications](architecture/smart-notifications.md) | LOT-NOTIF-001; policy-gated inbox and delivery |
| Engineering | [Architecture prototype and evidence plan](engineering/architecture-prototype-plan.md) | LOT-PROT-001; eight required experiments and acceptance evidence |
| Engineering | [Agent operating manual](engineering/agent-operating-manual.md) | Low-context task routing and handoff |
| Engineering | [Decision register](engineering/decision-register.md) | Owner directions, proposals and unresolved decisions |
| Engineering | [Project status](engineering/project-status.md) | Verified state and continuation point |
| Engineering | [Roadmap](engineering/roadmap.md) | Proposed delivery sequence and gates |

## Automated documentation checks

The structural validator at [scripts/check_docs.py](../../scripts/check_docs.py) checks paired Markdown paths, stable and unique document IDs, level-one titles, version/status metadata, and relative local links. GitHub Actions runs it through the [Documentation Governance workflow](../../.github/workflows/docs-governance.yml). These checks do not establish semantic translation parity; human review remains mandatory. The workflow has been added on the working branch; consult its run result before treating it as passing.

## Evidence and status discipline

The repository remains documentation-first. A document or design does not prove implementation. Unless repository and test evidence supports it, do not represent application code, database schema, provider connectivity, sandbox certification, financial processing, payout, automated CI or production deployment as complete.

Use explicit states: **Proposed**, **Implemented**, **Verified** and **Blocked**. A claim of Verified must identify the behavior, test/evidence, commit and environment.

## Bilingual synchronization

Every meaningful change under docs/en/ must be made in the same branch and pull request as its semantically equivalent docs/fa/ counterpart. Review parity for formulas, amounts, constraints, statuses, examples, acceptance criteria and security requirements—not merely file existence.

## Governance

Read repository-root [AGENTS.md](../../AGENTS.md). Use a working branch and pull request. Do not merge, deploy, change repository settings or perform destructive operations without explicit owner authorization.

## Affiliate security acceptance

- [Affiliate security acceptance and runtime boundary](engineering/affiliate-security-acceptance-runtime-boundary.md) — LOT-AFFILIATE-SEC-ACC-001; proposed runtime acceptance matrix, trust boundaries, idempotency, persistence, privacy and release gates; no runtime implementation or production approval.


## Affiliate G09-A3 security decisions and runtime proof

- [Affiliate G09-A3 decision packet and synthetic runtime proof plan](engineering/affiliate-g09-a3-decision-and-runtime-proof.md) — LOT-AFFILIATE-G09-A3-001; proposed decision records for IAM, installation/event registry, idempotency/fingerprinting, resource governance, data lifecycle, audit and economic-effect boundary, plus an isolated synthetic runtime proof plan. No decisions are approved and no runtime implementation is claimed.


## Affiliate G09-A4 runtime proof architecture

- [Affiliate G09-A4 runtime proof architecture and adversarial test design](engineering/affiliate-g09-a4-runtime-proof-architecture.md) — LOT-AFFILIATE-G09-A4-001; proposed isolated harness, trust boundaries, persistence invariants, 47 adversarial cases, independent test oracles, evidence requirements and stop gates. No runtime implementation or technology selection is approved.

- [Affiliate G09-A5 — Runtime Proof Readiness & Implementation Blueprint](engineering/affiliate-g09-a5-runtime-proof-readiness.md) — proposed logical persistence, atomicity, worker fencing, fixture, failure-injection and executable-test blueprint; no runtime approval.


## Affiliate G09-A6 design verification

- [Affiliate G09-A6 — Design Verification & Proof Closure](engineering/affiliate-g09-a6-design-verification.md) — LOT-AFFILIATE-G09-A6-001; independent document-level review of A4/A5, 47-case traceability, ten findings and runtime-proof blockers. Conditional design pass only; no runtime authorization.


## Affiliate G09-A7 — 47-case traceability

- [Affiliate G09-A7 — 47-Case Traceability & Decision Closure Blueprint](engineering/affiliate-g09-a7-47-case-traceability.md) — LOT-AFFILIATE-G09-A7-001; 47 individual stable A4 cases, synthetic fixtures, protocol/persistence/security/financial assertions, independent oracles, evidence contract, deterministic race schedules and F01–F10 closure register. Design only; all cases NOT RUN; runtime remains blocked.

- [Affiliate G09-A8 — Independent Verification & Adversarial Challenge](engineering/affiliate-g09-a8-independent-verification.md) — design self-review only; independent review pending; no runtime authorization.

- [Affiliate ADR-001 — Durable WorkItem Claim, Lease & Fencing](engineering/adr-001-workitem-claim-lease-fencing.md) — proposed temporal protocol; owner approval and independent review pending; no runtime authorization.


## Affiliate G09 decision records

- [Affiliate ADR-001 — Durable WorkItem Claim, Lease & Fencing](engineering/adr-001-workitem-claim-lease-fencing.md) — proposed temporal protocol; owner approval and independent review pending.
- [Affiliate ADR-002 — Atomic Ingress Acceptance & Unknown-Commit Reconciliation](engineering/adr-002-atomic-ingress-acceptance-reconciliation.md) — proposed atomic InboxReceipt + WorkItem acceptance, unknown-commit reconciliation, crash matrix and open owner decisions; no runtime authorization.


- [Affiliate G09-A11 — ADR-002 Adversarial Design Review](engineering/affiliate-g09-a11-adr002-adversarial-review.md) — same-workflow self-review; eight material findings and nine proposed NOT RUN subcases; independent review pending; no runtime authorization.

- [Affiliate G09-A12 — ADR-002 Independent Review Package](engineering/affiliate-g09-a12-adr002-independent-review-package.md) — reviewer-ready challenge protocol and evidence matrix; independent review NOT PERFORMED; all A11 findings remain OPEN; no runtime authorization.

- [Affiliate G09-A13 — Contract Validation Assurance Review](engineering/affiliate-g09-a13-contract-validation-assurance-review.md) — same-author review of exact-head CI scope, security/scope assertions, AsyncAPI dialect, dependency reproducibility, extension constraints and UNKNOWN response semantics; findings OPEN.

- [Affiliate G09-A14 — Contract Validation Hardening & Response-State Alignment](engineering/affiliate-g09-a14-contract-validation-hardening.md) — exact operation security/scope manifest, CloudEvents profile, AsyncAPI dialect guard, reproducible lockfiles and 11-root/53-fixture coverage; technical hardening verified on exact head `736390f86ab425a8c273dcf254cc5974e9eb55ae`; runtime/owner decisions remain open.


- [Affiliate G09-A15 — ADR-002 Persistence Proof Readiness & Owner Decision Matrix](engineering/affiliate-g09-a15-persistence-proof-readiness.md) — candidate-neutral proof obligations, 12 owner decisions, 12 deterministic proof schedules, independent evidence contract and staged gates; no candidate selected and no runtime proof executed.

- [Affiliate G09-A16 — ADR-002 Adversarial Architecture Review & Independent Reviewer Dossier](engineering/affiliate-g09-a16-adversarial-architecture-review.md) — author-led meta-review with ten cross-cutting challenge points, twelve deterministic schedule families, independent-oracle contract and reviewer hand-off; not independent sign-off or runtime proof.
- [Affiliate G09-A17 — ADR-002 Owner Decision Research & Recommendation Dossier](engineering/affiliate-g09-a17-adr002-owner-decision-research.md) — evidence-based analysis of OD-01..OD-12, conditional recommendations, rejected alternatives, proof requirements, decision dependencies and candidate hard gates; no owner decisions or technology selection made.

- [Affiliate G09-A18 — Persistence & Authority Candidate Architecture Evaluation](engineering/affiliate-g09-a18-persistence-authority-candidate-evaluation.md) — comparative research on engineered PostgreSQL HA, managed PostgreSQL HA, Distributed SQL, conditional Spanner and authority/outbox separation; defines G1–G7 hard gates and an R1 evidence plan; no candidate selected or runtime authorized.
- [Affiliate G09-A19 — Deployment Constraints & Candidate Qualification Matrix](engineering/affiliate-g09-a19-deployment-constraints-candidate-qualification.md) — constraint-first qualification: C-01..C-16 owner inputs, full data-flow/location inventory, G1–G9 hard gates, BIA-based recovery objectives and reproducible measurement; no provider, region or database selected.


## Affiliate G09-A20 — evidence acquisition and adversarial qualification

- [Affiliate G09-A20 — Constraint Evidence Acquisition & Adversarial Qualification Design](engineering/affiliate-g09-a20-constraint-evidence-adversarial-qualification.md) — evidence register for C-01..C-16, full data-flow inventory, candidate-neutral invariants/oracles, 28 adversarial test designs, execution safety gates and reproducibility manifest; all cases NOT RUN, no candidate qualified, no runtime authorization.


## Affiliate G09-A21 — adversarial assurance review

- [Affiliate G09-A21 — Adversarial Assurance Review of G09-A20](engineering/affiliate-g09-a21-adversarial-assurance-review.md) — internal self-review, not independent assurance; records 13 open findings (P0:1, P1:9, P2:3), traceability gaps and controlled A22–A24 remediation sequence. A20 remains research/test-design only; no runtime authorization.


## Affiliate G09-A22 — A20 specification remediation

- [Affiliate G09-A22 — A20 Specification Remediation](engineering/affiliate-g09-a22-a20-specification-remediation.md) — decision-gated identity/canonicalization, UNKNOWN-commit protocol, external receiver guarantees, retention/restore lifecycle, traceability, test-result semantics and strict synthetic-only financial boundary. Research only; no runtime authorization.
