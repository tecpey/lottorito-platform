# Enterprise Product, Technology and Supplier Evaluation Standard

**Document ID:** LOT-EVAL-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** PROPOSED — governance baseline; owner approval pending  
**Authority:** Evaluation method only. It does not select a product, technology, supplier, jurisdiction, legal entity or operating model; authorize procurement, integration, production data, financial activity or launch.

## 1. Purpose

LOT-EVAL-001 establishes one repeatable decision system for selecting, building, buying, adopting, integrating, retaining or retiring products, technologies, platforms, services and external suppliers across Lottorito.

Its purpose is to reduce irreversible decisions, hidden lifecycle costs, security and compliance exposure, vendor lock-in, poor integration choices and decisions based on demos, popularity or marketing rather than verifiable evidence.

It is the parent governance standard, not a replacement for specialist contracts. It defines the common process, evidence rules, risk classification, non-compensable gates, comparative method, decision record and lifecycle controls. Specialist documents define domain semantics and tests.

## 2. Scope and decision taxonomy

Apply this standard before a decision that can materially affect product capability, architecture, data, security, legal obligations, customer outcomes, operational resilience, finances or future exit cost.

Classify the decision unit as one or more of:

- **PRODUCT:** a customer-facing or internal product/capability, including build-versus-buy decisions.
- **TECHNOLOGY:** a language, framework, database, broker, workflow engine, cloud/runtime, observability or security technology.
- **SUPPLIER:** a vendor, provider, processor, operator, studio, aggregator, service provider or subcontractor.
- **INTEGRATION:** an API, SDK, protocol, data feed, identity/payment/chat connection or partner interface.
- **DATA / MODEL:** a dataset, model, analytics service, AI model or externally sourced content.
- **OPERATING MODEL:** a deployment, custody, outsourcing, support or service-responsibility arrangement.

A decision may span multiple types; assess each applicable risk dimension. Do not treat a technology component, commercial supplier and legally authorized operator as interchangeable roles.

### 2.1 Decision unit — mandatory scope key

Every evaluation must identify the business capability, decision type, product/domain, supplier/product legal entity (if any), jurisdiction(s), operating model, tenant/deployment model, data classes, transaction/funds model (if any) and intended users.

A conclusion is valid only for this exact scope and its recorded assumptions. No global availability, regulatory eligibility, security assurance or product suitability may be inferred from a different jurisdiction, entity, deployment, data flow or use case.

### 2.2 Lifecycle decisions

The standard applies to build/buy/partner/reuse/defer; shortlist and selection; controlled pilot and technical acceptance; production adoption and material scope expansion; renewal, reassessment and change approval; suspension, replacement, migration and exit.

A successful evaluation is not itself implementation, procurement, launch or production authorization.

## 3. Governance and decision rights

Assign named roles before evaluation begins:

- **Accountable business owner:** owns the need, expected outcome, budget envelope and final business recommendation.
- **Product/domain owner:** defines user outcomes, workflow and domain acceptance.
- **Architecture/engineering owner:** owns fit, integration design, operability and technical evidence.
- **Security owner:** evaluates threat exposure, identity, access, vulnerabilities and assurance.
- **Privacy/data owner:** classifies data, processing purposes, transfers, retention and deletion.
- **Legal/compliance owner:** determines jurisdiction-specific legal/regulatory questions and required advice.
- **Finance owner:** validates cost model, funds/ledger implications, fees, tax, settlement and financial controls.
- **Operations/SRE owner:** validates support, service levels, resilience, recovery and exit operations.
- **Independent reviewer:** challenges evidence and material assumptions where risk warrants independence.
- **Approving authority:** explicitly accepts the exact scope and residual risk within its delegated authority.

One person may hold multiple roles in a small team, but conflicts and missing specialist competence must be declared. The person proposing a high-risk option must not be the sole reviewer of its critical gates. Legal, security, privacy and financial approvals cannot be inferred from a general product or engineering sign-off.

The owner must define who can approve exceptions and residual risk. No author may self-authorize a legal, regulatory, custody, financial or security exception outside delegated authority.

## 4. Risk tiering and proportional depth

Classify each decision before scoring. Use the highest applicable tier; do not average tiers.

| Tier | Indicative impact | Minimum evaluation depth |
|---|---|---|
| T0 — Reversible / low impact | Easily replaced; no sensitive data, privileged access, customer funds or critical path | Lightweight fit, cost, license and security screen; documented owner |
| T1 — Material | Customer-facing capability or business workflow; limited data or operational dependency | Full dossier, evidence register, architecture/security/privacy review as applicable, comparative analysis |
| T2 — High | Sensitive/personal data, privileged access, critical service, cross-tenant boundary, external identity/payment, material vendor dependency | All T1 controls plus threat model, legal/privacy review, independent challenge, controlled negative testing, recovery/exit plan |
| T3 — Critical / regulated / financial | Customer funds, ledger/commission posting, custody, payout, regulated gaming, market access, high-impact identity, safety or legally restricted activity | All T2 controls plus qualified jurisdiction-specific legal/compliance review, finance/control-owner sign-off, formal assurance, adversarial tests, explicit executive/owner approval and separate production authorization |

These tiers are governance triggers, not legal classifications. A product may be T3 in one jurisdiction or use and T1 in another. Where uncertainty could place a decision in a higher tier, use the higher tier until resolved.

## 5. Evidence and claim discipline

Every material requirement and claim must map to an evidence item. Record source, scope, provenance, retrieval date, version, validity, reviewer, integrity reference, limitations and contradictions.

### 5.1 Evidence classes

| Class | Definition | Use |
|---|---|---|
| A — authoritative / independently verified | Competent authority record, executed legal instrument, independently scoped assurance, or witnessed test with retained evidence | May substantiate only the specific claim and scope verified |
| B — primary supplier/product evidence | Versioned API docs, architecture/security documents, signed proposal, test environment documentation | Establishes what is claimed and informs test design; not independent proof |
| C — assertion / demonstration | Sales statement, presentation, marketing page, verbal claim, unrecorded demo | Discovery lead only |
| D — secondary corroboration | Analyst/research report, public customer report, credible third-party review | Context; verify source, date, incentives and applicability |
| U — unknown / unavailable / contradictory | Missing, expired, inaccessible or conflicting evidence | Remains unknown; cannot be treated as pass |

Evidence quality is claim-specific. A licence record does not prove API behavior; a penetration-test summary does not prove legal eligibility; a contract does not prove resilience; a sandbox demo does not prove production readiness.

### 5.2 Confidence and freshness

For each finding record confidence High / Medium / Low, separate from the 0–5 score. Confidence reflects source authority, independence, scope match, recency, reproducibility and completeness. A score without traceable evidence is invalid. A low-confidence high score must be treated as unresolved, not as a favorable result.

Set expiry/revalidation dates by evidence type. Recheck legal status, ownership, certifications, subprocessors, security posture, API versions, service terms and pricing at renewal and after material changes. Preserve superseded evidence and explain why it changed.

## 6. Mandatory evaluation workflow

1. **Intake:** define the problem, desired outcome, baseline, users, constraints, urgency and accountable owner.
2. **Decision framing:** compare build, buy, partner, reuse and defer; define the decision unit, alternatives and explicit non-goals.
3. **Risk tiering:** classify T0–T3 and name required reviewers before candidate scoring.
4. **Requirements baseline:** separate mandatory requirements, measurable preferences, assumptions and unknowns. Assign stable IDs and acceptance evidence.
5. **Market and candidate discovery:** use a documented longlist and consistent information sources; record why candidates were included/excluded.
6. **Initial disqualification screen:** check scope mismatch, legal incompatibility, ownership/provenance, unacceptable data practices, security red flags, financial opacity, concentration and conflicts.
7. **Evidence collection / RFI:** issue the same scoped questions to comparable candidates; record unsupported and roadmap-only capabilities.
8. **Hard-gate assessment:** mark each gate Pass / Fail / Unknown / N/A with evidence and accountable reviewer. Do not score candidates as eligible while a mandatory gate is unknown or failed.
9. **Architecture, threat, privacy, legal and finance review:** conduct specialist reviews proportionate to tier.
10. **Controlled validation:** run only authorized, isolated, synthetic-data tests with explicit scope, test owner and stop conditions.
11. **Comparative analysis:** score only candidates within the same decision unit after hard gates; show uncertainty, cost scenarios and residual risks.
12. **Recommendation and approval:** record alternatives, rationale, dissent, conditions, approvers, exact scope and validity. Approval does not imply deployment permission.
13. **Adoption and monitoring:** define service owner, SLOs, telemetry, support, change notifications, review cadence and exit readiness.
14. **Reassessment / exit:** re-open the decision after triggers; suspend or exit when a gate fails, evidence expires or risk exceeds authority.

## 7. Non-compensable gates

A weighted score must never compensate for a failed or unknown mandatory gate. At minimum assess:

1. **Legal authority and permitted use:** exact entity, role, jurisdiction, product/activity, customer segment, contract chain and required approvals.
2. **Security and trust:** threat model, authentication, authorization, tenant isolation, secrets, cryptography, vulnerability handling, incident response and privileged access.
3. **Privacy and data rights:** data classification, purpose, lawful/contractual basis, controller/processor roles, residency/transfers, subprocessors, retention, deletion and export.
4. **Integrity and correctness:** data lineage, transaction semantics, idempotency, concurrency, auditability, reversals, reconciliation and failure behavior where relevant.
5. **Financial safety:** funds ownership/custody, accounting, pricing units, fees, taxes, settlement, reserves, liquidity and reconciliation where applicable.
6. **Operational resilience:** support ownership, incident response, capacity, availability evidence, backup/restore, RPO/RTO and dependency concentration.
7. **License and supply-chain provenance:** software/content/data rights, dependency provenance, SBOM or equivalent where relevant, subcontracting and change transparency.
8. **Contract and exit:** liability, audit rights, security/privacy terms, data portability, transition assistance, deletion, continuity and termination.
9. **Product safety and user impact:** accessibility, localization, fairness, abuse prevention, responsible-use controls and customer support where relevant.
10. **Evidence sufficiency:** critical claims have current, scoped evidence; material contradictions are resolved or explicitly block approval.

Use N/A only with written rationale and approval by the relevant control owner. A gate may be conditional only for a bounded, non-production experiment if the missing control is not needed for that experiment and the restriction is enforceable. Unknown legal eligibility, funds ownership, tenant isolation or critical data handling blocks the corresponding activity.

## 8. Comparative scoring — only after gates

Scoring is a structured aid to judgment, not an automated decision or procurement engine.

### 8.1 Freeze the rubric before viewing scores

For each decision unit, define and approve criteria and definitions; weights summing to 100%; mandatory versus preference requirements; minimum acceptable score per critical dimension if any; evidence expectations and test methods; scoring panel and conflict declarations.

Do not change weights after seeing candidate scores to favor a preferred option. Any change requires a versioned rationale and rescoring every candidate.

### 8.2 Common dimensions

Use these as a reusable catalogue; select applicable dimensions and create a domain profile rather than applying every dimension blindly:

- strategic and product outcome fit;
- functional completeness and workflow fit;
- quality attributes: performance, reliability, compatibility, usability, accessibility, security, maintainability, portability and safety;
- architecture, integration and interoperability;
- security, privacy and data governance;
- legal/regulatory and licensing fit;
- financial correctness and control;
- operational maturity, support and resilience;
- implementation complexity, migration and time-to-value;
- total cost of ownership and commercial sustainability;
- vendor/product viability, concentration and roadmap risk;
- data, content, IP and software supply-chain provenance;
- localization, language, currency, accessibility and regional fit;
- reversibility, portability and exit cost;
- measurable user/business value and outcome evidence.

### 8.3 Anchored scale

| Score | Anchor |
|---:|---|
| 0 | No credible evidence, unsupported, contradictory or unacceptable |
| 1 | Major gap; does not meet minimum requirement |
| 2 | Partially meets; material remediation or limitation remains |
| 3 | Meets the pre-defined requirement with adequate scope-matched evidence |
| 4 | Exceeds requirement with strong, current evidence and demonstrated operational fit |
| 5 | Exceptional, independently corroborated and repeatably demonstrated for the exact scope |

Calculate only using the frozen applicable dimensions: weighted score = sum(score × approved weight) / 5. Publish the formula, weights, excluded dimensions and raw scores. Do not silently redistribute N/A weights; predefine the normalization method or do not calculate an aggregate.

Display score beside confidence, gate status, evidence coverage and residual risk. Do not rank unlike decision units, different risk tiers or candidates assessed under different rubrics. Report ties and uncertainty honestly. A higher score is not a recommendation if the difference is within evidence uncertainty or lifecycle cost/risk.

## 9. Total cost, value and reversibility

Estimate total cost over an owner-approved horizon (normally scenario-based, not a single vendor quote). Include license/subscription, usage, minimums, overages, support and professional services; implementation, integration, migration, testing, certification and legal/compliance work; internal engineering, security, operations, finance and support effort; infrastructure, data transfer, storage, observability, backups and recovery; taxes, FX, payment/settlement fees, reserves and working-capital effects where applicable; incident, outage, fraud, error and remediation exposure; renewal escalation, price changes, capacity growth and usage volatility; exit, export, parallel run, replacement, termination and deletion costs.

Model low/base/high scenarios with assumptions, units, source dates and sensitivity drivers. Compare cost per meaningful unit (e.g. active tenant, verified transaction, supported conversation, successful workflow) where it improves decision quality. Do not optimize nominal price while ignoring operational labor, failure cost or lock-in.

Record reversibility: what can be exported, how long migration takes, which identifiers/contracts are portable, what data or history cannot move, whether dual-run is possible, and what happens if the supplier disappears or changes terms.

## 10. Controlled pilot and acceptance evidence

A pilot requires prior authorization, named owner, bounded purpose, isolated environment, supplier permission, synthetic or approved minimized data, test plan, rollback/cleanup and stop conditions. A pilot is not a shortcut around legal or security gates.

Tests should include, where applicable: happy path and boundary/negative cases; unauthorized, cross-tenant and wrong-scope access; duplicate, concurrent, delayed, reordered and replayed requests/events; timeout before/after remote acceptance and ambiguous outcomes; partial outage, rate limiting, backpressure, recovery and data reconciliation; schema/API version drift and unknown fields/enums; performance under representative load and degraded dependency; backup restore, failover, migration and rollback; auditability, export/deletion, redaction and access review; accessibility, localization and critical user journeys.

Retain test plan/version, environment, fixture hashes, test data classification, timestamps, correlation IDs, expected/actual outcomes, logs with secrets/PII removed, code/test commit, defects, reviewer and limitations. A demo, synthetic happy path, vendor certificate or CI pass is not a substitute for the relevant proof.

## 11. Standard decision dossier

Create one immutable/versioned dossier per decision unit containing: Evaluation ID and version; business problem and measurable outcomes; exact decision unit and assumptions; build/buy/partner/reuse/defer alternatives; T0–T3 tier and reviewer assignments; stable requirements register; evidence register with provenance, class, scope, freshness, hash/reference, confidence and limitations; hard-gate register; capability matrix; architecture/threat/privacy/legal/finance/operations assessments; frozen score rubric and sensitivity analysis; TCO scenarios; pilot authorization and test artifacts; risk/exception register; decision rationale, dissent, scope, conditions, approvers and validity; adoption plan, service owner, SLOs and review dates; exit plan and reassessment triggers.

No undocumented side-channel approval. Silence, a meeting, score, sales email, repository merge or CI pass does not constitute approval.

## 12. Decision states and exception rules

Use only these states:

- **Not assessed**
- **Discovery**
- **Evidence requested**
- **Blocked**
- **Conditional experiment** — only the explicitly bounded experiment is allowed; no production use.
- **Eligible for controlled pilot** — gates for the named pilot scope passed and pilot authorization separately recorded.
- **Recommended** — comparative analysis complete; approval still pending.
- **Approved for named scope** — required accountable approvals recorded for exact scope and validity.
- **Adopted** — implementation and operational acceptance completed under separate release controls.
- **Suspended**
- **Rejected**
- **Retired / Exited**

Exceptions must identify requirement, reason, risk, compensating control, owner, approving authority, expiry, monitoring and rollback. No permanent exception by silence. No exception may waive applicable law or a control outside the approver's authority.

## 13. Continuous monitoring and mandatory reassessment triggers

Reassess after a change in legal entity, ownership, licence, jurisdiction, permitted activity or contract; new product, customer segment, tenant model, funds flow, data category or processing purpose; material API/schema/SDK/version or authentication change; vulnerability, breach, fraud pattern, audit finding or security-assurance expiry; subprocessor, hosting region, data transfer or privileged-access change; SLO breach, material outage, DR failure, financial variance or reconciliation break; material pricing, commitment, exclusivity, liability or renewal change; supplier acquisition, insolvency, service withdrawal or deprecation notice; or invalidated exit assumptions / critical dependency concentration.

Monitor relevant reliability, latency, error rate, support response, security findings, data incidents, unit cost, financial variance, customer outcomes and exit readiness. Assign metric owner, threshold, source and response runbook.

## 14. Lottorito specialist profiles and precedence

LOT-EVAL-001 is the common parent. Apply stricter relevant specialist requirements; do not weaken them.

- **External provider / due diligence / RFI:** LOT-PROVIDER-EVAL-001.
- **Technology, architecture, deployment and reliability:** LOT-TECH-ADR-001 (technology-deployment-adrs.md).
- **Affiliate integration and event semantics:** LOT-INT-001, Affiliate API/wire contracts and related security/persistence ADRs.
- **Lottery integration:** LOT-LOTINT-001.
- **Security and threat assessment:** security baseline and threat model.
- **Financial posting and reconciliation:** LOT-FIN-POST-001 and applicable wallet/payment/payout contracts.
- **Quality and acceptance:** LOT-QA-001 and approved domain test plans.
- **Future gaming domains:** LOT-GAMING-STRATEGY-001 plus jurisdiction-specific provider and domain contracts.

If requirements conflict, stop and record the conflict. Apply law and binding obligations first, then the stricter approved security/financial/domain control. Accountable owners must resolve document conflicts; this standard does not silently override existing owner decisions.

## 15. Current Lottorito disposition

This document creates no candidate shortlist and approves no product, provider, technology, contract, jurisdiction, legal entity or architecture. Existing documents remain proposed unless their own approval records state otherwise. The Affiliate-first delivery priority is unchanged. RaidenBet remains an unconfirmed proposed pilot lead, not a verified customer, operator or integration. Lottery, sportsbook, casino and other gaming capabilities remain subject to their separate horizon and legal/domain gates.

The first use should be a retrospective pilot on one bounded, non-production decision unit selected by the accountable owner. Do not begin production procurement or integration solely because this standard exists.

## 16. Reference framework

Use the current edition and exact scope of each source; these frameworks inform the method but do not certify Lottorito or decide a candidate:

- ISO 31000:2018 — risk management principles, framework and process. ISO confirmed the edition current in 2023; guidance, not a certifiable standard: https://www.iso.org/standard/65694.html
- ISO/IEC 25010:2023 — ICT/software product quality model; nine characteristics for specifying and evaluating product quality: https://www.iso.org/standard/78176.html
- NIST SP 800-161 Rev. 1, Update 1 — cybersecurity supply-chain risk management across acquisition and lifecycle: https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final
- NIST SP 1326 (2026) — supplier due-diligence quick-start, including ownership/control/influence, provenance, resilience, foundational cyber practices and supply-chain tiers: https://csrc.nist.gov/pubs/sp/1326/final
- NIST SP 1305 — using CSF 2.0 to establish C-SCRM and communicate supplier requirements: https://csrc.nist.gov/pubs/sp/1305/final
- OWASP SAMM — measurable software assurance practices across Governance, Design, Implementation, Verification and Operations: https://owaspsamm.org/model/
- FinOps Framework — cost/usage allocation, forecasting, unit economics, licensing and optimization for cloud decisions: https://www.finops.org/framework/capabilities/
- NIST CSF 2.0 — organizational cybersecurity outcomes and governance: https://www.nist.gov/cyberframework

## 17. Change history

- 0.1.0 (2026-11-28): initial enterprise-wide parent standard; proposed, pending owner and specialist review.
