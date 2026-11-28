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


## G09-A6 design verification — 2026-11-27
- Added bilingual LOT-AFFILIATE-G09-A6-001. The review confirms all 47 stable A4 IDs are represented in A5's grouped mapping, but grouped mapping is not case-level executable coverage.
- Disposition: **CONDITIONAL DESIGN PASS WITH OPEN FINDINGS**. Ten findings F01–F10 are recorded. F01–F07 block runtime design approval; F08–F10 must close before the affected test groups can be accepted.
- Key clarifications required: mandatory atomic pair is InboxReceipt + WorkItem; DeliveryOutbox is distinct/conditional and must not weaken that pair; transaction race/unknown-commit schedules; stale-worker zero-write fencing proof; approved identity/fingerprint profile; lifecycle revalidation policy; defense-in-depth financial non-reachability; measurable resource profile; per-case oracle independence; and approved data lifecycle policy.
- On exact reviewed head `e6808bda79a65c84d0dfab6e8b07094014184910`, Affiliate Contract Validation run `46060385984` (#73) and Documentation Governance run `46060385973` (#956) both completed successfully. These are documentation/contract workflow results only, not runtime evidence.
- PR #76 remains Open/Draft. A4-GATE-01..08 remain mandatory. No runtime implementation or execution, vendor selection, partner integration, financial operation, merge or deployment is authorized.
- Next controlled step: close F01–F10 in bilingual documents, add a 47-row case/oracle manifest, then re-run exact-head CI. Runtime remains BLOCKED.


## G09-A7 continuation — 2026-11-27
- Added bilingual LOT-AFFILIATE-G09-A7-001. The manifest contains 47 unique stable A4 IDs (6 IAM, 7 AUTH, 8 IDEM, 6 PARSE, 5 RES, 8 DUR, 4 DATA, 3 FIN) in both language versions; an automated repository read confirmed 47 rows and 47 unique IDs per file, with identical ID order.
- Each row now maps fixture, deterministic stimulus, expected protocol/authorization, persistence and financial non-effect assertions, independent oracle/evidence, and explicit NOT RUN or policy/ADR BLOCKED status.
- Added five abstract deterministic schedules: concurrent duplicate ingress, unknown commit outcome, stale-worker fencing, atomic-pair crash matrix and tenant lifecycle race. These are design contracts only, not executed tests.
- Proposed mandatory atomic pair is InboxReceipt + WorkItem. DeliveryOutbox is separately conditional for downstream publication and cannot replace WorkItem. This is a proposed design clarification, not an approved physical schema or technology choice.
- F01 is ready for independent review; F02–F10 remain open pending accountable decisions, ADRs and evidence. No numeric quota, retention duration, vendor or runtime is selected.
- OWASP ASVS is pinned to stable 5.0.0 for future requirement mapping; bleeding-edge content is not silently adopted. No ASVS compliance claim is made.
- No runtime/harness/DB/queue implementation or execution, partner integration, financial operation, merge or deployment is authorized. All eight A4 gates remain mandatory.


## G09-A8 continuation — 2026-11-27
- Added bilingual LOT-AFFILIATE-G09-A8-001. This is an adversarial **self-review**, not independent approval; no runtime/infrastructure was inspected or executed.
- Recorded 12 additional findings: lease-validity at mutation, external-side-effect fencing, complete financial capability denial, lifecycle linearization, oracle independence, generation/token lifecycle, unknown-commit reconciliation, evidence provenance/time integrity, retention/deletion conflict, missing interleavings, resource amplification/fairness and semantic bilingual parity.
- Added eight proposed subcases under existing A4 IDs; the canonical 47 IDs are not renumbered and no tests have run.
- A7 F01–F10 remain open as previously classified. A7-F01 is still only ready for a genuinely independent review; A8 does not close it. A8-F01..F12 are OPEN.
- A4-GATE-01..08 remain NOT APPROVED; runtime/harness/database/queue/IAM execution remains BLOCKED. No partner integration, financial operation, merge or deployment is authorized.
- Next: obtain independent reviewer disposition; resolve temporal protocol and financial capability proof; update A7 subcase traceability and create accountable ADRs; revalidate bilingual governance and exact-head CI.


## G09-A9 / ADR-001 — 2026-11-28
- Added bilingual LOT-AFFILIATE-G09-ADR-001, a proposed durable per-WorkItem claim-generation and guarded-transition protocol. It defines the lease-expiry linearization race, authenticated owner/token checks, no lease resurrection, transaction boundary restrictions, unknown-commit reconciliation and restore/recovery fencing.
- The key semantic distinction is explicit: lease expiry makes work eligible for reclaim; the first serialized guarded durable transition wins. A transition that linearizes while the lease is valid is ordered before a later reclaim; after expiry or after generation change, the old worker must change zero protected rows. This depends on the eventual persistence engine's proven lock/time/failover semantics and is not yet approved.
- Added eight A8 subcases to both A7 traceability documents, mapped to their existing A4 parents. Canonical A4 count remains 47; parent and subcase outcomes must be reported separately. All subcases remain NOT RUN/BLOCKED.
- ADR-001 is PROPOSED. Owner decisions remain open for authoritative time/failover, persistence serialization semantics, generation exhaustion, recovery incarnation authority, lifecycle policy and bounded transaction/worker policy. No DB/queue/vendor or numeric values selected.
- Independent review is still required. A7 F01–F10 and A8 F01–F12 remain open. All eight A4 gates remain NOT APPROVED; runtime/harness/database/queue/IAM implementation or execution remains BLOCKED. No partner, financial, merge or deployment authorization.


## G09-A10 / ADR-002 — atomic acceptance and unknown-commit reconciliation (2026-11-28)
- Added bilingual LOT-AFFILIATE-G09-ADR-002. It proposes exactly one durable InboxReceipt + WorkItem pair in a single atomic transaction; acknowledgement only after confirmed commit; UNKNOWN as a first-class outcome; authoritative reconciliation by stable source identity; fail-closed handling when the primary/authority is unavailable; conflict and partial-pair quarantine; and a separate conditional DeliveryOutbox boundary.
- Added a 17-case crash/concurrency/failover matrix (C01–C17), independent-oracle/evidence requirements, alternatives and owner decisions. All cases are NOT RUN. No DB, isolation level, queue, vendor, schema, quota, retention value or topology is selected.
- Added LDR-055 to both decision registers. ADR-002 remains PROPOSED; owner approval and genuinely independent review are pending. A7-F01–F10 and A8-F01–F12 remain open; all eight A4 gates remain NOT APPROVED. No runtime, partner, financial, merge or deployment authorization.
- Live PR #76 head before this update was 3112f7e4db83c27c223a054db497665619df5164. Exact-head workflows were queued; final-head CI must be rechecked. A previously observed Documentation Governance failure was caused by ADR-001 lacking the required stable Document ID field in both languages; the two ADR-001 files have since been amended, and that correction must be verified by CI on the final head.


## G09-A11 — ADR-002 adversarial design review (2026-11-28)
- Added bilingual LOT-AFFILIATE-G09-A11-001 against ADR-002 v0.1.0 / reviewed head 985cfee7ce233e6297b7de2d5d2339d8484b843e.
- Eight findings: A11-F01 commit durability across failover (Critical); F02 authority epoch/split-brain fencing (Critical); F03 negative-read versus in-flight commit race (Critical); F04 pair cardinality/relationship constraints (High); F05 fingerprint profile/version dependency (High); F06 retention-bounded idempotency (Critical); F07 quarantine blast radius/DoS (High); F08 acceptance versus execution response semantics (High).
- Proposed nine A11 adversarial subcases under existing A4/A8 parents; canonical 47 A4 IDs are unchanged. All subcases are NOT RUN.
- This is a same-workflow self-review, not independent sign-off. LDR-056 recorded in both decision registers. ADR-002 remains PROPOSED; A7/A8 findings remain open; all eight A4 gates remain NOT APPROVED. No runtime, database, queue, partner, financial, merge or deployment authorization.
- Research references include official Google Spanner unknown-commit guidance and PostgreSQL HA, replication and WAL durability documentation. No provider/technology is selected.


## G09-A12 — ADR-002 v0.3.0 integration (2026-11-28)
- Integrated A11 design blockers into bilingual ADR-002 v0.3.0: single-writer Authority Epoch and old-primary fencing; acknowledged-commit durability/RPO; replay-horizon-bounded source-event dedupe/tombstones; graduated quarantine and worker exclusion; acceptance-only response semantics.
- Reconciled A11-F01..F08 in the bilingual A11 review record. This is same-author crosswalk, not independent closure. All eight findings remain OPEN pending owner decisions, independent review and candidate-specific evidence.
- Expanded bilingual A7 with nine A11 and four supplemental A10 subcases; canonical A4 remains 47 IDs. All added subcases are NOT RUN/BLOCKED.
- ADR-002 remains PROPOSED. No technology, authority service, database, queue, runtime, partner, financial operation, merge or deployment is authorized. All eight A4 gates remain NOT APPROVED.
- Exact-head CI must be rechecked after these commits; prior workflow success does not transfer.

- Follow-up synchronization: ADR-002 v0.3.0 now includes the A11 authority-epoch, durability/RPO, replay-retention, quarantine and response-semantics requirements; PostgreSQL HA/failover/WAL references are linked as comparative evidence only. A7 EN/FA each contain the same 47 canonical A4 IDs and 21 unique extension subcases (8 prior + 9 A11 + 4 A10); README EN/FA link the A11 review. All extensions remain NOT RUN/BLOCKED.

- A7 parent-reference precision correction: A11-DUR-02b is now explicitly mapped to both A4-DUR-02 and A4-IDEM-02 in English and Persian; the canonical 47-case set and 21 extension-subcase count are unchanged.


## G09-A12 — independent ADR-002 review package (2026-11-28)
- Added bilingual LOT-AFFILIATE-G09-A12-001. It packages independence/competence criteria, a frozen-input protocol, adversarial reconstruction schedules, an A11-F01..F08 evidence matrix, A7 extension inventory and independent-oracle requirements.
- The package explicitly does not constitute an independent review. No reviewer has been assigned or signed off; A11-F01..F08 remain OPEN, all A7 extension cases remain NOT RUN/BLOCKED, ADR-002 remains PROPOSED and all eight A4 gates remain NOT APPROVED.
- Corrected duplicate ADR-002 section numbering and a duplicated Persian A7 statement. These are editorial corrections only and do not close any design finding.
- Exact-head CI must be rechecked after the final sequential commits. No technology, runtime, partner, financial operation, merge or deployment is authorized.


## G09-A13 — contract validation assurance review (2026-11-28)
- Both workflows on exact source head `e88c6b6fac04b451926a8137ca68571f19e18fa8` completed SUCCESS: Documentation Governance #1014 and Affiliate Contract Validation #151. Job steps confirm OpenAPI lint, AsyncAPI CLI validation and representative Ajv payload fixtures ran.
- Added bilingual LOT-AFFILIATE-G09-A13-001 as a same-author assurance review, explicitly not independent. Findings A13-F01..F06 remain OPEN: operation-specific scheme/scope assertions, CloudEvents extension conformance/installation allowlist boundary, AsyncAPI dialect wording, transitive dependency reproducibility, 202/503/UNKNOWN response alignment with ADR-002, and fixture coverage completeness.
- Existing contract and security documentation already state runtime allowlist and scope semantics remain open; this review does not claim those are newly implemented. ADR-002 remains PROPOSED; A11-F01..F08 remain OPEN; A7 remains design-only; all eight A4 gates remain NOT APPROVED.
- Recommended next package G09-A14 is contract-validator hardening and response-state alignment. No runtime implementation, technology selection, partner integration, financial operation, merge or deployment is authorized.


## G09-A14 — contract validation hardening (2026-11-28)
- Added bilingual LOT-AFFILIATE-G09-A14-001 and machine-readable `contracts/validation/affiliate-contract-validation-manifest.v1.json`.
- Validator candidate now checks exact per-operation bearer scheme and `x-required-scopes` against a manifest, with seven negative mutation cases; constrains generic CloudEvents extension names/types and validates CloudEvents Unicode semantics for all CloudEvents string-valued context attributes (core and extension); corrects the AsyncAPI 3.0 default Schema Object description and guards the Ajv Draft-07-compatible subset; inventories all 11 current schema roots and 53 positive/negative fixtures.
- Partner 202/503 wire wording is conditional on atomic persistence and an owner-approved durability acknowledgement; UNKNOWN is explicitly not confirmed acceptance or rejection. Exact UNKNOWN HTTP/error mapping, failure model, RPO and promotion/recovery decisions remain open.
- Added separate exact-version manifests for `.github/contract-tools` and `.github/schema-tools`; their isolated dependency graphs prevent CLI/Ajv transitive collisions. CI bootstraps both lockfiles and a narrowly scoped write job commits only those files; this temporary path must be removed after lockfiles are committed. Both isolated lockfiles are committed (`.github/contract-tools/package-lock.json` and `.github/schema-tools/package-lock.json`); the temporary bootstrap/artifact/write job has been removed and strict `npm ci` is now mandatory. A13-F04 remains OPEN only until strict `npm ci` passes on the final exact head.
- A14 is IN PROGRESS. Source-level static cross-check found 53 unique script fixture labels matching 53 manifest fixture IDs; this is not an executed Node/Ajv result. Exact-head CI for the current A14 head must be checked after the latest sequential commits.
- A13-F02 remains partially open for installation-specific runtime allowlists; A13-F05 remains open for owner decisions and candidate-specific proof. ADR-002 remains PROPOSED; A11-F01..F08 remain OPEN; A7/A8 remain design-only/NOT RUN; all eight A4 gates remain NOT APPROVED. No runtime, persistence selection, partner integration, financial operation, merge or deployment is authorized.

### G09-A14 lockfile checkpoint
- Both isolated lockfiles are committed at the branch tip: contract-tools (1,409 package records) and schema-tools (7 package records), lockfileVersion 3. The bootstrap/artifact/write-back mechanism has been removed; the validator workflow now uses strict `npm ci` for both prefixes. Final exact-head verification is pending.

### G09-A14 exact-head verification — 2026-11-28
- Verified exact head `3a008718ab9cf40a551441e3a195f73874788f26`: Documentation Governance #1057 SUCCESS (`46070895494`) and Affiliate Contract Validation #227 SUCCESS (`46070891292`).
- Both strict `npm ci` installs from committed isolated lockfiles passed on Node 24.11.1/npm 11.6.2. Redocly OpenAPI, AsyncAPI CLI 6.2.2 and Node/Ajv payload validation passed: 66 assertions, 11 schema roots, 53 positive/negative fixtures.
- A13-F01/F03/F04/F06 are verified for contract/CI scope. A13-F02 remains partial pending installation-specific runtime allowlist proof; A13-F05 remains open pending owner decisions and candidate-specific durability/UNKNOWN proof. Non-blocking notices: missing `info.license` metadata and AsyncAPI CLI recommendation to consider 3.1.0; no license or dialect migration is inferred.
- ADR-002 remains PROPOSED; A11-F01..F08 OPEN; A7/A8 design-only/NOT RUN; all A4 gates NOT APPROVED; independent review outstanding. No runtime, persistence/queue selection, partner integration, financial operation, merge or deployment authorized.


## G09-A15 — ADR-002 persistence proof readiness (2026-11-28)
- Added bilingual LOT-AFFILIATE-G09-A15-001 with seven candidate-neutral proof obligations, 12 owner decisions, 12 synthetic schedules, independent evidence-manifest requirements, staged readiness gates and stop conditions.
- Baseline inspected: PR #76 head `736390f86ab425a8c273dcf254cc5974e9eb55ae`; Affiliate Contract Validation #235 and Documentation Governance #1062 both SUCCESS on that exact head. These runs do not apply to subsequent A15 documentation commits and do not prove persistence/runtime behavior.
- The A12 package remains the independent-review procedure; no independent GitHub review sign-off was present in the inspected PR record. A15 is not an independent review. A11-F01..F08 remain OPEN; ADR-002 remains PROPOSED; all A4 gates remain NOT APPROVED; S01-S12 are NOT RUN.
- A13-F02 installation-specific runtime allowlist and A13-F05 owner/candidate proof remain open. No persistence/queue/vendor selected; no runtime/harness execution, partner integration, financial operation, merge or deployment authorized. Latest-head CI must be checked after the A15 documentation commits.


### G09-A15 exact-head CI verification — 2026-11-28
- On exact head `5543d7ab24ec263fd0d71c40c157309a72d925c2`, Documentation Governance #1067 (run `46104632406`) and Affiliate Contract Validation #242 (run `46104632398`) both completed SUCCESS.
- Documentation Governance validated bilingual structure and local links. Affiliate Contract Validation completed locked tool installation, OpenAPI validation, AsyncAPI validation and schema payload fixture validation.
- A manual identifier-set comparison confirmed matching English/Persian inventories for PO-01..PO-07, OD-01..OD-12, S01..S12 and A11-F01..F08. This is structural ID parity, not a semantic translation audit.
- These results apply only to the exact head above. Any later commit requires exact-head CI re-verification. No runtime/persistence proof was executed; A11-F01..F08 remain OPEN, ADR-002 remains PROPOSED, S01..S12 remain NOT RUN, and all A4 gates remain NOT APPROVED.


## G09-A16 — adversarial architecture review dossier (2026-11-28)
- Added bilingual LOT-AFFILIATE-G09-A16-001 against frozen baseline PR #76 head `8e9a880c14000bd158f66ae2001c02669ed4cc6b`.
- A16 adds ten author-led cross-cutting challenge points, twelve deterministic schedule families, source-freeze/change-control requirements, reviewer independence/competence declaration, independent-oracle/evidence requirements and a signed reviewer disposition template.
- Research references include AWS Builders' Library/Well-Architected retry and idempotency guidance, PostgreSQL WAL/synchronous replication/failover documentation, fencing-token analysis, Jepsen history-checking methodology, RFC 8785 and RFC 7493. These inform review; no technology is selected.
- A16 is not independent sign-off. A11-F01..F08 remain OPEN; ADR-002 PROPOSED; A7/A8 extensions NOT RUN/BLOCKED; all A4 gates NOT APPROVED. No candidate/runtime/harness proof, partner integration, financial operation, merge or deployment authorized. CI must be checked on the post-A16 exact head.


## G09-A17 — independent-review reconciliation (2026-11-28)
- PR #76 was moved from Draft to Ready for review; it remains OPEN and unmerged. GitHub reported `mergeable=true` at the latest inspection. This is a platform mergeability observation only.
- Review #6095766449 by `xrayman6zfm-ux` is `APPROVED`, submitted at `2026-11-28T04:19:55Z`, and references exact commit `b547d3976c97e6068ace6747dbf72f3a6fb9828f`. Its body is empty; no inline review threads were observed. The review is valid platform-level approval evidence.
- A12 substantive-review requirements (independence/competence/conflict declaration, artifact inventory, reconstructed protocol, adversarial analysis and individual A11 dispositions) are not evidenced in the available GitHub review artifacts. This is an evidence limitation, not a claim that no off-platform analysis occurred.
- Added bilingual LOT-AFFILIATE-G09-A17-001 and LDR-062. A17 records the approval without inferring technical closure. A11-F01..F08 remain OPEN; OD-01..OD-12 remain OPEN; ADR-002 remains PROPOSED; all A4 gates remain NOT APPROVED.
- No runtime/persistence proof, candidate selection, partner integration, financial operation, merge or deployment is authorized. The A17 follow-up branch is based on the exact approved PR #76 head; any A17 changes require their own exact-head CI and review.


## Enterprise evaluation standard — 2026-11-28

- Added bilingual LOT-EVAL-001 at `docs/en/governance/enterprise-evaluation-standard.md` and `docs/fa/governance/enterprise-evaluation-standard.md`.
- LOT-EVAL-001 is a proposed parent governance standard spanning product, technology, supplier, integration, data/model and operating-model decisions. It introduces risk-proportionate T0–T3 depth, claim-level evidence classes and freshness, mandatory workflow, non-compensable gates, pre-frozen score rubrics, lifecycle TCO/reversibility, controlled-pilot evidence, decision dossiers, explicit states, reassessment triggers and specialist-profile precedence.
- It deliberately preserves LOT-PROVIDER-EVAL-001 and LOT-TECH-ADR-001 as specialist documents. It does not silently replace or approve either document, set binding score weights, select a candidate, approve legal/jurisdictional scope, or authorize procurement, implementation, production data, partner integration, financial activity or launch.
- Reference research includes ISO 31000:2018, ISO/IEC 25010:2023, NIST SP 800-161 Rev.1 Update 1, NIST SP 1326 (2026), NIST SP 1305, OWASP SAMM and FinOps Framework. References inform evaluation design; they do not certify Lottorito or any candidate.
- First application is proposed as a bounded, non-production retrospective evaluation, to be selected by the accountable owner after review. The standard remains PROPOSED pending owner and specialist review.


## LOT-EVAL-001 adversarial hardening — 2026-11-28

- Author-led adversarial review report LOT-EVAL-A18-001 added in English and Persian. It records 12 findings: 1 Critical, 10 High and 1 Medium. The report explicitly does not claim independent assurance.
- LOT-EVAL-001 advanced in draft from v0.1.0 to v0.2.0 with a bilingual normative Section 17 covering risk tier vs risk rating, inherent/residual risk, multidimensional evidence provenance, evidence sufficiency vs capability score, NS vs zero, normalized scoring, inter-rater controls, lifecycle TCO, supplier due diligence, DATA/MODEL evaluation, ISO/IEC 25010 quality scenarios, pilot protocol, approval separation and specialist-document precedence.
- The review reconciled the proposed scorecards in LOT-PROVIDER-EVAL-001 and LOT-TECH-ADR-001: their weights remain proposals until explicitly adopted for a named decision unit and reconciled with the parent rubric.
- A18 is author-led; independent review, owner risk-appetite decisions, specialist approval and exact-head CI remain pending. LOT-EVAL-001 remains PROPOSED. No candidate, provider, technology, jurisdiction, procurement, production data, partner integration, financial activity, merge or deployment is authorized.


## LOT-EVAL-001 follow-up corrections — 2026-11-28

- LOT-EVAL-001 is now proposed v0.3.0. Sections 8.3 and 17.10 add the complete capability rubric; separate evidence state and rating; explicit NS/Partial/N/A semantics; atomic-subcriterion handling; confidence anchors; synthetic-test versus operational tier boundary; risk-horizon and ordinal-matrix limitations; TCO forecast-bias/reference-class and switching-value analysis; and formal-assurance criteria.
- Follow-up adversarial review REV-01…REV-14 is recorded in A18. REV-11 is explicitly non-substantive: the two formulas are equivalent when applicable weights total 100.
- Owner direction on 2026-11-28 authorizes evidence-supported technical/document corrections across relevant artifacts. This is an implementation instruction, not item-level acceptance or residual-risk approval. All REV owner dispositions remain PENDING.
- Owner-led review, specialist challenge and independent assurance are distinct. No independent assurance is claimed or recorded. LOT-EVAL-001 remains PROPOSED and unapproved.
- English/Persian standard, A18, owner-review register and decision records have been synchronized. Documentation Governance must be checked on the final exact head; no CI success is claimed for the new commits.
- No candidate, supplier, technology, jurisdiction, procurement, contract, production data, partner integration, financial activity, merge or deployment is authorized.


## Cross-document LOT-EVAL alignment — 2026-11-28

- Provider profile LOT-PROVIDER-EVAL-001 advanced to proposed v0.2.0: evidence authority and independence are separate; its provider-specific weights remain proposals; its capability ratings, NS, Partial, N/A, confidence and hard-gate semantics inherit LOT-EVAL-001 v0.3.0.
- Technology ADR LOT-TECH-ADR-001 advanced to proposed v0.2.0: its local 1–5-only wording is replaced by the parent 0–5/NS/N/A evidence model; suggested technology weights remain unapproved.
- Security threat model LOT-SEC-TM-001 advanced to proposed v0.2.0: residual High/Critical risk labels now require a documented scenario, horizon, raw likelihood/impact pair, impact dimensions, uncertainty, control evidence and named acceptance authority, with a reference to the parent risk anchors.
- The gaming-provider strategy continues to rely on LOT-PROVIDER-EVAL-001 as its common supplier-evaluation process; no gaming provider or market is selected.
- The bilingual architecture quality-attributes catalogue now clarifies that QA scenario outcomes are bounded by tested scope/configuration/workload/period and inherit LOT-EVAL-001 evidence and decision semantics; QA status alone is not production assurance or a provider score.
- A further parent-standard consistency pass revised §4 is the sole canonical tier-trigger table and bases tiering on the exact decision unit and permission; bounded synthetic tests are classified by actual scope and are not automatically T3. A high-impact identity decision capable of materially changing access to customer funds/privileged activity or causing severe harm is an explicit T3 trigger. §5.1 now records evidence authority, independence, directness, scope, freshness, reproducibility and limitations as separate attributes rather than a conflated evidence class. §5.2 now contains explicit confidence anchors aligned with §17.10.2. The same corrections are present in Persian.
- A18 now maps REV-01…REV-14 to the v0.3.0 corrective sections. The next gate is the owner's finding-by-finding review plus specialist challenge where needed; independent assurance remains a distinct, risk/claim-dependent activity, not a synonym for owner review.
- The owner-review register now has a separate document-implementation-status column for REV-01…REV-14. It records applied document changes separately from owner disposition; substantive acceptance tests and all owner dispositions remain pending. REV-11 is recorded as non-substantive with its equivalence example retained.
- These are document-level consistency corrections only. No provider weights, technology, security control, residual risk, supplier, jurisdiction, procurement, production, financial activity, merge or deployment is approved.


## LOT-EVAL-RDM-001 — deterministic reference model (2026-11-28)

- Added an isolated, standard-library-only Python reference harness at `tools/lot_eval_rdm.py`; it is not imported by product code and uses embedded synthetic fixtures only.
- Local execution on Python 3.13.5: `python tools/lot_eval_rdm.py` — 21/21 AVT vectors PASS; 10/10 specification mutants killed; 210 mutant/vector evaluations; zero surviving mutants. This is author-led specification-level fault injection, not third-party mutation score or independent assurance.
- The harness maps the frozen LOT-EVAL-001 v0.3.0 / LOT-EVAL-AVT-001 v0.2.0 baseline at commit `e7aed0892a0de212fc3fd7603a6976eee503a76f`. Documentation Governance run #1133 (ID `46118746808`) succeeded on exact implementation head `863fe0eb8f27e93e68dcd0f6275aaef377cf3c32`: 62 bilingual pairs/160 local links checked and the RDM harness step passed. Any subsequent commit requires a fresh exact-head run.
- Interpretation stop: non-material NS aggregate treatment is not fully specified by §8.3; absent a separately recorded provisional authority, the model returns UNRESOLVED rather than inventing a rule. Authority/materiality are synthetic inputs, not validated approvals.
- Coverage is limited to AVT-01…AVT-21. Confidence, TCO, formal assurance, legal eligibility and actual owner dispositions are not automated. No independent reviewer has reconstructed the oracles.
- LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 remain PENDING. No candidate, procurement, provider integration, production data, financial activity, merge or deployment is authorized.


## LOT-EVAL-RDM-002 — adversarial audit (2026-11-28)

- Author-led source-to-oracle audit compared the actual RDM implementation with the frozen matrix's detailed fixtures and metamorphic properties.
- Findings: 5 HIGH and 5 MEDIUM. Key issues: tier permission boundary not implemented in baseline logic; N/A post-score sequence represented only by a Boolean; required mandatory-gate catalogue is not enforced; AVT-17 duplicates AVT-16 assertions; several AVT-01 metamorphic properties are not executed; horizon is only syntactically non-empty; mutant-equivalence/reachability counts were hard-coded zero and are now correctly reported NOT_ASSESSED/null; exact AVT/MUT population guards have been added, but semantic duplicate behavior under different IDs remains open; oracle independence remains absent.
- Correct interpretation: 21 registered checks passed; this is not proof that all 21 matrix vectors and their sub-properties were fully verified. Earlier “equivalent/unreachable/unresolved = 0” output is not evidential because the harness does not classify those categories.
- Recommended next stage: RDM-003 — reconstruct normative decision rules, obtain a blind independent oracle pack, then correct the model using decision tables, event/state-machine tests, metamorphic and property-based invariants, and truthful mutation accounting.
- This is author-led review, not independent assurance. LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 remain PENDING. No production, procurement, partner integration, financial activity, merge or deployment is authorized.


## LOT-EVAL-RDM-003A — normative rule decomposition (2026-11-28)

- Added bilingual `enterprise-evaluation-decision-rule-catalogue-001.md` with 18 atomic rules, five decision tables, five ambiguity issues and a rule-to-test traceability baseline.
- Explicitly classifies each rule as NORMATIVE, DERIVED-GUARD or UNRESOLVED. No unresolved interpretation is silently encoded as a deterministic result.
- Key unresolved issues: non-material NS/provisional aggregate authority and materiality; conditional experiment gate versus N/A; minimum decision-unit completeness; calibration of qualitative likelihood; criterion-specific thresholds for 1–5 anchors.
- The catalogue is an author-led design artifact. It does not change the parent standard or executable model. Independent blind oracle derivation and bilingual semantic review remain pending.
- Research basis: ISO/IEC/IEEE 29119-4:2021; ISTQB CTFL v4.0.1; NASA SWE-114 and SWE-072; NIST SP 800-160 Vol.1 Rev.1.
- LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 remain PENDING. No procurement, integration, production, financial activity, merge or deployment is authorized.


## LOT-EVAL-RDM-003B — blind independent oracle package (2026-11-28)

- Added bilingual reviewer packet and blank worksheet under `docs/{en,fa}/governance/`; indexed in both documentation READMEs and recorded as LDR-070.
- Frozen source snapshot: commit `4443ef5336935310f034419d72967dec3d86a21a`; packet records exact blob SHAs for parent standard v0.3.0 and AVT matrix v0.2.0. RDM-003A blob hashes are recorded for audit but explicitly withheld from the reviewer.
- Review population: 18 atomic rule IDs + 21 AVT input-only cases + 35 decision-table rows = 74 entries. The packet withholds author-derived rule descriptions, decision-table outputs, ambiguity dispositions, model source, model outputs and mutation results.
- Status is `PENDING_EXTERNAL_REVIEW`: no second reviewer is identified, no blind review has been performed, and no independent oracle has been returned or frozen. A qualified reviewer must complete, attest and hash the worksheet before any reconciliation.
- RDM-001 remains unchanged. No model changes until the independent worksheet is frozen, discrepancies are classified and any required owner/policy decisions are recorded. This is not independent assurance, adoption of LOT-EVAL-001, or acceptance of REV-01…REV-14.
- Research basis: ISO/IEC/IEEE 29119-1:2022 test-oracle definition; NASA SWE-141 and NASA IV&V independence guidance. These references inform process design; they do not certify this review.
- LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 remain PENDING. No candidate selection, procurement, integration, production data, financial activity, merge or deployment is authorized.


## RDM-003B — author-led second-pass review correction (2026-11-28)

- The owner directed that the authoring AI perform direct adversarial reviews because no second person is available. The method is now explicitly an author-led second-pass review, not blind review or formal independent assurance.
- Bilingual report: `docs/{en,fa}/governance/enterprise-evaluation-author-led-second-pass-review-003b.md`; findings AR-01…AR-15.
- The former blind-review packet and blank worksheet are superseded historical artifacts. The 35 decision-table rows were not supplied as input-only condition combinations, so the claimed blind derivation was not executable.
- RDM-001 was corrected for: explicit highest-plausible-tier input (not hard-coded T3); separate evidence state and capability rating; distinct AVT-17 ranking-sensitivity behavior; explicit late N/A state; and six model guard checks.
- AVT-09, AVT-06, AVT-14 and AVT-17 matrix semantics and DT-04 non-overlap are being reconciled bilingually. Exact-head CI is required before any pass claim.
- Historical CI results from the pre-correction harness do not apply to the corrected source. No independent assurance, owner acceptance, procurement, production, financial activity, merge or deployment is implied.


### RDM-003B follow-up verification (latest exact head)

- Full row-level review added AR-16…AR-18: DT-01 bounded-vs-unbounded tier ambiguity, DT-03 precedence, and DT-05 missing required risk-record fields. DT-05 now has seven rows; five decision tables contain 36 rows total.
- Current review inventory is 18 rule propositions + 21 AVT scenarios + 36 table rows = 75 review obligations, not 75 independent tests.
- RDM-001 now has 21 AVT checks and 8 separate model guards. All 8 guards include invalid trigger, empty candidate set, negative weight, empty compound atoms, inconsistent material-NS, incomplete provisional authorization, boolean capability rating and boolean risk anchor.
- Exact-head CI #1202 (run ID 46123183828) passed on 2dd02e5fd4b06d46c995ee1e934053d15987c001: 67 bilingual Markdown pairs, 172 local links, 21/21 AVT, 8/8 guards, 10/10 hand-authored mutants killed, 210 AVT mutant/check evaluations, zero failures and zero survivors. Structural and registered-harness evidence only; no full matrix-property or independent-assurance claim.


## LOT-EVAL-RDM-004 — full decision-table verification (2026-11-28)

- Added `tools/lot_eval_rdm004.py` and a bilingual verification record. All 36 rows across DT-01…DT-05 have stable executable row IDs and deterministic synthetic fixtures.
- Row-level execution also covers six registered metamorphic properties and four targeted specification mutations. These are reported separately; they are not 46 independent end-to-end tests or a conventional mutation score.
- Exact-head Documentation Governance run #1216 (run ID `46129592496`) succeeded on `36c2f66af85cbe24255feeaaab17c70329034071`: bilingual documentation validator PASS; existing RDM-001 harness PASS; RDM-004 runner PASS. The RDM-004 runner exits successfully only when all 36 row checks, six metamorphic checks and four targeted mutation checks pass.
- DT04-R5 intentionally remains UNRESOLVED for non-material NS without a separately complete provisional-authority path. No definitive aggregation rule was invented.
- RDM-U01…U05 remain unresolved. RDM-R13/R14/R17/R18 and other parent-standard requirements are not all covered by these tables and require separate verification. Synthetic fixtures do not authenticate real evidence, authority, applicability, legal status or control operation.
- LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 owner dispositions remain PENDING. No candidate/provider selection, procurement, partner integration, production data, financial activity, merge or deployment is authorized.


### RDM-004 follow-up — mandatory-gate registry hardening and exact-head CI

- Author-led code review found that the initial DT02-R6 fixture represented omission with an explicit flag. That checked the expected branch but did not itself prove that the evaluator could discover a missing required category from the recorded gate set.
- Corrected the model with a closed-world ten-category minimum gate registry derived from parent §7. DT02-R6 now omits one required category from the actual recorded set; the evaluator must return `BLOCK_INCOMPLETE_REGISTER`. Unknown categories are rejected.
- Exact-head Documentation Governance run #1221 (ID `46129804594`) succeeded on `f674bc5979df472a7334088f2937b89290bc50f4`: bilingual validator, RDM-001 and RDM-004 all passed; RDM-004 passed 36/36 rows, 6/6 metamorphic checks and 4/4 targeted mutations.
- This is a bounded synthetic check. The ten-category register does not decide real applicability, legal sufficiency or control-owner approval. All prior non-authorization and unresolved-policy boundaries remain unchanged.
