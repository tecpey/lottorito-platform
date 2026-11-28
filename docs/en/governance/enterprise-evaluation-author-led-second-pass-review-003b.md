# LOT-EVAL-RDM-003B — Author-led adversarial second-pass review

**Document ID:** LOT-EVAL-RDM-003B-AR-001  
**Version:** 0.1.0  
**Review date:** 2026-11-28  
**Status:** REVIEW COMPLETED — corrective changes committed; exact-head CI #1195 SUCCESS  
**Reviewer role:** Author-led second-pass adversarial reviewer, deliberately separated from implementation-author perspective  
**Independence statement:** The reviewer is the same AI system that authored prior artifacts and has access to prior outputs. This is not blind review, a second-person review, formal IV&V, independent assurance, certification or owner acceptance.

## 1. Scope and method

Reviewed against the frozen source snapshot `4443ef5336935310f034419d72967dec3d86a21a`:
- Parent standard v0.3.0 (EN/FA).
- AVT matrix v0.2.0 (EN/FA).
- RDM-003A rule catalogue v0.1.0 (EN/FA).
- RDM-001 Python reference model and its registered AVT checks.
- RDM-003B packet and worksheet (EN/FA).

The review deliberately challenged the prior work product rather than accepting its conclusions. It inspected source clauses, table conditions, test inputs, code paths, bilingual identifier populations and claimed coverage. Findings below are not claims of independent assurance.

## 2. Findings

| ID | Severity | Finding | Evidence / impact | Required disposition |
|---|---|---|---|---|
| AR-01 | HIGH | RDM-003B is labelled blind/independent although the author-reviewer has prior access to all derived outputs. | The same AI system authored RDM-003A/RDM-001 and now reviews them. A blind-oracle claim would be false. | Reclassify as author-led second-pass adversarial review; explicitly disclose prior access and prohibit claims of blind review, second-person independence or IV&V. |
| AR-02 | HIGH | The 35 decision-table rows are not independently reviewable from the packet/worksheet. | The worksheet lists only row IDs and table names; the packet withholds RDM-003A and does not provide sanitized row-condition inputs. A reviewer cannot classify or derive an oracle for those rows. | Provide input-only condition columns for all 35 rows, withholding expected outputs; then record the author-led derivation separately. |
| AR-03 | HIGH | Unresolved higher-tier handling over-escalates to T3. | `classify_tier()` appends T3 whenever a boolean says a higher tier is plausible. §4 requires the highest plausible tier; that could be T2, not necessarily T3. AVT-09 does not specify which tier is plausible. | Replace the boolean with an explicit validated highest-plausible-tier input; update AVT-09 to specify a T2 example and add a T3 example or boundary check. |
| AR-04 | HIGH | Evidence state and capability rating are conflated; Partial coverage is lost. | `evidence_rating()` returns state `NS` for partial/unknown/insufficient while §8.3 distinguishes evidence states (including Partial) from rating 0–5/NS. | Represent evidence state and capability rating as separate fields. Partial evidence must remain Partial; unsupported atomic ratings remain NS. |
| AR-05 | HIGH | AVT-17 is not independently implemented in the harness. | Its registered function duplicates AVT-16's N/A arithmetic and does not test ranking sensitivity or invariance when candidate evidence is added/removed. | Implement a distinct metamorphic/ranking test or mark AVT-17 unimplemented/blocked. Do not count it as an independent executed check until fixed. |
| AR-06 | MEDIUM | Empty candidate input can return a successful SCORED result. | `score_candidates()` does not reject an empty candidate map after gate/weight validation. | Reject an empty candidate population with a non-success state and add a regression test. |
| AR-07 | MEDIUM | Negative weights can pass the 100-point total check. | A malformed weight vector containing negative and positive values may sum to 100 and proceed. | Validate every weight as a non-negative integer, reject negative values, and require a positive effective denominator. |
| AR-08 | MEDIUM | Unknown tier trigger values can be silently ignored. | `classify_tier()` filters unknown trigger strings and may return a lower tier from the remaining valid triggers. | Reject invalid trigger values as invalid/unresolved input; never silently discard a potentially material trigger. |
| AR-09 | MEDIUM | An empty compound-criterion atom set can pass vacuously. | `compound_criterion()` compares two empty sets as equal and can return parent_pass=true. | Require at least one required atom and reject duplicate/empty atom identifiers. |
| AR-10 | MEDIUM | Aggregate authority is represented by a non-empty string token only. | The model treats any string as authority and returns PROVISIONAL even with material NS. The harness explicitly says authority is synthetic, but the test can be misread as validating authority. | Rename the input as a synthetic authorization fixture; require explicit structured attributes in the reference model or keep the result UNRESOLVED pending owner policy. Do not imply the harness authenticates authority. |
| AR-11 | MEDIUM | DT-04 rows have overlapping conditions without explicit multi-axis/precedence semantics. | DT04-R5 (material NS) and DT04-R7 (any NS) overlap; DT04-R6 and DT04-R7 also overlap for non-material NS. | Define outcome dimensions separately (definitive publication, provisional informational output, selection eligibility) and make row conditions mutually exclusive or specify precedence. |
| AR-12 | MEDIUM | “74 entries” mixes different coverage units. | 18 rule propositions + 21 AVT scenarios + 35 table rows are not 74 independent tests; rules and rows overlap with AVT coverage. | Report counts by unit and call 74 a review-obligation inventory, not test count or independent coverage. |
| AR-13 | MEDIUM | AVT-14 does not model the claimed post-score event sequence. | The harness only receives `approved_before_scoring=False`; it does not model score visibility, event order, or selective candidate scope. | Either add explicit state/sequence inputs and a metamorphic check or narrow the claim to “late approval flag rejected.” |
| AR-14 | MEDIUM | AVT-06 does not exercise both T1 and T2 independent triggers for a bounded synthetic test. | The matrix describes independent T1/T2/T3 triggers; the harness tests only a T1 trigger. | Add a T2 case or narrow the test claim; ensure the synthetic boundary does not suppress a real T2 trigger. |
| AR-15 | LOW | RDM-R17 traceability contains the ambiguous note “AVT-21? none direct.” | AVT-21 concerns compound-criterion dependencies, not assurance-role separation. | Replace with “No direct AVT mapping; human governance review required.” |

## 3. Coverage and execution interpretation

The previous CI output of 21 registered checks passing, 10/10 hand-authored specification mutants killed and 210 mutant/check evaluations is reproducible evidence only for the registered harness population. It does not demonstrate:
- 21 unique semantic properties (AVT-17 is duplicated);
- coverage of all 35 decision-table rows;
- full execution of all 18 atomic rules;
- an independent oracle;
- exhaustive state-space or property coverage;
- correctness of the parent standard or owner policy.

Until AR-03…AR-10 are corrected and retested, the existing RDM-001 execution result must be treated as a historical baseline, not current acceptance evidence. No conventional mutation score is claimed.

## 4. Disposition and next sequence

1. Reclassify RDM-003B from blind external review to author-led second-pass review; preserve the original documents as superseded history.
2. Correct the input package so all 35 decision-table row conditions are available without expected outputs.
3. Resolve AR-03…AR-10 in the reference model and add direct regression tests.
4. Resolve AR-11…AR-15 in the tables, AVT definitions and traceability.
5. Re-run bilingual parity checks and exact-head CI.
6. Update the PR description with the precise limitations and finding dispositions.

RDM-001 may be changed only as a controlled correction against this recorded author-led review. This does not approve LOT-EVAL-001, REV-01…REV-14, any candidate, procurement, integration, production data, financial activity, merge or deployment. Owner decisions remain with the project owner.

## 5. Corrective disposition and additional row-level findings

The owner-directed review supersedes the external blind-review protocol. The old packet/worksheet are retained as historical artifacts; the missing input-only 35-row packet is therefore closed by supersession, not by claiming a blind review occurred. The author reviewed the actual decision-table conditions directly against the frozen parent standard.

Additional findings from full row-level inspection:
- **AR-16 — MEDIUM, DT-01 overlap:** DT01-R5 (a specifically identified highest plausible tier) and DT01-R6 (unbounded/all-unknown tier inputs) were not mutually exclusive. Corrected by distinguishing a bounded highest plausible tier from an unbounded uncertainty state.
- **AR-17 — MEDIUM, DT-03 precedence:** scope mismatch, partial atomic coverage and insufficient full-scope evidence could overlap without an explicit decision order. Corrected with explicit precedence: scope mismatch → partial atoms → otherwise insufficient full-scope evidence → capability anchor only on sufficient full-scope evidence.
- **AR-18 — MEDIUM, DT-05 incomplete record schema:** the “complete” row did not require affected objectives, evidence/assumptions, uncertainty, treatment, risk owner and acceptance authority. Added those mandatory fields and DT05-R7 for missing fields. DT-05 now has seven rows; the five tables contain **36 decision-table rows** in total.

Corrective disposition:
- AR-01: CLOSED — packet/worksheet reclassified as superseded historical artifacts; no blind/independent claim.
- AR-02: CLOSED BY SUPERSESSION — no external reviewer workflow remains active; author-led review used the actual source tables. This does not create independent assurance.
- AR-03…AR-10: CORRECTED IN RDM-001; regression checks added.
- AR-11: CORRECTED — DT-04 conditions and outcomes are now explicit and non-overlapping by materiality/authorization state.
- AR-12: CLARIFIED — current inventory is 18 rule propositions + 21 AVT scenarios + 36 decision-table rows = 75 review obligations, not 75 independent tests.
- AR-13…AR-15: CORRECTED — late-score N/A state, T1/T2 synthetic triggers and assurance-role traceability clarified.
- AR-16…AR-18: CORRECTED — DT-01, DT-03 and DT-05 row-level defects fixed in both languages.

**Latest exact-head verification:** Documentation Governance run #1202 (ID `46123183828`) passed on head `2dd02e5fd4b06d46c995ee1e934053d15987c001`: 67 bilingual Markdown pairs, 172 local links, 21/21 AVT checks, 8/8 model guards, 10/10 hand-authored mutants killed and 210 AVT mutant/check evaluations; zero failures and zero surviving mutants. This is structural and registered-harness evidence only, not complete matrix-property coverage or independent assurance.
