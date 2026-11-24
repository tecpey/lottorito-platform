# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 0.5.0 | **Status:** Maintained verified baseline | **Reviewed:** 2026-11-24

## Verified repository state
- Repository: tecpey/lottorito-platform; default branch main; public visibility by owner decision.
- PR #19 is open and Draft, based on main. PR #20 is open and Draft, based on PR #19's head branch. Neither is merged.
- PR #20's current head must be read from live PR metadata; historical SHAs in this document are not authoritative.
- The repository work remains documentation-first. No runtime application, physical schema, provider integration, sandbox, financial posting, payout or production deployment is verified.
- Added scripts/check_docs.py and .github/workflows/docs-governance.yml for bilingual path/ID and local-link structure checks. The first run correctly exposed that the two language indexes use EN/FA-qualified IDs; normalization was added. The Documentation Governance workflow then passed on PR head 78e47168e67b14ccc2be9df7ceae79fbf56eb59e (run 45345429559). This validates structure and local links only, not semantic translation parity.
- The Documentation Governance workflow passed on PR head 71b527be77f8df03cb179c378a020c58716c4e7c (run 45347911477): 21 bilingual Markdown pairs and 47 local links checked, including title and version/status metadata checks. This is structural validation only; semantic translation parity still requires human review.

## Documentation baseline
The branch docs/agent-ready-foundation-v1 contains proposed bilingual references:
- LOT-AGENT-001: low-context agent operating manual.
- LOT-ADR-REG-001: decision authority and unresolved-decision register.
- LOT-LOTTERY-001 and LOT-LOTINT-001: Lottery discovery PRD and provider-neutral lifecycle contract.
- LOT-DOM-001, LOT-TEN-001 and LOT-EVENT-001: proposed domain model, tenant isolation and canonical event contract.
- LOT-FIN-POST-001: proposed financial posting, account ownership, balance semantics and reconciliation.
- LOT-SEC-TM-001: proposed system threat model and minimum security verification matrix.
- LOT-API-001: proposed resource, authorization, error, pagination, idempotency and webhook conventions.
- LOT-TECH-ADR-001: proposed technology, deployment, reliability, observability and data-lifecycle decision framework; no stack/provider approved.
- LOT-QA-001: proposed measurable quality scenarios, cross-cutting invariants, evidence strategy and release gates; numeric thresholds remain TBD.

The finance, security, API and technology/deployment references are proposals, not approved policies or implemented controls. LOT-TECH-ADR-001 compares architecture, database, queues/workflows, hosting, observability, recovery, security and data-residency decision criteria. No technology vendor or stack is approved by that document.

## Not verified
No application implementation, physical database schema/migrations, CI workflow, automated bilingual parity check, partner API connection, sandbox certification, financial calculation/posting, payout, penetration test or production deployment has been verified.

## Continuation rules
1. Read AGENTS.md and this status record.
2. Read the relevant English and Persian canonical documents.
3. Inspect current PR head, changed files, branch ancestry, statuses and repository tree before editing.
4. Search for existing work before creating a new file or issue.
5. Keep proposals, owner directions, decisions, implementation and verification evidence distinct.
6. Update both languages in the same change; validate links, IDs, content parity and scope.
7. Do not merge, deploy, alter settings or perform destructive actions without explicit owner approval.

## Next sequence
1. Review LOT-QA-001 with product, engineering/SRE, security, finance, legal/privacy and owner stakeholders; define workload profiles and approve thresholds only with accountable owners.
2. Review the proposed finance, threat and API baselines with the owner and domain reviewers.
3. Review LOT-TECH-ADR-001 and map each prototype to LOT-QA-001; run tenant, financial transaction, provider failure, migration, recovery and observability prototypes before accepting technology choices.
4. Extend documentation governance with metadata validation and reviewer-owned semantic parity checks; current CI covers paired paths, IDs and local links only.
5. Complete cross-product architecture and product-specific release gates.
6. Decide jurisdiction, operating model, provider due diligence and commercial/financial policies.
7. Only after decisions, scaffold the platform and implement isolated vertical slices with tests.

## Owner decisions still required
Legal entity and operating model; initial jurisdiction; provider and source-of-truth rules; USD 100 illustrative agent credit; commission/NGR and network progression; account mapping and funding/custody; payout permissions; technology and deployment choices; data residency and retention; official logo source asset.

## Evidence discipline
This record summarizes repository inspection, not an external audit. Re-fetch PR metadata and commit statuses before relying on a head SHA or CI state.
