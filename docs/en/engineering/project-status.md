# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 1.23.0 | **Status:** Maintained verified baseline | **Reviewed:** 2026-11-24

## Verified repository state
- Repository: tecpey/lottorito-platform; default branch main; public visibility by owner decision.
- As of 2026-11-24, PRs #19–#25 and #27–#36 are open Draft changes. The intended stack is #19 → #20 → #21 → #22 → #23 → #24 → #25 → #27 → #28 → #29 → #30 → #31 → #32 → #33 → #34 → #35 → #36. PR #26 is a separate open Draft branch based on main and overlaps shared governance files; it must be reconciled with the stack before integration. No PR in this sequence is merged.
- PR #25 is six commits behind the latest PR #24 head; PR #27–#35 inherit that stale upstream ancestry. PR #28 adds unified B2B2C, IAM and dashboard proposals; PR #29 adds LOT-WALLET-001; PR #30 adds LOT-PAYMENT-001; PR #31 adds LOT-PAYOUT-001; PR #32 adds LOT-B2C-PRD-001; PR #33 adds LOT-API-PLATFORM-001 on top of #32; PR #34 adds LOT-AFFILIATE-API-001 on top of #33; PR #35 adds LOT-CUSTOMER-PILOT-001 on top of #34 and clarifies the owner-directed RaidenBet scope as Advanced Affiliate & Agent plus Live Chat Widget only. Synchronize the upstream stack and rerun CI before merge consideration. Always read live PR metadata; this is a dated status snapshot.
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
- LOT-PROT-001: proposed eight-prototype experiment plan with pass/fail criteria and evidence templates. P-01 and P-02 now have partial, disposable synthetic executions; neither is production evidence or a technology approval.
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
- **LOT-PAYMENT-001:** proposed provider-neutral payment orchestration contract covering intents/attempts, merchant and tenant isolation, adapters, webhook trust, idempotency, routing, refunds, settlement and reconciliation; no provider, merchant account, licence, payment runtime or real-money flow is approved.
- **LOT-PAYOUT-001:** proposed disbursement contract separating customer withdrawals, Affiliate/Agent commission payouts, Lottery prize disbursements and treasury movements; covers beneficiary verification, reservations, maker-checker, provider execution, ambiguous outcomes, returns and reconciliation; no custody, banking, payout runtime or real-money disbursement is approved.
- **LOT-B2C-PRD-001:** proposed product requirements for the dedicated first-party B2C tenant, consuming approved shared modules through common contracts; covers customer journeys, entitlement/jurisdiction gates, wallet, payment, payout, chat, support, notifications, localization, privacy, accessibility and 20 acceptance scenarios. No B2C app launch or runtime is claimed.
- **LOT-API-PLATFORM-001:** proposed API platform and developer-experience contract extending LOT-API-001/LOT-EVENT-001 with control/data planes, app/client registration, entitlement catalog, credential lifecycle, webhook subscriptions, SDK generation, Developer Portal, isolated sandbox, metering/quotas and lifecycle governance. No API gateway, portal, SDK, sandbox or production API access is claimed.
- **LOT-CUSTOMER-PILOT-001:** owner-directed RaidenBet initial-customer scope and proposed delivery/acceptance plan for Advanced Affiliate & Agent plus Live Chat Widget; it defines customer review before controlled API connection and does not verify a contract, customer API, sandbox, implementation or production approval.
- **LOT-AFFILIATE-API-001:** proposed provider-neutral Affiliate & Agent API capability inventory for programs, memberships, hierarchy, campaigns, referral links, attribution, partner event intake, commission statements and reporting. Financial mutations remain in wallet/ledger/payment/payout domains; no partner, commercial formula, endpoint or integration is approved.

## Owner-directed initial customer scope

- **RaidenBet is the initial customer** for exactly two modules: Advanced Affiliate & Agent and Live Chat Widget. This owner clarification supersedes the historical LDR-014 wording that described RaidenBet only as a possible Affiliate partner; current authority is LDR-045.
- The customer receives only the two approved modules, not the whole Lottorito platform or Lottery/Casino/Sportsbook/E-Gaming. The customer's existing script remains customer-controlled and is intended to connect through a controlled, versioned API after its support/technical team reviews and explicitly approves the handoff contract.
- LOT-CUSTOMER-PILOT-001 records the proposed customer review, API/widget handoff, sandbox, acceptance and production gates. The customer API, legal entity, jurisdiction, sandbox, credentials, commercial contract and technical compatibility are not yet verified. No database/source-code access is assumed.
- This is an owner-directed scope and planning baseline, not evidence of signed commercial terms, implementation, customer acceptance or production authorization.

## Current executable experiments
- PR #36, [P-01 Tenant Isolation](https://github.com/tecpey/lottorito-platform/pull/36), is an open Draft stacked directly on PR #35. Branch: spike/p01-tenant-isolation. Re-fetch the live PR head before relying on a SHA.
- A disposable Node.js HTTP + PostgreSQL RLS slice exists with synthetic tenants, server-resolved test principals, transaction-local tenant context, a least-privilege runtime role, and integration tests for spoofing, cross-tenant object access and pooled-connection reuse.
- Candidate versions are Node.js 26.13.0, PostgreSQL 18.7 and node-postgres 8.23.1. They remain experiment inputs, not accepted technology decisions.
- GitHub Actions run [45412556456](https://github.com/tecpey/lottorito-platform/actions/runs/45412556456) passed on Node.js 26.13.0 + PostgreSQL 18.7 with committed npm lockfile and SHA-pinned Actions: 20 tests passed, 0 failed, 0 skipped on code head `f53caa4e801c9eeed94dfe706e03c6dfcf02a660`. In addition to HTTP/RLS and async outbox/dispatcher/Ed25519 job tests, the slice compares per-tenant LOGIN roles bound to PostgreSQL session_user across records, membership and jobs; GUC spoofing, cross-role SET ROLE/SET SESSION AUTHORIZATION, identity-map reads and cross-tenant writes are denied in that variant. The SECURITY DEFINER function's NOLOGIN/non-BYPASSRLS owner and fixed search_path are verified, including a temporary-schema shadowing attempt. Local execution has not been performed in this environment. The red-team test explicitly confirms the shared-role GUC trust limitation; the per-tenant credential broker and pool-scaling model remain untested.
- PR #38, [P-02 Financial Ledger](https://github.com/tecpey/lottorito-platform/pull/38), is an open Draft stacked on PR #36 branch spike/p01-tenant-isolation. Branch: spike/p02-financial-ledger. CI run [45416076701](https://github.com/tecpey/lottorito-platform/actions/runs/45416076701) passed 19 tests on Node.js 26.13.0 + PostgreSQL 18.7 on PR head a47e5e2107ecfe96c77c48bea3d8921f726b8a17; it covers exact NUMERIC amounts, per-currency double-entry, tenant/product RLS, concurrent idempotency, immutable postings, exact reversals, atomic outbox and reconciliation. Documentation Governance run [45415219866](https://github.com/tecpey/lottorito-platform/actions/runs/45415219866) passed on the bilingual docs head. P-02 is synthetic and partial; no production wallet, payout, payment, commission formula or financial policy is implemented or approved.
- PR #41, [P-03 Provider Event Delivery](https://github.com/tecpey/lottorito-platform/pull/41), is an open Draft stacked on PR #38 branch spike/p02-financial-ledger. Branch: spike/p03-provider-event-delivery. CI run [45418047425](https://github.com/tecpey/lottorito-platform/actions/runs/45418047425) passed 22 tests on Node.js 26.13.0 + PostgreSQL 18.7. It covers raw-body HMAC signature verification, timestamp freshness, key rotation, replay/duplicate/conflict handling, installation-bound tenant/product scope, CloudEvents normalization, inbox leases, concurrent claims, retry/dead-letter, outbound delivery attempts and provider-event reconciliation. Documentation Governance run [45418047381](https://github.com/tecpey/lottorito-platform/actions/runs/45418047381) passed. P-03 is synthetic only; no RaidenBet/provider API integration, external broker, production secrets manager or network sender exists.
- Overall P-01 remains partial/inconclusive: secure per-tenant credential brokering and pool scaling, high-contention revocation-race stress, support/break-glass, cache/object storage/search/reporting, load, failover and recovery remain untested.

## Not verified
No production application, production physical schema/migrations, provider API connection, sandbox certification, financial calculation/posting, payout, penetration test or production deployment has been verified. The disposable P-01 slice has a passing CI result for 20 defined tests, including an identity-bound per-tenant database-role comparison, but is not production software; full P-01 remains partial/inconclusive. The separate P-02 ledger slice has 19 passing synthetic CI tests; it is not a production financial ledger. Documentation Governance CI exists and has passed structural checks on selected PR heads; it does not prove semantic bilingual parity, runtime behavior, legal eligibility or security.

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
13. Define product-specific payout eligibility and treasury/funding controls through LOT-PAYOUT-001; do not activate withdrawal or disbursement before jurisdiction, liability, provider, beneficiary and funding approvals.
14. Review LOT-B2C-PRD-001 with owner/product/legal/finance/security/privacy/accessibility/operations; approve the first-party tenant, staged eligible modules and customer journeys before implementation.
15. Review LOT-API-PLATFORM-001 with architecture/security/finance/legal/operations; approve API audiences, app/credential model, sandbox, webhook and lifecycle gates before building the Developer Portal or publishing APIs.
16. Review LOT-AFFILIATE-API-001 against the actual first-pilot partner contract and sandbox; approve the narrow event/resource allowlist, attribution and commission semantics before implementing an adapter or exposing production APIs.
17. Only after decisions, scaffold the platform and implement isolated vertical slices with tests.

## Owner decisions still required
Legal entity and operating model; initial jurisdiction; provider and source-of-truth rules; USD 100 illustrative agent credit; commission/NGR and network progression; account mapping and funding/custody; payout permissions; technology and deployment choices; data residency and retention; official logo source asset.

## Evidence discipline
This record summarizes repository inspection, not an external audit. Re-fetch PR metadata and commit statuses before relying on a head SHA or CI state.
