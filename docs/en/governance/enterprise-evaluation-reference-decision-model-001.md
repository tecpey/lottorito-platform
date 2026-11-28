# LOT-EVAL-001 — Reference Decision Model & Adversarial Harness

**Document ID:** LOT-EVAL-RDM-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** IMPLEMENTED AND CI-VERIFIED ON A NON-PRODUCTION REVIEW BRANCH — owner disposition and independent review pending  
**Parent baseline:** LOT-EVAL-001 v0.3.0 and LOT-EVAL-AVT-001 v0.2.0  
**Frozen parent commit:** `e7aed0892a0de212fc3fd7603a6976eee503a76f`  
**Authority:** Deterministic reference behavior for the mapped synthetic acceptance vectors only. This is not the Lottorito product runtime, a procurement engine, a legal/security assurance, standard adoption, owner approval or production authorization.

## 1. Purpose and isolation

This package makes the 21 AVT-01…AVT-21 vectors executable against a small deterministic reference model and applies the ten MUT-01…MUT-10 specification faults to the same synthetic inputs.

The implementation is one Python file, `tools/lot_eval_rdm.py`, using only the Python standard library. It has no network, database, filesystem input, product-runtime, provider, credential or production-data dependency. Fixtures are embedded and synthetic. The model is intentionally not imported by product code.

## 2. Normative source freeze

| Source | Version | Frozen commit / blob |
|---|---|---|
| Parent standard | LOT-EVAL-001 v0.3.0 | Commit `e7aed0892a0de212fc3fd7603a6976eee503a76f`; EN blob `8bed42544e29f25abcf191e1bb38463e3e553d03`; FA blob `0bc75b12c02022d3a302f122b11ac79d0bb00aa8` |
| Acceptance matrix | LOT-EVAL-AVT-001 v0.2.0 | EN blob `319b4e713d1be54207bdbfadd19b3eb32ce773a7`; FA blob `52ba728e37f667429b0ac552f9683ad6491df239` |

The reference model is derived from §§4, 8.3 and 17.10.1–17.10.7, plus the 21 test oracles in the frozen matrix. A later parent or matrix revision requires explicit re-baselining; results do not transfer automatically.

## 3. Model boundaries and decision semantics

- **Evidence:** missing, insufficient, stale, contradictory or out-of-scope evidence yields NS with no numeric rating. Rating 0 requires sufficient evidence of absent/unacceptable capability. A threshold rating is limited to the evidenced scope.
- **Aggregate guard:** material NS blocks a definitive aggregate. A provisional result requires an explicit authority reference and discloses NS/materiality. For non-material NS without such a reference, the model returns `UNRESOLVED`; it does not invent a definitive-aggregation rule absent from the standard. The authority reference and materiality flag are synthetic inputs, not validated delegations or an independent materiality assessment.
- **Tier:** the highest applicable trigger governs; unresolved plausible higher-tier exposure is conservatively surfaced. A synthetic test is not automatically T3. If the fixture supplies no defensible baseline tier or trigger, the model returns `UNRESOLVED` rather than guessing T0/T1.
- **Risk:** scenario, horizon, raw likelihood/impact pair and impact dimensions remain separate. No L×I product is emitted as expected loss or a calibrated risk value.
- **Controls:** a control is not credited as effective without operating evidence.
- **N/A and scoring:** N/A must be pre-approved; mandatory gates cannot be removed; original/effective weights and denominator remain visible; candidates use the same criterion set. The arithmetic fixture is the matrix's 40/30/30 example (Alpha 74.29; Beta 68.57).
- **Compound criteria:** unsupported atoms remain NS; partial coverage cannot pass the parent; conclusions cannot exceed the evidenced version/scope.

The model does not choose risk appetite, decide legal status, approve authority, determine materiality, select a candidate or authorize the next lifecycle permission.

## 4. Executable coverage

| Matrix vectors | Model area |
|---|---|
| AVT-01…AVT-05 | Evidence state, NS/zero distinction, aggregate guard |
| AVT-06…AVT-09 | Decision-unit tiering and synthetic/operational boundary |
| AVT-10…AVT-13 | Risk horizon/pair preservation and operating-control evidence |
| AVT-14…AVT-17 | Prior N/A approval, mandatory gates, denominator and uniform scoring |
| AVT-18…AVT-21 | Atomic subcriteria, conjunction and scope conservation |

The harness executes each baseline vector once, then runs all 21 oracles against each of the ten deliberate mutants: 210 mutant/vector evaluations. A mutant is killed only when at least one mapped oracle fails against the mutated behavior.

## 5. Local execution record

Command:

```bash
python tools/lot_eval_rdm.py
```

Local environment: Python 3.13.5. The exact source file was syntax-compiled with `python -m py_compile` and executed in the isolated working directory.

| Measure | Result |
|---|---:|
| AVT vectors executed | 21 |
| AVT PASS / FAIL | 21 / 0 |
| Specification mutants generated / executed | 10 / 10 |
| Mutants killed / survived | 10 / 0 |
| Mutant/vector evaluations | 210 |
| Equivalent / unreachable / unresolved mutants | 0 / 0 / 0 |

This is a specification-level fault-injection result from this reference harness, not a conventional third-party mutation-testing score or evidence of overall test-suite adequacy. All expected oracles were authored in the same workstream; no independent reviewer has independently reconstructed them. Independent challenge remains outstanding.

Exact-head GitHub Actions run #1133 (run ID `46118746808`) on commit `863fe0eb8f27e93e68dcd0f6275aaef377cf3c32` succeeded: the structural documentation check validated 62 bilingual Markdown pairs and 160 local links, and the reference-model execution step passed. This is CI evidence for the exact implementation head, not independent assurance.

## 6. Open interpretation and assurance limitations

1. **Non-material NS:** §8.3 clearly blocks a definitive aggregate for material NS and allows explicitly provisional treatment under a separately recorded authority decision, but it does not fully specify when non-material NS may be omitted from a definitive aggregate. The model returns `UNRESOLVED` absent explicit authority. This requires owner/specialist clarification; no rule is silently adopted.
2. **Authority validation:** the harness accepts a synthetic authority reference as an input. It does not validate delegation, identity, competence or approval scope.
3. **Materiality:** supplied as a fixture attribute; no universal materiality threshold is inferred.
4. **Coverage boundary:** the 21-vector matrix targets REV-01/03/04/12/14. It does not execute every minimum acceptance test or every provision of LOT-EVAL-001. Confidence, TCO forecast bias/switching value, formal assurance, jurisdiction-specific legal review and actual owner disposition are not implemented as automated decisions here.
5. **Independence:** this is author-led model construction and execution, not independent assurance. A second competent reviewer must derive expected results independently and record disagreements before any independent-assurance claim.
6. **Status:** LOT-EVAL-001 remains PROPOSED; REV-01…REV-14 owner dispositions remain PENDING. This implementation does not adopt the standard or close owner decisions.

## 7. Safety boundary

Synthetic/non-production only. No candidate/provider/technology/jurisdiction is selected. No procurement, partner connection, production data, financial activity, customer funds, market activation, merge or deployment is authorized. The harness must remain isolated from product runtime unless a separately approved future decision explicitly changes its scope.
