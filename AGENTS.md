# Lottorito — Agent Operating Guide

## Mission
Continue Lottorito from the repository's verified state. Do not restart planning, recreate existing files, or claim unfinished work is complete.

## Before every task
1. Read this guide, then follow docs/en/engineering/agent-operating-manual.md (LOT-AGENT-001) or its Persian counterpart for token-efficient task routing.
2. Read the relevant language versions of docs/en/engineering/project-status.md (LOT-OPS-001) and docs/en/engineering/decision-register.md (LOT-ADR-REG-001).
3. Inspect current branches, files, issues, pull requests, and implementation before editing.
4. Search for existing modules, tests, and documents before creating replacements.
5. State assumptions explicitly; unresolved business rules must remain open questions.
6. Read only the domain documents required by the task; do not load the entire documentation set by default.

## Mandatory bilingual documentation
- docs/fa and docs/en are equally authoritative.
- Every document has a counterpart at the same relative path and a stable document ID.
- Update both language versions in the same commit or pull request.
- Preserve semantic parity for amounts, formulas, constraints, statuses, examples, and acceptance criteria.
- File existence alone does not prove synchronization.
- A structural validator is available at scripts/check_docs.py and is run by .github/workflows/docs-governance.yml. It checks paired Markdown paths, stable/unique IDs, level-one titles, version/status metadata and local links; it does not prove semantic translation parity.
- Reviewers must continue manually comparing both versions for meaning, formulas, amounts, constraints and policy status.

## Engineering rules
- Prefer small, reviewable, independently testable changes.
- Use feature branches and pull requests; do not push unfinished work directly to main once CI and branch protections are available.
- Do not merge, deploy, rotate secrets, change repository visibility, or perform destructive data operations without explicit owner approval.
- Never commit credentials, tokens, personal data, real player data, or production exports.
- Use parameterized SQL, strict input validation, authorization at every boundary, tenant scoping, idempotency for event ingestion, and audit logs for privileged actions.
- Financial correctness is a release blocker. Use an immutable double-entry ledger; never use direct balance mutation as the source of truth.
- Test happy paths, boundaries, duplicate/replayed events, concurrency, tenant isolation, reversals, and failure recovery.
- Report exact commands, results, skipped checks, and limitations. Never fabricate test or CI evidence.

## Verified baseline at 2026-11-24
- Repository: tecpey/lottorito-platform; default branch: main; visibility: public by owner decision.
- The repository contains paired Persian/English product, architecture, commission, finance, partner, security, glossary, roadmap and status documents.
- Agent operating manual (LOT-AGENT-001), decision register (LOT-ADR-REG-001), Lottery discovery PRD (LOT-LOTTERY-001), Lottery provider contract (LOT-LOTINT-001), finance posting (LOT-FIN-POST-001), threat model (LOT-SEC-TM-001), API resource specification (LOT-API-001), technology/deployment ADRs (LOT-TECH-ADR-001), and architecture quality attributes (LOT-QA-001), architecture prototype evidence plan (LOT-PROT-001), global localization standard (LOT-I18N-001), live chat architecture (LOT-COMMS-001), growth/content automation (LOT-GROWTH-001), and smart notification architecture (LOT-NOTIF-001), embeddable chat module architecture (LOT-CHAT-WIDGET-001), future regulated gaming domains and provider strategy (LOT-GAMING-STRATEGY-001), and cross-product provider evaluation/RFI standard (LOT-PROVIDER-EVAL-001), wallet domain and balance contract (LOT-WALLET-001), payment orchestration and provider adapter contract (LOT-PAYMENT-001), payout and withdrawal contract (LOT-PAYOUT-001), first-party B2C application PRD (LOT-B2C-PRD-001), API platform and developer experience (LOT-API-PLATFORM-001), Affiliate & Agent API capability contract (LOT-AFFILIATE-API-001) are maintained in documentation work branches pending review. The 12-language target is owner-directed; locale shortlist, quality gates, provider choices and implementations remain subject to review and approval. LOT-PROVIDER-EVAL-001 is a proposed evaluation process, not provider selection or approval; apply it to exact product/entity/jurisdiction decision units and retain all hard gates.
- The README refinement remains in open Draft PR #19; it has not been merged.
- No application code, physical database schema, partner API integration, sandbox, or production deployment has been verified. A structural documentation CI workflow exists and has passed; it checks paired paths, stable IDs and local links, not semantic translation parity.

## Definition of done
A task is done only when implementation exists, relevant tests pass, documentation is synchronized in both languages, security and tenant implications are reviewed, and commit/PR/CI evidence is linked.