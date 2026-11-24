# Lottorito Agent Operating Manual

**Document ID:** LOT-AGENT-001 | **Version:** 1.0.0 | **Status:** Maintained operating standard; product approvals remain separate

## Purpose
Low-context entry point for AI agents, human contributors, reviewers and automation. It reduces repeated discovery without weakening evidence, safety or bilingual parity. It does not replace domain specifications.

## Read in this order
1. Repository-root AGENTS.md — mandatory safety and workflow rules.
2. This manual — task routing and minimum context.
3. docs/en/engineering/project-status.md — verified baseline and blockers.
4. docs/en/engineering/decision-register.md — decision states and owner choices.
5. The task's authoritative domain document.
6. The exact Persian counterpart when editing or reviewing bilingual material.

Do not load every document by default. Retrieve only the relevant domain source and its dependencies.

## Task routing
| Task | Canonical source |
|---|---|
| Product scope, personas, MVP boundaries | LOT-PROD-001 |
| Lottery requirements | LOT-LOTTERY-001 |
| Architecture and domain boundaries | LOT-ARCH-001; LOT-TECH-ADR-001 |
| Affiliate commission policy | LOT-COM-001 |
| Wallet, accounting and financial invariants | LOT-FIN-001 |
| Affiliate partner events | LOT-INT-001 |
| Lottery provider lifecycle | LOT-LOTINT-001 |
| Security and privacy | LOT-SEC-001 |
| Shared terminology | LOT-GOV-001 |
| Delivery sequence | LOT-ROAD-001 |
| Verified project state | LOT-OPS-001 |
| Decision state | LOT-ADR-REG-001 |

## Evidence vocabulary
- Proposed: documented candidate; not approved for implementation.
- Accepted: explicitly approved by the owner or authorized governance.
- Implemented: code/configuration exists on a named branch or commit.
- Verified: defined tests/checks passed and evidence is recorded.
- Released: explicitly approved and deployed to a named environment.
- Blocked: a named prerequisite prevents progress.
- Superseded: replaced by a newer decision; preserve history and link the replacement.

Never upgrade status based on document presence, successful file creation, a draft PR, or unverified recollection.

## Mandatory task loop
1. Orient: read minimum sources; inspect branch, PR, files and recent changes.
2. Search before creating: find existing documents, issues, code, tests and decisions.
3. Classify: separate owner instruction, verified evidence, proposal, assumption and open question.
4. Plan: list files, dependencies, acceptance criteria and risks.
5. Change: use a dedicated branch and cohesive reviewable commits.
6. Pair languages: update English and Persian counterparts in the same PR; preserve parity for numbers, formulas, statuses, constraints, examples and acceptance criteria.
7. Validate: read back every changed file; run relevant checks where available; report skipped checks honestly.
8. Handoff: report branch, commit/PR, files, decisions, tests, limitations, open questions and next action.

## Token and time efficiency
- Do not reread full chat history when a maintained source answers the question.
- Start with project status and decision register; fetch only relevant documents/sections.
- Reuse stable document IDs, canonical terminology and existing templates.
- Do not duplicate full specifications in README, indexes, issues or prompts; link to the canonical source.
- Keep handoffs concise: goal, baseline, files, evidence, unresolved items, next step.
- If context is lost, recover from GitHub in this order: AGENTS.md → project status → decision register → relevant specification → PR/commit evidence.
- Ask the owner only questions that block a consequential decision. Do not repeat an already recorded approved answer.

## Authority boundaries
Agents may inspect, analyze, draft, create branches and open draft PRs when authorized. Without explicit owner approval, they must not merge, deploy, alter repository settings, rotate/expose secrets, incur external costs, contact partners or perform destructive operations.

No agent may turn a proposed commercial value, jurisdiction, provider behavior, payout rule or product scope into an implementation invariant without documented approval.

## Financial and security stop conditions
Stop and escalate potential duplicate economic effects, cross-tenant access, ledger mutation, untraceable adjustments, unauthorized payouts, secret/PII disclosure, or operation in a jurisdiction without required review. Financial history is append-only; corrections use linked reversals/adjustments.

## Technology decisions
Use LOT-TECH-ADR-001 as the only current technology/deployment decision framework. Its candidate directions remain Proposed; do not treat PostgreSQL, Modular Monolith, managed containers, OpenTelemetry or any vendor as approved until the required prototypes and owner reviews are recorded.

## Document maintenance
Every authoritative document has a stable ID, version, status, review responsibility and bilingual counterpart. Update indexes and decision register when scope or decision state changes. Use synthetic examples only. Never commit credentials, real customer/player data or production exports.

## Handoff template
- Goal/scope:
- Baseline inspected:
- Files changed (EN/FA):
- Decision state changed:
- Validation and results:
- Not verified/blocked:
- PR/commit:
- Next action:

## Non-goals
This manual does not authorize lottery/gambling launch, custody of customer funds, payouts, claims of regulatory compliance, provider selection or production readiness.