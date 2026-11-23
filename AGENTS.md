# Lottorito — Agent Operating Guide

## Mission
Continue Lottorito from the repository's verified state. Do not restart planning, recreate existing files, or claim unfinished work is complete. GitHub is the durable source of truth; conversations and summaries are not proof.

## Mandatory entry sequence
1. Read this file.
2. Read `docs/en/engineering/project-status.md` and `docs/fa/engineering/project-status.md`.
3. Read the bilingual execution procedure: `docs/en/engineering/codex-vscode-execution-runbook.md` and its Persian counterpart.
4. Inspect the live GitHub default branch, current branch and SHA, open/closed issues, PRs, review comments, and CI/workflow state.
5. Read relevant domain documents in both languages. Do not assume a document on an unmerged branch exists on `main`.
6. Search for existing files, modules, tests, migrations, contracts, issues, and PRs before creating anything.
7. State the intended files, risks, acceptance criteria, and tests before making changes.

## Source-of-truth and status rules
- Current GitHub state outranks previous reports and conversational memory.
- An open issue is planned work, not completed work.
- A file on an unmerged branch is not part of the default-branch baseline.
- A draft/open PR is not merged or approved.
- File existence is not evidence of semantic correctness, test success, or production readiness.
- Never claim a test, CI, API connection, sandbox, deployment, or permission unless directly verified.

## Mandatory bilingual documentation
- `docs/fa` and `docs/en` are equally authoritative.
- Every document has a counterpart at the same relative path and a stable document ID.
- Update both language versions in the same PR.
- Preserve semantic parity for amounts, formulas, constraints, statuses, examples, and acceptance criteria.
- Until automated parity CI is implemented and verified, reviewers must manually compare both versions.

## Engineering rules
- Prefer small, reviewable, independently testable changes.
- Use feature branches and pull requests; do not develop directly on `main`.
- Do not merge, deploy, rotate secrets, change repository visibility, or perform destructive data operations without explicit owner approval.
- Never commit credentials, tokens, personal data, real player data, or production exports.
- Use parameterized SQL, strict input validation, authorization at every boundary, tenant scoping, idempotency for event ingestion, and audit logs for privileged actions.
- Financial correctness is a release blocker. Use an immutable double-entry ledger; never use direct balance mutation as the source of truth.
- Test happy paths, boundaries, duplicate/replayed events, concurrency, tenant isolation, reversals, and failure recovery.
- Report exact commands, results, skipped checks, and limitations.

## Environment coordination
- GitHub is the system of record for branches, commits, issues, PRs, and CI.
- Cloud Codex tasks must have a bounded issue, acceptance criteria, and their own branch/PR.
- VS Code/local work must start from a synchronized branch; local uncommitted state is not a durable handoff.
- Do not let multiple agents edit the same files/branch concurrently without explicit coordination.
- Follow `LOT-ENG-002` for API access, secrets, cloud/local workflow, handoff reports, and permission boundaries.
- GitHub write access does not imply production, partner, database, or deployment access.

## Verified baseline at 2026-11-23
- Repository: `tecpey/lottorito-platform`; default branch: `main`; visibility: Public by owner decision.
- GitHub connection reported admin, maintain, push, pull, and triage permissions; this does not prove access to external systems.
- PR #7 is open/draft and contains the conceptual domain model and other documentation on `docs/domain-data-model-v1`; it is not part of `main` until merged.
- The new Codex/VS Code runbook is being proposed on `docs/codex-execution-baseline`; it is not yet merged.
- No application code, executable database schema/migration, verified CI workflow, automated bilingual parity check, partner API integration, sandbox, financial posting, or production deployment has been verified.

## Definition of done
A task is done only when implementation exists, relevant tests pass, documentation is synchronized in both languages, security and tenant implications are reviewed, and exact commit/PR/CI evidence is linked.
