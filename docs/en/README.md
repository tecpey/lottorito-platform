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


- [Affiliate G09-A17 — Independent Review Reconciliation & Evidence-Gap Closure](engineering/affiliate-g09-a17-review-reconciliation.md) — records the GitHub APPROVED event against its exact reviewed SHA, distinguishes platform approval from A12 substantive-review evidence, and keeps A11 findings/owner decisions open pending a supplemental disposition.


## Enterprise evaluation governance

- [Enterprise Product, Technology and Supplier Evaluation Standard](governance/enterprise-evaluation-standard.md) — LOT-EVAL-001; proposed parent standard for decision framing, risk tiers, evidence, non-compensable gates, fair scoring, total cost, controlled pilots, approvals, monitoring and exit. It governs and points to specialist provider/technology/domain profiles; it selects no candidate.


- [LOT-EVAL-A18-001 — Author-led Adversarial Review & Remediation Record](governance/enterprise-evaluation-adversarial-review-a18.md) — records the original 12 A18 findings plus follow-up REV-01…REV-14, maps the proposed v0.3.0 corrections, and distinguishes owner-led review from independent assurance.

- [LOT-EVAL-OWNER-REVIEW-001 — Owner-led Review & Disposition Register](governance/enterprise-evaluation-owner-review-001.md) — records REV-01…REV-14, owner disposition states, the delegated technical-implementation instruction and the rule that implementation does not equal risk acceptance.

- [LOT-EVAL-AVT-001 — Adversarial Acceptance Test Matrix](governance/enterprise-evaluation-adversarial-test-matrix-001.md) — 21 designed adversarial vectors for REV-01/03/04/12/14; test execution, owner disposition and independent assurance remain pending.

- [Provider Evaluation, Due Diligence and RFI Standard](partners/provider-evaluation-standard.md) — LOT-PROVIDER-EVAL-001 v0.2.0; evidence and scoring semantics inherit the LOT-EVAL-001 parent standard.
- [Technology, Deployment and Reliability ADRs](architecture/technology-deployment-adrs.md) — LOT-TECH-ADR-001 v0.2.0; technology weights remain proposed and inherit the parent rubric.
- [Lottorito Security Threat Model](security/threat-model.md) — LOT-SEC-TM-001 v0.2.0; residual-risk assessment references the parent likelihood/impact anchors.


## LOT-EVAL reference decision model

- [LOT-EVAL-RDM-001 — Reference Decision Model & Adversarial Harness](governance/enterprise-evaluation-reference-decision-model-001.md) — isolated Python standard-library harness for AVT-01…AVT-21 and MUT-01…MUT-10; synthetic/non-production only; independent review and owner disposition pending.


## LOT-EVAL reference-model adversarial audit

- [LOT-EVAL-RDM-002 — Adversarial Audit of the Reference Model and Test Oracles](governance/enterprise-evaluation-reference-model-adversarial-audit-002.md) — author-led audit; identifies unverified matrix properties and defines the independent-oracle and multi-layer verification path. Findings remain open.


- [LOT-EVAL-RDM-003A — Normative Rule Catalogue & Decision Tables](governance/enterprise-evaluation-decision-rule-catalogue-001.md) — author-led decomposition of LOT-EVAL-001 into atomic rules, five decision tables, unresolved-ambiguity register and rule-to-test traceability; independent oracle review and owner disposition pending.

- [LOT-EVAL-RDM-004 — Full Decision-Table Verification](governance/enterprise-evaluation-full-decision-table-verification-004.md) — executable row-level checks for all 36 decision-table rows, eleven metamorphic checks and four targeted specification mutations; exact-head CI #1231 passed on code SHA `2e0eadfcc2bc6200af1410197dcbeaa563e8fed0`; unresolved policy and non-covered atomic rules remain open.


## Historical LOT-EVAL-RDM-003B blind-review draft — superseded

- [Historical LOT-EVAL-RDM-003B — Blind Review Packet](governance/enterprise-evaluation-blind-oracle-review-003b.md) — superseded draft only; no blind review was performed and the 35-row input package was incomplete. Do not use as an active review gate.
- [Historical LOT-EVAL-RDM-003B Worksheet](governance/enterprise-evaluation-blind-oracle-worksheet-003b.md) — superseded blank template; its former 74-entry count is historical and must not be represented as 74 independent tests.


### RDM-003B review correction

- [Author-led adversarial second-pass review](governance/enterprise-evaluation-author-led-second-pass-review-003b.md) — the active review record. The former blind packet and blank worksheet are superseded historical artifacts; no external reviewer or blind oracle is claimed.


- DT05 schema hardening: row R5 directly rejects a missing residual pair; risk schema rejects duplicate/unknown dimensions and blank evidence fields; MT-11 added. Exact-head run #1231 succeeded on `2e0eadfcc2bc6200af1410197dcbeaa563e8fed0`.

- [LOT-EVAL-RDM-005 — Bidirectional Traceability Audit](governance/enterprise-evaluation-bidirectional-traceability-audit-005.md) — static integrity checks for 18 rules, 21 AVTs, 10 specification mutations, 36 decision-table rows, 8 model guards, 11 metamorphic properties and 4 targeted mutations; exact-head CI #1245 passed 376/376 checks. This is structural traceability evidence, not semantic verification or independent assurance.
- [LOT-EVAL-RDM-006 — Normative Gap Research & Owner Decision Pack](governance/enterprise-evaluation-normative-gap-research-006.md) — research-backed options and conservative recommendations for RDM-U01…U05, plus review of weighted scoring; all normative dispositions remain pending owner approval.
