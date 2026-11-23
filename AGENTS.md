# Lottorito — Agent Operating Guide

## Mission
Continue Lottorito from the repository's verified state. Do not restart planning, recreate existing files, or claim unfinished work is complete.

## Before every task
1. Read this guide and the relevant Persian and English documents under docs/.
2. Read docs/en/engineering/project-status.md and relevant decision records.
3. Inspect current branches, files, issues, pull requests, and implementation before editing.
4. Search for existing modules, tests, and documents before creating replacements.
5. State assumptions explicitly; unresolved business rules must remain open questions.

## Mandatory bilingual documentation
- docs/fa and docs/en are equally authoritative.
- Every document has a counterpart at the same relative path and a stable document ID.
- Update both language versions in the same commit or pull request.
- Preserve semantic parity for amounts, formulas, constraints, statuses, examples, and acceptance criteria.
- File existence alone does not prove synchronization.
- Until automated parity CI is implemented and verified, reviewers must manually compare both versions.

## Engineering rules
- Prefer small, reviewable, independently testable changes.
- Use feature branches and pull requests; do not push unfinished work directly to main once CI and branch protections are available.
- Do not merge, deploy, rotate secrets, change repository visibility, or perform destructive data operations without explicit owner approval.
- Never commit credentials, tokens, personal data, real player data, or production exports.
- Use parameterized SQL, strict input validation, authorization at every boundary, tenant scoping, idempotency for event ingestion, and audit logs for privileged actions.
- Financial correctness is a release blocker. Use an immutable double-entry ledger; never use direct balance mutation as the source of truth.
- Test happy paths, boundaries, duplicate/replayed events, concurrency, tenant isolation, reversals, and failure recovery.
- Report exact commands, results, skipped checks, and limitations. Never fabricate test or CI evidence.

## Verified baseline at 2026-11-23
- Repository: tecpey/lottorito-platform; default branch: main; visibility: public by owner decision.
- GitHub connection reported admin, maintain, push, pull, and triage permissions.
- docs/fa/README.md and docs/en/README.md exist and were read back successfully.
- No application code, database schema, partner API integration, CI workflow, or production deployment has yet been verified.

## Definition of done
A task is done only when implementation exists, relevant tests pass, documentation is synchronized in both languages, security and tenant implications are reviewed, and commit/PR/CI evidence is linked.