# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 0.3.0 | **Reviewed:** 2026-11-23

## Verified state at the latest review
- Repository `tecpey/lottorito-platform` is Public and uses `main` as its default branch, per the owner's decision.
- GitHub connection reported admin, maintain, push, pull, and triage permissions.
- `AGENTS.md`, root README, and `docs/fa` / `docs/en` READMEs exist.
- Foundational product, architecture, commission, wallet/ledger, partner integration, security, glossary, roadmap, and project-status documents exist.
- The conceptual data model/ERD, final-roundtable protocol, and initial bilingual audit report are on branch `docs/domain-data-model-v1`.
- PR #7 is Open and Draft with 8 changed files; it has not been merged.
- Latest reviewed PR head: `4d3714e7181c32e8519aba4ea49bdcfc5aae2879`.
- Issue #8 tracks the final roundtable; Issue #9 tracks the initial documentation audit; Issues #10–#14 track new gaps in Attribution, QA, Threat Model/Data Governance, UX, and SRE.
- Official vector brand assets and favicon are committed in `assets/logo/` with dual-theme SVG support and documented in bilingual specification `LOT-BRAND-001`.
- An initial content review of documentation has been completed; the final independent roundtable and specialist product audit have not been conducted.

## Initial audit conclusion
The documentation foundation is suitable for detailed design, but the actual partner contract and sandbox, complete OpenAPI/Event Contract, financial definitions, Attribution, QA Strategy, Threat Model/Data Governance, UX, and SRE/Operations require further work. See `LOT-AUDIT-DOC-001`.

## Not yet verified
No application implementation, executable schema/migration, test suite, GitHub Actions workflow, automated parity check, partner API connection, sandbox, financial calculation, payout, or production deployment has been verified. No status checks were reported for the current PR #7 head. Absence of status checks is not a passing test result.

## Continuation instructions for every agent
1. Read this document and `AGENTS.md`.
2. Read relevant documents in both languages, especially `LOT-DATA-001` and `LOT-AUDIT-DOC-001`.
3. Re-check actual branches, files, issues, and PRs on GitHub; the SHA here is only a review-time snapshot.
4. Search existing issues and PRs before creating work; do not duplicate LOT-001 through LOT-006.
5. Convert ambiguity into questions or issues; never turn assumptions into rules.
6. Deliver documentation changes in both languages, in one PR, with evidence.
7. Do not confuse the conceptual model with an executable schema or migration; resolve open decisions and ADRs first.
8. Do not merge, deploy, or perform financial/production operations without the required authorization.

## Next sequence
1. Specialist review of PR #7 and Persian/English parity.
2. Complete LOT-001 through LOT-006 and resolve DATA-Q01 through DATA-Q12 in approved records.
3. Complete new specifications tracked by Issues #10–#14.
4. Obtain the partner's actual contract and sandbox.
5. Approve technology/database ADRs, then logical schema and migrations.
6. Implement parity CI, tests, and application scaffolding.
7. Conduct the final roundtable after MVP completion and before release-readiness approval.

## Owner decisions required
Nature of the USD 100 promotional credit, NGR definition, commission rates/distribution, progression rules, withdrawal policy, sponsor/downline transfer model, jurisdictions, attribution model, and partner API details.
