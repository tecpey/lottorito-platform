# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 0.2.0 | **Reviewed:** 2026-11-23

## Verified state
- Repository `tecpey/lottorito-platform` uses default branch `main` and is Public; public visibility is retained per the owner's current decision.
- GitHub connection reported admin, maintain, push, pull, and triage permissions.
- `AGENTS.md` and bilingual README files exist.
- Foundational product, system architecture, wallet/ledger, glossary, and roadmap documents exist.
- A bilingual conceptual domain model and ERD have been created on branch `docs/domain-data-model-v1`. This is conceptual design, not an executable schema, and has not been merged.
- A dedicated PR for the data-model change is being prepared; report final state only after the PR and CI are inspected.

## Not yet verified
No application implementation, database schema, migration, CI workflow, automated language-parity check, partner API connection, sandbox, financial calculation, payout, or production deployment has been verified. Never claim tests or deployment succeeded without evidence.

## Continuation instructions for every agent
1. Read this document and `AGENTS.md`.
2. Read relevant documents in both languages, especially `LOT-DATA-001`.
3. Inspect actual branches, files, issues, and pull requests.
4. Search for existing work before creating anything.
5. Convert ambiguity into questions or issues; never turn assumptions into rules.
6. Deliver changes bilingually, tested, and with evidence.
7. Do not confuse the conceptual model with an executable schema or migration; resolve open decisions and ADRs first.

## Next sequence
Review LOT-DATA-001; answer DATA-Q01 through DATA-Q12; complete the logical ERD and data dictionary; approve database and tenant-isolation ADRs; design ledger accounting; define API/event envelopes; then implement parity CI and application scaffolding.

## Owner decisions required
Nature of the USD 100 promotional credit, NGR definition, commission rates/distribution, progression rules, withdrawal policy, sponsor/downline transfer model, jurisdictions, and partner API details.
