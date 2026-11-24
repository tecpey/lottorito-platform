# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 0.2.0 | **Reviewed:** 2026-11-24

## Verified state
- Repository tecpey/lottorito-platform exists; default branch is main and visibility is Public, remaining public per the owner's current decision.
- GitHub connection reported admin, maintain, push, pull, and triage permissions.
- docs/fa/README.md and docs/en/README.md were created and their contents were successfully read back from GitHub.
- Foundational product documentation, agent guide, and continuation record are being established.

## Documentation baseline updated on 2026-11-24
- Added LOT-AGENT-001, a bilingual low-context operating manual for agents and contributors.
- Added LOT-ADR-REG-001, a bilingual register distinguishing owner directions, proposals and unresolved decisions.
- Added LOT-LOTTERY-001, a proposed Lottery discovery PRD; it is not approved for implementation or launch.
- Added LOT-LOTINT-001, a proposed provider-neutral Lottery lifecycle contract; no provider API or sandbox is verified.
- Updated both documentation indexes to route agents to these sources.
- These changes are on docs/agent-ready-foundation-v1 and are not merged to main.

## Not yet verified
No application implementation, database schema, CI workflow, automated language-parity check, partner API connection, sandbox, financial calculation, payout, or production deployment has been verified. Never claim tests or deployment succeeded without evidence.

## Continuation instructions for every agent
1. Read this document and AGENTS.md.
2. Read relevant documents in both languages.
3. Inspect actual branches, files, issues, and pull requests.
4. Search for existing work before creating anything.
5. Convert ambiguity into questions or issues; never turn assumptions into rules.
6. Deliver changes bilingually, tested, and with evidence.

## Next sequence
1. Complete cross-product domain model, bounded contexts, ownership map and ERD.
2. Add explicit tenant/identity model and threat model.
3. Define canonical API conventions and shared event envelope, including source-event/economic-effect/journal-entry identities.
4. Expand finance posting, reconciliation, payout-control and product/tenant account mappings.
5. Create technology, deployment, reliability and data-residency ADRs with decision criteria.
6. Add automated bilingual parity and documentation link/metadata checks.
7. Only after owner decisions and evidence, scaffold the platform and implement isolated vertical slices.

## Owner decisions required
Nature of the USD 100 promotional credit, NGR definition, commission rates/distribution, progression rules, withdrawal policy, jurisdictions, and partner API details.