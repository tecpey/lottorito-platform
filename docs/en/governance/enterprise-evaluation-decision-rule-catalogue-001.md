# LOT-EVAL-RDM-003A — Normative Rule Catalogue & Decision Tables

**Document ID:** LOT-EVAL-RDM-003A  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** AUTHOR-LED ANALYSIS — proposed; independent oracle review and owner disposition pending  
**Parent:** LOT-EVAL-001 v0.3.0  
**Related:** LOT-EVAL-AVT-001 v0.2.0; LOT-EVAL-RDM-001; LOT-EVAL-RDM-002

## 1. Purpose and limits

This document decomposes selected normative provisions of LOT-EVAL-001 into atomic, traceable decision rules and human-reviewable decision tables. It is the first RDM-003A design artifact, not a replacement for the parent standard, an adopted policy, an executable evaluator, an independent oracle, legal advice, or an approval.

The catalogue deliberately separates:

- **N — Normative:** directly stated by LOT-EVAL-001 v0.3.0.
- **D — Derived guard:** a conservative operational guard needed to avoid an invalid inference from the normative text. It must be confirmed by the owner before it becomes binding policy.
- **U — Unresolved:** the parent text does not define a deterministic outcome sufficiently. The evaluator must stop or expose the ambiguity; it must not invent a default.

No U rule may be silently converted into PASS, FAIL, 0, N/A, a lower tier, or a definitive aggregate.

## 2. Method and traceability contract

The method follows a requirements-to-verification chain:

1. Freeze the parent-standard version and source sections.
2. Extract one atomic proposition per rule; preserve modal force (must / must not / may).
3. Identify decision inputs, preconditions, output, blocked conditions and authority.
4. Enumerate feasible condition combinations in an extended-entry decision table.
5. Mark infeasible combinations explicitly; do not use “don't care” to hide an unknown.
6. Link every rule to one or more test obligations and expected observable outputs.
7. Independently derive expected outputs before comparing them with the reference implementation.
8. Keep unresolved wording as a decision issue, not a guessed test oracle.

**Traceability invariant:** every normative rule has a parent clause; every decision-table rule has at least one rule ID; every future test has an expected result and a source rule; every implementation branch must trace back to a rule; every rule must be reachable from at least one test or be explicitly justified as inspection/analysis-only.

### Rule-status vocabulary

| Status | Meaning | Permitted treatment |
|---|---|---|
| NORMATIVE | Directly supported by parent text | May be encoded only after independent oracle review |
| DERIVED-GUARD | Conservative guard against unsafe inference | Proposed; owner confirmation required before binding use |
| UNRESOLVED | Text does not uniquely determine outcome | Stop, disclose, obtain authoritative clarification |
| OUT-OF-SCOPE | Not addressed by this catalogue | No inference; create a separate rule package |

## 3. Atomic rule register

| Rule ID | Class | Source | Atomic rule / expected decision | Block or escalation condition |
|---|---|---|---|---|
| RDM-R01 | N + D | §2.1, §4 | Bind every evaluation to the exact decision unit: capability, decision type, domain, entity, jurisdiction, operating model, tenant/deployment, data, funds/transaction path, users and lifecycle permission. | Missing scope fields that could change a tier or gate make the decision unresolved; if a higher tier is plausible, retain the higher plausible tier (§4). |
| RDM-R02 | N | §4, §17.10.3 | Determine tier from the exact requested decision unit and permission; apply the highest triggered tier, never an average. | Any in-scope T3 trigger forces T3. Unresolved higher-tier plausibility prevents selecting a lower tier. |
| RDM-R03 | N | §4, §17.10.3 | A bounded synthetic experiment is classified on its own actual scope; it is not automatically T3 or T0. Evaluate independent T1/T2/T3 triggers. | Missing containment facts, real funds/users, production access, partner connection or regulated activity require scope clarification and re-tiering. |
| RDM-R04 | N | §7 | A failed or unknown mandatory gate cannot be compensated by a weighted score. | Any required gate Fail or Unknown blocks eligibility for the corresponding activity. |
| RDM-R05 | N + D | §7; AVT-15 | N/A cannot be used to erase a mandatory gate. A bounded non-production experiment may be conditional only where the control is not needed for that experiment and the restriction is enforceable. | Gate N/A requires control-owner rationale and a re-framed, versioned decision unit where applicability genuinely changes; no post-score gate removal. |
| RDM-R06 | N | §8.3, §17.10.1 | Evidence sufficiency and capability rating are separate. Missing, inaccessible, contradictory, expired, out-of-scope or insufficient evidence produces NS, never 0 or neutral. | A numeric capability rating without sufficient full-scope evidence is invalid. |
| RDM-R07 | N | §8.3 | Rating 0 requires sufficient, scope-matched evidence demonstrating absent or unacceptable capability. Ratings 1–5 must satisfy their anchored definitions. | Supplier assertion, unverified demo or missing documentation alone cannot justify 0 or a favorable score. |
| RDM-R08 | N | §8.3, §17.10.1 | Split compound criteria into atomic subcriteria. Unsupported atoms remain NS; evidence cannot be generalized beyond its evidenced entity/version/configuration/environment/jurisdiction/population. | Parent criterion cannot pass unless all required atoms are supported for the requested scope. |
| RDM-R09 | N | §8.3, §17.10.1 | N/A is permitted only when genuinely inapplicable, with written rationale and accountable control-owner approval before scoring. | N/A after scores are visible is invalid for that round; a legitimate scope change requires versioned re-baseline and uniform rescoring. |
| RDM-R10 | N | §8.3 | Applicable original weights total 100 before exclusions; show original/effective weights and denominator; normalize only over approved remaining applicable criteria. | Hidden denominator, candidate-selective exclusion, or candidate-specific rubric blocks comparison. |
| RDM-R11 | N + U | §8.3, §17.10.1; AVT-01 | Material NS blocks a definitive aggregate/rank. Non-material NS must remain visible. | The standard does not fully define when/how a definitive or provisional aggregate with non-material NS is permitted; no default is encoded. |
| RDM-R12 | N + U | §8.3, §17.10.1 | Any provisional aggregate requires a separately recorded authority decision and disclosure of NS, denominator, limitations and authority. | The parent text does not fully specify authority delegation, materiality test, minimum disclosure schema, expiry or permissible downstream use. Until clarified, do not treat provisional output as selection/approval. |
| RDM-R13 | N | §5.1, §17.10.2 | Record evidence authority, independence, directness, scope, freshness, reproducibility, provenance, limitations and conflicts as separate attributes. | A source authoritative for one claim is not automatically authoritative for another; source authority does not imply independence. |
| RDM-R14 | N | §5.2, §17.10.2 | Confidence is High/Medium/Low with rationale and remains separate from capability rating; do not average it or multiply it into score. | Low confidence cannot support a favorable definitive conclusion on a material claim. |
| RDM-R15 | N | §17.10.4 | Each risk record includes scenario, horizon, affected objectives, evidence/assumptions, uncertainty, inherent and residual likelihood-impact pairs, control evidence, treatment, owner and acceptance authority. | Missing horizon-specific likelihood rationale or missing raw pair makes the risk record incomplete. |
| RDM-R16 | N | §17.10.4 | Preserve likelihood and impact separately by relevant dimensions; ordinal L×I is not expected loss or calibrated quantitative risk. | A scalar product cannot replace scenario, pair, dimensions or uncertainty. |
| RDM-R17 | N | §17.10.6 | Owner review, specialist challenge, supplier assurance and independent assurance are distinct. | Author-led review or CI cannot be represented as independent assurance. |
| RDM-R18 | D | §4, §7, §8.3, §17.10 | Decision outputs must carry exact decision-unit version, source-standard version, rule IDs, evidence references, authority and limitations. | Missing traceability prevents a reproducible decision; this is a proposed control for owner confirmation. |

## 4. Decision Table DT-01 — tier selection

**Input domain:** exact decision unit and requested permission. “Unknown” is not equivalent to “false”.

| Rule | Any T3 trigger? | T2 trigger? | T1 trigger? | Higher tier plausibly unresolved? | Bounded synthetic test? | Expected output |
|---|---|---|---|---|---|---|
| DT01-R1 | Yes | – | – | – | Any | T3 |
| DT01-R2 | No | Yes | – | – | Any | T2 |
| DT01-R3 | No | No | Yes | No | Any | T1 |
| DT01-R4 | No | No | No | No | Any | T0 only if every §4 T0 condition is evidenced for the exact decision unit |
| DT01-R5 | No/Unknown | Any | Any | Yes | Any | Highest plausible tier pending resolution |
| DT01-R6 | Unknown | Unknown | Unknown | Unknown | Unknown | UNRESOLVED; do not default to T0 |

Notes:
- “Bounded synthetic test” is not a tier by itself. It only prevents automatic inheritance of a future operational T3 permission.
- An independent T1/T2/T3 trigger still applies to the test's actual scope.
- This table is a compact decision aid; §4 remains the sole canonical trigger catalogue.

## 5. Decision Table DT-02 — mandatory gate disposition

Each gate must first be classified as required/applicable for the named decision unit by the accountable control owner. A missing gate record is not N/A.

| Rule | Applicability | Gate result | Written control-owner rationale | Enforceable bounded non-production restriction | Expected disposition |
|---|---|---|---|---|---|
| DT02-R1 | Required | PASS | Not needed | Any | Gate satisfied for exact scope only |
| DT02-R2 | Required | FAIL | Any | Any | BLOCK corresponding activity |
| DT02-R3 | Required | UNKNOWN / missing evidence | Any | Any | BLOCK corresponding activity |
| DT02-R4 | Genuinely not applicable after scope review | N/A | Present and approved before decision | Not required | N/A recorded; scope and reason retained |
| DT02-R5 | Control is needed only for later operational permission, not this bounded experiment | Conditional | Present; restriction and stop condition enforceable | Yes | Conditional for experiment only; later permission remains blocked |
| DT02-R6 | Required gate omitted from record | Missing | Absent | Any | BLOCK; incomplete gate register |
| DT02-R7 | Required gate marked N/A to improve eligibility | Required | Invalid/absent | Any | Reject N/A; gate remains required |

Open interpretation: §7 allows a gate to be conditional for a bounded experiment under stated constraints, while AVT-15 rejects marking a mandatory legal/security/financial gate N/A unless the decision unit is reframed with authorized rationale. This catalogue interprets the safe path as **reframing the decision unit before evaluation**, not changing gate status after results. Owner confirmation is required.

## 6. Decision Table DT-03 — evidence state and capability rating

| Rule | Evidence sufficient for full atomic scope? | Demonstrated capability result | Evidence freshness/scope/contradiction | Expected evidence state | Expected capability |
|---|---|---|---|---|---|
| DT03-R1 | No | Unknown / not demonstrated | Missing, stale, contradictory or out of scope | Unknown / Insufficient | NS |
| DT03-R2 | Yes | Absent / unacceptable | Current and scope-matched | Sufficient | 0 |
| DT03-R3 | Yes | Severe gap below minimum | Current and scope-matched | Sufficient | 1 |
| DT03-R4 | Yes | Partial capability with material limits | Current and scope-matched | Sufficient | 2 |
| DT03-R5 | Yes | Predefined threshold met | Current and scope-matched | Sufficient | 3 |
| DT03-R6 | Yes | Materially above requirement | Strong, current, reproducible | Sufficient | 4 |
| DT03-R7 | Yes | Exceptional repeatable performance | Strong/repeatable; independent corroboration where warranted | Sufficient | 5 |
| DT03-R8 | Partial atomic coverage only | Parent compound criterion not fully supported | Some atoms unsupported | Partial at parent / atom-level states retained | Unsupported atoms NS; no parent pass |
| DT03-R9 | Yes for one scope only | Claim requested for wider scope | Scope mismatch | NS for unsupported scope | No extrapolated rating |

The table does not convert an evidence state to a score mechanically. The capability anchor must be defined in the frozen criterion before evidence is evaluated.

## 7. Decision Table DT-04 — N/A and aggregate publication

Evaluate this table only after the N/A decision has passed the prior-approval and mandatory-gate checks. Rows DT04-R5…R7 are mutually exclusive by the final two columns.

| Rule | N/A valid and pre-score? | Mandatory gate excluded? | NS present? | NS material? | Complete provisional authorization fixture? | Expected outcome |
|---|---|---|---|---|---|---|
| DT04-R1 | No | Any | Any | Any | Any | Reject for current round; versioned re-baseline and uniform rescoring if scope legitimately changes |
| DT04-R2 | Yes | Yes | Any | Any | Any | Reject N/A; gate remains applicable |
| DT04-R3 | Yes | No | No | – | Any | Apply uniform approved exclusion; show original/effective weights and denominator |
| DT04-R4 | Yes | No | Yes | Yes | No | No definitive aggregate/rank; any provisional output remains unresolved absent the separate authority path |
| DT04-R5 | Yes | No | Yes | No | No | UNRESOLVED; do not infer a definitive non-material-NS rule |
| DT04-R6 | Yes | No | Yes | Any | Yes | Provisional non-selection information only; disclose NS, materiality, denominator, scope, authority, expiry and permitted use |
| DT04-R7 | Yes | No | No | – | Any | No NS publication restriction; weighted aggregation may proceed only if all other gates and rubric controls pass |

**Arithmetic guard:** applicable original weights must total 100 before N/A exclusions. The same approved exclusions and denominator apply to every candidate in the decision unit. No candidate-specific N/A. A provisional result under DT04-R6 is not a candidate ranking, selection or approval.

## 8. Decision Table DT-05 — risk record completeness

| Rule | Scenario | Horizon-specific likelihood rationale | Impact dimensions and rationale | Inherent/residual pair | Control operating evidence | Expected outcome |
|---|---|---|---|---|---|---|
| DT05-R1 | Present | Present | Present | Both preserved | Present / not applicable with rationale | Complete for review, subject to authority and evidence quality |
| DT05-R2 | Missing | Any | Any | Any | Any | Incomplete |
| DT05-R3 | Present | Missing or not tied to horizon | Any | Any | Any | Incomplete; likelihood cannot be compared as if horizon-matched |
| DT05-R4 | Present | Present | Missing | Any | Any | Incomplete; impact profile hidden |
| DT05-R5 | Present | Present | Present | Collapsed to L×I only | Any | Invalid representation |
| DT05-R6 | Present | Present | Present | Preserved | Claimed control without operating evidence | Do not credit control as effective; preserve uncertainty |

## 9. Ambiguity and decision-issue register

| Issue ID | Parent text / conflict | Why a unique oracle is not yet justified | Safe interim treatment | Required resolution |
|---|---|---|---|---|
| RDM-U01 | §8.3 and §17.10.1: material NS blocks definitive aggregate; non-material NS may be provisional under separately recorded authority | No complete materiality test, authority/delegation rule, denominator treatment, expiry, downstream-use restriction or distinction between provisional aggregate and rank is specified | Preserve NS; do not publish a definitive rank; any provisional output remains non-selection information and requires explicit owner-authorized case decision | Owner-approved policy amendment defining materiality, authority, disclosure, expiry and permitted use |
| RDM-U02 | §7 conditional gate vs AVT-15 mandatory-gate N/A | Conditional experiment scope and genuine non-applicability are distinct, but parent text does not provide a full state model | Reframe exact decision unit before evaluation; never erase gate after scoring | Owner/control-owner confirmation and updated normative text |
| RDM-U03 | §4 T0 wording vs decision-unit scope completeness | Missing facts can conceal a higher trigger; the standard says use higher tier where higher tier plausible, but does not enumerate minimum completeness schema | Missing scope that can affect tier => unresolved/higher plausible tier | Approve mandatory decision-unit schema and missing-field handling |
| RDM-U04 | §17.10.4 proposed likelihood anchors | Qualitative categories are not calibrated probabilities; boundary examples and reference-class evidence are not prescribed | Treat as ordinal, horizon-bound judgments; do not convert to percentages | Owner-approved calibration guidance for each decision domain if quantitative use is ever proposed |
| RDM-U05 | §8.3 rating anchors 1–5 | Anchor 1/2/4/5 still require criterion-specific measurable acceptance thresholds and context | Freeze criterion-specific anchors before candidate evidence is seen; do not automate from generic labels | Add per-domain criterion templates and scoring examples |

## 10. Rule-to-test traceability baseline

| Rule family | Existing AVT mapping | Coverage statement at RDM-003A |
|---|---|---|
| RDM-R01…R03 tier | AVT-06…AVT-09 | Matrix scenarios exist; RDM-001 does not yet implement the full decision-unit/permission truth table |
| RDM-R04…R05 gates | AVT-07, AVT-08, AVT-15 | Current RDM has no closed-world mandatory-gate catalogue |
| RDM-R06…R08 evidence / atomic scope | AVT-01…AVT-05, AVT-18…AVT-21 | Current checks cover only subsets; full metamorphic and scope invariants remain outstanding |
| RDM-R09…R12 N/A / aggregate | AVT-01, AVT-14…AVT-17 | AVT-14 models a visible-score/late-request condition; AVT-17 is a distinct before/after ranking-sensitivity fixture. Full metamorphic coverage remains bounded to these fixtures |
| RDM-R13…R14 evidence authority / confidence | Not directly covered | Inspection/review and new tests required; do not infer automated coverage |
| RDM-R15…R16 risk | AVT-10…AVT-13 | Horizon test is syntactic; scenario and raw-pair checks are partial |
| RDM-R17 assurance roles | No direct AVT mapping | No executable acceptance vector; require human governance review; AVT-21 is unrelated and must not be cited |
| RDM-R18 traceability | Matrix protocol / CI structure | Requires bidirectional trace audit; CI link checks alone do not prove semantic traceability |

## 11. Acceptance criteria for RDM-003A

This artifact is ready for independent review only when the following are completed:

- [ ] A competent second reviewer independently derives expected outcomes from LOT-EVAL-001 v0.3.0 without seeing the model's expected outputs.
- [ ] Every rule's modal force and source clause are confirmed.
- [ ] Every table combination is classified feasible, infeasible or unresolved; no implicit don't-care is used for unknowns.
- [ ] All unresolved issues are adjudicated by the appropriate owner/control authority or remain explicitly blocked.
- [ ] Persian/English semantic parity is reviewed by a bilingual technical reviewer.
- [ ] The RDM-001 model is not changed until the independent oracle baseline is frozen.

## 12. Research basis

- ISO/IEC/IEEE 29119-4:2021, *Software testing — Part 4: Test techniques*. Defines test design techniques, including decision-table techniques; official ISO/IEEE/IEC descriptions: https://www.iso.org/standard/79430.html and https://standards.ieee.org/ieee/29119-4/7500/
- ISTQB CTFL Syllabus v4.0.1 (2024), §§4.2.3–4.2.4. Decision tables cover feasible condition combinations and help expose gaps/contradictions; state-transition tables explicitly represent invalid transitions: https://istqb.org/wp-content/uploads/2024/11/ISTQB_CTFL_Syllabus_v4.0.1.pdf
- NASA Software Engineering Handbook, SWE-114. Test procedures should state IDs, requirements, preconditions, inputs, steps, expected results, evaluation criteria, traceability and configuration: https://swehb.nasa.gov/pages/viewpage.action?pageId=23201211
- NASA NPR 7150.2B, SWE-072. Requires bidirectional traceability between software test procedures and requirements: https://nodis3.gsfc.nasa.gov/displayAll.cfm?Internal_ID=N_PR_7150_002B_&page_name=ALL
- NIST SP 800-160 Vol. 1 Rev. 1 (2022), *Engineering Trustworthy Secure Systems*. Supports requirements decomposition, objective verification evidence and traceability as support for assurance claims: https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final

These sources inform the method. They do not certify LOT-EVAL-001 or establish compliance with any external standard.

## 13. Governance boundary

This is author-led decomposition. No independent oracle has been obtained; no owner disposition is implied. LOT-EVAL-001 remains PROPOSED and REV-01…REV-14 remain PENDING. No provider, technology, jurisdiction, contract, procurement, production data, partner integration, financial activity, merge or deployment is authorized.

## 14. Change history

- 0.1.0 (2026-11-28): Initial normative rule decomposition, five decision tables, ambiguity register and rule-to-test traceability baseline. Proposed; independent review and owner disposition pending.
