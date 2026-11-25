# Lottorito — Agent Operating Guide

## Mission
Continue Lottorito from the repository's verified state. Do not restart planning, recreate existing files, or claim unfinished work is complete.

## Before every task
1. Read this guide, then follow docs/en/engineering/agent-operating-manual.md (LOT-AGENT-001) or its Persian counterpart for token-efficient task routing.
2. Read the relevant language versions of docs/en/engineering/project-status.md (LOT-OPS-001) and docs/en/engineering/decision-register.md (LOT-ADR-REG-001).
3. Inspect current branches, files, issues, pull requests, and implementation before editing.
4. Search for existing modules, tests, and documents before creating replacements.
5. State assumptions explicitly; unresolved business rules must remain open questions.
6. Read only the domain documents required by the task; do not load the entire documentation set by default.

## Mandatory bilingual documentation
- docs/fa and docs/en are equally authoritative.
- Every document has a counterpart at the same relative path and a stable document ID.
- Update both language versions in the same commit or pull request.
- Preserve semantic parity for amounts, formulas, constraints, statuses, examples, and acceptance criteria.
- File existence alone does not prove synchronization.
- A structural validator is available at scripts/check_docs.py and is run by .github/workflows/docs-governance.yml. It checks paired Markdown paths, stable/unique IDs, level-one titles, version/status metadata and local links; it does not prove semantic translation parity.
- Reviewers must continue manually comparing both versions for meaning, formulas, amounts, constraints and policy status.

## Engineering rules
- Prefer small, reviewable, independently testable changes.
- Use feature branches and pull requests; do not push unfinished work directly to main once CI and branch protections are available.
- Do not merge, deploy, rotate secrets, change repository visibility, or perform destructive data operations without explicit owner approval.
- Never commit credentials, tokens, personal data, real player data, or production exports.
- Use parameterized SQL, strict input validation, authorization at every boundary, tenant scoping, idempotency for event ingestion, and audit logs for privileged actions.
- Financial correctness is a release blocker. Use an immutable double-entry ledger; never use direct balance mutation as the source of truth.
- Test happy paths, boundaries, duplicate/replayed events, concurrency, tenant isolation, reversals, and failure recovery.
- Report exact commands, results, skipped checks, and limitations. Never fabricate test or CI evidence.

## Verified baseline at 2026-11-24
- Repository: tecpey/lottorito-platform; default branch: main; visibility: public by owner decision.
- The repository contains paired Persian/English product, architecture, commission, finance, partner, security, glossary, roadmap and status documents.
- Agent operating manual (LOT-AGENT-001), decision register (LOT-ADR-REG-001), Lottery discovery PRD (LOT-LOTTERY-001), Lottery provider contract (LOT-LOTINT-001), finance posting (LOT-FIN-POST-001), threat model (LOT-SEC-TM-001), API resource specification (LOT-API-001), technology/deployment ADRs (LOT-TECH-ADR-001), and architecture quality attributes (LOT-QA-001), architecture prototype evidence plan (LOT-PROT-001), global localization standard (LOT-I18N-001), live chat architecture (LOT-COMMS-001), growth/content automation (LOT-GROWTH-001), and smart notification architecture (LOT-NOTIF-001), embeddable chat module architecture (LOT-CHAT-WIDGET-001), future regulated gaming domains and provider strategy (LOT-GAMING-STRATEGY-001), and cross-product provider evaluation/RFI standard (LOT-PROVIDER-EVAL-001), wallet domain and balance contract (LOT-WALLET-001), payment orchestration and provider adapter contract (LOT-PAYMENT-001), payout and withdrawal contract (LOT-PAYOUT-001), first-party B2C application PRD (LOT-B2C-PRD-001), API platform and developer experience (LOT-API-PLATFORM-001), Affiliate & Agent API capability contract (LOT-AFFILIATE-API-001) are maintained in documentation work branches pending review. The 12-language target is owner-directed; locale shortlist, quality gates, provider choices and implementations remain subject to review and approval. LOT-PROVIDER-EVAL-001 is a proposed evaluation process, not provider selection or approval; apply it to exact product/entity/jurisdiction decision units and retain all hard gates.
- LOT-CUSTOMER-PILOT-001 records the owner-directed initial RaidenBet customer scope: Advanced Affiliate & Agent plus Live Chat Widget only; the customer reviews and explicitly approves the versioned integration contract before its existing script is connected. It does not establish a signed contract, API compatibility, implementation or production approval.
- The README refinement remains in open Draft PR #19; it has not been merged.
- No production application, production database schema, partner API integration, sandbox, or production deployment has been verified. A disposable P-01 HTTP/PostgreSQL RLS slice is present on PR #36; its 20 defined CI tests passed in run 45412556456 on code head f53caa4e801c9eeed94dfe706e03c6dfcf02a660 using a committed npm lockfile and SHA-pinned GitHub Actions, including asynchronous job isolation, atomic outbox writes, concurrent dispatcher claims, Ed25519 envelopes, worker-side membership re-authorization and a comparative per-tenant LOGIN-role/session_user RLS model tested across records, membership and jobs, including SECURITY DEFINER owner/search_path and temporary-schema shadowing checks, plus deterministic two-connection proof that membership revocation waits behind an in-flight FOR SHARE transaction; the shared-role GUC bypass remains an explicit trust-boundary finding and the per-tenant credential broker/pool scaling remain untested; full P-01 remains partial/inconclusive. The report documents the shared-role custom-GUC trust boundary; consult the bilingual LOT-PROT-P01-001 report before making any security claim. Follow-on PR #39 (branch spike/p01-support-breakglass-v2) is stacked on the latest PR #36 head and adds a synthetic read-only support-grant/audit experiment; its latest 26-test CI run 45418177150 passed on head d2e9fc81a17036e5d6e63c07ee1e64fa055a24eb. It verifies active/expired/revoked/mismatched grants, metadata-only support role, no tenant payload access, append-only audit permissions and FOR SHARE grant-revocation serialization. Known gaps: shared support_authorizer sees grant metadata across synthetic tenants; support payload read inherits app_runtime custom-GUC trust; production identity/MFA, metadata minimization, endpoint race stress, failure injection and production break-glass operations are not implemented. PR #37 was closed as superseded; review PR #39. Follow-on PR #42 (branch spike/p01-data-plane-isolation) is stacked on PR #39 and adds synthetic tenant-derived cache keys, tenant-prefixed object keys, server-injected search filters and RLS-protected reporting. Its 30-test CI run 45422429667 passed on head 82fda92768e2f57b987e5005d63fd56b3de10c91; Documentation Governance run 45422429766 also passed. Cache/object/search use in-memory adapters only; Redis/S3/OpenSearch/warehouse behavior, invalidation/TTL, CDN/export, provider enforcement, load and recovery remain unverified. Full P-01 remains partial/inconclusive. Follow-on PR #45 (branch spike/p01-tenant-pool-broker-v2) is rebuilt on the latest PR #42 head and adds a synthetic tenant credential/pool registry: server-side credential resolution, DB identity verification before pool publication, bounded pools, pending-lease reservations, idle-only eviction, TTL, revocation drain and shutdown. Its rebuilt PR #45 P-01 run 45424342187 passed 40 tests (0 failed, 0 skipped) on code head 153fc8974c9c620acd8d509afdea0341669e5c; Documentation Governance run 45424793114 passed. Stale PR #43 was closed unmerged. No production secret manager, rotation, fleet-wide quota, PgBouncer, TLS policy, failover or scale proof is included. Follow-on PR #46 (branch spike/p02-ledger-posting) is stacked on PR #45 and adds the first synthetic double-entry posting slice: database-session tenant identity, SECURITY DEFINER boundary, NOLOGIN non-BYPASSRLS executor, FORCE RLS, immutable request/journal/line/outbox records, NUMERIC(38,0) integer minor units, per-currency balancing, tenant-scoped idempotency, concurrent duplicate convergence and one-statement transactional outbox. Its P-02 CI run 45428017700 passed 20 tests (0 failed, 0 skipped) on head 009ccb5e7066ab4e22fd070d679da4cb8e8f939f; Documentation Governance 45428017847 passed. It does not define commissions/NGR, wallet balances, FX, reversal policy, payouts, external reconciliation or production accounting. No production readiness is claimed. A structural documentation CI workflow exists and has passed; it checks paired paths, stable IDs and local links, not semantic translation parity.

## Definition of done
A task is done only when implementation exists, relevant tests pass, documentation is synchronized in both languages, security and tenant implications are reviewed, and commit/PR/CI evidence is linked.

## P-03D continuation — 2026-11-25
- Read both `docs/en/engineering/prototypes/p03-provider-ledger-integration.md` and `docs/fa/engineering/prototypes/p03-provider-ledger-integration.md`, plus the P-02, P-03C and LOT-FIN-POST-001 contracts before changing this integration.
- Current working branch: `spike/p03d-provider-ledger-integration`, based on P-03C PR #60 head `32b34f4c7c67b12874cdf6a14a2788d9a2f4c6dc`. Keep it stacked on P-03C; do not retarget to main.
- PR #41 is an older provider fixture based on an older P-02 branch and uses shared custom-GUC tenant/product scope. Reuse its signature/duplicate/conflict ideas only after review; do not cherry-pick its database model into the session_user-derived tenant/product identity design.
- P-03D's atomic processing transaction must include P-02 `post_journal`, inbox processed state and the P-03C after-insert delivery-state trigger. The simulated HTTP 202 is allowed only after durable inbox commit.
- Tenant and product must be derived from trusted installation configuration and the database LOGIN role mapping. Never trust payload tenant/product/account IDs. Product identity must remain present in ledger and delivery records; current tenant-wide unique constraints are conservative and must not be silently relaxed.
- Run P-02, P-03C and P-03D integration workflows and bilingual Documentation Governance on the exact final branch head. Report each run, exact test count, failures/skips and synthetic limitations.
- Do not add real provider credentials, live HTTP/network calls, commission/NGR formulas, payout rules or legal/accounting policy. No merge, main update, destructive migration or deployment without explicit owner approval.


## P-04 reconciled continuation — 2026-11-25
- P-04 PR #51 is a sibling of P-03C PR #60 and P-03D PR #61; its base is P-03 PR #50, not P-03D. Do not assume the P-04–P-08 chain contains the inbound/outbound ledger bridge.
- Work on branch `spike/p04-schema-evolution-p03d`, created from P-03D PR #61 docs-synchronized head `11f2069b537d4cf74175fd7b628a331650c45f52`. The P-04 prototype is intentionally isolated from P-02/P-03 database schemas.
- Original P-04 PR #51 is historical review context only. Do not retarget or merge it. Create a new Draft PR stacked on P-03D after bilingual docs and code review.
- Re-run P-02, combined P-03C/P-03D, P-04 and Documentation Governance on the exact new PR head. P-03D implementation evidence is on code head `40d002a2af5875a6ead178604b90dc92aa678dc5` (P-02 25, P-03C 15, P-03D 19, docs governance passed); this does not replace regression on the new branch.
- After P-04 passes, replay P-05A, P-05B, P-05C, P-06, P-07A, P-07B, P-07C and P-08 in dependency order onto the reconciled chain, preserving each experiment's boundaries. Reconcile shared documentation semantically; never copy an older branch's whole README/status/AGENTS over newer P-03D evidence.
- No merge, main update, destructive migration, production credential, real provider integration or deployment without explicit owner approval.


## P-04 reconciled verification and next handoff — 2026-11-25
- Reconciled PR #62 code head `dca0762678ed45da122ba109276c54ce61ac0846` passed P-02 (25), P-03C (15), P-03D (19), P-04 (7) and Documentation Governance. Runs: 45608274029, 45608274098, 45608274118, 45608274060. All completed successfully with 0 failures and 0 skipped tests.
- Keep PR #62 Draft/open stacked on P-03D PR #61. Original P-04 PR #51 remains open/Draft as historical review context; do not retarget or merge it.
- Next sequence is P-05A -> P-05B -> P-05C -> P-06 -> P-07A -> P-07B -> P-07C -> P-08. Rebase/replay each in dependency order onto the reconciled P-04 head, reconcile bilingual shared docs semantically, and run the complete P-02/P-03C/P-03D/P-04 plus downstream regression on every new final head.
- Preserve synthetic-only claims. No production migration, provider credential, merge, main update, destructive operation or deployment without explicit owner approval.


## P-05A reconciled continuation — 2026-11-25
- Original P-05A PR #52 is based on original P-04 PR #51 and therefore omits the newer P-03C/P-03D bridge. Work on replacement branch `spike/p05-backup-restore-recovery-p03d`, based on reconciled P-04 PR #62 head `1013f3b93b55b2cb0859b371db58e1e17ec4ad5e`.
- P-05A is synthetic only: Docker/PostgreSQL fixture, base backup/manifest verification, WAL/PITR, tenant RLS and ledger/source reconciliation. Preserve all explicit gaps: missing-WAL and interrupted-restore negative drills, off-site immutable retention, key custody, object-byte recovery, app/worker recovery, provider reconciliation, regional failover and approved RPO/RTO.
- Create a new Draft PR stacked on PR #62; leave original PR #52 open/Draft and untouched.
- Re-run P-02, P-03C/P-03D, P-04, P-05A and bilingual Documentation Governance on the exact replacement head. Do not reuse historical PR #52 CI as proof of the replacement.
- No production data, credentials, real provider, merge, main update, destructive migration or deployment without explicit owner approval.


## P-05A reconciled verification and next handoff — 2026-11-25
- Replacement PR #63 code head 76650b0c799e2f2a5b2f3ae4831bb55d3a3811a6 passed P-02 (25), P-03C (15), P-03D (19), P-04 (7), P-05A recovery (P05A_RESULT=PASS) and Documentation Governance. Runs: 45609220358, 45609220468, 45609220377, 45609220359 and 45609220328. All succeeded on the same head.
- Keep PR #63 Draft/open stacked on reconciled P-04 PR #62. Original PR #52 remains open/Draft as historical context.
- Next: P-05B object/key/idempotent-event recovery. Rebase/replay onto PR #63, keep original PRs as review references, and rerun the complete P-02/P-03C/P-03D/P-04/P-05A/P-05B chain on the exact final head.
- No production recovery claim, real credentials, merge, main update, destructive migration or deployment without explicit owner approval.


## P-05B reconciled continuation — 2026-11-25
- Original P-05B PR #53 is based on original P-05A PR #52 and omits reconciled P-03C/P-03D ancestry. Work on replacement branch `spike/p05b-object-key-event-recovery-p03d`, based on P-05A PR #63 docs-synchronized head `481a0ab2ac15ee982745e0a3b48d4d93cc829431`.
- This branch includes P-05A recovery-complete gating and missing-WAL/incomplete-restore negative drills, plus P-05B AES-GCM object/key recovery and ordered event replay. Preserve synthetic-only boundaries.
- P-05B hardening added manifest tenant/object/key/format/version checks, tenant-bound wrapped-DEK AAD, strict base64/nonce/size validation, plaintext size/hash comparison, unique aggregate sequence and pg_temp-last SECURITY DEFINER search_path.
- Create a new Draft PR stacked on reconciled P-05A PR #63; leave original PR #53 open/Draft and untouched.
- Run P-02, P-03C/P-03D, P-04, combined P-05A/P-05B plus negative drills, and bilingual Documentation Governance on the exact final replacement head. Historical PR #53 CI does not validate this branch.
- No real KMS/HSM, object store, broker, provider, key custody, production data, merge, main update, destructive migration or deployment without explicit owner approval.


## P-05B reconciled verification and next handoff — 2026-11-25
- PR #64 code head bbad5969fc3c952ebafdaed3c8d2306dbd018ad4 passed P-02 (25), P-03C (15), P-03D (19), P-04 (7), combined P-05A/P-05B positive and negative recovery, and Documentation Governance. Runs: 45611209596, 45611209613, 45611209559, 45611209642 and 45611209546.
- P-05B hardening includes strict manifest context, tenant-bound wrapped-DEK AAD, nonce/base64/size checks, plaintext size/hash verification, unique aggregate sequence and pg_temp-last SECURITY DEFINER search_path. P-05A negative restore/WAL drills passed.
- Next: P-05C failover/fencing/failback. Keep PR #64 Draft/open and original PR #53 open/Draft. RPO/RTO remain TBD; no production recovery claim, merge, main update, destructive migration or deployment.
