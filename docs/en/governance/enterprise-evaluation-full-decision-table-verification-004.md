# LOT-EVAL-RDM-004 — Full Decision-Table Verification

**Document ID:** LOT-EVAL-RDM-004-001  
**Version:** 0.2.0  
**Date:** 2026-11-28  
**Status:** VERIFIED FOR THE BOUNDED FIXTURE SET — exact-head run #1225 succeeded  
**Parent:** LOT-EVAL-001 v0.3.0  
**Inputs:** LOT-EVAL-RDM-003A decision-rule catalogue v0.1.0; LOT-EVAL-RDM-001; LOT-EVAL-AVT-001 v0.2.0

## 1. Purpose and boundary

RDM-004 provides executable row-level verification for all 36 rows in DT-01…DT-05. The runner is `tools/lot_eval_rdm004.py`; it uses only the Python standard library and deterministic synthetic fixtures. It has no network, database, provider, credential, product-runtime or production-data dependency and is not imported by product code.

This is an author-led reference-model and test-oracle exercise. It is not blind review, second-person review, independent assurance, formal IV&V, legal advice, certification, owner acceptance or adoption of LOT-EVAL-001.

## 2. Frozen source and scope

The catalogue is checked against the parent standard:
- §4 — exact decision-unit tiering and highest-trigger rule;
- §7 — ten minimum non-compensable gate categories and bounded conditional experiments;
- §8.3 and §17.10.1 — evidence states, 0–5 capability anchors, N/A and NS;
- §17.10.2 — evidence authority/independence/confidence distinction;
- §17.10.3 — exact decision-unit and synthetic-test boundary;
- §17.10.4 — scenario, horizon, affected objectives, evidence/assumptions, uncertainty, inherent pair, controls/evidence, residual pair, treatment, owner and acceptance authority.

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

- **Feasible input states:** DT01-R1…R5; DT02-R1…R5; DT03-R1…R8; DT04-R1…R4 and R6…R7; DT05-R1…R7. This includes deliberately invalid or blocked requests.
- **Not acceptable as an approved decision:** DT01-R6 is unresolved; DT02-R6/R7 are blocked or rejected; DT03-R1/R9 remain NS; DT04-R1/R2 are rejected and R4 blocks definitive publication; DT05-R2…R7 are incomplete, invalid or do not credit a control.
- **Normatively unresolved:** DT04-R5 remains `UNRESOLVED_NON_MATERIAL_NS`. Passing this test means the model preserves the unresolved parent-policy question rather than inventing an aggregation rule.

These labels describe synthetic fixture outcomes, not the commercial or legal feasibility of a real provider or product.

### 3.2 Mandatory-gate register completeness

The DT-02 runner includes a closed-world ten-category minimum gate register derived from parent §7: legal authority; security and trust; privacy and data rights; integrity and correctness; financial safety; operational resilience; license and supply-chain provenance; contract and exit; product safety and user impact; evidence sufficiency. DT02-R6 removes a required category and verifies that the evaluator detects the omission. This checks register completeness only; each category still needs a decision-specific disposition and evidence. It does not decide legal applicability or validate a claimed N/A.

## 4. Cross-row and metamorphic properties

Eleven metamorphic checks are registered:
1. Adding a higher in-scope tier trigger cannot lower the selected tier.
2. Incomplete/unknown decision-unit scope cannot produce a definitive lower tier.
3. Approved N/A uses the same effective denominator for all candidates.
4. Removing a mandatory risk-record field cannot improve completeness.
5. Partial evidence cannot produce a parent capability score.
6. Conditional permission for a bounded experiment does not grant later operational permission.
7. A failed mandatory gate blocks provisional output as well as definitive selection.
8. Partial atomic coverage takes precedence over generic insufficient-evidence handling after scope mismatch is excluded.
9. Inherent and residual likelihood-impact pairs are both required and separately retained.
10. Risk anchors reject Boolean and non-integer values.
11. Risk schema rejects duplicate impact dimensions and blank evidence/assumption/control-evidence fields.

Metamorphic checks supplement row checks; they do not exhaust the input state space or establish mathematical completeness.

## 5. Targeted specification mutations

Four targeted fault injections check whether selected row oracles detect:
- lowest-tier selection instead of highest-trigger selection;
- silent acceptance of an omitted mandatory gate;
- conversion of insufficient evidence to rating 0;
- replacement of a complete risk profile by an L×I-only product.

These are hand-authored faults in this reference test module, not third-party mutation-tool output or a conventional mutation score. They do not replace the separate MUT-01…MUT-10 RDM-001 exercise.

## 6. Adversarial hardening findings and dispositions

A second author-led review of the RDM-004 implementation found three material semantic gaps despite the earlier successful CI:
- **RDM004-AR-01 — DT-03 precedence:** partial atomic coverage could be classified as NS because generic insufficiency was checked first. The evaluator now follows explicit precedence: scope mismatch → partial coverage → insufficient full-scope evidence → capability rating.
- **RDM004-AR-02 — DT-04 gate precedence:** a provisional non-selection output could be returned despite a failed other mandatory control. Mandatory-gate failure now blocks all publication paths, including provisional output.
- **RDM004-AR-03 — DT-05 risk fidelity:** the initial model checked only one likelihood-impact pair and did not explicitly require evidence/assumptions and per-dimension impact anchors. It now requires separate inherent and residual pairs, validates integer anchors (excluding booleans), requires anchored impact dimensions, and requires evidence/assumptions plus control evidence where a control is claimed.

These findings were corrected in the reference model and regression/metamorphic checks were added. They are author-led findings, not independent review. Exact-head CI run #1225 verifies the corrected code at the recorded SHA below; earlier runs #1214, #1221 and #1222 do not verify the corrected code.

## 7. Unresolved matters and explicit non-coverage

RDM-004 deliberately does not resolve RDM-U01…U05:
- definitive/provisional treatment of non-material NS;
- conditional experiment gate versus genuine N/A in a complete normative state model;
- mandatory decision-unit completeness schema;
- domain-specific qualitative likelihood calibration;
- criterion-specific measurable 1–5 anchors.

RDM-R13/R14 (evidence authority, independence and confidence), RDM-R17 (assurance-role separation) and RDM-R18 (end-to-end decision traceability) require separate human/structural verification. No RDM-004 result closes those gaps.

Synthetic values stand in for real evidence sufficiency, approval, applicability, enforceability, authority and control-operation evidence. The harness does not authenticate documents, identities, delegation, timestamps, legal status, control effectiveness or real-world risk.

## 8. Execution and acceptance record

Command:

```bash
python tools/lot_eval_rdm004.py
```

The exact-head Documentation Governance workflow runs:
1. bilingual documentation structure and local-link validation;
2. the existing RDM-001 AVT/mutation harness;
3. the RDM-004 decision-table runner.

The recorded CI run must match the exact PR head SHA. A prior-head run does not verify a later source change. Results must report row checks, metamorphic checks and targeted mutations separately.

**Exact-head verification:** Documentation Governance run #1225 (ID `46161484120`) succeeded on PR head `79751ad277968346fcd0044d74951af2a2c3301c`. The bilingual validator, existing RDM-001 harness and RDM-004 runner all completed successfully. The RDM-004 runner's exit condition requires 36/36 row checks, 10/10 metamorphic checks and 4/4 targeted mutation checks to pass. This verifies the bounded synthetic fixtures at that exact code SHA only. A passing run is bounded verification of these fixtures only; it is not proof of full matrix-property coverage, standard adequacy, independent assurance, owner approval or operational readiness.

## 9. Governance and authorization

LOT-EVAL-001 remains PROPOSED. REV-01…REV-14 owner dispositions remain PENDING unless the owner separately records a disposition. No provider, candidate, technology, jurisdiction, contract or pilot is selected. No procurement, partner integration, production data, financial activity, merge or deployment is authorized.

## 10. Change history

- 0.1.0 (2026-11-28): initial 36 row checks, six metamorphic checks and four targeted mutations.
- 0.2.0 (2026-11-28): corrected DT-03 precedence, DT-04 mandatory-gate precedence and DT-05 inherent/residual risk-pair and evidence-field modelling; expanded metamorphic checks from six to eleven; added strict dimension uniqueness and non-blank evidence validation. Exact-head CI #1225 succeeded on `79751ad277968346fcd0044d74951af2a2c3301c`.


### Subsequent schema-hardening verification

The DT05-R5 row oracle now rejects missing residual-pair values directly, rather than relying only on a mutation switch. Risk schema validation also rejects duplicate/unknown impact dimensions, malformed dimension-rating maps, blank evidence/assumption/control-evidence entries and invalid risk anchors. This adds MT-11.

Documentation Governance run #1231 (ID `46161867851`) succeeded on exact code head `2e0eadfcc2bc6200af1410197dcbeaa563e8fed0`; bilingual documentation validation, RDM-001 and RDM-004 all succeeded. RDM-004 acceptance at this code SHA requires 36/36 row checks, 11/11 metamorphic checks and 4/4 targeted mutations.
