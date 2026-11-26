# P-10F — Operational Readiness, Verification and Release Acceptance Framework

**Document ID:** LOT-PROT-P10F-001 | **Version:** 0.1.0 | **Status:** Source-neutral governance and verification proposal; not release authorization | **Reviewed:** 2026-11-26

## 1. Purpose and assurance boundary

P-10F defines how Lottorito moves from proposed architecture and design to implementation evidence, controlled environment verification and (only after explicit approval) production release. It provides a common evidence model, control catalogue, verification gates, release decision record, exception process, ownership model and post-release assurance loop.

The purpose is to prevent a recurring assurance error: treating a document, a passing unit test, a green CI workflow, a merged pull request, a running service or a vendor statement as proof of production readiness. Each proves a different, bounded claim.

This is a source-neutral framework. It is not an implementation audit, legal opinion, security certification, accounting approval, deployment procedure or permission to access production. No live service, production configuration, credentials, customer/player/payment data, source database, infrastructure, deployment pipeline or operational evidence was inspected for this document. No control is declared implemented or effective merely because it appears here.

P-10F governs assurance for P-10A through P-10E and subsequent implementation work. It does not approve or merge those PRs, authorize migration, custody or movement of funds, activate lottery/gaming functionality, or authorize production access.

## 2. Foundational assurance principles

1. **Claim-scoped evidence:** every assurance claim states exactly what component, version, environment, tenant scope, data class, time window and threat/failure condition it covers.
2. **Evidence over assertion:** an owner statement is context, not technical proof. A test result is proof only for the test's stated scope and conditions.
3. **Environment separation:** local, CI, ephemeral test, staging, pre-production and production evidence are distinct. Never silently promote a result from one environment to another.
4. **Identity and provenance:** evidence identifies the subject, source commit, build, artifact digest, workflow/run, environment and collector where applicable.
5. **Freshness and change sensitivity:** evidence expires or becomes stale after relevant code, dependency, configuration, schema, provider, identity, threat or infrastructure changes.
6. **Negative evidence matters:** denied access, cross-tenant isolation, replay rejection, rollback, key-loss, degraded mode and failure-path tests are first-class.
7. **Independent challenge:** high-impact financial, tenant-isolation, security and recovery controls require review independent of the implementer.
8. **No silent exceptions:** a failed, missing, flaky, skipped or inconclusive control is not PASS. Exceptions are explicit, scoped, time-bound and owned.
9. **Reproducibility:** another authorized reviewer should be able to locate, interpret and, where safe, reproduce the evidence.
10. **No assurance inflation:** do not describe CI as production verification, a design as implementation, a scan as penetration testing, or a checklist as certification.

## 3. Evidence taxonomy and assurance levels

### 3.1 Evidence classes

| Class | What it can establish | What it cannot establish by itself |
|---|---|---|
| Design evidence (D) | Intended architecture, threat model, requirements, ADR, control design | Code exists or control operates |
| Implementation evidence (I) | Code, schema, config, IaC, policy and review tied to an exact version | Runtime behavior or production deployment |
| Automated verification (T) | Results of a named automated test/tool in a stated environment | Untested paths, production equivalence or absence of all defects |
| Environment verification (E) | Observed behavior in a named controlled environment | Other environments or future versions |
| Production operational evidence (P) | Time-bounded production telemetry, deployment records, access reviews, restore/incident evidence | Universal correctness or future behavior |
| Independent assurance (A) | Independent review, audit or scoped assessment with methodology and findings | Certification beyond its explicit scope |

Evidence may belong to multiple classes, but each claim must identify the exact assertion and source. A screenshot without provenance, a pasted log without run identity, a mutable dashboard view or a verbal statement is weak evidence and must not be treated as a substitute for source records.

### 3.2 Assurance maturity states

Use these labels for each control, not as a single platform-wide badge:

- **DRAFTED:** requirement or design exists; not independently reviewed.
- **DESIGN-REVIEWED:** design has named reviewers and resolved/recorded findings.
- **IMPLEMENTED:** code/configuration exists at a pinned version; runtime effectiveness not yet demonstrated.
- **TEST-VERIFIED:** required tests passed in a named non-production environment with retained evidence.
- **STAGING-VERIFIED:** control passed in representative staging/pre-production conditions; production equivalence limitations recorded.
- **PRODUCTION-OBSERVED:** control behavior has been observed in production during a defined period, with telemetry and ownership.
- **INDEPENDENTLY-ASSESSED:** a qualified independent reviewer assessed the exact stated scope.
- **EXCEPTION:** an approved, expiring deviation exists; this is not a passing state.
- **BLOCKED / NOT-ASSESSED:** prerequisites missing or no valid evidence.

Do not automatically promote a control from one state to another. A new commit, dependency, configuration, tenant boundary, provider, data flow or material incident may invalidate prior evidence.

## 4. Evidence record schema

Every material evidence item should be stored in a controlled, access-restricted evidence register. Minimum fields:

| Field | Requirement |
|---|---|
| Evidence ID | Unique immutable identifier |
| Control / requirement IDs | One or more stable control references |
| Claim | Precise assertion being supported |
| Class and maturity | D/I/T/E/P/A and control state |
| Subject | Service, component, dataset, workflow or process |
| Version identity | Commit SHA, artifact digest, schema/config/IaC version |
| Environment | Local, CI, test, staging, pre-production or production |
| Scope | Tenant/product/legal entity/region/data class as relevant |
| Method | Test, inspection, query, review, observation or exercise |
| Result | PASS, FAIL, PARTIAL, NOT_RUN, INCONCLUSIVE, EXPIRED |
| Timestamp | UTC time, collection interval and clock provenance |
| Collector / owner | Actor, tool and accountable control owner |
| Source reference | Immutable run URL, artifact, report, log or ticket |
| Integrity | Digest/signature or trusted source identity where feasible |
| Limitations | Exclusions, assumptions, sampling, known blind spots |
| Retention / access | Evidence retention and authorized viewers |
| Reviewer / decision | Independent reviewer, date and disposition |
| Expiry / invalidation | Expiry date or change triggers |

Do not put secrets, raw credentials, payment instruments, unnecessary personal data or unrestricted production records into the evidence register. Prefer redacted, minimized, reproducible evidence with access controls. Retention and cross-border handling require privacy/legal review.

### 4.1 Evidence quality tests

Before accepting evidence, ask:
- Is it authentic and attributable to a trusted source?
- Does it bind to the exact source/build/artifact/configuration under review?
- Is it complete enough to reproduce the claim?
- Is the test oracle meaningful, including negative cases?
- Is the environment representative for this claim?
- Is it recent relative to relevant changes?
- Are limitations and failed/skipped cases disclosed?
- Can an independent reviewer reach the same conclusion?

A green status without a stable run ID, exact commit and meaningful test scope is insufficient for release-critical evidence.

## 5. Control catalogue and crosswalk

Create a version-controlled control register. Each control has: stable ID, risk statement, requirement, scope, owner, reviewer, implementation reference, verification method, expected result, evidence IDs, maturity, exception, expiry and change triggers.

Recommended control families:

| Family | Required coverage | Reference framework |
|---|---|---|
| Product and requirements | Approved scope, user journeys, acceptance criteria, non-goals | Product requirements and traceability |
| Architecture and data | Service boundaries, data authority, schema, event contracts, consistency | P-10C; ADRs |
| Identity and authorization | Authentication, MFA, session, workload identity, least privilege | P-10D; OWASP ASVS 5.0 |
| Tenant isolation | Tenant context, RLS/grants, object/API/cache/queue/search/export boundaries | P-10D; negative isolation tests |
| Financial integrity | Journal invariants, idempotency, reconciliation, reversal, period close | Financial posting policy and P-10E recovery controls |
| Provider integration | Contract, signature, replay, timeout/unknown outcome, rate limit, versioning | Adapter contract and provider evidence |
| Privacy and legal | Data inventory, purpose, minimization, retention, deletion, jurisdiction | Approved legal/privacy assessment |
| Application security | Threat model, secure coding, SAST/DAST/dependency review, ASVS requirements | OWASP ASVS 5.0; NIST SSDF |
| Supply chain | Protected build, dependency provenance, artifact integrity, signing and deployment identity | SLSA; platform-specific controls |
| Reliability and DR | SLO, backup/restore, failover, RTO/RPO, recovery tests | P-10E |
| Operations | Monitoring, alerting, on-call, runbooks, incident and capacity | SRE practices |
| UX and accessibility | Critical journey usability, localization, RTL/LTR, keyboard/screen-reader checks | Product-approved accessibility standard |
| Documentation and support | Bilingual consistency, operator guides, support escalation, known limitations | Documentation governance |

Framework crosswalks are mappings, not blanket compliance claims. Use the exact version and applicable requirements. OWASP ASVS 5.0.0 is a verification requirement catalogue; select and justify a risk-appropriate subset/profile, record N/A decisions, and report failures/exceptions. Do not claim OWASP certification.

## 6. Verification strategy and test layers

### 6.1 Verification pyramid

Use the lowest-cost test that can reliably detect a defect, then add higher-level tests for interactions and operational risks:
1. Static checks, formatting, types, lint, secret scanning and policy-as-code.
2. Unit tests for deterministic domain rules and invariants.
3. Component/contract tests for API, event, provider and schema compatibility.
4. Integration tests with real supported dependencies or faithful isolated substitutes.
5. End-to-end tests for critical user and operator journeys.
6. Security tests: authorization matrix, tenant isolation, abuse cases, ASVS-mapped checks, SAST/DAST and targeted manual review.
7. Resilience tests: timeouts, retries, duplicate/reordered events, worker crashes, partial outages, restore and failover in authorized isolated environments.
8. Performance/capacity tests with documented workload model and safe limits.
9. Staging/pre-production acceptance and controlled release verification.
10. Production observation, canary analysis and post-release checks after separate authorization.

Mocks are useful for deterministic contracts but do not prove real provider compatibility, cryptographic behavior, database semantics or production resilience. Critical integrations need contract evidence from the actual provider sandbox or a separately approved environment.

### 6.2 Required test properties

Every test suite should state:
- scope and requirements covered;
- preconditions, fixtures and synthetic-data status;
- deterministic setup and cleanup;
- expected outcome and assertion/oracle;
- failure-path and negative cases;
- isolation and concurrency assumptions;
- supported dependency/version matrix;
- timeout, retry and flake policy;
- report/run ID and artifacts;
- known exclusions.

Flaky tests are not repeatedly rerun until green and then called PASS. Track flakiness, preserve the original failure, identify root cause and use an explicit quarantine policy with owner and expiry. A quarantined release-critical test is a gate failure unless an approved exception explicitly permits it.

## 7. Release gates

All gates are conjunctive for the release scope: one failed or missing mandatory gate blocks progression. A gate can be waived only through the exception process; legal, financial, security and tenant-safety prohibitions cannot be waived by an informal product decision.

### Gate G0 — Scope and authority
- Product scope, target users, tenant/product/legal-entity scope and non-goals approved.
- Named accountable owners and decision authority exist.
- Data classification, legal/privacy basis and provider responsibilities identified.
- Production access and operational actions have explicit authorization.

### Gate G1 — Design and threat review
- Architecture and ADRs reviewed against current requirements.
- Threat model, trust boundaries, abuse cases and data flows reviewed.
- Financial invariants, tenant isolation, recovery and failure modes specified.
- Unresolved high-severity design risks block progression.

### Gate G2 — Implementation and supply-chain integrity
- Exact commit, code review, branch protection and required checks recorded.
- Dependency, secret, license and vulnerability policy evaluated.
- Build provenance/artifact digest and deployment identity recorded where supported.
- Schema/config/IaC changes are reviewed, reversible where possible and have an approved rollout/rollback plan.

### Gate G3 — Automated and independent verification
- Required test layers pass against the exact candidate.
- Security verification is mapped to scoped ASVS requirements and risk profile.
- Tenant-isolation negative tests cover cross-tenant API, DB, cache, queue, storage, search and export paths where applicable.
- Financial tests cover idempotency, balanced journals, replay, reversal, reconciliation and unknown external outcomes.
- Critical findings are resolved or formally blocked; independent reviewers sign off high-impact controls.

### Gate G4 — Environment readiness
- Environment configuration and secrets are controlled and verified.
- Observability, alert routing, on-call and incident runbooks are tested.
- Backup/restore and recovery prerequisites have current evidence appropriate to the service risk.
- Capacity, provider quotas, rate limits, operational dependencies and rollback/containment are reviewed.
- Staging/pre-production differences from production are documented.

### Gate G5 — Release authorization
- Exact artifact digest and source commit are pinned.
- Change record, scope, release window, blast radius and rollback/stop criteria are approved.
- Named release authority and operations owner approve.
- Finance/security/privacy/legal approval is obtained when their control domains are affected.
- No unresolved blocker or expired exception is present.
- Production deployment occurs only through an explicitly authorized process and environment.

### Gate G6 — Post-release verification
- Verify deployed artifact identity, health and critical user journeys.
- Observe SLI/SLO, error rate, latency, queue lag, ledger invariants, provider outcomes and tenant-isolation signals as relevant.
- Compare canary/control or before/after metrics with predeclared thresholds.
- Stop, rollback or contain on trigger; do not continue rollout solely because process health is green.
- Close release only after owner review, incident check and evidence capture.

No gate is passed by this document itself. The gates are a framework to be instantiated against actual implementation and risk.

## 8. High-risk domain acceptance matrix

| Domain | Minimum proof before controlled release | Mandatory stop conditions |
|---|---|---|
| Tenant boundary | Positive and negative tests across API, DB/RLS, cache, queue, storage, search, export and support paths | Any cross-tenant read/write or unresolved ambiguous ownership |
| Ledger | Balanced postings, unique effect identity, immutable/reversal semantics, replay and period reconciliation | Unbalanced journal, duplicate financial effect, missing lineage or unexplained delta |
| Payments/provider | Signed webhook validation, replay controls, timeout/unknown outcome reconciliation, idempotent retries and sandbox contract proof | Unknown outcome retried as new payment; invalid signature accepted; duplicate movement |
| Identity/access | MFA/step-up where required, revocation, session expiry, least privilege, workload identity and break-glass audit | Privilege escalation, stale access after revocation, unlogged emergency access |
| Affiliate attribution/commission | Versioned policy, deterministic attribution, source-to-posting trace, period lock/reversal and dispute trace | Unexplained commission, mutable historical policy without version, non-idempotent event |
| Queue/event processing | Durable source, bounded retry, idempotent consumer, ordering contract, DLQ visibility and replay evidence | Lost authoritative event, unbounded retry storm, duplicate external side effect |
| Chat/notifications | Tenant isolation, message persistence policy, delivery state, provider failure and retention tests | Cross-tenant message exposure or loss beyond approved objective |
| Analytics/reporting | Source lineage, freshness, tenant filters and reproducible aggregate checks | Financial report divergence or tenant leakage |
| Recovery/DR | Isolated restore, integrity checks, key recovery, writer fencing, measured RTO/RPO and owner approval | No valid restore path, missing key, split-brain risk or unreconciled financial state |
| Localization/accessibility | Critical journeys in supported locales, RTL/LTR layout, number/currency/date formatting, keyboard and assistive checks | Materially misleading financial/legal content or unusable critical flow |

These are baseline proof categories, not exhaustive test cases or evidence that any feature currently exists.

## 9. Security and supply-chain assurance

Adopt a risk-based secure development profile aligned to NIST SSDF and a scoped OWASP ASVS 5.0 verification profile. Map each applicable requirement to an implementation artifact, test or independent review. Record exclusions and compensating controls; do not report only a percentage score that hides critical failures.

For the build and release chain:
- protect source branches, review workflow changes and pin third-party actions/dependencies to reviewed immutable versions where feasible;
- use least-privilege, short-lived CI identities and separate build from deployment authority;
- prevent untrusted pull-request code from receiving deployment secrets;
- bind artifact digest to source commit, build workflow and builder identity;
- verify provenance and artifact identity at deployment;
- preserve SBOM/dependency and vulnerability disposition where appropriate;
- restrict production environment approvals and deployment credentials;
- retain immutable or access-controlled release records.

SLSA levels describe specific build provenance and platform guarantees, not overall application security or operational maturity. Do not claim a level unless every requirement for that level and its applicable track is independently verified. A signed artifact alone does not prove secure source, safe dependencies or safe runtime configuration.

## 10. Change, rollback and progressive delivery

Every change is classified by blast radius: documentation-only, low-risk application, data/schema, identity/security, financial/ledger, tenant-boundary, provider integration, infrastructure, cryptographic/key or recovery control. Higher-risk classes require stronger review, staged rollout, explicit rollback/containment and domain-owner approval.

For database changes, use expand/migrate/contract where suitable; verify backward compatibility with concurrently running versions; define lock, duration, backfill, dual-read/write and rollback hazards. A schema rollback is not always a data rollback. Never assume a reverse migration can safely undo financial or externally visible effects.

Canary/progressive delivery requires:
- stable control population and bounded exposure;
- predeclared success/abort metrics and observation duration;
- one clearly identified candidate artifact;
- tenant-aware blast-radius controls;
- no concurrent rollout that contaminates evaluation;
- automatic stop or human decision on threshold breach;
- rollback/forward-fix decision based on data and side effects, not deployment status alone.

Rollback may be unsafe after irreversible external effects or schema/data transformation. In such cases use forward recovery, compensating action and reconciliation under approved runbooks.

## 11. Exception, risk acceptance and stop-the-line policy

An exception record must include:
- control ID and exact failed/missing evidence;
- scope, affected tenants/products/data and exposure window;
- risk scenario, likelihood/impact rationale and residual risk;
- compensating controls and monitoring;
- accountable risk owner and independent approver;
- start, expiry, review date and closure criteria;
- customer/regulatory/provider impact and notification decision where applicable.

Exceptions cannot silently renew. Expired exceptions return to BLOCKED. Do not use exceptions to bypass known cross-tenant data exposure, unbalanced financial records, unverified payment outcomes, missing legal authority or unsafe key custody. Any suspected material security, privacy or financial integrity incident triggers stop/containment and incident governance.

## 12. Ownership and decision rights

Use a RACI or equivalent per service and control. Minimum roles:
- Product owner: scope, user outcomes, acceptance and business impact.
- Service/technical owner: architecture, implementation and operability.
- Data owner: classification, lineage, retention and recovery requirements.
- Finance/control owner: ledger invariants, reconciliation, settlement and financial acceptance.
- Security owner: threat model, access, vulnerability disposition and security gate.
- Privacy/legal owner: jurisdiction, purpose, retention, transfer and regulatory obligations.
- Platform/SRE/DBA: environment, build/deploy, observability, backup and recovery.
- QA/verification owner: test strategy, traceability, evidence quality and independent challenge.
- Release authority/incident commander: release/stop decision and incident coordination.

One person may hold multiple roles in a small team, but high-impact approval must not become self-approval of the control they implemented. Define an independent reviewer or compensating oversight. Unnamed roles are unresolved blockers, not implicit approvals.

## 13. Metrics and assurance reporting

Report by control and release scope, not a single blended score:
- mandatory controls passed/failed/not-run/expired;
- evidence freshness and traceability coverage;
- unresolved findings by severity and age;
- exceptions by owner, scope and expiry;
- test flakiness and escaped defects;
- tenant-isolation and financial-invariant test coverage;
- vulnerability age and remediation SLA;
- artifact provenance and deployment traceability;
- recovery-test age and measured RTO/RPO where approved;
- post-release SLO and incident outcomes.

Coverage percentages are descriptive, not a substitute for risk weighting. A single critical failure blocks a release even if 99% of checks pass. Missing evidence is not equivalent to a passing control.

## 14. Implementation roadmap and deliverables

P-10F itself establishes the framework. Source-specific execution should proceed only after the source inventory and owner authorization gates are met.

Recommended sequence:
1. Establish named control owners and approved product/system scope.
2. Build an implementation inventory from authorized repositories/environments.
3. Convert P-10A–P-10E requirements into stable control IDs and a traceability matrix.
4. Select scoped ASVS/SSDF/SLSA profiles and document applicability.
5. Create evidence register, exception register and release decision template.
6. Implement verification automation with exact commit/artifact binding.
7. Validate test environments and synthetic fixtures; distinguish mocks from real provider sandboxes.
8. Run isolated domain-specific verification, including negative tenant and financial tests.
9. Perform authorized staging/recovery exercises and independent review.
10. Obtain domain-owner approvals before any production gate is considered.

Required deliverables: control catalogue; requirements-to-control traceability matrix; evidence register; test strategy and reports; security verification profile; build provenance/SBOM policy; environment equivalence statement; release checklist and decision record; exception/risk register; RACI; rollback/containment plans; post-release observation report.

## 15. P-10A–P-10F assurance map

| Phase | Primary assurance question | Current evidence boundary |
|---|---|---|
| P-10A | Is migration readiness governed and staged? | Documentation and protocol; no migration performed |
| P-10B | Is source inventory safe and authorized? | Read-only inventory protocol only; not executed |
| P-10C | Is migration architecture source-neutral and controlled? | Architecture design; no source/target approved |
| P-10D | Are security and tenant governance controls designed? | Architecture design; no implementation verification |
| P-10E | Are reliability and recovery controls designed? | Architecture design; no live backup/restore or DR test |
| P-10F | How will implementation and release claims be evidenced and accepted? | Assurance framework; no control implementation or production gate passed |

P-10F does not close implementation blockers in earlier phases. It defines how future evidence will close them.

## 16. Acceptance criteria

P-10F is ready to serve as the project assurance baseline when:
1. Persian and English versions are structurally aligned and semantically reviewed.
2. The evidence taxonomy distinguishes design, implementation, test, environment, production and independent assessment.
3. Control states cannot be confused with release authorization.
4. Evidence records bind claims to exact versions, environments, scopes, methods and reviewers.
5. Release gates have explicit pass/fail/block/exception semantics.
6. High-risk tenant, ledger, payment, identity, queue and recovery controls have domain-specific stop conditions.
7. Exception and risk acceptance require scope, owner, expiry and compensating controls.
8. RACI prevents unreviewed self-approval for high-impact controls.
9. Security and supply-chain frameworks are mapped without unsupported compliance/certification claims.
10. No statement implies live implementation, production readiness or release approval absent evidence.

## 17. Non-goals and current status

This document does not declare Lottorito production-ready, certify any framework, approve a release, choose vendors, authorize production access, run tests, scan infrastructure, review live customer data, approve legal compliance, validate payment providers, approve financial operations, merge PRs or deploy software.

Current work remains documentation architecture and governance. All implementation maturity states are unverified unless an exact evidence item is separately inspected and accepted. P-10F is a method for future verification, not the result of that verification.

## 18. Research references

- NIST SP 800-218, Secure Software Development Framework (SSDF) 1.1: https://csrc.nist.gov/pubs/sp/800/218/final
- OWASP Application Security Verification Standard 5.0.0: https://asvs.owasp.org/
- OWASP ASVS assessment and certification guidance: https://github.com/OWASP/ASVS/blob/master/5.0/en/0x04-Assessment_and_Certification.md
- SLSA Build Track Basics 1.2: https://slsa.dev/spec/v1.2/build-track-basics
- SLSA Build Provenance: https://slsa.dev/spec/v1.2/build-provenance
- Google SRE Workbook, Canarying Releases: https://sre.google/workbook/canarying-releases/
- Google SRE Workbook, Release Engineering: https://sre.google/workbook/release-engineering/
- NIST Cybersecurity Framework 2.0: https://www.nist.gov/cyberframework

These references inform the assurance framework only. They do not establish compliance, certification, actual Lottorito implementation or production readiness.
