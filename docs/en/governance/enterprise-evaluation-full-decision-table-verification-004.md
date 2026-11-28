# LOT-EVAL-RDM-004 — Full Decision-Table Verification

**Document ID:** LOT-EVAL-RDM-004-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** VERIFIED FOR THE BOUNDED FIXTURE SET — exact-head CI run #1214 succeeded  
**Parent:** LOT-EVAL-001 v0.3.0  
**Inputs:** LOT-EVAL-RDM-003A decision-rule catalogue v0.1.0; LOT-EVAL-RDM-001; LOT-EVAL-AVT-001 v0.2.0

## 1. Purpose and boundary

RDM-004 adds executable row-level verification for all 36 rows in the five decision tables DT-01…DT-05. It addresses the gap between having human-readable decision tables and having explicit executable checks for each declared row.

The runner is `tools/lot_eval_rdm004.py`. It uses only the Python standard library and deterministic synthetic fixtures. It has no network, database, provider, credential, product-runtime or production-data dependency. It is not imported by product code.

This is an author-led reference-model and test-oracle exercise. It is not blind review, second-person review, independent assurance, formal IV&V, legal advice, certification, owner acceptance or adoption of LOT-EVAL-001.

## 2. Frozen source and scope

The catalogue is checked against the parent standard's relevant provisions:
- §4 — exact decision-unit tiering and highest-trigger rule;
- §7 — non-compensable mandatory gates and bounded conditional experiments;
- §8.3 and §17.10.1 — evidence states, 0–5 capability anchors, N/A and NS semantics;
- §17.10.2 — evidence authority/independence/confidence distinction;
- §17.10.3 — exact decision-unit and synthetic-test boundary;
- §17.10.4 — complete risk-record fields, horizon and raw likelihood/impact pair.

The 36 table rows are verification obligations, not 36 independent end-to-end tests. RDM-004 does not claim complete verification of all 18 atomic rules, every parent-standard clause, all 21 AVT vectors or all possible input combinations.

## 3. Row coverage and expected disposition

| Decision table | Rows | Row-level coverage |
|---|---:|---|
| DT-01 — tier selection | 6 | T3, T2, T1, evidenced T0, specifically bounded higher-plausible tier, unbounded unknown scope |
| DT-02 — mandatory gates | 7 | Required PASS, FAIL, UNKNOWN, approved genuine N/A, conditional bounded experiment, omitted required gate, invalid gate N/A |
| DT-03 — evidence and rating | 9 | NS, ratings 0–5, Partial compound coverage, scope mismatch |
| DT-04 — N/A and publication | 7 | Late N/A, gate exclusion, approved uniform N/A and denominator, material NS, unresolved non-material NS, constrained provisional output, no-NS aggregation |
| DT-05 — risk completeness | 7 | Complete record, missing scenario, missing horizon rationale, missing impact dimensions, collapsed L×I, unsupported control effectiveness, missing other mandatory fields |
| **Total** | **36** | **Every registered table row has a stable executable ID** |

### 3.1 Row classification

- **Feasible:** DT01-R1…R5; DT02-R1…R5; DT03-R1…R8; DT04-R1…R4 and R6…R7; DT05-R1…R7. These rows represent feasible input states, including deliberately invalid or blocked requests.
- **Infeasible as an accepted decision:** DT01-R6 is unresolved rather than a valid tier assignment; DT02-R6 and R7 are blocked/rejected; DT03-R1 and R9 remain NS; DT04-R1 and R2 are rejected; DT04-R4 blocks definitive publication; DT05-R2…R7 are incomplete/invalid or do not credit a control.
- **Normatively unresolved:** DT04-R5 remains `UNRESOLVED_NON_MATERIAL_NS`. This is a passing test outcome because the model preserves the unresolved parent-policy question instead of inventing a definitive aggregation rule.

These labels describe the fixture's expected disposition, not the commercial or legal feasibility of a real supplier or product.

## 3.2 Mandatory-gate register completeness

The DT-02 runner includes a closed-world ten-category minimum gate register derived from parent §7. It detects an omitted category rather than relying only on a caller-supplied “omitted” Boolean. Each category still needs an explicit decision-specific disposition; a recorded N/A is not automatically valid without the required rationale/approval.

## 4. Cross-row and metamorphic properties

Six metamorphic checks are registered:
1. Adding a higher in-scope tier trigger cannot lower the selected tier.
2. Incomplete/unknown decision-unit scope cannot produce a definitive lower tier.
3. Approved N/A uses the same effective denominator for all candidates.
4. Removing a mandatory risk-record field cannot improve completeness.
5. Partial evidence cannot produce a parent capability score.
6. Conditional permission for a bounded experiment does not grant later operational permission.

Metamorphic checks supplement row checks; they do not exhaust the input state space or establish mathematical completeness.

## 5. Targeted specification mutations

Four targeted fault injections are used to check whether selected row oracles detect:
- lowest-tier selection instead of highest-trigger selection;
- silent acceptance of an omitted mandatory gate;
- conversion of insufficient evidence to rating 0;
- replacement of a complete risk profile by an L×I-only product.

A targeted mutation is counted as killed only when its observable result differs from the expected decision-table oracle. These are hand-authored faults in this reference test module, not third-party mutation-tool output or a conventional mutation score. They do not replace the separate MUT-01…MUT-10 RDM-001 exercise.

## 6. Unresolved matters and explicit non-coverage

RDM-004 deliberately does not resolve:
- RDM-U01: definitive/provisional treatment of non-material NS, including materiality, delegation, expiry and downstream use;
- RDM-U02: conditional experiment gate versus genuine N/A in a complete normative state model;
- RDM-U03: mandatory decision-unit completeness schema;
- RDM-U04: domain-specific qualitative likelihood calibration;
- RDM-U05: criterion-specific measurable 1–5 anchors.

The current decision tables do not directly cover every atomic rule. In particular, RDM-R13/R14 (evidence authority, independence and confidence), RDM-R17 (assurance-role separation) and RDM-R18 (end-to-end decision traceability) require separate human/structural verification. No RDM-004 result closes those gaps.

The ten-category register is a bounded encoding of the parent §7 minimum list. It does not decide applicability, legal sufficiency or whether a control is truly not applicable.

Synthetic booleans and enums stand in for real evidence sufficiency, approval, applicability, enforceability, authority and control-operation evidence. The harness does not authenticate documents, identities, delegation, timestamps, legal status, control effectiveness or real-world risk.

## 7. Execution and acceptance record

Command:

```bash
python tools/lot_eval_rdm004.py
```

The exact-head GitHub Actions Documentation Governance run must execute:
1. bilingual documentation structure and local-link validation;
2. the existing RDM-001 AVT/mutation harness;
3. the RDM-004 decision-table runner.

The recorded CI run must match the exact PR head SHA. A prior-head run does not verify a later source change. Results must report row checks, metamorphic checks and targeted mutations separately.

**Exact-head verification:** Documentation Governance run #1214 (run ID `46129536308`) succeeded on PR head `18af39533ce3a01091d0e60f3ed3df9c071699e9`. The workflow's RDM-004 execution step completed successfully: 36/36 decision-table row checks, 6/6 metamorphic checks and 4/4 targeted mutation checks passed. The same run also completed the bilingual documentation validator and the existing RDM-001 harness successfully. This evidence applies only to the exact source and fixtures at that SHA.

**Acceptance rule:** all 36 row checks, all six registered metamorphic checks and all four targeted mutation checks must pass on the exact head. A passing run is bounded verification of these fixtures only; it is not proof of full matrix-property coverage, standard adequacy, independent assurance, owner approval or operational readiness.

## 8. Governance and authorization

LOT-EVAL-001 remains PROPOSED. REV-01…REV-14 owner dispositions remain PENDING unless the owner separately records a disposition. No provider, candidate, technology, jurisdiction, contract or pilot is selected. No procurement, partner integration, production data, financial activity, merge or deployment is authorized.

## 9. Change history

- 0.1.0 (2026-11-28): first executable row-level verification for 36 decision-table rows, six metamorphic checks and four targeted specification mutations; bounded exact-head CI run #1214 succeeded on `18af39533ce3a01091d0e60f3ed3df9c071699e9`. Any later source change requires a new exact-head run.
