# Codex, VS Code & GitHub Execution Runbook

**Document ID:** LOT-ENG-002  
**Version:** 0.1.0  
**Status:** Proposed operating procedure; tool choices and execution policies require owner approval  
**Counterpart:** `docs/fa/engineering/codex-vscode-execution-runbook.md`

## 1. Purpose

This document defines one operating method for continuing Lottorito through GitHub, cloud Codex, and VS Code. The goal is to make every environment and agent continue from the same verifiable state, avoid duplicate work, and prevent concurrent changes from overwriting one another.

## 2. Source of truth

Information precedence:

1. Current GitHub state: commits, branches, files, issues, pull requests, and CI results.
2. Approved documentation on a branch whose PR has been reviewed and merged.
3. Recorded ADRs and product-owner-approved business decisions.
4. Open issues as planned work, not implemented capabilities.
5. Conversations, summaries, and agent outputs are clues only; they do not replace repository evidence.

No agent may infer that a file, test, API, or feature exists solely from conversational memory or an earlier claim.

## 3. Mandatory agent entry procedure

At the start of every work session:

1. Verify the current branch and commit from GitHub.
2. Read `AGENTS.md` and this Runbook.
3. Read `docs/en/engineering/project-status.md` and its Persian counterpart.
4. Review relevant open issues and pull requests.
5. Read the relevant domain documents in both languages.
6. Search for existing files, classes, endpoints, migrations, and tests before creating anything.
7. Write a short pre-change plan covering target files, risks, and tests.

If the local state differs from GitHub, report and reconcile the difference first. Do not code against an unknown baseline.

## 4. Environment responsibilities

### GitHub

- System of record for history, code, documentation, issues, and pull requests.
- Every reviewable change belongs on an independent branch.
- `main` is the stable baseline; do not develop directly on it.
- A PR must explain purpose, scope, decisions, changed files, tests, risks, and unfinished work.

### Cloud Codex

- Use for independent, delegable tasks. Every task must have an issue, scope, acceptance criteria, and branch.
- Codex must refresh GitHub state and read the agent guide before editing.
- Its output is a reviewable PR, not authorization to merge or deploy.
- Two agents must not write to the same files or shared branch concurrently without coordination.

### VS Code and local Codex

- Use for interactive development, running tests, debugging, and local review.
- Before starting, sync the working branch with the latest GitHub state.
- Run relevant tests after each coherent unit of work and record actual results.
- Before pushing, inspect the diff and check for unwanted files, secrets, and real user data.
- Local uncommitted files are not a reliable continuation point; changes must be committed to a named branch and PR.

## 5. API access and secrets

- Never commit API keys, tokens, passwords, webhook secrets, private keys, or credentials to Git, issues, PRs, logs, or example documentation.
- Use official connections and only the minimum permissions required.
- For local development, use an environment file outside Git such as `.env.local`; the committed example may list variable names and non-secret descriptions only.
- For cloud execution, store secrets in the service's secure Secrets facility; never place them in prompts or project files.
- GitHub write access does not imply access to production servers, databases, partner accounts, or deployment authorization.
- Any new access must be scoped to a service, resource, and action, and actual access must be verified before use.

## 6. Standard task lifecycle

1. Select an existing issue; if none exists, search for duplicates before creating one.
2. Record acceptance criteria and dependencies.
3. Create a branch from the latest `main` or an explicitly approved dependency branch.
4. Inspect related documentation and code; state the change plan before implementation.
5. Implement a small, bounded change.
6. Run unit, integration, contract, security, or E2E tests appropriate to the risk.
7. Update Persian and English documentation in the same PR.
8. Review the diff, secret scanning, lint, typecheck, and relevant tests.
9. Create or update the PR and record the exact SHA and evidence.
10. Address reviews and CI; merge only after required approvals by an authorized person.

## 7. Anti-duplication and concurrency rules

- Search the full repository and open work before creating a file or issue.
- Give each task a stable identifier and reflect its state in the issue and project-status document.
- Use only these states: Proposed, In Progress, Blocked, In Review, Verified, Done, or Deferred.
- “File created” is not equivalent to “content reviewed,” “tested,” or “approved.”
- Do not copy or rewrite unfinished work from another PR without inspecting and coordinating it.
- If an existing PR already contains the required document, review and continue that PR; do not create a parallel copy.
- Keep each task in one small, traceable PR; avoid ambiguous commits and unrelated changes.

## 8. Gates before product implementation

Before selecting the stack and creating the executable application scaffold, clarify:

- MVP scope, user roles, and administrative roles
- Approved pilot business rules and unresolved questions
- ADRs for runtime, API framework, database, migrations, queue, authentication, and testing
- Canonical event contract and the real partner contract; unknowns must remain explicit adapter interfaces and clearly labeled mocks
- Financial model, currencies, decimal precision, posting lifecycle, reversals, and reconciliation
- Security, tenant isolation, and privacy requirements
- Test architecture, CI, and acceptance criteria

Until the actual partner contract is received, do not guess partner-specific endpoints, payloads, signature schemes, or financial behavior.

## 9. Required agent handoff report

Every handoff must include:

- Issue and objective
- Branch and PR
- Exact commit SHA
- Files created or changed
- Decisions made and ADR references
- Tests run, with commands and actual results
- Tests not run and why
- Risks and limitations
- Open items and dependencies
- Exact starting point for the next agent

## 10. Permission boundaries

Agents may modify documentation and code on a working branch and create PRs within their actual granted permissions. Final merge, production deployment, visibility/permission changes, data changes or deletion, use of production credentials, and real financial actions require separate authorization.

## 11. Current status

This Runbook was prepared on branch `docs/codex-execution-baseline` and has not been merged into `main`. Its existence does not mean Cloud Codex, VS Code, API access, Secrets, CI, or a runtime environment has been successfully connected or configured. Those connections must be verified separately with real evidence.


## 12. Distinguish Codex, Cloud, and the OpenAI API

Do not treat these as the same capability:

- **Codex sign-in:** Official documentation describes signing in with a ChatGPT account or using an API key in supported clients. Verify the active method in the installed client.
- **Codex Cloud:** Runs tasks in managed cloud environments. The repository, tools, dependencies, GitHub access, and environment settings must first be prepared and published. Each task has its own workspace; commit important changes. Starting a new task does not recover another task's uncommitted changes.
- **OpenAI API for the product:** The Lottorito application's API key is used by the application to call OpenAI models/services. It is not the same as GitHub permission or Codex sign-in and must never be committed.
- **OpenAI Developer Docs MCP:** `https://developers.openai.com/mcp` provides read-only search and access to official documentation; it does not execute product API requests.

### Recommended practical path
1. Install the official Codex extension in VS Code and sign in using an allowed account/key method.
2. Open `tecpey/lottorito-platform` in VS Code and verify that the branch and SHA match GitHub.
3. If using Codex Cloud, create an environment for this repository, define tools/dependencies, and test GitHub access separately.
4. Run a documentation-only proof task from Issue #16; its output must be a reviewable branch and PR.
5. Only after this path is proven, select the first product-coding task from existing issues and after the required ADRs are complete.

### Official references reviewed
- Codex access and sign-in methods: https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan
- Codex Cloud environments and tasks: https://help.openai.com/en/articles/20001545-using-codex-cloud
- OpenAI Developer Docs MCP: https://developers.openai.com/learn/docs-mcp

**Limitation:** This section describes the official product workflow; the user's actual account connection, Cloud availability, repository permission, and successful task execution must be tested separately.
