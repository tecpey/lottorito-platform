# Verified Project Status and Continuation Point

**Document ID:** LOT-OPS-001 | **Version:** 2.0.0 | **Status:** Maintained verified baseline | **Reviewed:** 2026-11-27

## Verified repository state
- Repository: tecpey/lottorito-platform; default branch main; public visibility by owner decision.
- As of 2026-11-24, PRs #19–#25 and #27–#34 are open Draft documentation changes. The intended stack is #19 → #20 → #21 → #22 → #23 → #24 → #25 → #27 → #28 → #29 → #30 → #31 → #32 → #33 → #34. PR #26 is a separate open Draft branch based on main and overlaps shared governance files; it must be reconciled with the stack before integration. No PR in this sequence is merged.
- PR #25 is six commits behind the latest PR #24 head; PR #27–#34 inherit that stale upstream ancestry. PR #28 adds unified B2B2C, IAM and dashboard proposals; PR #29 adds LOT-WALLET-001; PR #30 adds LOT-PAYMENT-001; PR #31 adds LOT-PAYOUT-001; PR #32 adds LOT-B2C-PRD-001; PR #33 adds LOT-API-PLATFORM-001 on top of #32; PR #34 adds LOT-AFFILIATE-API-001 on top of #33. Synchronize the upstream stack and rerun CI before merge consideration. Always read live PR metadata; this is a dated status snapshot.
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
- **LOT-PAYMENT-001:** proposed provider-neutral payment orchestration contract covering intents/attempts, merchant and tenant isolation, adapters, webhook trust, idempotency, routing, refunds, settlement and reconciliation; no provider, merchant account, licence, payment runtime or real-money flow is approved.
- **LOT-PAYOUT-001:** proposed disbursement contract separating customer withdrawals, Affiliate/Agent commission payouts, Lottery prize disbursements and treasury movements; covers beneficiary verification, reservations, maker-checker, provider execution, ambiguous outcomes, returns and reconciliation; no custody, banking, payout runtime or real-money disbursement is approved.
- **LOT-B2C-PRD-001:** proposed product requirements for the dedicated first-party B2C tenant, consuming approved shared modules through common contracts; covers customer journeys, entitlement/jurisdiction gates, wallet, payment, payout, chat, support, notifications, localization, privacy, accessibility and 20 acceptance scenarios. No B2C app launch or runtime is claimed.
- **LOT-API-PLATFORM-001:** proposed API platform and developer-experience contract extending LOT-API-001/LOT-EVENT-001 with control/data planes, app/client registration, entitlement catalog, credential lifecycle, webhook subscriptions, SDK generation, Developer Portal, isolated sandbox, metering/quotas and lifecycle governance. No API gateway, portal, SDK, sandbox or production API access is claimed.
- **LOT-AFFILIATE-API-001:** proposed provider-neutral Affiliate & Agent API capability inventory for programs, memberships, hierarchy, campaigns, referral links, attribution, partner event intake, commission statements and reporting. Financial mutations remain in wallet/ledger/payment/payout domains; no partner, commercial formula, endpoint or integration is approved.
- **LOT-AFFILIATE-SEC-001:** proposed threat-oriented review of the wire contracts. Records high/medium findings for BOLA, token trust and human/machine principal separation, custom scope semantics, event identity/fingerprinting, extension/schema allowlists, SSRF, resource ceilings, data minimization, errors and audit. It is a design review, not a penetration test or production security approval.

- **LOT-AFFILIATE-WIRE-001:** proposed wire-level extension of LOT-AFFILIATE-API-001 / LOT-API-001 / LOT-EVENT-001. Adds separate Affiliate management and partner-event ingress OpenAPI contracts plus a transport-neutral AsyncAPI canonical-event profile. On PR #76 head `5877746173cbc83e715a7134426d2c086c0181b8`, Documentation Governance run `46054085669` (#930) and Affiliate Contract Validation run `46054085685` (#32) both passed. The latter validated both OpenAPI documents (Redocly 2.83.0), the AsyncAPI 3.0.0 document (AsyncAPI CLI 6.2.2) and 31 positive/negative schema-instance assertions (Ajv 8.17.1; separate 2020-12 and Draft 07 instances). These are document/schema checks, not runtime verification. The PR remains Draft; no endpoint, provider, partner mapping, OAuth profile or production deployment is approved.

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
13. Define product-specific payout eligibility and treasury/funding controls through LOT-PAYOUT-001; do not activate withdrawal or disbursement before jurisdiction, liability, provider, beneficiary and funding approvals.
14. Review LOT-B2C-PRD-001 with owner/product/legal/finance/security/privacy/accessibility/operations; approve the first-party tenant, staged eligible modules and customer journeys before implementation.
15. Review LOT-API-PLATFORM-001 with architecture/security/finance/legal/operations; approve API audiences, app/credential model, sandbox, webhook and lifecycle gates before building the Developer Portal or publishing APIs.
16. Review LOT-AFFILIATE-API-001 against the actual first-pilot partner contract and sandbox; approve the narrow event/resource allowlist, attribution and commission semantics before implementing an adapter or exposing production APIs.
17. Only after decisions, scaffold the platform and implement isolated vertical slices with tests.
18. Complete the LOT-AFFILIATE-SEC-001 gates before application implementation: decide authentication trust and scope enforcement, strict JSON parsing and fingerprinting, registered event/schema allowlists, resource ceilings, retention and audit. Add cross-tenant, scope, duplicate-concurrency, conflict and abuse-boundary tests.
19. Reconcile the exact resource/event allowlist with approved partner documentation and authorized sandbox evidence; only then plan the Affiliate runtime vertical slice.

## Owner decisions still required
Legal entity and operating model; initial jurisdiction; provider and source-of-truth rules; USD 100 illustrative agent credit; commission/NGR and network progression; account mapping and funding/custody; payout permissions; technology and deployment choices; data residency and retention; official logo source asset.

## Evidence discipline
This record summarizes repository inspection, not an external audit. Re-fetch PR metadata and commit statuses before relying on a head SHA or CI state.

## Latest PR #76 evidence and G09-A3 continuation

- PR #76 remains Open/Draft, base `docs/affiliate-api-capability-contract-v1`, head branch `docs/g09-affiliate-api-wire-contract-v1`; do not merge or deploy.
- Exact PR head verified: `59414d2cc7544fed187e41e9c823e1d453c41a3a`.
- Documentation Governance run `46054529199` (#939): **PASS**.
- Affiliate Contract Validation run `46054529202` (#48): **PASS**; job `140693686036` completed successfully.
- Run #48 validated Redocly 2.83.0 (both OpenAPI documents valid; one non-blocking missing-license warning per document), AsyncAPI CLI 6.2.2 (AsyncAPI 3.0.0 valid; informational 3.1.0 recommendation), and **46 positive/negative payload and security-boundary assertions** using Ajv 8.17.1 / ajv-formats 3.0.1.
- The 46 assertions include ProgramPage boundary 100/101 and contract-level checks for separate Management/Ingress bearer schemes and non-empty proposed scope metadata on every secured operation.
- CI explicitly states it does not test runtime authorization, tenant binding, Inbox/Job atomicity, deduplication, ledger effects or provider allowlists. These remain NOT TESTED at runtime.
- Added bilingual LOT-AFFILIATE-SEC-ACC-001, a proposed runtime security acceptance and boundary specification. It defines principal/authorization boundaries, trusted ingress flow, idempotency/fingerprint semantics, event/schema governance, resource protection, persistence/worker invariants, privacy/audit, a runtime test matrix and four release gates. It is not implementation or security approval.
- The workflow checkout used PR merge ref `ad0cd3237e0dbe94cb4a49f257cba0ac00bd167d`, which combines the tested PR head with its base. The PR head remains the exact commit above.
- Remaining non-blocking tool notices: Redocly license metadata warnings; AsyncAPI informational latest-version recommendation; npm dependency deprecation warnings; GitHub Actions Node 20 deprecation notice for pinned actions. Do not silently treat these as validation failures or production risks without separate assessment.

### Next controlled work
1. Review LOT-AFFILIATE-SEC-ACC-001 and reconcile every requirement with LOT-API-PLATFORM-001, LOT-IAM-TENANT-001, LOT-EVENT-001, LOT-FIN-POST-001 and LOT-QA-001.
2. Produce an owner-decision sheet for unresolved identity, capability, installation lifecycle, registry ownership, fingerprint ADR, numeric quotas, retention/audit and commission-effect identity; leave unknown values explicitly TBD.
3. Define a synthetic-only isolated runtime proof plan and its test harness boundaries. No production adapter, real partner credentials, financial posting or sandbox request until the required decisions and actual partner documentation/authorization exist.
4. Re-run bilingual documentation governance after index/status updates and verify the exact final PR head and all workflows.


## G09-A3 decision packet and synthetic runtime proof plan — 2026-11-27

- Added bilingual LOT-AFFILIATE-G09-A3-001 at `docs/en/engineering/affiliate-g09-a3-decision-and-runtime-proof.md` and `docs/fa/engineering/affiliate-g09-a3-decision-and-runtime-proof.md`.
- The packet records 15 explicit decision items across principal/IAM, authorization, credentials, installation and event/schema registry, event identity, fingerprinting, concurrency, resource ceilings, data classification/retention/encryption, audit and the financial non-effect boundary. Every item remains Proposed or Open; no owner approval is implied.
- It defines P0–P6 synthetic proof stages covering harness isolation, identity/tenant boundaries, strict parsing and registry controls, idempotency/concurrency, transaction/crash recovery, resource/privacy controls and zero financial side effects.
- Runtime proof is not started. It requires explicit owner scope approval, security/operations isolation approval and an approved disposable persistence candidate with real transactional constraints. No partner adapter, real credential, sandbox call, financial posting, merge or deployment is authorized.


## G09-A4 runtime proof architecture and adversarial test design — 2026-11-27

- Added bilingual LOT-AFFILIATE-G09-A4-001 at `docs/en/engineering/affiliate-g09-a4-runtime-proof-architecture.md` and `docs/fa/engineering/affiliate-g09-a4-runtime-proof-architecture.md`.
- The design specifies a synthetic-only disposable harness, seven trust boundaries, eight persistence invariants, 47 stable adversarial case IDs across identity, object/function/property authorization, idempotency/canonicalization, parser/schema/SSRF, resource governance, transaction/worker recovery, privacy/audit and financial non-effect.
- It defines six independent test oracles, an evidence bundle, eight owner/reviewer approval gates, execution ordering, severity and immediate stop conditions. OWASP API Security Top 10 (2023), RFC 8785, CloudEvents and conditional PostgreSQL references are cited as design references, not as implementation/vendor approvals.
- No test harness or runtime implementation has been built or run. A4 execution remains BLOCKED pending explicit scope/isolation approval, approved disposable persistence/queue candidates, test identity profile, data/evidence policy, workload ceilings and finance/security attestation of zero financial reachability.
- No partner adapter, real credential, external sandbox request, commission calculation, financial posting, merge or deployment is authorized.

## G09-A5 continuation point (2026-11-27)
- Added bilingual LOT-AFFILIATE-G09-A5-001. It translates the 47 stable A4 cases into a technology-neutral persistence/atomicity model, claim-generation fencing protocol, synthetic identity fixtures, failure-injection mapping, executable test contract, independent oracles and gated execution sequence.
- No database, queue, IAM provider, runtime, quota, retention period or physical schema was selected. A5 is a design blueprint only; A4's eight approval gates remain binding. Runtime implementation and execution remain BLOCKED pending explicit approvals.
- The blueprint explicitly separates source-event identity, request idempotency key and economic-effect identity; requires durable uniqueness and atomic Receipt+Work creation; treats queue messages as wake-up hints; and requires stale-worker fencing and zero financial reachability.
