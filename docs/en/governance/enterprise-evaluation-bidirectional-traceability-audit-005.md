# LOT-EVAL-RDM-005 — Bidirectional Traceability Audit

**Document ID:** LOT-EVAL-RDM-005-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** IMPLEMENTED — bounded static audit passed on exact PR head  
**Parent:** LOT-EVAL-001 v0.3.0  
**Related:** LOT-EVAL-RDM-003A v0.1.0; LOT-EVAL-AVT-001 v0.2.0; LOT-EVAL-RDM-001; LOT-EVAL-RDM-004 v0.2.0

## 1. Purpose and assurance boundary

RDM-005 checks the integrity of declared traceability across normative rules, source clauses, adversarial vectors, decision-table rows, model guards, metamorphic properties, and targeted mutations. Its executable checker is `tools/lot_eval_rdm005.py`.

The checker is a **static structural audit**. It validates registered identifiers, source-clause declarations, existence of referenced headings, forward/reverse mapping consistency, bilingual identifier populations, and English/Persian source-clause parity. It does not prove that a linked test semantically verifies a rule, that the rule is adequate, that a source clause is interpreted correctly, or that an independent oracle exists.

RDM-005 is author-led engineering work. It is not blind review, second-person review, independent assurance, formal IV&V, legal advice, certification, owner acceptance, or adoption of LOT-EVAL-001.

## 2. Frozen scope and populations

The audit reads the normative catalogue, parent standard, AVT matrix, RDM-001 and RDM-004 reference harnesses, and the Persian counterparts.

| Population | Registered items |
|---|---:|
| Atomic rules | 18 |
| Adversarial vectors (AVT) | 21 |
| Specification mutation operators | 10 |
| Decision-table rows | 36 |
| RDM-001 input/model guards | 8 |
| RDM-004 metamorphic properties | 11 |
| RDM-004 targeted mutations | 4 |

The audit also distinguishes rule coverage states:
- **PARTIAL_EXECUTABLE:** some linked executable coverage exists, but material scope/real-evidence limitations remain.
- **PARTIAL_UNRESOLVED:** linked fixtures exist, but a normative policy gap remains open.
- **HUMAN_REVIEW_REQUIRED:** no direct AVT/DT executable mapping is claimed; a human governance review remains necessary.
- **STATIC_TRACEABILITY_GUARD_ONLY:** declared static trace links are checked, but the derived rule is not adopted policy.

The checker must not promote any of these statuses to complete verification or assurance.

## 3. Audit properties

RDM-005 checks:
1. Exact registered populations for rule, AVT, mutation, decision-table, guard, metamorphic and targeted-mutation IDs.
2. Token-boundary correctness so a document ID such as `LOT-EVAL-AVT-001` cannot create a false `AVT-00` identifier.
3. Every rule has an explicit source-clause set and a declared coverage state/limitation.
4. Declared source clauses match the source column for that rule in the normative decision-rule catalogue.
5. Each declared source clause exists as a parent-standard heading.
6. Forward and reverse AVT and decision-table mappings agree.
7. Each mutation, guard, metamorphic property and targeted mutation maps to one or more known rules.
8. Persian and English rule/AVT/mutation populations agree.
9. Persian and English source-clause sets agree after numeral normalization.
10. Required parent-standard sections exist in both language versions.
11. Parser regression fixtures cover level-2 headings, nested headings, Persian numerals and identifier boundaries.

The audit's 376 checks are structural assertions over registered metadata. They are not 376 semantic tests, not 376 independent tests and not a coverage percentage.

## 4. Findings and corrections

The first RDM-005 CI attempt exposed both checker defects and genuine traceability defects. These were not suppressed; the checker was corrected and rerun.

- **RDM005-F01 — heading parser false negatives:** an f-string embedded the heading-marker quantifier `#{2,3}` as interpolation instead of regex syntax. This caused existing English and Persian source headings to be reported missing. Replaced with a dedicated heading parser using concatenated regex fragments and added regression fixtures.
- **RDM005-F02 — identifier-boundary false positive:** the unbounded `AVT-\d{2}` pattern interpreted the `AVT-001` substring in a document ID as `AVT-00`. Identifier patterns now require token boundaries; a regression fixture covers this case.
- **RDM005-F03 — forward/reverse AVT mapping defects:** AVT-06 also exercises the exact decision-unit scope rule RDM-R01; AVT-02 exercises both evidence sufficiency and the precondition for rating 0; AVT-13 maps to the risk-record/control-evidence rule RDM-R15, not the ordinal risk-pair rule RDM-R16. The forward and reverse declarations were reconciled.
- **RDM005-F04 — source-clause declaration drift:** RDM-R01 and RDM-R05 declarations were reconciled to the actual source column in RDM-003A. The audit now compares declared rule sources to the catalogue rather than merely checking that a declared heading exists.
- **RDM005-F05 — source-row parser overreach:** the initial source parser also consumed summary rows such as “RDM-R01…R03”. It now accepts only exact atomic rule-row identifiers and normalizes the section marker before comparing references.
- **RDM005-F06 — bilingual source-reference drift:** the new EN/FA parity check detected that Persian RDM-R09 omitted parent clause §17.10.1 even though the English row included it. The Persian source reference was corrected; the finding is evidence that bilingual ID parity alone is insufficient.

Intermediate evidence:
- Run #1239 failed with 48 reported traceability checks.
- Run #1242 failed with 20 remaining checks after the first parser corrections.
- Run #1243 passed 357/357 checks before EN/FA source-clause parity was added.
- Run #1244 then detected one real bilingual source-clause mismatch (RDM-R09).
- Run #1245 passed after the mismatch and checker were corrected.

This history is retained to distinguish discovery, correction and final verification.

## 5. Exact-head execution evidence

**Documentation Governance run:** #1245  
**Run ID:** `46162905434`  
**Exact PR head:** `364dac4591bad89f2a3eca581b9983c5e9750b09`  
**Result:** SUCCESS  
**URL:** https://github.com/tecpey/lottorito-platform/actions/runs/46162905434

The exact-head run passed:
- bilingual documentation validation;
- RDM-001 reference-model and adversarial harness;
- RDM-004 decision-table verification;
- RDM-005 bidirectional traceability audit.

RDM-005 result: **376 executed / 376 passed / 0 failed**. The audited populations were 18 rules, 21 AVTs, 10 specification mutations, 36 decision-table rows, 8 RDM-001 guards, 11 RDM-004 metamorphic properties and 4 targeted mutations.

A later commit changes the PR head; this run is evidence only for the SHA stated above. The final PR head must be revalidated after subsequent edits.

## 6. Limitations and residual work

The following remain outside the checker:
- semantic correctness or adequacy of the normative rules;
- whether every parent-standard requirement has been decomposed into a rule;
- whether each AVT/DT test actually exercises its declared rule rather than merely containing its ID;
- independence and competence of the test oracle/reviewer;
- authentication, provenance, authority, freshness and scope of real evidence;
- human-review obligations for RDM-R13, RDM-R14 and RDM-R17;
- unresolved policy for RDM-U01…U05 and partially unresolved RDM-R11/RDM-R12;
- owner acceptance, legal eligibility, supplier selection, procurement, production readiness or operational assurance.

A syntactically correct trace link is necessary for auditability but is not sufficient to establish semantic verification. RDM-005 must remain one layer in a larger evidence chain.

## 7. Research basis

- NASA Software Engineering Handbook, **SWE-072 — Bidirectional Traceability Between Software Test Procedures and Software Requirements**: https://swehb.nasa.gov/spaces/SWEHBVB/pages/32604549/SWE-072%2B-%2BBidirectional%2BTraceability%2BBetween%2BSoftware%2BTest%2BProcedures%2Band%2BSoftware%2BRequirements
- NASA Software Engineering Handbook, **SWE-114 — Software Test Procedures**: test procedures identify requirements, preconditions, inputs, steps, expected results, evaluation criteria, traceability and configuration: https://swehb.nasa.gov/pages/viewpage.action?pageId=23004603
- ISO/IEC/IEEE 29119-4:2021, **Software testing — Part 4: Test techniques**: https://www.iso.org/standard/79430.html
- NIST SP 800-160 Vol. 1 Rev. 1, **Engineering Trustworthy Secure Systems** (2022): assurance arguments require relevant, accurate, credible and sufficient objective evidence: https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final

These sources inform the audit design. They do not certify this repository or establish compliance with the referenced standards.

## 8. Governance and next step

LOT-EVAL-001 remains PROPOSED. REV-01…REV-14 remain PENDING for owner disposition. RDM-U01…U05 remain unresolved. RDM-005 does not authorize any provider, technology, jurisdiction, contract, procurement, partner integration, production data, financial activity, merge or deployment.

**Recommended next work package:** RDM-006 — Normative Gap Research & Owner Decision Pack. It should examine RDM-U01…U05 using authoritative risk, appraisal, assurance and software-quality sources; compare viable policy options; recommend conservative defaults; define observable acceptance criteria; and leave final normative dispositions to the owner.
