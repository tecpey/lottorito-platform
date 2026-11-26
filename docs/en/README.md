# Lottorito — English Documentation

**Document ID:** LOT-DOC-INDEX-EN-001 | **Version:** 3.1.0 | **Status:** Maintained index

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
| Engineering | [P-01 tenant isolation experiment](engineering/prototypes/p01-tenant-isolation.md) | LOT-PROT-P01-001; partial HTTP/PostgreSQL RLS and async-job experiment; 20 CI tests passed on the parent PR head; full P-01 remains inconclusive |
| Engineering | [P-01 support access prototype](engineering/prototypes/p01-support-breakglass.md) | LOT-PROT-P01-SUPPORT-001; scoped, time-bound, read-only support access with append-only audit; 26 CI tests passed on PR #39, synthetic-only and not production-ready |
| Engineering | [P-01 secondary data-plane isolation](engineering/prototypes/p01-data-plane-isolation.md) | LOT-PROT-P01-DATA-001; cache/object/search/reporting tenant boundaries; 30 CI tests passed on PR #42; synthetic adapters only, provider behavior unverified |
| Engineering | [P-01 tenant credential and pool broker](engineering/prototypes/p01-tenant-pool-broker.md) | LOT-PROT-P01-POOL-001; trusted tenant credential resolution, bounded pools, DB identity verification, lease-safe eviction/revocation/shutdown; 48 CI tests passed on PR #49, synthetic-only and P-01 remains partial |
| Engineering | [P-02 tenant-bound double-entry ledger](engineering/prototypes/p02-ledger-posting.md) | LOT-PROT-P02-001; exact integer amounts, per-currency balancing, immutable journal, request/effect idempotency, hardened SECURITY DEFINER boundary and transactional outbox; 25 CI tests passed on PR #46, synthetic only |
| Engineering | [P-03 tenant-scoped outbox delivery](engineering/prototypes/p03-outbox-delivery.md) | LOT-PROT-P03-001; leased relay, bounded retries/dead-letter, stale-worker fencing, idempotent consumer inbox; 10 CI tests passed on PR #50, synthetic only |
| Engineering | [P-04 schema evolution and compatibility](engineering/prototypes/p04-schema-evolution.md) | LOT-PROT-P04-001; additive expand, old/new app/worker compatibility, resumable tenant-scoped backfill, migration checksum, lock-timeout and concurrent-index recovery; 7 CI tests passed on PR #51, synthetic only |
| Engineering | [P-03C ledger outbox integration](engineering/prototypes/p03-ledger-outbox-integration.md) | LOT-PROT-P03C-001; connects P-02 immutable ledger_outbox to P-03 tenant-scoped delivery state in one PostgreSQL transaction; 15 CI tests passed on PR #60, synthetic-only |
| Engineering | [P-03D provider inbox to ledger integration](engineering/prototypes/p03-provider-ledger-integration.md) | LOT-PROT-P03D-001; signed provider inbox, atomic product-scoped P-02 posting + P-03C outbox; 22 P-03D, 15 P-03C and 25 P-02 CI tests passed on PR #61 head `b75a2e12`; synthetic only |
| Engineering | [P-03 provider event delivery](https://github.com/tecpey/lottorito-platform/pull/41) | Parallel provider-ingress/delivery experiment; 22 synthetic tests reported on PR #41; remains separate from P-02 posting |
| Engineering | [P-05A backup, restore and PITR](engineering/prototypes/p05-backup-restore-recovery.md) | LOT-PROT-P05A-001; physical backup, WAL archive, manifest validation and PITR drills; synthetic recovery proof |
| Engineering | [P-05B object, key and event recovery](engineering/prototypes/p05b-object-key-event-recovery.md) | LOT-PROT-P05B-001; object checksum, wrapped-key failure, ordered replay, idempotency and ledger reconciliation; synthetic recovery proof |
| Engineering | [P-05C failover, fencing and failback](engineering/prototypes/p05c-failover-fencing-failback.md) | LOT-PROT-P05C-001; replication divergence, fencing epochs, rewind and failback; synthetic HA proof, no production RPO/RTO claim |
| Engineering | [P-06 observability and privacy](engineering/prototypes/p06-observability-privacy.md) | LOT-PROT-P06-001; trace/log correlation, HMAC references, tenant RLS, audited forensic access and cardinality controls; synthetic-only |
| Engineering | [P-07A product boundaries](engineering/prototypes/p07a-product-isolation.md) | LOT-PROT-P07A-001; product dependency graph and deny-by-default shared capability ownership; synthetic architecture proof |
| Engineering | [P-07B shared platform and trust boundaries](engineering/prototypes/p07b-shared-trust-boundaries.md) | LOT-PROT-P07B-001; shared capability ownership, contract and authorization boundaries; synthetic security proof |
| Engineering | [P-07C independent product lifecycle](engineering/prototypes/p07c-independent-lifecycle.md) | LOT-PROT-P07C-001; product activation, schema/configuration isolation, promotion/rollback and white-label traceability; 41 CI tests passed, synthetic-only |
| Engineering | [P-08 deployment, health gates and rollback](engineering/prototypes/p08-deployment-health-rollback.md) | LOT-PROT-P08-001; deterministic artifact, provenance consistency, runtime-only secrets, health gates and schema-aware recovery; 45 CI tests passed on PR #59, synthetic-only |
| Engineering | [Agent operating manual](engineering/agent-operating-manual.md) | Low-context task routing and handoff |
| Engineering | [Decision register](engineering/decision-register.md) | Owner directions, proposals and unresolved decisions |
| Engineering | [P-10A production-readiness baseline](engineering/prototypes/p10a-production-readiness-baseline.md) | LOT-PROT-P10A-001; verified PR ancestry, exact-head CI, synthetic limitations and P-10B–P-10F migration/operations gates |
| Engineering | [P-10B read-only source inventory protocol](engineering/prototypes/p10b-read-only-source-inventory.md) | LOT-PROT-P10B-001; scoped read-only authorization, PostgreSQL metadata-only query template, lineage and ambiguity register; no source access executed |
| Engineering | [P-10C staged migration architecture](engineering/prototypes/p10c-migration-architecture.md) | LOT-PROT-P10C-001; source-neutral migration patterns, single-writer coexistence, resumable/idempotent backfill, financial reconciliation, cutover fencing and state-dependent recovery; no source/target selected or migration authorized |
| Engineering | [P-10D security and governance architecture](engineering/prototypes/p10d-security-governance-architecture.md) | LOT-PROT-P10D-001; Zero Trust, scoped authorization, end-to-end tenant isolation, RLS/runtime-role controls, workload identity, secrets/key lifecycle, audit, privacy and security verification; design only, no deployed controls assessed |
| Engineering | [Project status](engineering/project-status.md) | Verified state and continuation point |
| Engineering | [Roadmap](engineering/roadmap.md) | Proposed delivery sequence and gates |

## Automated documentation checks

The structural validator at [scripts/check_docs.py](../../scripts/check_docs.py) checks paired Markdown paths, stable and unique document IDs, level-one titles, version/status metadata, and relative local links. GitHub Actions runs it through the [Documentation Governance workflow](../../.github/workflows/docs-governance.yml). These checks do not establish semantic translation parity; human review remains mandatory. A prior P-08 PR #59 documentation revision (`1046b525...`) passed Documentation Governance in run [45577321154](https://github.com/tecpey/lottorito-platform/actions/runs/45577321154); consult PR #59 for the latest exact-head result. This is structural/link validation, not semantic translation certification.

## Evidence and status discipline

The repository remains documentation-first. A document or design does not prove implementation. Unless repository and test evidence supports it, do not represent application code, database schema, provider connectivity, sandbox certification, financial processing, payout, automated CI or production deployment as complete.

Use explicit states: **Proposed**, **Implemented**, **Verified** and **Blocked**. A claim of Verified must identify the behavior, test/evidence, commit and environment.

## Bilingual synchronization

Every meaningful change under docs/en/ must be made in the same branch and pull request as its semantically equivalent docs/fa/ counterpart. Review parity for formulas, amounts, constraints, statuses, examples, acceptance criteria and security requirements—not merely file existence.

## Governance

Read repository-root [AGENTS.md](../../AGENTS.md). Use a working branch and pull request. Do not merge, deploy, change repository settings or perform destructive operations without explicit owner authorization.


## Reliability and disaster recovery

- [P-10E — Reliability, Resilience and Disaster Recovery Architecture](engineering/prototypes/p10e-reliability-disaster-recovery-architecture.md): source-neutral design baseline for backup, recovery, failover, tenant restore, SLOs and DR evidence; not operational approval.
