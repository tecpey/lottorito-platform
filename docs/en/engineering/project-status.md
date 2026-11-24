# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 1.2.0 | **Status:** Maintained verified baseline | **Reviewed:** 2026-11-24

## Verified repository state
- Repository: tecpey/lottorito-platform; default branch main; public visibility by owner decision.
- As of 2026-11-24, PRs #19–#25 and #27 are open Draft documentation changes. The intended stack is #19 → #20 → #21 → #22 → #23 → #24 → #25 → #27. PR #26 is a separate open Draft branch based on main and overlaps shared governance files; it must be reconciled with the stack before integration. No PR in this sequence is merged.
- PR #25 is currently six commits behind the latest PR #24 head; PR #27 inherits that stale upstream base. Synchronize the stack and rerun CI before considering either ready for merge. Always read live PR metadata; this is a dated status snapshot.
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
- LOT-PROT-001: proposed eight-prototype experiment plan with pass/fail criteria and evidence templates; no prototype execution is verified.
- LOT-I18N-001: owner-directed 12-language launch target (ten-language shortlist proposed) with equal product/content/support quality gates; no locale implementation is verified.
- LOT-COMMS-001: proposed multilingual live-chat and customer-communications architecture; no provider/runtime is verified.
- LOT-GROWTH-001: proposed multilingual content, SEO/GEO/AEO and channel-automation workflow; no publishing integration is verified.
- LOT-NOTIF-001: proposed policy-gated smart-notification architecture; no notification runtime/provider is verified. TecPey notification source was inspected as a reference: policy-only creation, transactional outbox, replay protection and runtime copy safety are useful patterns; its in-app-only, fa/en, single-tenant pilot and delivered-only frequency counter are not Lottorito-ready.
- LOT-PROVIDER-EVAL-001: proposed cross-product provider evaluation, evidence, RFI, hard-gate, controlled-test and approval standard; no provider is selected or approved by it.

The finance, security, API and technology/deployment references are proposals, not approved policies or implemented controls. LOT-TECH-ADR-001 compares architecture, database, queues/workflows, hosting, observability, recovery, security and data-residency decision criteria. No technology vendor or stack is approved by that document.

- **LOT-PLATFORM-001:** proposed unified B2B2C architecture covering the first-party B2C tenant, operator, white-label, affiliate/agent, role dashboards, wallet/ledger, deposits/withdrawals, payment adapters, chat/widget, security and work packages; none is verified as implemented runtime.

- **LOT-IAM-TENANT-001:** proposed tenant/identity/membership/authorization contract with 17 sections, role/workspace access matrix, lifecycle, isolation invariants and 12 threat-test scenarios; not an implemented IAM or tenant-isolation service.

- **LOT-DASH-001:** proposed role-based workspace blueprint with 12 sections, detailed Platform/Tenant/White-Label/Affiliate/Support/Finance/Compliance/B2C experiences, KPI governance and 12 acceptance tests; no dashboard implementation claimed.
- **LOT-WALLET-001:** proposed wallet-domain contract covering ownership/classes, typed units, balance projections, holds, transfers, ledger boundaries, authorization and 15 adversarial acceptance scenarios; it does not approve custody, stored value, payments, transfers, withdrawals or any wallet runtime.

## Not verified
No application implementation, physical database schema/migrations, provider API connection, sandbox certification, financial calculation/posting, payout, penetration test or production deployment has been verified. Documentation Governance CI exists and has passed structural checks on selected PR heads; it does not prove semantic bilingual parity, runtime behavior, legal eligibility or security.

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
3. Review LOT-TECH-ADR-001 and LOT-PROT-001; approve experiment scope and accountable owners, then run P-01 through P-08 in isolated synthetic environments before accepting technology choices.
4. Extend documentation governance with metadata validation and reviewer-owned semantic parity checks; current CI covers paired paths, IDs and local links only.
5. Review and approve the 12-language portfolio/locale variants, then define native-review coverage and quality gates.
6. Review live-chat, content/channel automation and smart-notification policies; evaluate providers and integration contracts without enabling campaigns.
7. Review and approve LOT-PROVIDER-EVAL-001 with accountable owner, legal/compliance, security, finance, product and engineering reviewers; confirm proposed weights before any binding procurement use.
8. Apply the standard first to a named Affiliate pilot decision unit and a separate Lottery research decision unit; establish jurisdiction and operating model before issuing RFIs or testing.
9. Review LOT-GAMING-STRATEGY-001 as a future horizon; run Sportsbook, Live Casino and RNG/E-Gaming provider RFIs only after Affiliate and Lottery priorities, with separate jurisdiction, provider, finance, security and certification gates.
10. Complete cross-product architecture and product-specific release gates.
11. Decompose the wallet direction into LOT-WALLET-001; resolve ownership, unit classes, accounting mapping and legal treatment before any wallet implementation.
12. Specify payment orchestration (LOT-PAYMENT-001) and payout/withdrawal controls (LOT-PAYOUT-001) as separate provider-neutral domains; do not combine wallet credit, payment authorization, settlement and payout into one state machine.
13. Only after decisions, scaffold the platform and implement isolated vertical slices with tests.

## Owner decisions still required
Legal entity and operating model; initial jurisdiction; provider and source-of-truth rules; USD 100 illustrative agent credit; commission/NGR and network progression; account mapping and funding/custody; payout permissions; technology and deployment choices; data residency and retention; official logo source asset.

## Evidence discipline
This record summarizes repository inspection, not an external audit. Re-fetch PR metadata and commit statuses before relying on a head SHA or CI state.
