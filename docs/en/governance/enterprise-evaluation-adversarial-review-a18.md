# LOT-EVAL-001 — Author-led Adversarial Review & Remediation Record

**Document ID:** LOT-EVAL-A18-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** REVIEW REPORT — author-led; owner-led review initiated; no independent assurance performed  
**Review target:** LOT-EVAL-001 v0.1.0 and existing specialist profiles  
**Remediated draft:** LOT-EVAL-001 v0.3.0 on PR #78 branch

## 1. Executive determination

LOT-EVAL-001 v0.1.0 was a useful governance skeleton but was not sufficiently deterministic for repeated enterprise decisions without further hardening. The author-led adversarial review identified material ambiguity in risk tiering, evidence strength, score semantics, TCO assumptions, supplier due diligence, AI/model evaluation, approval separation and specialist-document precedence.

The proposed standard has been revised to v0.3.0 through bilingual normative corrections. The follow-up review added REV-01…REV-14 and explicit acceptance tests. This is document-design remediation only. It is not independent assurance, legal advice, procurement approval, security certification or proof that the standard works in operation.

**Disposition:** LOT-EVAL-001 remains PROPOSED. Do not call it approved, operationalized or globally compliant. Do not select a candidate or use a scorecard for binding procurement until the exact decision unit, rubric, risk appetite and approvals are explicitly adopted.

## 2. Review scope and evidence inspected

Reviewed:
- LOT-EVAL-001 in English and Persian.
- LOT-PROVIDER-EVAL-001 in English and Persian.
- LOT-TECH-ADR-001 in English and Persian.
- LOT-QA-001.
- LOT-SEC-TM-001.
- Bilingual decision registers and project status.

External framework cross-checks:
- ISO 31000:2018; ISO/IEC 25010:2023.
- NIST SP 800-161 Rev.1 Update 1; final NIST SP 1326 (2026); NIST SP 800-30 Rev.1.
- NIST CSF 2.0; OWASP SAMM.
- ISO/IEC 42001:2023; NIST AI RMF.
- FinOps Framework unit economics.

These frameworks inform the method; they do not certify Lottorito. Private legal opinions, supplier contracts, production systems, candidate products and external provider evidence were not reviewed.

## 3. Findings and disposition

| ID | Severity | Finding | Risk if unresolved | Draft remediation |
|---|---|---|---|---|
| A18-F01 | HIGH | T0–T3 examples were not sufficiently separated from per-risk likelihood/impact or inherent/residual risk. | Under-tiering and hidden residual risk. | Explicit tier triggers, highest-tier rule, separate inherent/residual fields, impact dimensions and risk-appetite ownership. |
| A18-F02 | HIGH | Evidence class A combined official records, contracts, independent assurance and witnessed tests despite different authority and independence. | Contract or supplier-witnessed demo misread as independent operational proof. | Separate authority, independence, directness, scope, freshness and reproducibility. |
| A18-F03 | CRITICAL | Score 0 conflated missing evidence with demonstrated unacceptable capability; score 5 and N/A normalization were underspecified. | Misleading rankings, false precision and hidden unknowns. | Separate evidence state from rating; NS is not zero; define normalization, N/A, material-unknown stop and uncertainty. |
| A18-F04 | HIGH | Rubric lacked explicit controls for inter-rater bias, correlated criteria and post-hoc score manipulation. | Weight manipulation, double counting and unstable rankings. | Freeze rubric before scoring; independent scoring for material decisions; record disagreement; publish sensitivity. |
| A18-F05 | HIGH | TCO did not require common horizon, currency/FX, discount assumptions, scenarios or build/buy/defer baseline. | Hidden lifecycle, labor, migration and exit costs. | Common assumptions, nominal/NPV separation, fully loaded costs, scenarios, unit economics and exclusions. |
| A18-F06 | HIGH | Supplier due diligence did not make ownership/control/influence, provenance, supply-chain tiers, financial stability and subcontractor concentration a clear minimum. | Hidden ownership, compromised provenance and opaque fourth parties. | Risk-proportionate ICT supplier profile aligned to NIST SP 800-161 and final SP 1326. |
| A18-F07 | HIGH | DATA/MODEL was in scope but lacked model-specific evaluation requirements. | Unassessed data rights, leakage, cohort performance, drift, hallucination and oversight. | Model/version, data rights, evaluation-set, cohort, robustness, oversight, drift, fallback and inference-cost requirements. |
| A18-F08 | HIGH | Provider and technology documents had their own proposed scorecards without explicit parent precedence/reconciliation. | Conflicting score systems treated as active defaults. | Specialist weights remain proposals until owner adoption for a named decision unit and rubric reconciliation. |
| A18-F09 | HIGH | Discovery, experiment, pilot, procurement, contract, production release and jurisdiction activation were not clearly independent approvals. | Sandbox approval or supplier licence misread as launch authority. | Separate recorded decisions and explicit budget/contract authority; supplier licence is not Lottorito authorization. |
| A18-F10 | MEDIUM | ISO/IEC 25010:2023 was cited without explicit mapping of its nine quality characteristics to measurable scenarios. | Vague checklist or improvised quality score. | Map applicable characteristics to decision-specific scenarios and LOT-QA-001; no certification claim. |
| A18-F11 | HIGH | Pilot examples did not consistently require hypotheses, baseline, success/failure thresholds and stop conditions before execution. | Demo-driven acceptance and post-hoc interpretation. | Pre-approved pilot protocol, measurable acceptance, negative/failure tests, synthetic/minimized data, rollback and evidence retention. |
| A18-F12 | HIGH | Exit and monitoring needed stronger portability tests, dependency inventory and reassessment triggers. | Lock-in and unusable exit plan discovered after adoption. | Dependency inventory, portability/exit test, operational owner, SLO/incident model and suspension on failed gates or invalid evidence. |

## 4. Remediation mapping

LOT-EVAL-001 v0.3.0 Sections 17 and 17.10 map the original A18 findings and follow-up REV findings as follows:
- 17.1 → A18-F01.
- 17.2 → A18-F02.
- 17.3 → A18-F03 and A18-F04.
- 17.4 → A18-F05.
- 17.5 → A18-F06.
- 17.6 → A18-F07.
- 17.7 → A18-F10 and A18-F11.
- 17.8 → A18-F09 and A18-F12.
- 17.9 → A18-F08.
- 17.10.1 → REV-01, REV-05, REV-12 and REV-14.
- 17.10.2 → REV-02 and REV-06.
- 17.10.3 → REV-03.
- 17.10.4 → REV-04 and REV-13.
- 17.10.5 → REV-10.
- 17.10.6 → REV-07 and REV-09.
- 17.10.7 → REV-08 and REV-11, plus cross-document acceptance consistency.

The original v0.2.0 mapping is historical traceability only. The v0.3.0 follow-up mapping is: REV-01/05/12/14 → §§8.3 and 17.10.1; REV-02/06 → §§5.1, 5.2 and 17.10.2; REV-03 → §§4 and 17.10.3; REV-04/13 → §§17.1 and 17.10.4; REV-07/09 → §17.10.6 and the role language in A18/owner-review; REV-08 → §18; REV-10 → §§9 and 17.10.5; REV-11 → formula equivalence test in §17.10.7. These are document-level corrections, not operational verification or independent assurance.

## 5. Residual limitations

1. T0–T3 remain governance triggers; the accountable owner must approve risk appetite, authority limits and exact decision-unit classification.
2. Likelihood/impact scales are ordinal triage tools, not actuarial or monetary estimates.
3. No universal weights or minimum composite score are approved.
4. This standard gives no jurisdiction-specific legal conclusion and does not determine whether Lottorito, a tenant, operator or supplier may conduct regulated activity.
5. It does not replace LOT-PROVIDER-EVAL-001, LOT-TECH-ADR-001, LOT-QA-001, LOT-SEC-TM-001 or domain contracts.
6. No independent assurance has been performed or signed off this report or v0.3.0.
7. No candidate, supplier, technology, legal entity, jurisdiction, contract, runtime or operating model is selected or approved.

## 6. Required next review

The current next gate is completion of the owner-led, finding-by-finding review recorded in LOT-EVAL-OWNER-REVIEW-001. The owner has separately delegated evidence-supported document corrections to the assistant; this execution instruction does not itself dispose of findings or accept residual risk. Specialist challenge may be commissioned for matters requiring domain competence. Independent assurance is a distinct activity and is required only where the tier, claim, governance policy or owner decision calls for it; if claimed, its provider, competence, objectivity, scope, method, evidence access, limitations and report must be documented.

After owner dispositions and any required specialist/independent work, reconcile findings, update both languages together, run exact-head Documentation Governance and obtain explicit owner approval before declaring LOT-EVAL-001 approved. No merge or deployment is authorized by this report.

## 6.1 Follow-up adversarial review — REV-01…REV-14

A second author-led pass examined internal consistency, scoring semantics, decision-unit boundaries, risk aggregation, cost-estimate bias and assurance-role definitions. The findings below are reviewer conclusions and technical recommendations, not independent assurance or owner risk acceptance.

| ID | Severity | Finding / required correction |
|---|---|---|
| REV-01 | CRITICAL | Separate evidence sufficiency from capability rating: missing/insufficient evidence is NS; 0 requires sufficient evidence demonstrating unacceptable/absent capability. |
| REV-02 | HIGH | Separate source authority from independence; record each as a distinct evidence attribute. |
| REV-03 | HIGH | Reconcile tier triggers and classify the exact permission/decision unit; distinguish a bounded synthetic test from later operational enablement. |
| REV-04 | HIGH | Anchor likelihood/impact scales to a stated horizon, scenario, evidence, uncertainty and explicit acceptance authority. |
| REV-05 | HIGH | Use one complete 0–5 rubric with consistent anchors; define NS/N/A and when independent corroboration is warranted. |
| REV-06 | MEDIUM | Anchor High/Medium/Low confidence and define conflict handling and evaluator calibration. |
| REV-07 | HIGH | Distinguish owner-led review, specialist challenge, supplier assurance and independent assurance; do not mislabel one as another. |
| REV-08 | LOW | Keep Section 18 as the sole version-history authority; remove duplicate/stale version markers. |
| REV-09 | HIGH | Define formal assurance by competence, objectivity, scope, method, evidence access, limitations, report and acceptance authority. |
| REV-10 | MEDIUM | Add historical forecast-error/reference-class/optimism-bias treatment and switching-value analysis to material TCO decisions. |
| REV-11 | NOT SUBSTANTIVE | The two weighted-score formulas are equivalent when applicable weights total 100; retain as a clarity test, not an open defect. |
| REV-12 | HIGH | Require prior N/A rationale/approval, visible effective weights, and prohibit N/A from removing mandatory gates. |
| REV-13 | MEDIUM | Preserve raw likelihood-impact pairs; do not treat ordinal multiplication as calibrated quantitative risk or expected loss. |
| REV-14 | MEDIUM | Operationalize Partial evidence through atomic subcriteria; unsupported atomic criteria remain NS and partial coverage cannot pass a compound criterion. |

### Implementation and assurance boundary

The project owner instructed the assistant on 2026-11-28 to apply technically supported corrections throughout the relevant project artifacts, using evidence and professional judgment. This authorizes preparation and application of document-level technical corrections within the current PR scope. It does **not** convert any REV item into an owner disposition, accept residual risk, approve a rubric for a named procurement decision, authorize a supplier or jurisdiction, or permit production/financial activity. The owner-disposition register therefore remains PENDING until the owner records item-level decisions.

The current correction set includes LOT-EVAL-001 v0.3.0, LOT-PROVIDER-EVAL-001 v0.2.0, LOT-TECH-ADR-001 v0.2.0 and LOT-SEC-TM-001 v0.2.0. The specialist provider/technology scorecards now inherit the parent evidence/rating semantics; the threat model references the parent risk-assessment anchors while retaining its own security scope. These are proposed document controls and remain subject to owner/security-specialist review and exact-head documentation validation.

## 7. References

- ISO 31000:2018: https://www.iso.org/standard/31000
- ISO/IEC 25010:2023: https://www.iso.org/standard/78176.html
- NIST SP 800-161 Rev.1 Update 1: https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final
- NIST SP 1326 (final, 2026): https://csrc.nist.gov/pubs/sp/1326/final
- NIST SP 800-30 Rev.1: https://csrc.nist.gov/pubs/sp/800/30/r1/final
- NIST CSF 2.0: https://www.nist.gov/publications/nist-cybersecurity-framework-csf-20
- OWASP SAMM: https://owaspsamm.org/model/
- ISO/IEC 42001:2023: https://www.iso.org/standard/42001
- NIST AI RMF: https://www.nist.gov/itl/ai-risk-management-framework
- FinOps Unit Economics: https://www.finops.org/framework/capabilities/unit-economics/

## 8. Change history

- 0.1.0 (2026-11-28): first author-led adversarial review and remediation register for LOT-EVAL-001.
