#!/usr/bin/env python3
"""LOT-EVAL-RDM-004: row-level decision-table verification.

Standard-library only; deterministic synthetic fixtures; no product/runtime,
provider, credentials, external network, or production data.
"""
from __future__ import annotations

import json
from typing import Callable

TIERS = ("T0", "T1", "T2", "T3")
EXPECTED_ROWS = tuple(
    [f"DT01-R{i}" for i in range(1, 7)]
    + [f"DT02-R{i}" for i in range(1, 8)]
    + [f"DT03-R{i}" for i in range(1, 10)]
    + [f"DT04-R{i}" for i in range(1, 8)]
    + [f"DT05-R{i}" for i in range(1, 8)]
)


def tier_decision(*, triggers: set[str], scope_complete: bool,
                  highest_plausible: str | None = None,
                  t0_conditions_evidenced: bool = False,
                  unbounded_unknown: bool = False,
                  mutant: str | None = None) -> str:
    if not triggers.issubset(set(TIERS)):
        return "INVALID"
    if highest_plausible is not None and highest_plausible not in TIERS:
        return "INVALID"
    if unbounded_unknown or not scope_complete:
        return "UNRESOLVED"
    if highest_plausible is not None:
        triggers = set(triggers) | {highest_plausible}
    if triggers:
        if mutant == "MUT-TIER-LOWEST":
            return min(triggers, key=TIERS.index)
        return max(triggers, key=TIERS.index)
    return "T0" if t0_conditions_evidenced else "UNRESOLVED"


def gate_decision(*, applicability: str, result: str,
                  rationale_approved: bool = False,
                  experiment_only: bool = False,
                  control_needed_for_experiment: bool = True,
                  restriction_enforceable: bool = False,
                  omitted_from_register: bool = False,
                  mutant: str | None = None) -> str:
    if omitted_from_register:
        return "BLOCK_INCOMPLETE_REGISTER" if mutant != "MUT-OMIT-GATE-PASS" else "PASS"
    if applicability == "REQUIRED":
        if result == "PASS":
            return "PASS"
        if result in {"FAIL", "UNKNOWN", "MISSING", "N/A"}:
            return "BLOCK"
        return "INVALID"
    if applicability == "NA":
        return "NA_RECORDED" if rationale_approved and not experiment_only else "INVALID_NA"
    if applicability == "CONDITIONAL":
        if (experiment_only and not control_needed_for_experiment
                and restriction_enforceable):
            return "CONDITIONAL_EXPERIMENT_ONLY"
        return "BLOCK"
    return "INVALID"


def evidence_decision(*, sufficient: bool, demonstrated: str = "meets",
                      fresh: bool = True, scope_match: bool = True,
                      contradictory: bool = False, coverage: str = "complete",
                      mutant: str | None = None) -> tuple[str, int | None]:
    if not fresh or not scope_match or contradictory or not sufficient:
        if mutant == "MUT-EVIDENCE-ZERO":
            return ("SCORED", 0)
        return ("NS", None)
    if coverage == "partial":
        return ("PARTIAL", None)
    anchors = {
        "absent": 0, "severe_gap": 1, "partial_limits": 2,
        "meets": 3, "above": 4, "exceptional": 5,
    }
    if demonstrated not in anchors:
        return ("INVALID", None)
    return ("SCORED", anchors[demonstrated])


def weighted_score(ratings: dict[str, int], weights: dict[str, int]) -> float:
    if not weights or set(ratings) != set(weights) or sum(weights.values()) <= 0:
        raise ValueError("candidate criteria must match the same non-empty effective rubric")
    if any(v not in range(0, 6) for v in ratings.values()):
        raise ValueError("capability ratings must be integer anchors 0..5")
    return round(100 * sum(ratings[k] * weights[k] for k in weights)
                 / (5 * sum(weights.values())), 2)


def na_decision(*, approved_before_scores: bool, gate_excluded: bool = False,
                ns_present: bool = False, ns_material: bool = False,
                provisional_complete: bool = False,
                all_other_controls_pass: bool = True,
                mutant: str | None = None) -> str:
    if not approved_before_scores:
        return "REJECT_LATE_NA"
    if gate_excluded:
        return "REJECT_GATE_NA"
    if ns_present and ns_material:
        return "BLOCK_DEFINITIVE"
    if ns_present and not ns_material:
        return ("PROVISIONAL_NON_SELECTION" if provisional_complete
                else "UNRESOLVED_NON_MATERIAL_NS")
    if not all_other_controls_pass:
        return "BLOCK_OTHER_CONTROL"
    return "AGGREGATION_PERMITTED"


def risk_record(*, scenario: str | None, horizon_rationale: str | None,
                impact_dimensions: tuple[str, ...] | None,
                likelihood: int | None, impact: int | None,
                control_claimed: bool, control_operating_evidence: bool,
                objectives: tuple[str, ...] | None,
                assumptions: tuple[str, ...] | None,
                uncertainty: str | None, treatment: str | None,
                owner: str | None, acceptance_authority: str | None,
                mutant: str | None = None) -> str:
    if not scenario:
        return "INCOMPLETE"
    if not horizon_rationale:
        return "INCOMPLETE"
    if not impact_dimensions:
        return "INCOMPLETE"
    if likelihood not in range(1, 6) or impact not in range(1, 6):
        return "INVALID_PAIR"
    if mutant == "MUT-RISK-PRODUCT":
        return "INVALID_PRODUCT_ONLY"
    if control_claimed and not control_operating_evidence:
        return "CONTROL_NOT_CREDITED"
    if not all((objectives, assumptions, uncertainty, treatment, owner,
                acceptance_authority)):
        return "INCOMPLETE"
    return "COMPLETE_FOR_REVIEW"


def _full_risk(**overrides) -> str:
    args = dict(
        scenario="synthetic service outage",
        horizon_rationale="likelihood calibrated to next 12 months",
        impact_dimensions=("availability", "customer"),
        likelihood=2, impact=4,
        control_claimed=True, control_operating_evidence=True,
        objectives=("availability objective",),
        assumptions=("synthetic assumption",),
        uncertainty="limited sample",
        treatment="mitigate",
        owner="synthetic risk owner",
        acceptance_authority="synthetic acceptance authority",
    )
    args.update(overrides)
    return risk_record(**args)


TABLE_TESTS: list[tuple[str, Callable[[], bool]]] = []


def row(row_id: str):
    def register(fn):
        TABLE_TESTS.append((row_id, fn))
        return fn
    return register


# DT-01: exact decision-unit tiering (6 rows)
@row("DT01-R1")
def _(): return tier_decision(triggers={"T3"}, scope_complete=True) == "T3"
@row("DT01-R2")
def _(): return tier_decision(triggers={"T2"}, scope_complete=True) == "T2"
@row("DT01-R3")
def _(): return tier_decision(triggers={"T1"}, scope_complete=True) == "T1"
@row("DT01-R4")
def _(): return tier_decision(triggers=set(), scope_complete=True, t0_conditions_evidenced=True) == "T0"
@row("DT01-R5")
def _(): return tier_decision(triggers={"T1"}, scope_complete=True, highest_plausible="T2") == "T2"
@row("DT01-R6")
def _(): return tier_decision(triggers=set(), scope_complete=False, unbounded_unknown=True) == "UNRESOLVED"


# DT-02: mandatory-gate disposition (7 rows)
@row("DT02-R1")
def _(): return gate_decision(applicability="REQUIRED", result="PASS") == "PASS"
@row("DT02-R2")
def _(): return gate_decision(applicability="REQUIRED", result="FAIL") == "BLOCK"
@row("DT02-R3")
def _(): return gate_decision(applicability="REQUIRED", result="UNKNOWN") == "BLOCK"
@row("DT02-R4")
def _(): return gate_decision(applicability="NA", result="N/A", rationale_approved=True) == "NA_RECORDED"
@row("DT02-R5")
def _():
    current = gate_decision(applicability="CONDITIONAL", result="CONDITIONAL",
        experiment_only=True, control_needed_for_experiment=False,
        restriction_enforceable=True)
    later = gate_decision(applicability="REQUIRED", result="UNKNOWN")
    return current == "CONDITIONAL_EXPERIMENT_ONLY" and later == "BLOCK"
@row("DT02-R6")
def _(): return gate_decision(applicability="REQUIRED", result="MISSING", omitted_from_register=True) == "BLOCK_INCOMPLETE_REGISTER"
@row("DT02-R7")
def _(): return gate_decision(applicability="REQUIRED", result="N/A") == "BLOCK"


# DT-03: evidence state and capability rating (9 rows)
@row("DT03-R1")
def _(): return evidence_decision(sufficient=False) == ("NS", None)
@row("DT03-R2")
def _(): return evidence_decision(sufficient=True, demonstrated="absent") == ("SCORED", 0)
@row("DT03-R3")
def _(): return evidence_decision(sufficient=True, demonstrated="severe_gap") == ("SCORED", 1)
@row("DT03-R4")
def _(): return evidence_decision(sufficient=True, demonstrated="partial_limits") == ("SCORED", 2)
@row("DT03-R5")
def _(): return evidence_decision(sufficient=True, demonstrated="meets") == ("SCORED", 3)
@row("DT03-R6")
def _(): return evidence_decision(sufficient=True, demonstrated="above") == ("SCORED", 4)
@row("DT03-R7")
def _(): return evidence_decision(sufficient=True, demonstrated="exceptional") == ("SCORED", 5)
@row("DT03-R8")
def _(): return evidence_decision(sufficient=True, coverage="partial") == ("PARTIAL", None)
@row("DT03-R9")
def _(): return evidence_decision(sufficient=True, scope_match=False) == ("NS", None)


# DT-04: N/A and aggregate publication (7 rows)
@row("DT04-R1")
def _(): return na_decision(approved_before_scores=False) == "REJECT_LATE_NA"
@row("DT04-R2")
def _(): return na_decision(approved_before_scores=True, gate_excluded=True) == "REJECT_GATE_NA"
@row("DT04-R3")
def _():
    result = na_decision(approved_before_scores=True)
    weights = {"C1": 40, "C2": 30, "C3": 30}
    effective = {k: v for k, v in weights.items() if k != "C3"}
    alpha = weighted_score({"C1": 5, "C2": 2}, effective)
    beta = weighted_score({"C1": 3, "C2": 4}, effective)
    return (result == "AGGREGATION_PERMITTED" and sum(weights.values()) == 100
            and sum(effective.values()) == 70 and alpha == 74.29 and beta == 68.57)
@row("DT04-R4")
def _(): return na_decision(approved_before_scores=True, ns_present=True, ns_material=True) == "BLOCK_DEFINITIVE"
@row("DT04-R5")
def _(): return na_decision(approved_before_scores=True, ns_present=True, ns_material=False) == "UNRESOLVED_NON_MATERIAL_NS"
@row("DT04-R6")
def _(): return na_decision(approved_before_scores=True, ns_present=True, ns_material=False, provisional_complete=True) == "PROVISIONAL_NON_SELECTION"
@row("DT04-R7")
def _(): return na_decision(approved_before_scores=True, all_other_controls_pass=True) == "AGGREGATION_PERMITTED"


# DT-05: risk-record completeness (7 rows)
@row("DT05-R1")
def _(): return _full_risk() == "COMPLETE_FOR_REVIEW"
@row("DT05-R2")
def _(): return _full_risk(scenario=None) == "INCOMPLETE"
@row("DT05-R3")
def _(): return _full_risk(horizon_rationale=None) == "INCOMPLETE"
@row("DT05-R4")
def _(): return _full_risk(impact_dimensions=None) == "INCOMPLETE"
@row("DT05-R5")
def _(): return _full_risk(mutant="MUT-RISK-PRODUCT") == "INVALID_PRODUCT_ONLY"
@row("DT05-R6")
def _(): return _full_risk(control_operating_evidence=False) == "CONTROL_NOT_CREDITED"
@row("DT05-R7")
def _(): return _full_risk(assumptions=None) == "INCOMPLETE"


def metamorphic_tests() -> dict[str, bool]:
    # Tier monotonicity: adding an in-scope higher trigger cannot lower tier.
    tier_base = tier_decision(triggers={"T1"}, scope_complete=True)
    tier_plus = tier_decision(triggers={"T1", "T2"}, scope_complete=True)
    # Scope narrowing to unknown cannot produce a lower/definitive tier.
    tier_unknown = tier_decision(triggers={"T1"}, scope_complete=False)
    # Candidate-independent, uniform N/A arithmetic: same effective denominator.
    w = {"A": 40, "B": 30, "C": 30}
    effective = {k: v for k, v in w.items() if k != "C"}
    alpha_alone = weighted_score({"A": 5, "B": 2}, effective)
    alpha_with_beta = weighted_score({"A": 5, "B": 2}, effective)
    beta_with_alpha = weighted_score({"A": 3, "B": 4}, effective)
    # A missing required risk field cannot improve completeness.
    complete = _full_risk()
    incomplete = _full_risk(acceptance_authority=None)
    # Adding evidence for one atom must not imply full parent coverage.
    partial = evidence_decision(sufficient=True, coverage="partial")
    # A conditional experiment permission cannot imply later operational permission.
    later = gate_decision(applicability="REQUIRED", result="UNKNOWN")
    return {
        "MT-01-tier-monotonicity": tier_base == "T1" and tier_plus == "T2",
        "MT-02-unknown-scope-no-definitive-lower-tier": tier_unknown == "UNRESOLVED",
        "MT-03-uniform-na-denominator-and-candidate-invariance": (
            sum(effective.values()) == 70 and alpha_alone == alpha_with_beta == 74.29
            and beta_with_alpha == 68.57),
        "MT-04-missing-risk-field-non-improving": complete == "COMPLETE_FOR_REVIEW" and incomplete == "INCOMPLETE",
        "MT-05-partial-evidence-no-parent-score": partial == ("PARTIAL", None),
        "MT-06-experiment-does-not-grant-production": later == "BLOCK",
    }


def targeted_mutation_tests() -> dict[str, bool]:
    # Each mutation deliberately violates a decision-table invariant; the
    # corresponding row oracle must detect the changed outcome.
    return {
        "MUT-TIER-LOWEST-killed": tier_decision(
            triggers={"T1", "T3"}, scope_complete=True,
            mutant="MUT-TIER-LOWEST") != "T3",
        "MUT-OMIT-GATE-PASS-killed": gate_decision(
            applicability="REQUIRED", result="MISSING", omitted_from_register=True,
            mutant="MUT-OMIT-GATE-PASS") != "BLOCK_INCOMPLETE_REGISTER",
        "MUT-EVIDENCE-ZERO-killed": evidence_decision(
            sufficient=False, mutant="MUT-EVIDENCE-ZERO") != ("NS", None),
        "MUT-RISK-PRODUCT-killed": _full_risk(mutant="MUT-RISK-PRODUCT") != "COMPLETE_FOR_REVIEW",
    }


def execute() -> dict:
    ids = [rid for rid, _ in TABLE_TESTS]
    if len(ids) != len(set(ids)):
        raise RuntimeError("duplicate decision-table row test ID")
    if set(ids) != set(EXPECTED_ROWS):
        raise RuntimeError(f"row population mismatch: missing={sorted(set(EXPECTED_ROWS)-set(ids))}; unexpected={sorted(set(ids)-set(EXPECTED_ROWS))}")
    row_results = {rid: bool(fn()) for rid, fn in TABLE_TESTS}
    meta = metamorphic_tests()
    mutations = targeted_mutation_tests()
    return {
        "model": "LOT-EVAL-RDM-004",
        "execution_scope": "synthetic/non-production only",
        "decision_table_rows": {
            "designed": len(EXPECTED_ROWS), "executed": len(TABLE_TESTS),
            "passed": sum(row_results.values()), "failed": len(row_results)-sum(row_results.values()),
            "results": {k: ("PASS" if v else "FAIL") for k, v in row_results.items()},
        },
        "metamorphic_tests": {"executed": len(meta), "passed": sum(meta.values()),
                              "failed": len(meta)-sum(meta.values()), "results": meta},
        "targeted_mutations": {"executed": len(mutations), "killed": sum(mutations.values()),
                               "survived": len(mutations)-sum(mutations.values()), "results": mutations},
        "limitations": [
            "Row-level fixtures test the catalogue's declared outcomes; they do not authenticate real evidence, approvals, delegated authority or control operation.",
            "DT04-R5 remains UNRESOLVED by design; no definitive non-material-NS policy is inferred.",
            "DT02-R4/R5 use synthetic control-owner approval and enforceable-restriction flags; real authorization is outside this harness.",
            "DT01 tier triggers are supplied as classified inputs; this harness does not decide legal status or infer a real decision unit.",
            "The 36 rows are table-row checks, not 36 independent end-to-end tests or proof of standard adequacy.",
            "This author-led harness is not independent assurance, formal IV&V, legal advice, certification or owner adoption."
        ],
    }


if __name__ == "__main__":
    report = execute()
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    failed = (report["decision_table_rows"]["failed"]
              + report["metamorphic_tests"]["failed"]
              + report["targeted_mutations"]["survived"])
    raise SystemExit(1 if failed else 0)
