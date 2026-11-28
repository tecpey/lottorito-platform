# LOT-EVAL-001 — Adversarial Acceptance Test Matrix

**Document ID:** LOT-EVAL-AVT-001  
**Version:** 0.2.0  
**Date:** 2026-11-28  
**Status:** PROPOSED — test design only; execution and owner disposition pending  
**Parent:** LOT-EVAL-001 v0.3.0, §§4, 8.3, 17.10.1–17.10.7; related lifecycle and governance provisions in §§17.1–17.3  
**Scope:** REV-01, REV-03, REV-04, REV-12 and REV-14  
**Authority:** This matrix defines falsifiable acceptance tests. It does not approve the parent standard, a risk appetite, a scorecard, a candidate, procurement, production use or residual-risk acceptance.

## 1. Purpose and test discipline

This matrix converts five high-consequence methodological revisions into explicit adversarial test vectors. It is intended to detect ambiguity, inconsistent interpretation, gaming and unsafe decision outcomes before LOT-EVAL-001 is considered for adoption.

Use specification-based decision tables, equivalence partitions, boundary-value analysis, scenario testing and metamorphic relations. These techniques are consistent with the test-design vocabulary in ISO/IEC/IEEE 29119; NIST IR 8397 also recommends threat modeling, automated consistency checks, black-box and structural test cases, historical tests and fuzzing as appropriate verification techniques. NIST IR 8286A Rev. 1 supports scenario-based risk records with likelihood, impact, roles and response context. These references inform test design; they do not certify this matrix or Lottorito.

### 1.1 Evidence and execution labels

Each test has one of these states:

- **DESIGNED:** the test vector and expected oracle are specified.
- **DOCUMENT-REVIEWED:** a reviewer has checked the relevant wording against the oracle and recorded the exact document version/lines.
- **EXECUTED:** the test was run against a named implementation or controlled evaluation record; inputs, outputs and artifacts are retained.
- **FAILED:** observed output violates the oracle.
- **BLOCKED:** the test cannot be run because required evidence, authority, environment or a decision record is absent.
- **NOT APPLICABLE:** the test is genuinely outside the named scope, with an approved rationale.

A prose example is not an executed test. A CI documentation pass is not a semantic acceptance test. A test result applies only to the tested document version, decision unit, data, evaluator instructions and environment.

**Current status at creation:** all vectors below are **DESIGNED**. No execution, independent assurance or owner disposition is claimed.

### 1.2 Required test record

For every executed test retain: test ID and version; parent-standard commit SHA and file hash; evaluator and reviewer; decision-unit fixture; exact inputs and evidence references; expected oracle; observed result; rationale for any deviation; timestamp; artifacts; defects; retest reference; and limitations. Redact secrets and personal data. Use synthetic fixtures only.

## 2. Test matrix

| Test ID | Revision | Attack / property | Expected oracle | Failure condition |
|---|---|---|---|---|
| AVT-01 | REV-01 | Evidence absent | Affected criterion/subcriterion = NS; no numeric capability rating for that item. A definitive aggregate is blocked when the NS item is material; otherwise any provisional/aggregate treatment must follow §8.3 and disclose the NS, denominator and authority | Missing evidence becomes 0, 1, neutral, is silently omitted, or a material NS is hidden/treated as resolved |
| AVT-02 | REV-01 | Supplier demo/assertion only | NS unless the pre-defined criterion expressly permits that evidence and its scope is sufficient; never 0 solely due to missing proof | Demo absence or assertion is treated as demonstrated failure or proven capability |
| AVT-03 | REV-01 | Sufficient evidence proves capability absent/unacceptable | Rating 0; evidence state Sufficient; claim bounded to tested scope | 0 is rejected merely because it is negative, or assigned without sufficient evidence |
| AVT-04 | REV-01 | Sufficient evidence proves threshold met | Rating at least 3 only if the pre-written criterion and threshold are met; scope stated | Score is inferred from document volume, vendor reputation or unrelated evidence |
| AVT-05 | REV-01 | Evidence expired, contradictory or out of scope | NS for the affected claim until revalidated/resolved; contradiction and scope gap visible | Stale/contradictory evidence remains scored as current and sufficient |
| AVT-06 | REV-03 | Isolated synthetic experiment, no real users/funds, production access or partner connection | Tier determined from actual decision unit and permission; not automatically T3; any independent T1/T2 trigger still applies | Future operational capability automatically forces this experiment to T3, or experiment is automatically T0 |
| AVT-07 | REV-03 | Operational permission enables material customer-funds movement, consequential ledger/commission posting or regulated-market access | T3 under the canonical §4 trigger table; separate approvals and permissions required | Lower tier chosen by averaging, label manipulation or reference to a non-canonical table |
| AVT-08 | REV-03 | High-impact identity decision can materially affect funds/privileged access or cause severe harm | T3 trigger applies; record exact identity action, affected party and consequence | Identity decision omitted because it is not itself a payment or ledger function |
| AVT-09 | REV-03 | Scope/jurisdiction/permission is unresolved and a higher tier is plausible | Higher plausible tier applies until uncertainty is resolved; scope gap is explicit | Lower tier selected by assuming the unknown is harmless |
| AVT-10 | REV-04 | Same risk assessed over different horizons | Horizon is explicit; likelihood rationale is horizon-specific; results are not compared as if horizons match | A likelihood label is reused without stating its time horizon |
| AVT-11 | REV-04 | Same likelihood band, materially different impact dimensions | Raw likelihood-impact pair and impact dimensions remain visible; no single unqualified number hides the difference | Different harm profiles collapse to one unexplained score |
| AVT-12 | REV-04 | L1×I5 compared with L5×I1 | Both raw pairs and scenarios remain distinguishable; equal products do not imply equal risk | Product 5 is treated as equal expected loss or interchangeable risk |
| AVT-13 | REV-04 | Control claimed to reduce residual risk but no operating evidence exists | Control is not credited as effective; residual assessment remains conservative/uncertain and limitation is recorded | A designed or claimed control automatically lowers residual likelihood/impact |
| AVT-14 | REV-12 | N/A requested after candidate scores are visible | Reject/defer the N/A request for that scoring round; require prior approval and versioned re-baseline/rescoring of all candidates | Post-hoc N/A selectively improves a preferred candidate |
| AVT-15 | REV-12 | Mandatory legal/security/financial gate marked N/A | Invalid; gate remains applicable or decision unit must be reframed with authorized rationale; N/A cannot remove the gate | Gate disappears from eligibility because of N/A |
| AVT-16 | REV-12 | Valid N/A on a genuinely inapplicable preference criterion, approved before scoring | Original and effective weights, excluded criterion, approver, rationale and denominator are visible; remaining applicable weights normalized transparently | Effective weights or denominator are hidden, or applicable weights did not total 100 before exclusion |
| AVT-17 | REV-12 | N/A changes the ranking | Recalculate all candidates with the same approved criterion set and show sensitivity; no selective candidate-only recalculation | Only one candidate is recalculated or ranking change is concealed |
| AVT-18 | REV-14 | Compound criterion has five atomic subcriteria; evidence supports only two | Split into five atomic records; two may be rated if independently sufficient; three unsupported atoms remain NS; compound criterion is not passed as a whole | 2/5 evidence is promoted into a positive whole-criterion score |
| AVT-19 | REV-14 | Four of five atoms supported, one material atom unsupported | Unsupported atom remains NS; no whole-criterion pass or definitive aggregate if material NS remains | 4/5 coverage silently rounds to complete |
| AVT-20 | REV-14 | Evidence covers one version, region, tenant or population only | Claim and rating limited to evidenced scope; other scope remains NS/untested | Evidence is generalized to all versions, regions, tenants or users |
| AVT-21 | REV-14 | Compound criterion cannot be decomposed without losing a critical dependency | Record dependency and define a testable atomic structure preserving the conjunction; all required atoms must pass for whole-criterion acceptance | Reviewer chooses an arbitrary percentage threshold or treats partial completion as full pass |

## 3. Detailed test vectors and oracles

### 3.1 REV-01 — Missing evidence is not a zero

**Fixture A:** Criterion C-SEC-01 requires documented and tested tenant isolation for a named service/version/environment. No evidence is supplied.  
**Expected:** evidence state Unknown or Insufficient; the affected criterion is NS and receives no numeric capability rating. If it is a mandatory gate, that gate remains Unknown/Blocked. If it is material, no definitive aggregate/rank may be published. If it is not material, do not automatically block every aggregate; apply §8.3, disclose the NS and any explicitly authorized provisional treatment, including denominator and limitations.

**Fixture B:** A controlled, scope-matched negative test demonstrates that tenant B can read tenant A's protected record. Evidence is complete and reproducible.  
**Expected:** evidence state Sufficient; capability rating 0 (or another anchored rating only if the rubric explicitly distinguishes the demonstrated severity); security gate Fail for the tested scope; do not soften the result because it is adverse.

**Metamorphic property:** Removing evidence from Fixture B must change the affected item to NS, not preserve 0. Adding irrelevant evidence must not change its rating. Changing the entity/version/environment outside the evidence scope must invalidate unsupported extrapolation. Changing only the materiality classification must change aggregate publication control, not the underlying NS state.

### 3.2 REV-03 — Tier is a function of the exact decision unit and permission

Evaluate each case separately; do not average tiers:

- **Case A — bounded test:** synthetic data, isolated environment, no real users/funds, production credentials, external partner or regulated-market activity. Expected: classify the test's own scope; it is not automatically T3. It may be T1/T2 if another §4 trigger applies.
- **Case B — operational financial permission:** real customer-funds movement, payout, materially consequential ledger/commission posting or regulated-market access. Expected: T3 and separate legal, finance, security, assurance and owner authorization as applicable.
- **Case C — identity:** a decision can materially deny or grant access to customer funds or privileged activity, or cause severe harm. Expected: T3 even if no payment API is called.
- **Case D — ambiguity:** jurisdiction, funds path, population or permission is unknown and a higher tier is plausible. Expected: higher plausible tier until evidence resolves the uncertainty.

**Metamorphic property:** Changing only the lifecycle permission from isolated synthetic test to real operational activity must trigger re-tiering. Changing an unrelated future roadmap item must not change the tier of a genuinely isolated test. Removing a T3 trigger cannot lower the tier if another T3 trigger remains.

### 3.3 REV-04 — Risk rating must preserve scenario, horizon and uncertainty

For each scenario capture: asset/process; threat/failure event; cause/vulnerability; affected parties; time horizon; likelihood band and rationale; impact dimensions and rationale; evidence/assumptions; uncertainty; existing controls and operating evidence; inherent pair; residual pair; owner; response; acceptance authority and expiry.

**Counterexample pair:**  
- R-A: likelihood 1, impact 5 — rare but catastrophic.  
- R-B: likelihood 5, impact 1 — frequent but minor.  
Both have arithmetic product 5. The matrix must preserve the distinct pairs and scenarios; the product is not expected loss and cannot by itself set acceptance, urgency or resource allocation.

**Control test:** A control described in a design document but not evidenced as operating cannot automatically reduce residual risk. If evidence is partial, record the limitation and uncertainty rather than silently treating the control as effective.

### 3.4 REV-12 — N/A must not become a score-manipulation channel

**Fixture A:** Candidate Alpha scores poorly on a criterion. After seeing results, an evaluator proposes N/A for that criterion only for Alpha.  
**Expected:** reject the post-hoc selective change for the current round. Any legitimate scope change requires a versioned rubric update, prior authorization and rescoring every candidate consistently.

**Fixture B:** A preference criterion is genuinely irrelevant to the decision unit; the accountable control owner approves N/A before scoring.  
**Expected:** retain original weights; disclose excluded criterion, reason, approver, effective weights and denominator; normalize all candidates on the same remaining criteria. Original applicable weights must total 100 percentage points before exclusion.

**Deterministic arithmetic fixture:** original weights are C1=40, C2=30, C3=30. C3 is approved N/A before scoring for every candidate. Candidate Alpha has C1=5 and C2=2; Candidate Beta has C1=3 and C2=4. Effective denominator is 70 for both. Expected normalized scores are Alpha = 100×(5×40+2×30)/(5×70) = **74.29**; Beta = 100×(3×40+4×30)/(5×70) = **68.57**. The same excluded criterion and denominator must apply to both. This fixture tests arithmetic and uniformity only; it does not set a universal acceptance threshold.

**Fixture C:** A mandatory security or legal gate is marked N/A to remove a blocker.  
**Expected:** invalid. A scoring N/A cannot waive a mandatory gate or law. A materially different decision unit requires explicit re-framing and separate authorization, not relabeling.

**Metamorphic property:** Applying the same approved N/A criterion to every candidate must use the same denominator and criterion set. A candidate's result must not change because another candidate's evidence is added or removed. N/A must not improve eligibility when a mandatory gate is failed or unknown.

### 3.5 REV-14 — Partial evidence cannot pass a compound criterion

**Fixture:** Criterion C-OPS-01 comprises five required atoms: (1) documented backup policy, (2) immutable backup protection, (3) restore test, (4) measured RPO/RTO, (5) independent restore evidence for the target environment. Evidence supports atoms 1 and 2 only.  
**Expected:** atoms 1 and 2 may be rated independently if evidence is sufficient; atoms 3–5 remain NS; the compound criterion is not passed. If the criterion is material, no definitive aggregate/rank may be published while NS remains, consistent with §8.3.

**Scope fixture:** A restore test was performed for version 1 in region A. The claim concerns version 2 in region B.  
**Expected:** no extrapolation. Evidence is limited to version 1/region A; version 2/region B remains untested/NS.

**Metamorphic property:** Adding evidence for one atom may change only that atom's state unless the newly supplied evidence directly supports other atoms. It must not automatically upgrade the compound criterion. A scope expansion invalidates only claims outside the proven scope, not the valid evidence within it.

## 4. Cross-revision invariants

1. **No compensation:** no score, average, N/A or risk product overrides a failed/unknown mandatory gate.
2. **Scope conservation:** no conclusion exceeds the entity, product, version, configuration, environment, jurisdiction, population or permission evidenced.
3. **Unknown preservation:** missing/insufficient/expired/contradictory evidence remains NS/Unknown; it is never silently converted to zero, neutral or pass.
4. **No post-hoc rubric gaming:** criteria, weights and N/A decisions are frozen before scoring; any authorized change is versioned and applied uniformly.
5. **Decision-unit separation:** experiment, pilot, procurement, integration, production and regulated/financial activation are distinct permissions where scope or impact changes.
6. **Traceability:** every result links to inputs, source evidence, evaluator, oracle and exact standard version.

## 5. Acceptance criteria

This matrix is acceptable for **test-design completeness** only when:

- every test has a stable ID, revision mapping, adversarial input, expected oracle and falsifiable failure condition;
- both language versions are semantically equivalent and contain the same test IDs;
- all normative outcomes trace to the exact controlling provisions: §§4 and 8.3; §§17.10.1–17.10.7 for the revisions and minimum acceptance tests; and relevant lifecycle/approval provisions in §§17.1–17.3;
- no test assumes an unapproved risk appetite, score threshold, N/A policy exception or owner decision;
- document review and execution status are recorded separately;
- defects are recorded with severity, affected revision, evidence and retest requirement.

It is **not** acceptable evidence of standard adoption, successful operational use, independent assurance or production readiness.

## 6. Execution plan and exit gates

1. Freeze the parent-standard commit SHA and the two matrix file hashes.
2. Perform bilingual semantic review and a cross-reference check against the exact parent sections.
3. Have a second competent reviewer independently derive expected outcomes for AVT-01…AVT-21; record disagreements before adjudication.
4. Execute the vectors against a controlled, synthetic evaluation dossier or a small deterministic test harness. Do not use production or real customer data.
5. Perform specification-mutation analysis using the catalogue in §7. For each non-equivalent mutation, run the affected test vectors and record whether the oracle detects the altered decision rule. Do not report a conventional code mutation score unless an executable reference model and a defined, reproducible mutant population exist. Classify equivalent, unreachable and unresolved mutants separately.
6. Record PASS/FAIL/BLOCKED with artifacts and exact versions. A failed test requires a defect and correction; a blocked test remains open.
7. Re-run Documentation Governance on the exact PR head after all edits.
8. Keep REV owner dispositions PENDING until the owner records a decision. Independent assurance, if required, is a separate commissioned activity.

**Exit gate:** no unresolved Critical/High test failure; no unexplained blocked mandatory-gate test; bilingual semantic parity confirmed; owner and specialist approvals recorded where required. Passing these tests does not itself adopt LOT-EVAL-001.

### 6.1 Adversarial review findings for v0.2.0

The following defects were found by comparing the matrix against the exact LOT-EVAL-001 v0.3.0 text. They are document-design findings, not executed test failures:

| Finding | Severity | Defect | Disposition |
|---|---|---|---|
| AVTR-01 | High | AVT-01 originally blocked every aggregate whenever any evidence was NS, while §8.3 blocks a definitive aggregate when a **material** criterion remains NS and permits only explicitly controlled provisional treatment. | Corrected: NS remains unscored at criterion level; aggregate handling now distinguishes materiality and requires transparent disclosure/authority. |
| AVTR-02 | Medium | The parent-section mapping cited §§17.1–17.3 but omitted the direct normative provisions in §§17.10.1–17.10.7. | Corrected: parent mapping and acceptance traceability now identify §§4, 8.3 and 17.10.1–17.10.7, with §§17.1–17.3 retained only for related lifecycle/approval context. |
| AVTR-03 | Low | Inserting the mutation catalogue created duplicate section numbering for the research references and change history. | Corrected: change history is now §9; research references remain §8. |

The v0.2.0 arithmetic fixture and mutation catalogue are additional test-design improvements. The above findings are considered **document corrections applied**, not owner dispositions, executed acceptance tests or independent assurance. All AVT vectors and MUT operators remain DESIGNED.

## 7. Specification-mutation catalogue and execution protocol

This is **specification-mutation analysis**, not a claim that a software mutation-testing tool has been run against an implementation. The object being challenged is the written decision rule and its test oracle. A future executable reference evaluator may support conventional mutation testing, but none is assumed here.

| Mutant ID | Deliberate rule defect | Required detecting tests | Kill condition |
|---|---|---|---|
| MUT-01 | Convert missing/expired/out-of-scope evidence from NS to 0 | AVT-01, 05, 18–20 | At least one applicable fixture is incorrectly scored 0 and the suite flags the deviation |
| MUT-02 | Treat NS as neutral, omit it silently, or hide it from the denominator | AVT-01, 05, 19 | The materiality-dependent aggregate rule or visible evidence state is violated |
| MUT-03 | Remove the sufficient-evidence precondition for rating 0 | AVT-02, 03 | A missing assertion/demo is rated 0, or a proven failure is not distinguished from absence of evidence |
| MUT-04 | Replace highest-trigger tiering with lowest-trigger selection or tier averaging | AVT-07–09 | Any in-scope T3 trigger fails to force T3 for that decision unit |
| MUT-05 | Automatically classify every synthetic experiment as T3, or every synthetic experiment as T0 | AVT-06 | The test ignores actual scope, impact, access or an independent T1/T2 trigger |
| MUT-06 | Remove the assessment horizon from likelihood | AVT-10 | Likelihood is compared or reused without an explicit horizon-specific rationale |
| MUT-07 | Collapse risk profiles to L×I alone | AVT-11, 12 | Distinct raw pairs/scenarios are treated as interchangeable solely because products match |
| MUT-08 | Credit a control as effective without evidence that it operates | AVT-13 | Residual risk is reduced solely on design/assertion without operating evidence and rationale |
| MUT-09 | Permit post-score or candidate-selective N/A; conceal effective weights/denominator | AVT-14–17 | N/A changes only a preferred candidate, bypasses prior approval, hides weights or removes a mandatory gate |
| MUT-10 | Allow partial compound evidence to pass the parent criterion or generalize beyond proven scope | AVT-18–21 | A parent passes without all required atoms, or a rating is extended beyond evidenced scope |

**Protocol:** (1) Freeze the exact parent-standard and matrix commits. (2) Copy the decision rule into a controlled test fixture; never mutate the authoritative branch in place. (3) Apply one mutation at a time and record the exact before/after rule. (4) Execute all mapped tests against both original and mutated rule sets using identical synthetic inputs. (5) A mutant is *killed* only when a test produces an observable oracle mismatch. (6) If no test distinguishes the mutant, record it as *survived* and add/repair a test or explain why the mutant is equivalent. (7) A reviewer must adjudicate equivalence; do not silently discard survivors. (8) Retest after every oracle or rule correction.

**Accounting:** report counts separately: generated; executed; killed; survived; equivalent (with rationale); unreachable/not applicable (with rationale); and unresolved. If a mutation score is later reported, state its formula and denominator explicitly and exclude only adjudicated equivalent mutants; do not use a single percentage as proof of overall test quality. For this governance standard, all non-equivalent mutations affecting mandatory gates or critical decision semantics must be killed before the corresponding acceptance tests can pass. No arbitrary universal percentage threshold is asserted.

**Execution state:** all MUT-01…MUT-10 are designed only. No mutation has been applied or executed against an executable evaluator. A manual specification review is not an executed mutation test.

## 8. Research references

- NIST IR 8397, *Guidelines on Minimum Standards for Developer Verification of Software* (2021): https://csrc.nist.gov/pubs/ir/8397/final
- NIST IR 8286A Rev. 1, *Identifying and Estimating Cybersecurity Risk for Enterprise Risk Management* (final, Dec 2025): https://csrc.nist.gov/pubs/ir/8286/a/r1/final
- NIST IR 8286 Rev. 1, *Integrating Cybersecurity and Enterprise Risk Management* (Dec 2025): https://nvlpubs.nist.gov/nistpubs/ir/2025/NIST.IR.8286r1.pdf
- ISO/IEC/IEEE 29119-1:2022, *Software testing — General concepts*: https://www.iso.org/obp/ui?_escaped_fragment_=iso%3Astd%3Aiso-iec-ieee%3A29119%3A-1%3Aed-2%3Av1%3Aen
- ISO/IEC/IEEE 29119-4:2021, *Software testing — Test techniques*: https://www.iso.org/standard/79430.html
- ISTQB Glossary, *Test oracle*: https://glossary.istqb.org/en_US/term/test-oracle
- Barr, Harman, McMinn, Shahbaz and Yoo, *The Oracle Problem in Software Testing: A Survey*, IEEE Transactions on Software Engineering 41(5), 2015, DOI: https://doi.org/10.1109/TSE.2014.2372785
- Schuler and Zeller, *(Un-)Covering Equivalent Mutants*, IEEE ICST 2010, DOI: https://doi.org/10.1109/ICST.2010.30
- Papadakis et al., *Practical Mutation Testing at Scale: A view from Google*, IEEE Transactions on Software Engineering 48(10), 2022, DOI: https://doi.org/10.1109/TSE.2021.3107634
- Papadakis et al., *A systematic literature review of techniques and metrics to reduce the cost of mutation testing*, Journal of Systems and Software, 2020: https://www.sciencedirect.com/science/article/pii/S0164121219301554

## 9. Change history

- 0.2.0 (2026-11-28): corrected REV-01 materiality/NS aggregate semantics; repaired parent-section traceability; added a ten-operator specification-mutation catalogue and explicit accounting/execution protocol. No tests or mutations executed.
- 0.1.0 (2026-11-28): initial bilingual adversarial acceptance-test design for REV-01, REV-03, REV-04, REV-12 and REV-14. No tests executed.
