# LOT-EVAL-RDM-002 — Adversarial Audit of the Reference Model and Test Oracles

**Document ID:** LOT-EVAL-RDM-002  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** AUTHOR-LED ADVERSARIAL AUDIT — findings open; not independent assurance  
**Audited implementation:** `tools/lot_eval_rdm.py` at commit `90fab7c1fa6c8a3e5d40d1c97248fa067a3bf749` (file blob `90bcccf712fdfbcb8d0ff32b112435cc891e961c`)  
**Normative baseline:** LOT-EVAL-001 v0.3.0 and LOT-EVAL-AVT-001 v0.2.0 at frozen parent commit `e7aed0892a0de212fc3fd7603a6976eee503a76f`

## 1. Executive conclusion

The exact-head CI result establishes that the current Python harness executes successfully and that its 21 registered Boolean checks pass against its ten hand-coded specification mutants. It does **not** establish full execution of all expected behaviors and metamorphic properties in the 21 matrix vectors.

This audit compared the implementation and each registered test with the normative vector descriptions, not merely with the test names. It identified material gaps in tier semantics, post-score N/A sequencing, mandatory-gate completeness, candidate-uniformity testing, and execution-report integrity. Therefore, the earlier “21/21 AVT PASS” statement must be interpreted as **21 registered harness checks passed**, not “all 21 matrix vectors are fully verified.”

No production behavior is implicated: the harness is isolated, synthetic and non-production. These findings affect confidence in the reference model and the scope of its test evidence.

## 2. Findings

| ID | Severity | Finding | Evidence / consequence |
|---|---|---|---|
| RDM-AUD-01 | HIGH | Decision-unit tier boundary is not implemented in the baseline model. | `classify_tier` accepts `synthetic_isolated` but does not use it outside MUT-05. It does not model permission, real funds, identity impact, jurisdiction, or case-specific containment. AVT-06 therefore does not establish the matrix's Case A/B/C distinction or permission-change metamorphic property. |
| RDM-AUD-02 | HIGH | AVT-14 does not model event order or post-score N/A. | The fixture passes `approved_before_scoring=False` directly. Candidate score data are present but no scoring event, timestamp, frozen rubric version, N/A proposal event, or all-candidate rescore transition is represented. The test checks a Boolean guard, not the post-hoc sequence in matrix Fixture A. |
| RDM-AUD-03 | HIGH | Mandatory-gate completeness is open-world. | `score_candidates` rejects non-PASS entries supplied in `mandatory_gates`, but it has no required-gate catalogue for the decision unit. An omitted gate is indistinguishable from a non-applicable gate; an incomplete/empty map can proceed. The model must know the expected mandatory-gate set and block missing/unknown entries. |
| RDM-AUD-04 | HIGH | AVT-17 duplicates AVT-16's executable assertion. | Both invoke the same scoring fixture and assert the same denominator, effective weights and Alpha/Beta scores. AVT-17 therefore does not test the matrix's metamorphic requirement that one candidate's result remains unchanged when another candidate is added/removed, nor candidate-uniform N/A behavior under changed candidate populations. |
| RDM-AUD-05 | MEDIUM | AVT-01 implements only a subset of its metamorphic properties. | The code checks missing evidence, material NS blocking, provisional authority and non-material NS unresolved. It does not execute the controlled negative-test Fixture B, evidence-removal relation, irrelevant-evidence invariance, scope-change invalidation, or materiality-only transformation while asserting the evidence state is unchanged. |
| RDM-AUD-06 | MEDIUM | Horizon validation is syntactic, not semantic. | `risk_record` rejects an empty horizon but does not bind likelihood anchors/rationale to the horizon or prevent comparing likelihood labels derived from different horizons. AVT-10 is only a non-empty-field check. |
| RDM-AUD-07 | MEDIUM | Mutation classification fields are asserted rather than derived. | The report hard-codes equivalent/unreachable/unresolved counts as zero. The harness does not analyze equivalence or reachability; those states must be recorded as NOT ASSESSED until a defined analysis has been performed. A zero count currently overstates the evidence. |
| RDM-AUD-08 | MEDIUM | The runner does not enforce the expected test population or unique IDs. | It reports the number of registered tests, not whether the exact expected AVT-01…AVT-21 set appears once each. Duplicate semantic tests can therefore produce a nominal 21/21 result. |
| RDM-AUD-09 | MEDIUM | Evidence, control and tier inputs are simplified flags, not validated decision records. | The model does not validate source identity/provenance, authority, timestamps, evidence scope objects, operating periods, or control-test artifacts. The RDM document discloses some simplifications, but test outcomes must not be described as validation of those underlying facts. |
| RDM-AUD-10 | HIGH | Oracle independence has not been established. | The same authoring stream produced the parent revisions, matrix, reference model, tests and expected outcomes. The implementation is useful for consistency checks but cannot provide independent confirmation of its own interpretation. |

### Severity interpretation

HIGH means the gap can materially invalidate a claimed acceptance property or permit a misleading governance conclusion. MEDIUM means the test provides narrower evidence than the matrix description implies, or the report overstates what was measured. These are author-assigned review severities, not owner-approved risk ratings.

## 3. Correct interpretation of current execution evidence

- 21 registered checks executed; all returned PASS on the current harness.
- Ten hand-coded mutants were injected; all were detected by at least one registered check.
- 210 mutant/check evaluations were performed.
- This is not proof that 21 full matrix vectors, all their sub-properties, or all standard requirements were tested.
- Equivalent, unreachable and unresolved mutant populations have **not been independently classified**. The current hard-coded zero values are not valid evidence of absence.
- The earlier local/CI execution records remain valid for the code and checks actually executed; the scope statement is narrowed by this audit.

## 4. Recommended method — evidence-first, independent-oracle, multi-layer verification

The recommended method combines, rather than substitutes, the following practices:

1. **Normative decomposition:** Convert each controlling clause into atomic, uniquely identified decision rules. For each rule record inputs, preconditions, state transitions, outputs, exceptions, authority, evidence requirements, and unresolved language. Preserve a clause-to-rule-to-test trace.
2. **Decision tables and state machines:** Model tiering and mandatory gates as explicit decision tables. Model lifecycle-sensitive N/A, scoring and re-framing as event sequences, not Booleans. Freeze rubric/version before scoring; reject post-score selective changes; permit a legitimate scope change only through a separately authorized new version and uniform rescoring.
3. **Independent oracle derivation:** A second competent reviewer, not involved in writing the model or tests, independently derives expected outcomes from the frozen standard and matrix without seeing the implementation's answers. Record disagreements before adjudication. Until this is done, label all review as author-led.
4. **Example-based and boundary testing:** Retain concrete positive/negative fixtures, add boundary cases for every decision-table row and state transition, and verify missing/unknown values explicitly.
5. **Metamorphic testing:** Execute the relations already specified in the matrix: evidence removal, irrelevant evidence addition, scope changes, lifecycle-permission changes, persistence of another T3 trigger, candidate add/remove invariance, uniform N/A denominator, and compound-criterion atom changes. A relation is a test only when both transformed inputs and expected output relation are executable.
6. **Property-based and stateful testing:** Generate bounded synthetic inputs and event sequences; assert invariants after every transition. Stateful testing is particularly suitable for freeze → score → N/A proposal → reject or authorized reframe → rescore-all flows. Keep deterministic seeds/reproduction artifacts for every failure.
7. **Mutation analysis with honest accounting:** Derive mutants from normative rules, freeze a defined mutant population, and record each mutant's affected rule, expected detector, execution, kill witness, and disposition. Classify survivors, equivalent, unreachable and unresolved mutants only after analysis. Do not treat a small hand-authored mutant set as a universal quality score.
8. **Assurance case:** Structure the conclusion as claims, arguments, evidence, assumptions, context and defeaters. A passing test is evidence for a bounded claim, not the claim itself. Explicitly list what the evidence cannot establish.
9. **Risk-based independent challenge:** Prioritize mandatory gates, tier transitions, financial/identity/legal decisions and evidence-state changes. An independent reviewer must be able to select additional tests and challenge the scope without author approval.

## 5. Required invariants for RDM-003

At minimum, the next model revision must make these properties executable:

- **Evidence:** loss of required evidence can never improve a rating; irrelevant evidence cannot change a rating; scope mismatch cannot support extrapolation; materiality changes publication control, not the evidence state.
- **Tier:** highest applicable trigger governs; changing only permission/scope can re-tier; unrelated roadmap capabilities cannot change the current decision unit; unresolved plausible higher tier remains blocked/escalated.
- **Mandatory gates:** the required gate set is explicit for each decision unit; missing, unknown, failed or N/A mandatory gates cannot produce scoring eligibility; no weighted average can compensate.
- **N/A and candidates:** N/A approval precedes freeze/scoring; candidate-selective post-hoc N/A is rejected; a legitimate reframe is versioned and every candidate is rescored; adding/removing another candidate cannot alter an unchanged candidate's result; all candidates use the same criterion set and denominator.
- **Risk:** likelihood is bound to a stated horizon and rationale; raw likelihood/impact pairs and dimensions remain distinct; control credit requires scope-matched operating evidence.
- **Compound criteria:** every required atom is independently evidenced; parent pass requires all required atoms; no scope expansion.
- **Harness integrity:** exact expected AVT IDs occur once; no duplicate registration; expected mutant IDs are explicit; unknown tests/mutants fail closed; unassessed mutant categories are reported as NOT ASSESSED, not zero.

## 6. Implementation sequence and exit criteria

**RDM-003A — Specification reconstruction:** Produce an EN/FA decision-rule catalogue and decision tables from the frozen parent. Mark ambiguous clauses unresolved; do not invent rules.

**RDM-003B — Independent oracle pack:** Have a second reviewer derive expected results for all atomic assertions and metamorphic relations. Record reviewer identity/competence and conflict declarations in the assurance record, not in public project docs unless approved.

**RDM-003C — Model and harness correction:** Implement explicit decision-unit/tier and mandatory-gate schemas; event-sourced N/A/scoring state machine; unique test registry; metamorphic/property-based tests; truthful mutation accounting.

**RDM-003D — Adversarial execution:** Execute baseline, transformed fixtures, stateful sequences and the frozen mutant population. Preserve full JSON output, source hash, Python version, exact command and CI run.

**RDM-003E — Assurance and owner disposition:** Produce a bounded assurance case with claims/evidence/assumptions/defeaters. Keep owner decisions PENDING until explicitly recorded. Independent assurance remains separate.

Exit requires: all HIGH findings corrected or explicitly blocked by unresolved normative ambiguity; every matrix property either executed or marked NOT EXECUTED with reason; no duplicate/missing test IDs; mandatory-gate omissions fail closed; metamorphic and state-transition tests pass; mutation categories honestly classified; bilingual semantic parity checked; exact-head CI passes; independent review is recorded if an independence claim is made.

## 7. Research basis

- Barr et al. (2015), *The Oracle Problem in Software Testing: A Survey*, IEEE Transactions on Software Engineering 41(5), 507–525, DOI: 10.1109/TSE.2014.2372785. Covers specification/model/contract/metamorphic oracles and the continuing role of human domain judgment.
- Segura et al. (2016), *A Survey on Metamorphic Testing*, IEEE Transactions on Software Engineering 42(9), 805–824. Explains metamorphic relations when direct expected outputs are difficult to define.
- Catal et al. (2022), *Metamorphic relation automation: Rationale, challenges, and solution directions*, Journal of Software: Evolution and Process 35(1), e2509, DOI: 10.1002/smr.2509. Systematic review noting expert knowledge and relation design costs.
- ISO/IEC/IEEE 29119-4:2021, test-design techniques; it defines techniques, not a substitute for a complete test process.
- NIST IR 8397 (2021), minimum developer verification techniques, including threat modeling, automated consistency tests, black-box and structural tests, historical tests and fuzzing.
- Petrović et al. (2022), *Practical Mutation Testing at Scale: A view from Google*, IEEE TSE 48(10), 3900–3912, DOI: 10.1109/TSE.2021.3107634. Supports incremental, context-aware and actionable mutation selection, not simplistic score maximization.
- NASA-STD-8739.8B and NASA IV&V guidance: distinguish technical, managerial and financial independence; IV&V practitioners must not be the developers of the system they independently assess.
- ISO/IEC/IEEE 15026-2:2022, assurance-case structure and terminology for claims, argument and evidence.

These references inform the method; they do not imply Lottorito conformity, certification or adoption of any external standard.

## 8. Governance boundary

This report is author-led adversarial analysis, not independent assurance, legal advice, certification or owner acceptance. LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 remain PENDING. No supplier, candidate, jurisdiction, contract, procurement, partner integration, production data, financial activity, merge or deployment is approved.
