# Lottorito Execution Ledger and Continuation Point

**Document ID:** LOT-OPS-002 | **Version:** 0.1.0 | **Recorded:** 2026-11-23

## Verified baseline
- Repository `tecpey/lottorito-platform` is Public and its default branch is `main`.
- Root README and `AGENTS.md` have been read from GitHub.
- Issues LOT-001 through LOT-006 already exist.
- Issues 8 through 15 also exist for the audit, final roundtable, Attribution, QA, security/data governance, UX, SRE, and legal requirements.
- PR #7 is Draft/Open on `docs/domain-data-model-v1`; it is not merged.
- Domain model, initial audit, and roundtable documents are on PR #7's branch; do not assume they exist on `main`.
- Branch `docs/codex-execution-baseline` contains the bilingual Codex/VS Code Runbook and an updated agent guide; it is not merged.

## Work completed on the current branch
- `docs/fa/engineering/codex-vscode-execution-runbook.md`
- `docs/en/engineering/codex-vscode-execution-runbook.md`
- Updated `AGENTS.md` to require live GitHub state checks, anti-duplication, and coordination between Cloud Codex and VS Code.

## Remaining work and evidence required
| Area | Status | Completion evidence |
|---|---|---|
| Product foundation docs | Exist; full re-review required | File-by-file review matrix and parity |
| Domain model and ERD | In PR #7; not merged | Review, open decisions, and PR acceptance |
| Technology/database ADRs | Issue #3; open | Options analysis and recorded owner/architect decision |
| Partner API/events | Issue #4; incomplete/unverified | Real partner contract, OpenAPI, and valid examples |
| Ledger/financial model | Issue #5; further design required | Invariants, accounting model, tests, and finance review |
| Pilot business decisions | Issue #6; open | Product-owner-approved written rules |
| Bilingual CI | Issue #1; implementation unverified | Workflow run with positive and negative tests |
| Attribution | Issue #10; open | Versioned policy and owner approval |
| QA/testing | Issue #11; open | Test strategy and actual CI |
| Security/data governance | Issue #12; open | Threat model, controls, and tests |
| UX/accessibility | Issue #13; open | Journeys, acceptance criteria, and RTL/LTR |
| SRE/operations | Issue #14; open | SLOs, tested backup/restore, and runbooks |
| Legal/jurisdictions | Issue #15; open | Authoritative sources and qualified counsel review |
| Executable application | Not yet established | Required ADRs and gates, then scaffold and tests |

## Important limitation
Until branches and commits are checked live, this document is only a snapshot recorded on the date above. State may change. It does not verify application code, migrations, passing CI, partner API connectivity, a sandbox, or deployment.

## Next starting point
1. Fully review PR #7: diff, every changed file, open review comments, CI, and main/head divergence.
2. Inventory all files on `main` and the PR branch, recording each file's location and status.
3. Review every Persian/English pair for semantic parity; identify incomplete and duplicate documents.
4. Complete LOT-001 through LOT-006 and resolve open decisions.
5. Record technology/database ADRs and freeze MVP scope.
6. Build bilingual-parity CI and the test foundation.
7. Create the application scaffold only after required decisions and acceptance criteria are recorded.

## Continuation rule
Every agent must update this ledger when status changes, including issue, PR, SHA, tests, and remaining work. If work was not done or cannot be verified, record that explicitly.
