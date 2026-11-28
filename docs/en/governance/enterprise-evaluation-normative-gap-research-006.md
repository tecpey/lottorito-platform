# LOT-EVAL-RDM-006 — Normative Gap Research & Owner Decision Pack

**Document ID:** LOT-EVAL-RDM-006-001  
**Version:** 0.2.0  
**Date:** 2026-11-28  
**Status:** RESEARCH COMPLETE — proposed policy options; owner disposition pending  
**Parent:** LOT-EVAL-001 v0.3.0  
**Inputs:** RDM-003A v0.1.0; RDM-004 v0.2.0; RDM-005 v0.1.0; unresolved issues RDM-U01…U05

## 1. Executive conclusion

This package researches five unresolved normative issues and two cross-cutting weaknesses in the current scoring method. It proposes conservative, testable policy options but does **not** adopt them. The owner retains all normative decision rights.

The principal conclusions are:

1. **Unknown evidence is not a score.** Materiality must be determined by whether the unresolved evidence could change eligibility, a hard gate, a minimum threshold, risk acceptability or the preferred option—not by an arbitrary universal percentage.
2. **N/A, conditional experiment permission and gate outcome are different dimensions.** They must not share one overloaded status field.
3. **The decision unit needs a versioned minimum scope schema.** Unknown scope is not false; scope omissions that could alter tier or gate outcomes block definitive lower-tier decisions.
4. **Likelihood scales must be scenario- and horizon-bound.** Qualitative categories are valid when calibrated as ordinal judgments; they must not be presented as probabilities without defensible data and method.
5. **A generic 0–5 label is not a measurable rubric.** Each criterion needs observable, pre-approved anchors and evidence rules.
6. **The current weighted score must remain a secondary decision aid.** A single composite score cannot override hard gates, critical thresholds, risk appetite, evidence uncertainty or rank instability. For complex trade-offs, structured MCDA and sensitivity analysis are preferable to unexamined simple weighting.

No fixed likelihood percentage, materiality percentage, universal 1–5 threshold, legal interpretation or owner approval is invented here.

## 2. Research method and source applicability

The analysis used current official standards/guidance and engineering references, with the following hierarchy:
- International standards and NIST publications for risk, quality, systems engineering and evidence concepts.
- Current government risk/appraisal/evaluation guidance for decision governance, uncertainty, sensitivity and proportionality.
- NASA systems-engineering guidance for decision-analysis and testability.
- Existing LOT-EVAL-001 wording as the controlling internal policy text until the owner approves an amendment.

Applicability caveat: HM Treasury/UK government guidance is not binding law or a mandatory framework for Lottorito. NIST publications are guidance for their stated contexts, not proof of legal compliance for this project. ISO catalogue abstracts do not replace the full licensed standard. The sources inform design; they do not certify this standard.

### 2.1 Evidence-based principles extracted

- The 2026 Orange Book calls for common risk criteria, explicit consideration of evidence limitations, sensitivity/confidence, time-related factors and the effectiveness of controls; it recognises qualitative, quantitative or combined methods according to context and intended use.
- The 2026 Green Book distinguishes uncertainty from risk, recommends scenario analysis and explicit communication of assumptions, and warns that probabilities may be subjective where objective data are absent. It also calls for explicit optimism-bias adjustments informed by historical forecast error where applicable.
- HM Treasury's MCDA guidance explains swing weighting and sensitivity analysis; it says criterion weights should reflect the difference between best and worst performance as well as stakeholder importance, not importance in isolation.
- NASA decision-analysis guidance says scale definitions should be operational and repeatable; if reducing uncertainty could change the ranking, that uncertainty and the value of further information should be considered.
- The Magenta Book requires evaluation to be credible, robust and proportionate; independent scrutiny is useful, particularly for high-risk/high-uncertainty/high-cost decisions.
- NIST SP 800-53 Rev. 5.2.0 CA-02 requires an assessment plan that identifies scope, procedures, environment, team and responsibilities, and assesses whether controls are implemented correctly and operate as intended.
- ISO/IEC 25010:2023 supplies a product-quality taxonomy of nine characteristics. It is a taxonomy for specifying/measuring quality properties, not a universal numeric scoring rubric.

## 3. RDM-U01 — Material and non-material NS

### Problem

The parent standard blocks a definitive aggregate when material NS exists, but does not define materiality, provisional-output authority, expiry, denominator handling or permitted downstream use.

### Options

| Option | Rule | Benefit | Main risk |
|---|---|---|---|
| U01-A — strict stop | Any NS blocks all aggregation and ranking | Simple, conservative, low false-confidence risk | May unnecessarily block a decision where the unknown is demonstrably irrelevant |
| U01-B — bounded sensitivity | NS remains unscored; test whether every admissible value could change gates, thresholds, risk acceptability or ranking; only a robust non-decisional range may be shown | Makes materiality testable; preserves uncertainty | Requires explicit bounds and a disciplined sensitivity method |
| U01-C — discretionary provisional rank | Authority may permit a provisional aggregate/rank despite NS | Flexible | High risk of a provisional rank being treated as approval or a fact |

### Recommended owner decision

Prefer **U01-B with U01-A as the default stop condition**:

1. NS is never converted to 0, a midpoint, neutral value or hidden denominator.
2. A materiality assessment is performed per decision unit and criterion before publication.
3. NS is **material** if any admissible value consistent with the frozen criterion could change: (a) a mandatory gate; (b) eligibility; (c) a critical minimum threshold; (d) risk-tier or residual-risk acceptability; (e) preferred option/rank; or (f) the recommendation/approval path.
4. For sensitivity only, use a documented admissible interval. The interval is not a capability rating and does not convert NS into a score. Where no defensible narrower bound exists, use the full possible range and treat the NS as material if it can alter the decision.
5. If the ranking/eligibility is robust under all admissible values, allow only a clearly labelled **provisional, non-selection information view**. Do not call it a definitive rank or recommendation.
6. Any provisional output requires named delegated authority, rationale, scope/version, disclosed NS and denominator, validity/expiry, prohibited uses, and a reassessment trigger.
7. NS affecting a legal, security, financial-safety or other mandatory gate cannot be declared non-material merely because a weighted score/rank appears stable.

**Owner decisions required:** approve the materiality test; identify who may authorize provisional information; set expiry/reassessment rules; define downstream-use restrictions.

### Acceptance tests to add

- NS never appears as a numeric capability rating.
- A possible gate/threshold/rank reversal makes NS material.
- If the rank interval overlaps or a plausible NS value reverses the order, definitive ranking is blocked.
- Stable ranking does not bypass any failed/unknown mandatory gate.
- Provisional output contains every required disclosure and cannot be consumed as selection/approval.
- Missing/expired authority blocks provisional output.

## 4. RDM-U02 — Conditional experiment versus genuine N/A

### Problem

A bounded experiment may not need a control that is mandatory for a later operational permission. That is not the same as saying the control is inapplicable to the decision or deleting a mandatory gate.

### Options

- **U02-A:** represent both states as N/A. Rejected: collapses different meanings and creates a route to gate erasure.
- **U02-B:** keep N/A for genuine non-applicability and use a separate conditional-scope permission for the bounded experiment. Recommended.
- **U02-C:** require all later operational controls before any experiment. Safest in some domains but may prohibit low-risk isolated experiments without a demonstrated need.

### Recommended owner decision — separate dimensions

Use distinct fields, not one overloaded enum:

| Dimension | Suggested states | Meaning |
|---|---|---|
| Applicability | APPLICABLE / NOT_APPLICABLE / UNRESOLVED | Whether the control applies to this exact decision unit |
| Gate result | PASS / FAIL / UNKNOWN / NOT_ASSESSED | Evidence-based control disposition |
| Permission | BLOCKED / BOUNDED_EXPERIMENT_ONLY / OPERATIONAL | What activity is actually authorized |
| Restriction | Versioned, enforceable constraints + stop conditions | What must remain true for the bounded permission |

Rules:
1. N/A means genuinely outside the scoped activity, with rationale and accountable approval before scoring.
2. Conditional experiment means the control is relevant to a later permission but is not required for the tightly bounded experiment; the experiment must remain safe without it and restrictions must be enforceable.
3. A control required to make the experiment itself safe/legal cannot be waived by calling it conditional.
4. Conditional experiment permission is not a PASS for the future operational gate.
5. Scope expansion, production access, real users/funds, partner connection, new jurisdiction or removal of containment triggers re-tiering and a new gate assessment.

**Owner/control-owner decisions required:** approve state vocabulary; decide which gate categories may ever be conditional for which experiment types; define minimum restriction and stop-condition evidence.

### Acceptance tests to add

- N/A cannot satisfy a required gate.
- Conditional experiment cannot yield operational permission.
- A failed or unknown required gate blocks the relevant activity.
- A scope-expansion event invalidates the old bounded permission.
- The restriction must be represented as enforceable controls, not a prose-only promise.

## 5. RDM-U03 — Decision-unit completeness schema

### Problem

The parent standard requires an exact decision unit and highest-trigger tiering, but does not define a mandatory minimum schema. Missing scope can conceal a higher tier or a mandatory gate.

### Recommended schema proposal

Every evaluation should carry a versioned decision-unit record with:

**Core fields**
- stable decision ID, version, purpose and decision owner;
- capability/product/service/system and requested decision/action;
- lifecycle stage and exact permission sought (research, synthetic test, pilot, production, financial operation, etc.);
- in-scope entities/components and accountable operating entity;
- operating model and deployment/environment boundary;
- applicable jurisdictions/geographies and intended markets;
- user/population classes and privilege/access level;
- data classes/sensitivity and principal data flows;
- third parties, providers, subprocessors, integrations and material dependencies;
- financial/funds/asset/transaction paths where relevant;
- scale/volume, duration and relevant risk horizon;
- explicit exclusions, assumptions, containment, restrictions and stop conditions;
- accountable owner, control owners, approvers, effective date and source evidence.

**Conditional fields** should be mandatory when triggered by the decision type: licensing/regulated activity; custody/payment/settlement; children/vulnerable users; cross-border data; AI/model use; safety-critical use; privileged administration; subcontracting; high availability; material concentration; or other specialist profile.

Each field must be one of:
- known value with evidence/source;
- not applicable with rationale;
- unresolved/unknown with owner and resolution date.

Do not silently default missing fields to false, empty or N/A.

### Tiering rule

If a missing field could change a gate or tier, the decision is UNRESOLVED. Retain the specifically identified highest plausible tier if it can be bounded; if it cannot, do not invent T0 or T3—block definitive tier assignment pending scope resolution.

**Owner decision required:** approve the core schema, conditional trigger catalogue, and the rule for bounded versus unbounded unknowns.

### Acceptance tests to add

- Missing mandatory core field blocks definitive tiering.
- Conditional field omission blocks only when its trigger applies or is unresolved.
- Explicit N/A requires rationale and does not equal unknown.
- Changing a material scope field creates a new decision-unit version.
- Any new higher-tier trigger monotonically raises or preserves the tier.

## 6. RDM-U04 — Qualitative likelihood calibration

### Problem

Qualitative likelihood labels without horizon, scenario, criteria or evidence basis are not reproducible and can create false precision.

### Research findings

The Orange Book permits qualitative, quantitative or combined risk analysis depending on context and intended use, but requires common criteria and explicit treatment of evidence limitations, sensitivity/confidence and time-related factors. It describes likelihood as something that may be judged objectively or subjectively, qualitatively or quantitatively, and may be expressed as probability or frequency over a time period. The Green Book notes that probability estimates can be subjective and that scenario analysis is useful where uncertainty is material. NIST SP 800-30 distinguishes likelihood that an event occurs from likelihood that it results in adverse impact; collapsing these can obscure the risk pathway.

### Recommended owner decision

Use a **horizon-bound ordinal likelihood scale by default**. Do not assign percentage values unless a domain-specific quantitative method and adequate data support them.

Each likelihood rating should record:
- exact cause–event–consequence scenario;
- time horizon and exposure basis;
- likelihood category and operational definition;
- evidence/reference class, sample size and relevant base rate where available;
- whether judgment is empirical, expert-elicited or assumption-driven;
- confidence/sensitivity and known limitations;
- relevant changes, dependencies and control effectiveness;
- separate inherent and residual likelihood/impact pairs.

Where quantitative probabilities are proposed, require documented data lineage, population/reference class, denominator, observation window, model assumptions, uncertainty interval, validation/back-testing and responsible specialist. Do not manufacture probabilities from ordinal categories.

The scale should be calibrated for the domain and decision use; one universal frequency table for cybersecurity, supplier failure, fraud, legal change and operational outages is not justified by the cited sources.

**Owner/risk-owner decisions required:** approve default ordinal use; decide when quantitative probabilities are allowed; assign domain calibration owners and review cadence.

### Acceptance tests to add

- A likelihood rating without scenario/horizon rationale is incomplete.
- A qualitative category cannot be displayed as a percentage without a quantitative method.
- Probability of event occurrence is not silently conflated with probability of harm.
- Sensitivity/confidence and evidence limitations are required.
- Inherent and residual pairs remain separately visible.

## 7. RDM-U05 — Criterion-specific measurable 0–5 anchors

### Problem

A generic 0–5 scale cannot produce repeatable scores across unrelated criteria unless each criterion has an operational definition, evidence rule and observable anchor. The current standard correctly requires a frozen rubric and separates NS from scores, but the domain templates are not yet defined.

### Recommended owner decision

For every criterion, freeze a **criterion measurement specification** before candidate evidence is viewed:

1. criterion ID, purpose, construct and exact scope;
2. criticality class: mandatory gate, critical threshold or preference;
3. measurement unit and operational definition;
4. test/inspection method, environment, configuration, version and sample;
5. minimum acceptable threshold and pass/fail logic where relevant;
6. observable anchors for 0, 1, 2, 3, 4 and 5;
7. evidence sufficiency, freshness, source authority and independence expectations;
8. atomic subcriteria and dependency rules;
9. N/A applicability rule and prior approval authority;
10. calibration examples, known boundary cases and evaluator disagreement procedure.

The anchors must describe observable capability, not vague adjectives such as “good”, “advanced” or “excellent”. Rating 0 continues to require sufficient positive evidence of absent/unacceptable capability; missing evidence remains NS. Partial compound coverage remains Partial/NS at unsupported atoms.

ISO/IEC 25010:2023 can provide a product-quality taxonomy for relevant software characteristics, but it does not supply the criterion-specific numeric thresholds. Those must be designed for the product, decision unit and test method.

### Cross-cutting scoring-method warning

The UK Government Analysis Function's 2024 MCDA guide states that simple weighting alone is not a valid way to derive weights and that additive MCDA requires cardinal component values and mutual preferential independence. HM Treasury's 2024 MCDA supplementary guidance explains **swing weighting**: weights reflect both the importance of a criterion and the actual performance difference between best and worst options; it requires sensitivity analysis and competent facilitation.

This does not mean Lottorito must adopt HM Treasury's process. It means the current weighted score should not be treated as an objective truth or sole selector. The UK public-expenditure guidance limits its use of MCDA to longlist appraisal and uses other methods at shortlist stage. That stage-specific rule is context-bound and must not be transplanted as a legal or universal supplier-selection rule for Lottorito. The Green Book 2026 is cited here for risk/uncertainty, scenario analysis, sensitivity and optimism-bias guidance—not as the source of the simple-weighting critique.

### 7.1 Additional candidate gap — cardinal measurement and additive-model validity (proposed RDM-U06)

The current parent formula is an additive weighted sum of 0–5 ratings. Such arithmetic implicitly treats the inputs as cardinal value measures: the size of a difference between adjacent rating points matters, and the values can be traded off through weights. Merely assigning numbers to ordered categories does not establish this property.

The Government Analysis Function's MCDA guide states that component values must be cardinal for weights to be valid, and that a linear additive value model is valid only under mutual preferential independence between criteria. It also distinguishes criterion performance from the component value function that translates performance into stakeholder preference. EFSA's scientific guidance explains that ordinal categories express order but not the magnitude of differences; numerical labels do not create interval measurement, and calculations that treat ordinal scales as quantitative are invalid.

**Finding:** LOT-EVAL-001 §8.3 defines ordered 0–5 capability anchors and a weighted arithmetic formula, but the present evidence does not establish that each 0–5 scale is an interval/cardinal value function or that mutual preferential independence holds across the selected criteria. This does not prove the formula is mathematically wrong in every application; it means the assumptions required to interpret its output as a valid additive preference ranking are currently undocumented and unverified.

**Options:**

| Option | Approach | Consequence |
|---|---|---|
| U06-A — retain ordinal ratings only | Keep 0–5 as ordered capability categories; do not use arithmetic aggregation to rank options | Most transparent where value intervals cannot be defended; may reduce convenience of one-number summaries |
| U06-B — construct cardinal value functions | For each criterion, map measured performance to an interval-scale preference value using defined worst/best anchors and elicited intermediate indifference points; elicit swing weights; assess preferential independence | Supports additive aggregation if assumptions and evidence are satisfied; requires expert effort and documented elicitation |
| U06-C — use non-compensatory/ordinal decision methods | Preserve hard gates and critical thresholds; use dominance, lexicographic or appropriate outranking/robust ordinal methods where cardinal trade-offs are not defensible | Avoids false cardinality but produces different outputs and requires method-specific governance |

**Recommended direction:** do not use the current weighted total as a definitive ranking until the project has either (a) justified criterion-specific cardinal value functions, swing weights and additive-model assumptions, or (b) selected and documented an alternative method that does not require cardinal aggregation. Until then, show raw criterion profiles, gates, evidence states and uncertainty; label any arithmetic total as a non-decisional descriptive index if it is retained at all.

Do not interpret an interval-scale overall value as a ratio: a score of 80 is not “twice as much value” as 40. Do not allow additive compensation across mandatory gates or critical thresholds. If stakeholders say a trade-off “depends” on another criterion, investigate whether preferential independence fails; do not force a constant weight.

**Owner decision required:** add RDM-U06 as a distinct unresolved issue or incorporate it into U05; decide whether the existing weighted aggregate may be used pending validation; approve the required value-function/weight-elicitation or alternative ranking method.

**Acceptance tests to add if adopted:**
- Numeric aggregation is blocked unless each input is marked as a validated cardinal value, not merely an ordinal rating.
- Each criterion has a performance-to-value function with explicit range-of-interest and documented intermediate preference points.
- Weights are elicited from swings between worst and best performance, not importance labels alone.
- Mutual preferential independence is assessed and documented for an additive model.
- If independence or cardinality is not supported, the additive aggregate is suppressed and an approved alternative is used.
- Sensitivity analysis varies value-function shapes, weights and uncertain performance; rank robustness is reported.
- No ratio interpretation is made from interval-scale totals; no gate/threshold can be compensated.

**This is a candidate gap only.** It is not yet added to the canonical RDM-003A unresolved register and has no owner disposition.

**Recommended safeguard:**
- hard gates and critical thresholds first;
- evidence/NS and risk disposition second;
- criterion-level results and Pareto/threshold comparison remain visible;
- weighted aggregate only as a secondary summary where criteria are commensurable enough and weights are justified;
- for material complex trade-offs, use a documented MCDA method (e.g. swing weighting) with sensitivity and rank-robustness analysis;
- show how plausible changes in weights, scores and NS assumptions affect ranking;
- if ranking is fragile, report the close alternatives and unresolved information need to the decision-maker rather than pretending there is a stable winner.

**Owner decision required:** approve criterion-template requirements; decide whether simple weighted scoring remains permitted and under what limits; specify when MCDA/sensitivity analysis is mandatory.

### Acceptance tests to add

- Rubric version and anchors must be frozen before candidate scoring.
- Missing criterion-specific anchors blocks numeric rating.
- A threshold failure cannot be compensated by unrelated high scores.
- Candidate ranking must be tested against approved weight and evidence uncertainty ranges for material decisions.
- A score change or rubric change after scores are visible requires versioning and uniform rescoring.
- The report must disclose score inputs, weights, denominator, sensitivity and ranking robustness.

## 8. Proposed disposition matrix — owner decision required

| Issue | Recommended direction | Current state | Owner decision |
|---|---|---|---|
| RDM-U01 | Bounded sensitivity; strict stop if any plausible value changes decision; provisional non-selection only under explicit authority | UNRESOLVED | PENDING |
| RDM-U02 | Separate applicability, gate result and permission dimensions | UNRESOLVED | PENDING |
| RDM-U03 | Versioned core decision-unit schema plus triggered conditional fields | UNRESOLVED | PENDING |
| RDM-U04 | Horizon-bound ordinal likelihood by default; quantitative only with validated domain method | UNRESOLVED | PENDING |
| RDM-U05 | Criterion-specific measurable anchors; aggregate score is secondary; MCDA/sensitivity for complex material trade-offs | UNRESOLVED | PENDING |
| RDM-U06 (candidate) | Validate cardinal value functions and additive-model assumptions, or use an ordinal/non-compensatory alternative | NOT REGISTERED — owner must decide whether to add or merge into U05 | PENDING |

No recommendation in this table changes the normative parent standard. The owner may accept, reject, amend or defer each item independently.

## 9. Required next implementation sequence after owner disposition

1. Record owner decisions individually in the decision register; do not batch-approve by implication.
2. Amend LOT-EVAL-001 in English and Persian with explicit version history and precedence.
3. Update RDM-003A atomic rules and decision tables; mark each rule NORMATIVE, DERIVED-GUARD or UNRESOLVED.
4. Add executable model states for applicability, gate result, permission, NS materiality and provisional publication.
5. Add decision-table rows and metamorphic properties for scope, horizon, rank robustness and rubric freeze.
6. Add targeted specification mutations for each new mandatory semantic.
7. Run bilingual validation, RDM-001, RDM-004 and RDM-005 on the exact PR head.
8. Preserve independent specialist/assurance requirements where the decision tier or claim warrants them.

## 10. Research references

1. HM Treasury, **The Orange Book: Management of Risk — Principles and Concepts**, updated 18 November 2026: https://www.gov.uk/government/publications/orange-book/the-orange-book-management-of-risk-principles-and-concepts
2. HM Treasury, **The Green Book 2026**, updated 28 October 2026: https://www.gov.uk/government/publications/the-green-book--2/the-green-book-2026
3. HM Treasury, **Use of Multi-Criteria Decision Analysis in options appraisal of economic cases**, updated 16 May 2024: https://www.gov.uk/government/publications/green-book-supplementary-guidance-multi-criteria-decision-analysis/use-of-multi-criteria-decision-analysis-in-options-appraisal-of-economic-cases
4. NIST SP 800-30 Rev. 1, **Guide for Conducting Risk Assessments** (2012): https://csrc.nist.gov/pubs/sp/800/30/r1/final
5. NASA Systems Engineering Handbook, **6.8 Decision Analysis**: https://www.nasa.gov/reference/6-8-decision-analysis/
6. HM Treasury, **Magenta Book: Central Government guidance on evaluation**, updated 15 May 2026: https://www.gov.uk/government/publications/the-magenta-book/magenta-book-central-government-guidance-on-evaluation-html
7. FedRAMP 2026, NIST SP 800-53 Rev. 5.2.0 **CA-02 Control Assessments**: https://www.fedramp.gov/2026/providers/rev5/controls/assessment-authorization-and-monitoring/
8. ISO 31000:2018, **Risk management — Guidelines**, reviewed and confirmed in 2023: https://www.iso.org/standard/31000
9. ISO/IEC 25010:2023, **Product quality model**: https://www.iso.org/standard/78176.html
10. NIST SP 800-160 Vol. 1 Rev. 1, **Engineering Trustworthy Secure Systems** (2022): https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final
11. UK Government Analysis Function, **An Introductory Guide to Multi-Criteria Decision Analysis (MCDA)** (1 May 2024): https://analysisfunction.civilservice.gov.uk/policy-store/an-introductory-guide-to-mcda/
12. EFSA Scientific Committee, **The principles and methods behind EFSA's Guidance on Uncertainty Analysis in Scientific Assessment**, EFSA Journal (2018): https://doi.org/10.2903/j.efsa.2018.5122

## 11. Governance boundary

This is research and a proposed owner decision pack. It is not an approved amendment. LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 remain PENDING; RDM-U01…U05 remain UNRESOLVED until the owner records explicit dispositions. No provider, technology, jurisdiction, contract, procurement, partner integration, production data, financial activity, merge or deployment is authorized.

## 12. Change history

- 0.1.0 (2026-11-28): Initial research synthesis, policy options, conservative recommendations, proposed acceptance tests and owner-decision matrix.
- 0.2.0 (2026-11-28): Added candidate RDM-U06 after measurement-theory review of the 0–5 weighted additive model; distinguished ordinal ratings from cardinal value functions, documented mutual preferential independence, and added owner decision/acceptance requirements. No normative change adopted.
