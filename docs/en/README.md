# Lottorito — English Documentation

**Document ID:** LOT-DOC-INDEX-EN-001 | **Version:** 1.0.0 | **Status:** Maintained index

This directory is the authoritative English documentation space for Lottorito. The Persian documentation under `docs/fa/` is equally authoritative.

## Product direction

Lottorito's strategic direction is a global, modular, API-first, multi-tenant infrastructure platform supporting two independently usable product families:

1. **Affiliate & Agent Infrastructure** — partner programs, affiliate and agent networks, campaign tracking, attribution, commission policies, financial records, reconciliation, and operational reporting.
2. **Lottery Infrastructure** — provider-neutral lottery integrations and the lifecycle capabilities required to manage catalogs, tickets, results, validation, prizes, and settlement, subject to separate product, legal, provider, and implementation gates.

Shared foundations may include identity and access, tenant management, API contracts, partner adapters, event processing, ledger and finance controls, notifications, audit, reporting, and operations.

This is a strategic product direction, not a statement that all listed capabilities have been implemented or approved for release.

## Documentation map

| Area | Document | Purpose |
|---|---|---|
| Product | [Vision & PRD](product/vision-and-prd.md) | Product principles, proposed scope, roles, acceptance criteria, and open questions |
| Product | [Glossary](product/glossary.md) | Shared domain terminology |
| Architecture | [System architecture](architecture/system-architecture.md) | Proposed modular and multi-tenant architecture |
| Commission | [Commission engine](commission/commission-engine.md) | Versioned commission concepts and unresolved policy choices |
| Finance | [Wallet & ledger](finance/wallet-and-ledger.md) | Financial integrity and ledger principles |
| Partners | [Integration contract](partners/integration-contract.md) | Partner event and delivery boundaries |
| Security | [Security baseline](security/security-baseline.md) | Initial security requirements and controls |
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
