# Lottorito — English Documentation

**Document ID:** LOT-DOC-INDEX-EN-001 | **Version:** 1.0.0 | **Status:** Maintained index

This directory is the authoritative English documentation space for Lottorito. The Persian documentation under `docs/fa/` is equally authoritative.

## Product direction

Lottorito's strategic direction is a global, modular, API-first, multi-tenant infrastructure platform supporting two independently usable product families:

1. **Affiliate & Agent Infrastructure** — partner programs, affiliate and agent networks, campaign tracking, attribution, commission policies, financial records, reconciliation, and operational reporting.
2. **Lottery Infrastructure** — provider-neutral lottery integrations and the lifecycle capabilities required to manage catalogs, tickets, results, validation, prizes, and settlement, subject to separate product, legal, provider, and implementation gates.

Shared foundations may include identity and access, tenant management, API contracts, partner adapters, event processing, ledger and finance controls, notifications, audit, reporting, and operations.

This is a strategic product direction, not a statement that all listed capabilities have been implemented or approved for release.

## Documentation coverage note

The current `LOT-PROD-001` and `LOT-ARCH-001` files remain early, Affiliate-led drafts; they are not a complete cross-product PRD or approved architecture. A separate Lottery discovery PRD (`LOT-LOTTERY-001`) and provider-neutral lifecycle contract baseline (`LOT-LOTINT-001`) now exist as proposals. They do not establish provider compatibility, legal approval, implementation authorization, or a complete cross-product architecture. Provider-specific profiles and cross-product architecture still require evidence and review.

## Documentation map

| Area | Document | Purpose |
|---|---|---|
| Product | [Vision & PRD](product/vision-and-prd.md) | Initial Affiliate-led requirements draft; not a complete Lottery PRD |
| Product | [Lottery PRD](product/lottery-prd.md) | Proposed Lottery discovery baseline; not approved for implementation or launch |
| Product | [Glossary](product/glossary.md) | Shared domain terminology |
| Architecture | [System architecture](architecture/system-architecture.md) | Initial architecture proposal; full cross-product topology remains pending |
| Architecture | [Domain model & logical ERD](architecture/domain-model-and-erd.md) | Proposed cross-product ownership and logical relationships; not a physical schema |
| Architecture | [Tenant isolation model](architecture/tenant-isolation-model.md) | Proposed identity/context propagation and isolation controls |
| Commission | [Commission engine](commission/commission-engine.md) | Versioned commission concepts and unresolved policy choices |
| Finance | [Wallet & ledger](finance/wallet-and-ledger.md) | Draft financial integrity and ledger principles; product-specific mappings remain open |
| Partners | [Integration contract](partners/integration-contract.md) | Initial Affiliate partner-event contract |
| Partners | [Lottery provider contract](partners/lottery-provider-contract.md) | Proposed provider-neutral lifecycle contract; no provider API verified |
| Security | [Security baseline](security/security-baseline.md) | Initial security requirements and controls |
| Engineering | [Canonical event contract](engineering/canonical-event-contract.md) | Proposed event envelope, identity separation, time and delivery semantics |
| Engineering | [Agent operating manual](engineering/agent-operating-manual.md) | Low-context task routing, evidence rules and handoff standard |
| Engineering | [Decision register](engineering/decision-register.md) | Owner directions, proposals and unresolved decisions |
| Engineering | [Project status](engineering/project-status.md) | Verified state and continuation point |
| Engineering | [Roadmap](engineering/roadmap.md) | Proposed delivery sequence and gates |

## Evidence and status discipline

The repository is currently documentation-first. The existence of a document or a proposed design does not prove implementation. Unless supported by repository and test evidence, the following must not be represented as complete: application code, database schema, provider connectivity, sandbox certification, financial processing, payout, automated CI, or production deployment.

Use explicit status language:

- **Proposed** — a design or requirement awaiting decision.
- **Implemented** — code or configuration exists in the repository.
- **Verified** — the stated behavior has passed its defined verification with recorded evidence.
- **Blocked** — progress depends on an unresolved decision, access, or external prerequisite.

## Bilingual synchronization

Every meaningful change under `docs/en/` must be made in the same branch and pull request as its semantically equivalent Persian counterpart under `docs/fa/`. Review parity for formulas, amounts, constraints, statuses, examples, acceptance criteria, and security requirements—not merely file existence.

## Governance

Read the repository-root [AGENTS.md](../../AGENTS.md) before contributing. Use a working branch and pull request. Do not merge, deploy, change repository settings, or perform destructive operations without explicit owner authorization.
