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
| Partners | [Initial customer pilot & delivery plan](partners/initial-customer-pilot-and-delivery-plan.md) | LOT-CUSTOMER-PILOT-001; owner-directed RaidenBet scope limited to Advanced Affiliate & Agent and Live Chat Widget, with customer review and controlled API handoff gates |
| Partners | [Lottery provider contract](partners/lottery-provider-contract.md) | Proposed provider-neutral Lottery lifecycle |
| Partners | [Provider evaluation standard](partners/provider-evaluation-standard.md) | LOT-PROVIDER-EVAL-001; proposed cross-product evidence, RFI, hard gates and decision process |
| Security | [Security baseline](security/security-baseline.md) | Initial security requirements |
| Security | [Threat model](security/threat-model.md) | LOT-SEC-TM-001; proposed trust boundaries, abuse cases and controls |
| Engineering | [API resource specification](engineering/api-resource-specification.md) | LOT-API-001; proposed API, auth, error, pagination and webhook conventions |
| Engineering | [API platform and developer experience](engineering/api-platform-and-developer-experience.md) | LOT-API-PLATFORM-001; proposed control/data planes, app registration, entitlement catalog, credentials, webhooks, SDKs, Developer Portal, sandbox, metering and lifecycle governance |
| Engineering | [Canonical event contract](engineering/canonical-event-contract.md) | Proposed event envelope and delivery semantics |
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
