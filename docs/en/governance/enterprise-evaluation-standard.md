# Enterprise Product, Technology and Supplier Evaluation Standard

**Document ID:** LOT-EVAL-001  
**Version:** 0.3.0  
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

### 8.3 Anchored capability scale and evidence state

Record evidence sufficiency separately from capability. Use **Sufficient / Partial / Insufficient / Unknown / N/A** for evidence state and **0–5 / NS** for capability rating. NS means not scored; it is not zero and must never be converted to zero or treated as a neutral value.

| Rating | Required interpretation |
|---:|---|
| 0 | Sufficient, scope-matched evidence demonstrates that the capability is absent or unacceptable against the pre-defined criterion. |
| 1 | Sufficient evidence demonstrates a severe gap and failure of the minimum acceptance threshold. |
| 2 | Sufficient evidence demonstrates partial capability, with material limitations or remediation still required. |
| 3 | Sufficient evidence demonstrates that the pre-defined requirement and threshold are met for the exact scope. |
| 4 | Strong, current and reproducible evidence demonstrates performance materially above the requirement in the intended operating context. |
| 5 | Exceptional, repeatable evidence demonstrates performance materially above the requirement; independent corroboration is required where risk, claim type or tier warrants it. |
| NS | Evidence is missing, inaccessible, contradictory, expired, out of scope or otherwise insufficient to support a defensible rating. |
| N/A | The criterion genuinely does not apply to the named decision unit; written rationale and approval by the accountable control owner are required before scoring. |

A rating of 0 is a positive finding about demonstrated capability, not a penalty for missing evidence. A supplier assertion, unverified demo or absence of documentation cannot by itself justify 0. A criterion may be rated only when its evidence is sufficient for its full defined scope.

Split compound criteria into atomic, testable subcriteria before scoring. Evidence for only some subcriteria must not be used to pass or positively score the entire compound criterion. If an atomic subcriterion remains unsupported, mark that subcriterion NS. Do not expand a claim beyond the entity, product, version, configuration, environment, jurisdiction or population actually evidenced.

N/A must be approved before candidate scoring; it cannot remove a mandatory gate or a requirement that is material to the decision. Publish the original and effective weights and the exact denominator. Where approved N/A criteria are excluded, normalize only across the remaining applicable weights and show the calculation. Applicable weights must total 100 percentage points before exclusions. If any material criterion remains NS, do not publish a definitive aggregate or rank; show the evidence gap and keep the comparison blocked or explicitly provisional under a separately recorded authority decision.

For applicable ratings r and approved weights w, the normalized score is 100 × sum(r × w) / (5 × sum(w)). When applicable weights total 100, this is algebraically equivalent to sum(r × w) / 5. Publish raw ratings, evidence states, original/effective weights, excluded criteria, gate status, confidence, uncertainty and sensitivity. A weighted score never overrides a failed/unknown mandatory gate, minimum criterion threshold, unacceptable residual risk or legal restriction.

For T2/T3 and other material decisions, evaluators score independently before consensus. Preserve individual ratings, disagreements, rationale and adjudication. The proposer must not be the sole scorer or approver of critical gates. If no competent second evaluator is available, record that limitation; do not describe the outcome as independent.

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

- ISO 31000:2018 — risk management principles, framework and process. ISO confirmed the edition current in 2023; guidance, not a certifiable standard: https://www.iso.org/standard/31000
- ISO/IEC 25010:2023 — ICT/software product quality model; nine characteristics for specifying and evaluating product quality: https://www.iso.org/standard/78176.html
- NIST SP 800-161 Rev. 1, Update 1 — cybersecurity supply-chain risk management across acquisition and lifecycle: https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final
- NIST SP 1326 (2026) — supplier due-diligence quick-start, including ownership/control/influence, provenance, resilience, foundational cyber practices and supply-chain tiers: https://csrc.nist.gov/pubs/sp/1326/final
- NIST SP 1305 — using CSF 2.0 to establish C-SCRM and communicate supplier requirements: https://csrc.nist.gov/pubs/sp/1305/final
- OWASP SAMM — measurable software assurance practices across Governance, Design, Implementation, Verification and Operations: https://owaspsamm.org/model/
- FinOps Framework — cost/usage allocation, forecasting, unit economics, licensing and optimization for cloud decisions: https://www.finops.org/framework/capabilities/
- NIST CSF 2.0 — organizational cybersecurity outcomes and governance: https://www.nist.gov/cyberframework
- NIST SP 800-30 Rev. 1 — risk assessment concepts, threat/vulnerability, likelihood, impact and response: https://csrc.nist.gov/pubs/sp/800/30/r1/final
- ISO/IEC 42001:2023 — AI management-system requirements: https://www.iso.org/standard/42001
- NIST AI Risk Management Framework — AI risk governance and trustworthy-AI practices; check current revision status: https://www.nist.gov/itl/ai-risk-management-framework

## 17. Adversarial hardening addendum — normative clarifications

Section 18 is the sole version-history authority. The original 0.1.0 baseline is retained there; no duplicate version marker is maintained in this addendum.

This section is part of LOT-EVAL-001 and prevails over inconsistent general wording in Sections 4, 5, 8, 9 or 14. It closes methodological ambiguities found during the author-led adversarial review. It does not approve a candidate, risk appetite, procurement or production use.

### 17.1 Risk assessment, tier triggers and residual risk

Risk tier and risk rating are different controls. T0–T3 determines governance depth; it is not a probability score and must never be averaged. For each material risk record the asset/process and scope, threat or failure scenario, affected parties, cause/vulnerability, inherent likelihood and impact, existing controls and evidence, residual likelihood and impact, treatment, risk owner, approval authority and expiry/review trigger. A control reduces risk only when its design and operating evidence support that conclusion.

Use documented 1–5 likelihood and impact scales for prioritization where useful. Their product is ordinal triage, not expected monetary loss or scientific precision. Assess impact across confidentiality, integrity, availability, financial loss, legal/regulatory consequence, customer harm, safety and systemic/concentration effects. Do not collapse unlike impact types into one unqualified number.

Apply the highest tier triggered by any condition. T3 is mandatory where a decision can enable custody or movement of customer funds, materially consequential ledger/commission posting, regulated gaming or other legally restricted activity, safety-critical outcomes, or severe/large-scale harm. T2 is mandatory for sensitive personal data, privileged access, cross-tenant boundaries, critical service dependencies, or material external identity/payment processing. T1 applies to material customer/business workflows not meeting higher triggers. T0 is permitted only when readily reversible and there is no sensitive data, privileged access, customer funds, critical path or material external dependency. Unresolved scope or impact uncertainty uses the higher plausible tier.

The owner must define risk appetite and delegated acceptance authority before accepting residual risk. A risk score never waives a mandatory gate, legal requirement, control invariant or T3 approval. High/critical residual risks require explicit named acceptance within delegated authority; otherwise the decision remains Blocked.

### 17.2 Evidence is multidimensional, not a single quality ladder

Do not treat evidence class, independence and authority as interchangeable. For each item separately record: source/issuer and its authority for the claim; independence from supplier and evaluator; directness (official record, executed instrument, observed test, supplier document or secondary report); exact scope match (entity, product, version, region, configuration, date and environment); freshness/validity and reproducibility; integrity/provenance, limitations, conflicts and reviewer.

Distinguish at least: authoritative public/official records; executed contractual instruments; independent assurance reports; directly witnessed tests; supplier-controlled primary documents; supplier assertions/demos; secondary commentary; and unknown/contradictory evidence. A signed contract is authoritative for agreed terms, not independent proof of operational capability. A regulator register may establish a licence entry, not API behavior. A supplier-witnessed test is not automatically independent. One item may support one claim and fail to support another.

Evidence sufficiency is decided per requirement and gate. A high-level class label never validates a claim by itself. Missing, expired, inaccessible or contradictory evidence remains Unknown and blocks a mandatory gate until resolved.

### 17.3 Separate evidence sufficiency from capability scoring

Use two distinct fields: (1) Evidence state: Sufficient / Partial / Insufficient / Unknown / Not applicable; and (2) Capability rating: 0–5, assigned only when evidence is sufficient for the criterion and scope.

Unknown or insufficient evidence is NS (not scored), not zero. A score of 0 means the capability was assessed with sufficient evidence and demonstrated to be unacceptable or absent. Use 0–5 only against a pre-written, measurable criterion and acceptance threshold. A 5 requires exceptional, repeatable evidence relevant to the claim; independent corroboration is required where the risk or claim demands it, not mechanically for every low-risk feature. A 3 means the predefined requirement is met, not merely that a supplier supplied a document.

Before candidate identities/scores are compared, freeze criteria and definitions, applicable dimensions, percentage-point weights, minimum acceptable ratings for critical preferences, evidence requirements, scoring panel, conflicts and aggregation method. Applicable weights must total 100 percentage points. If a criterion is N/A, justify and approve it before scoring; publish effective weights and normalized formula. For ratings r and weights w, normalized result = 100 × sum(r × w) / (5 × sum(w)). Do not publish a definitive aggregate if a material criterion remains NS; show the gap and use a provisional comparison only if the decision authority explicitly permits it.

No aggregate score overrides a failed/unknown mandatory gate, minimum criterion threshold, unacceptable residual risk or legal restriction. Do not double-count correlated criteria (e.g. security in both quality and security dimensions); map each requirement to one primary scoring location. Publish raw ratings, weights, evidence states, effective weights, sensitivity analysis and uncertainty. Differences within evidence uncertainty are ties, not precise rankings.

For T2/T3 and other material decisions, evaluators should score independently before consensus. Record individual scores, disagreement, rationale and final adjudication. The proposer must not be the sole scorer or gate approver. If a second competent reviewer is unavailable, record the limitation and do not call the result independent.

### 17.4 Total-cost and value model

Before comparing TCO, approve a common analysis horizon, currency, FX source/date, inflation/escalation assumptions, discount rate (if using NPV) and tax treatment. Show nominal cash flows and NPV separately where relevant; never silently mix currencies or nominal/real assumptions.

Include build, buy, partner and defer baselines; one-time and recurring costs; fully loaded internal labor; implementation, integration, migration, testing, security/legal assurance, training and support; infrastructure, observability, backup, data transfer and recovery; consumption tiers, minimum commitments, overages, price escalators, FX, taxes, fees, reserves and working capital; incident, outage, fraud, remediation and concentration exposure; parallel run, export, exit, replacement, termination and deletion. Separate sourced prices from estimates and assumptions.

Provide low/base/high scenarios, demand/growth drivers, break-even and unit economics, sensitivity to major cost drivers, and cost of delay/failure where decision-relevant. Do not turn speculative risk into false-precision expected cost. Record excluded costs and who accepted the omission. Compare cost and value per stable business unit with an explicit denominator and quality threshold.

### 17.5 Supplier due-diligence minimum profile

For any material ICT supplier, the dossier must address, proportionate to tier: legal entity and beneficial ownership; ownership/control/influence including relevant foreign ownership/control/influence; corporate and financial stability; product/service provenance and development/supply-chain tiers; critical subcontractors and subprocessors; geographic and operational dependencies; foundational cyber practices; incident history and notification; vulnerability/patch process; business continuity and resilience; concentration and substitutability; and contract, data and exit rights. Record what cannot be verified.

This profile is informed by NIST SP 800-161 Rev.1 Update 1 and the final 2026 NIST SP 1326 due-diligence guide. Supplier self-attestation is an input, not independent verification. Apply additional domain-specific legal, financial, gaming, payment and custody controls where relevant.

### 17.6 Data, AI and model-specific evaluation

A DATA/MODEL decision requires a profile beyond ordinary software scoring. Record model/provider/version and hosting; intended and prohibited uses; training/evaluation data provenance and rights; leakage and retention; personal/sensitive data handling; evaluation-set representativeness and contamination controls; accuracy by relevant cohort; robustness, security and abuse resistance; hallucination/error impact; explainability/traceability where needed; human oversight and override; drift/change notification; reproducibility; fallback and kill switch; output ownership and indemnity; model/prompt portability; and total inference/evaluation cost.

For high-impact or customer-facing AI, define risk controls, human review, monitoring, incident response and domain-specific legal review before pilot. Use ISO/IEC 42001 and NIST AI RMF as relevant references, checking current revision status and applicability. A benchmark, vendor model card or generic certification does not prove fitness for Lottorito's use case.

### 17.7 Product quality and measurable acceptance

For ICT/software products, use ISO/IEC 25010:2023 as a quality-characteristics reference, not a universal weighted score. Map relevant characteristics—functional suitability, performance efficiency, compatibility, interaction capability, reliability, security, maintainability, flexibility and safety—to decision-specific quality scenarios. Each scenario identifies stimulus, environment, response, measurable threshold, owner and evidence. Align with LOT-QA-001; do not invent numeric thresholds or claim conformity from a checklist.

A pilot plan states hypotheses, baseline, success/failure thresholds, sample/load profile, test version, environment, synthetic/minimized data, stop conditions, rollback/cleanup, test owner and evidence retention. Define negative tests and failure schedules before execution. Pilot acceptance is limited to the named test scope and grants no production, regulated-market, customer-fund or launch authority.

### 17.8 Separate approvals and lifecycle gates

Record separate decisions for: discovery/RFI permission; bounded experiment permission; pilot acceptance; procurement and contract signature; architecture/security/privacy/finance/legal acceptance for the named scope; production release; and jurisdiction/product activation or financial operations where applicable. One approval must not be inferred from another. Contract-signature and budget authority must be explicit. T3 activity requires qualified jurisdiction-specific legal/compliance review and explicit owner approval; a provider licence alone is not Lottorito authorization.

Before adoption, define operational owner, support model, SLO/SLI, incident escalation, change notification, periodic evidence review, dependency inventory, portability test, exit trigger and tested exit/continuity plan proportionate to tier. Reassess after material change and suspend the affected scope when a mandatory gate fails or evidence becomes invalid.

### 17.9 Precedence and specialist-document reconciliation

LOT-EVAL-001 governs the common decision process, risk tiering, evidence discipline, mandatory gates, decision states, approval separation and minimum dossier. A specialist profile may add stricter controls and domain-specific tests; it may not weaken parent gates.

Existing specialist scorecards and weights remain proposals unless an explicit owner decision adopts them for a named decision unit. LOT-PROVIDER-EVAL-001's proposed 20/10/15/15/15/10/10/5 weights and LOT-TECH-ADR-001's proposed 1–5 technology matrix are not universal or automatically active. Before use, reconcile criteria with this addendum, eliminate double-counting, define applicable dimensions and freeze the exact rubric/weights for that decision. If conflict remains, mark it OPEN and do not calculate a binding aggregate. This parent standard does not silently supersede specialist documents.

## 17.10 Follow-up adversarial corrections — normative precedence

This subsection is part of LOT-EVAL-001 v0.3.0. It supersedes any inconsistent wording in Sections 4, 5, 8, 9 and 17.1–17.9. It records method corrections arising from follow-up adversarial review REV-01…REV-14. It does not record owner acceptance of residual risk, approve a candidate, or authorize procurement, integration, production, financial activity or launch.

### 17.10.1 Evidence states, partial evidence and scoring

Apply the evidence-state/rating separation and full 0–5/NS/N/A rubric in Section 8.3. “Partial” describes coverage, not a positive score. Where a criterion is compound, split it into atomic subcriteria; score only fully evidenced atomic subcriteria and mark unsupported atomic subcriteria NS. A parent criterion cannot pass because a subset of its subcriteria passed. Missing evidence is not evidence of failure; demonstrated failure requires sufficient positive evidence. Material NS prevents a definitive aggregate. No mandatory gate may be removed or compensated through N/A or weighting.

### 17.10.2 Evidence authority, independence and confidence

Do not use a single evidence class to imply both authority and independence. Record at least: issuer/authority for the particular claim; independence from supplier and evaluator; directness; exact scope match; freshness/validity; reproducibility; provenance/integrity; limitations and conflicts. Confidence is a separate judgment, not a score multiplier. Use:
- **High:** current, complete, scope-matched, reproducible evidence from an authoritative or appropriately independent source, with no material unresolved contradiction.
- **Medium:** credible evidence with a bounded limitation in independence, coverage, recency or reproducibility that does not invalidate the stated conclusion.
- **Low:** material gaps, indirect or supplier-controlled evidence, stale evidence, unresolved contradiction or weak scope match. Low confidence cannot support a favorable definitive conclusion on a material claim.
Record evaluator rationale and disagreement; calibrate evaluators on common examples before material scoring. Do not average confidence labels or multiply them into capability scores.

### 17.10.3 Decision-unit tiering and synthetic-test boundary

Tier the exact decision unit and permission being requested, not a hypothetical future product capability. A bounded, isolated, synthetic-data test with no real users, funds, production access, external partner connection or regulated-market activity is not automatically T3 merely because a later operational product could be T3. Classify the test itself on its actual scope and impact, document its containment and stop conditions, and assess the later operational enablement separately. Any capability enabling materially consequential ledger/commission posting, custody or movement of customer funds, high-impact identity or legally restricted/regulated-market activity remains subject to the applicable higher-tier gates and separate authorization. A successful synthetic test does not inherit or grant operational permission.

Use one canonical tier table and highest-trigger rule across the document. Tier (T0–T3) is governance depth; likelihood/impact is a separate per-risk assessment. Do not average tiers.

### 17.10.4 Risk scales, horizon and aggregation limits

For each risk, record the assessment horizon, scenario, affected objectives, evidence/assumptions, uncertainty, inherent likelihood-impact pair, controls and their evidence, residual pair, treatment, owner and acceptance authority. Define likelihood anchors for the selected horizon and impact anchors separately for relevant dimensions (financial, legal/regulatory, customer, safety, confidentiality, integrity, availability and systemic/concentration). Do not use unanchored numbers.

Preserve and display the raw likelihood-impact pair and the impact dimensions. Prefer an explicitly approved risk matrix with documented decision bands. Multiplying ordinal likelihood and impact values is not a calibrated quantitative measure and can conceal materially different profiles (for example, L1/I5 versus L5/I1). If a product is retained as a screening heuristic, label it ordinal only, preserve the pair, state its limitations and never call it expected loss, probability-adjusted cost or calibrated quantitative risk without supporting empirical data. Risk acceptance thresholds and authority are owner decisions; the matrix cannot approve risk.

### 17.10.5 Total-cost estimation bias and switching value

For material TCO estimates, record historical forecast-versus-actual error where available, reference-class or comparable-project evidence, optimism-bias adjustments and reasons for exclusions. If no usable history or reference class exists, disclose the limitation and use scenario/sensitivity analysis rather than fabricated precision. For consequential or hard-to-reverse choices, calculate or qualitatively document switching value: the point at which a change in cost, demand, performance, delay or risk would reverse the preferred option. Identify assumptions, source dates, horizon, currency/FX, discount treatment and the owner of each estimate. These are decision aids, not guarantees of future cost.

### 17.10.6 Formal assurance and role separation

“Formal assurance” is not a label for an ordinary review, supplier certificate or CI run. Before relying on it, define the assurance objective and scope; competent provider and relevant expertise; objectivity and independence proportionate to the claim; conflicts; criteria and method; evidence access and sampling; period/configuration covered; exclusions and limitations; report and findings; remediation/closure method; and the authority that accepts the result. Record whether the work is owner-led review, specialist challenge/control assessment, supplier assurance or independent third-line assurance. These roles are not interchangeable. An owner-led review or author-led adversarial review must never be described as independent assurance.

### 17.10.7 Cross-document and acceptance consistency

The same evidence-state semantics, rating anchors, N/A controls, tier boundary, risk-pair treatment, confidence anchors, TCO assumptions and assurance-role definitions must be used in the main body, this addendum, A18, owner-review records, examples, decision registers and both language versions. Remove stale/duplicated version markers; Section 18 is the sole change-history authority. A formula example must demonstrate equivalence when applicable weights total 100; it is a clarity check, not a substantive defect.

Minimum acceptance tests:
1. Missing/expired/out-of-scope evidence → NS, never 0.
2. Sufficient evidence of unacceptable capability → 0.
3. Partial evidence for 2 of 5 atomic subcriteria cannot pass or score the 5-part parent criterion.
4. N/A requires prior rationale/approval, exposes effective weights, and cannot remove a mandatory gate.
5. Material NS blocks a definitive aggregate/ranking.
6. A synthetic isolated test is tiered on its actual permission; later operational financial/regulated enablement is assessed separately.
7. L1/I5 and L5/I1 remain distinguishable; no unsupported expected-loss claim is made.
8. Confidence is justified separately and is not multiplied into capability.
9. TCO records forecast bias/reference class or explicitly discloses unavailable evidence; switching value is considered for consequential choices.
10. Formal assurance has a defined scope, competent independent provider where independence is claimed, method, access, limitations, report and acceptance authority.
11. Formula example: ratings 3, 4, 5 with weights 40, 30, 30 yields 78 under either equivalent formula.
12. English and Persian normative meaning, examples, statuses and version history remain semantically aligned.

## 18. Change history

- 0.3.0 (2026-11-28): Follow-up REV-01…REV-14 corrections; evidence/rating separation; Partial and N/A semantics; synthetic-test/operational tier boundary; confidence and risk anchors; TCO bias and switching value; formal-assurance definition and bilingual acceptance tests. Proposed; final owner and specialist approval remains required.

- 0.2.0 (2026-11-28): adversarial hardening separates risk tier from risk rating, evidence sufficiency from capability score, clarifies evidence provenance/independence, normalizes scoring, strengthens TCO and supplier due diligence, adds AI/model and ISO/IEC 25010 quality profiles, separates approval stages and reconciles specialist scorecards. Proposed; owner and specialist review pending.
