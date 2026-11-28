#!/usr/bin/env python3
"""LOT-EVAL-RDM-001: isolated, deterministic reference decision model.

Python standard library only. Synthetic fixtures only. Not product/runtime code,
not a procurement engine, and not an approval or production authorization.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Callable

MUTANTS = tuple(f"MUT-{i:02d}" for i in range(1, 11))
EXPECTED_TEST_IDS = tuple(f"AVT-{i:02d}" for i in range(1, 22))


@dataclass(frozen=True)
class Result:
    state: str
    rating: int | None = None
    reason: str = ""
    evidence_state: str | None = None


def evidence_rating(*, present: bool, sufficient: bool, fresh: bool = True,
                    scope_match: bool = True, contradiction: bool = False,
                    demonstrated: str = "meets", coverage: str = "complete",
                    mutant: str | None = None) -> Result:
    """Keep evidence state distinct from the 0..5/NS capability rating."""
    if coverage not in {"none", "partial", "complete"}:
        return Result("INVALID_INPUT", None, "unknown evidence coverage value", "Unknown")
    if not present or coverage == "none":
        state = "Unknown" if not present else "Insufficient"
        return Result("NOT_SCORED", None, "no evidence covers the requested claim", state)
    if not fresh or not scope_match or contradiction:
        return Result("NOT_SCORED", None, "evidence is stale, out of scope or contradictory", "Insufficient")
    if coverage == "partial":
        return Result("NOT_SCORED", None, "partial coverage is retained as Partial; no parent rating", "Partial")
    adequate = present and sufficient
    evidence_state = "Sufficient" if adequate else "Insufficient"
    if mutant == "MUT-01" and not adequate:
        return Result("SCORED", 0, "mutant converted unknown evidence to zero", "Sufficient")
    if mutant == "MUT-02" and not adequate:
        return Result("NEUTRAL", None, "mutant neutralized/omitted NS", evidence_state)
    if mutant == "MUT-03" and present and fresh and scope_match and not contradiction:
        return Result("SCORED", 3, "mutant bypassed evidence sufficiency", "Insufficient")
    if not adequate:
        return Result("NOT_SCORED", None,
                      "evidence is missing, insufficient, stale, contradictory or out of scope",
                      evidence_state)
    anchors = {
        "absent_or_unacceptable": (0, "sufficient evidence demonstrates unacceptable/absent capability"),
        "severe_gap": (1, "sufficient evidence demonstrates a severe gap below minimum threshold"),
        "partial_with_material_limits": (2, "sufficient evidence demonstrates partial capability with material limits"),
        "meets": (3, "predefined threshold demonstrated for evidenced scope"),
        "above": (4, "strong evidence demonstrates above-threshold capability"),
        "exceptional": (5, "repeatable exceptional performance demonstrated for evidenced scope"),
    }
    if demonstrated not in anchors:
        return Result("NOT_SCORED", None, "capability outcome is not mapped to an approved anchor", "Insufficient")
    rating, reason = anchors[demonstrated]
    return Result("SCORED", rating, reason, "Sufficient")


def aggregate(*, scores: list[int], material_ns: bool, ns_present: bool,
              provisional_authority: dict | None = None) -> Result:
    """Apply NS publication guards; a synthetic authority fixture is not authenticated."""
    if material_ns and not ns_present:
        return Result("INVALID_INPUT", None, "material_ns cannot be true when no NS is present")
    if ns_present:
        if provisional_authority is not None:
            required = ("decision_id", "authorized_by", "scope", "expiry")
            complete = (isinstance(provisional_authority, dict)
                        and all(isinstance(provisional_authority.get(k), str)
                                and provisional_authority[k].strip() for k in required)
                        and provisional_authority.get("disclosure_complete") is True
                        and provisional_authority.get("permitted_use") == "non-selection-information-only")
            if complete:
                return Result("PROVISIONAL_NON_DECISIONAL", None,
                              "synthetic authorization fixture present; authority is not authenticated")
            return Result("UNRESOLVED", None, "provisional authority fixture is incomplete or use is not restricted")
        if material_ns:
            return Result("BLOCKED", None, "material NS prevents a definitive aggregate")
        return Result("UNRESOLVED", None,
                      "standard does not fully specify definitive treatment of non-material NS; do not infer a rule")
    if not scores:
        return Result("BLOCKED", None, "no applicable scored criteria")
    return Result("ELIGIBLE_FOR_AGGREGATION", None,
                  "no unresolved NS; weighted calculation requires a separately frozen rubric")


def classify_tier(*, triggers: list[str], synthetic_isolated: bool,
                   highest_plausible_tier: str | None = None,
                   baseline_tier: str | None = None,
                   mutant: str | None = None) -> str:
    ranks = {"T0": 0, "T1": 1, "T2": 2, "T3": 3}
    if any(t not in ranks for t in triggers):
        return "INVALID_INPUT"
    if highest_plausible_tier is not None and highest_plausible_tier not in ranks:
        return "INVALID_INPUT"
    valid = list(triggers)
    if mutant == "MUT-05":
        return "T3" if synthetic_isolated else "T0"
    if highest_plausible_tier is not None:
        valid.append(highest_plausible_tier)
    if not valid:
        return baseline_tier if baseline_tier in ranks else "UNRESOLVED"
    return min(valid, key=lambda t: ranks[t]) if mutant == "MUT-04" else max(valid, key=lambda t: ranks[t])


def risk_record(*, scenario: str, horizon: str, likelihood: int, impact: int,
                dimensions: tuple[str, ...], mutant: str | None = None) -> dict:
    if not scenario.strip():
        raise ValueError("risk scenario is required")
    if not horizon.strip() and mutant != "MUT-06":
        raise ValueError("risk horizon is required")
    if likelihood not in range(1, 6) or impact not in range(1, 6):
        raise ValueError("likelihood and impact must be anchored 1..5")
    if not dimensions:
        raise ValueError("at least one impact dimension is required")
    record = {"scenario": scenario, "horizon": horizon,
              "likelihood": likelihood, "impact": impact,
              "impact_dimensions": list(dimensions)}
    if mutant == "MUT-07":
        return {"ordinal_product_only": likelihood * impact}
    return record


def control_is_effective(*, claimed: bool, operating_evidence: bool,
                         mutant: str | None = None) -> bool:
    if mutant == "MUT-08":
        return claimed
    return claimed and operating_evidence


def score_candidates(*, original_weights: dict[str, int],
                      excluded: set[str], approved_before_scoring: bool,
                      mandatory_gates: dict[str, str],
                      candidates: dict[str, dict[str, int]],
                      mandatory_gate_criteria: set[str] | None = None,
                      scores_visible: bool = False,
                      mutant: str | None = None) -> dict:
    if mutant == "MUT-09":
        # Deliberate mutant: bypass prior approval and allow candidate-selective N/A.
        approved_before_scoring = True
        if candidates:
            return {"state": "SCORED", "candidate_specific_na": True,
                    "scores": {next(iter(candidates)): 100.0}}
    if not approved_before_scoring or (excluded and scores_visible):
        return {"state": "BLOCKED", "reason": "N/A was not approved before scoring or scores are already visible"}
    if not candidates:
        return {"state": "BLOCKED", "reason": "candidate population is empty"}
    if (not isinstance(original_weights, dict)
            or any(not isinstance(k, str) or not k.strip() for k in original_weights)
            or any(not isinstance(v, int) or isinstance(v, bool) or v < 0
                   for v in original_weights.values())):
        return {"state": "BLOCKED", "reason": "weights must be non-negative integers with valid criterion keys"}
    mandatory_gate_criteria = mandatory_gate_criteria or set()
    if excluded.intersection(mandatory_gate_criteria):
        return {"state": "INELIGIBLE", "reason": "N/A cannot remove a mandatory gate criterion"}
    if any(status != "PASS" for status in mandatory_gates.values()):
        return {"state": "INELIGIBLE", "reason": "mandatory gate failed or unknown"}
    if sum(original_weights.values()) != 100:
        return {"state": "BLOCKED", "reason": "applicable original weights must total 100"}
    if any(k not in original_weights for k in excluded):
        return {"state": "BLOCKED", "reason": "unknown excluded criterion"}
    effective = {k: v for k, v in original_weights.items() if k not in excluded}
    denominator = sum(effective.values())
    if denominator <= 0:
        return {"state": "BLOCKED", "reason": "no applicable weight"}
    results = {}
    for name, ratings in candidates.items():
        if set(ratings) != set(effective):
            return {"state": "BLOCKED", "reason": "candidate criterion set differs"}
        if any(v not in range(0, 6) for v in ratings.values()):
            return {"state": "BLOCKED", "reason": "ratings must be 0..5"}
        numerator = sum(ratings[k] * effective[k] for k in effective)
        results[name] = round(100 * numerator / (5 * denominator), 2)
    return {"state": "SCORED", "denominator": denominator,
            "effective_weights": effective, "scores": results}


def compound_criterion(*, required_atoms: tuple[str, ...],
                       supported_atoms: set[str],
                       evidenced_scope: str, requested_scope: str,
                       mutant: str | None = None) -> dict:
    if (not required_atoms or any(not isinstance(a, str) or not a.strip() for a in required_atoms)
            or len(set(required_atoms)) != len(required_atoms)
            or not supported_atoms.issubset(set(required_atoms))):
        raise ValueError("required atoms must be non-empty, unique and contain every supported atom")
    scope_ok = evidenced_scope == requested_scope
    if mutant == "MUT-10":
        passed = bool(supported_atoms)
        scope_ok = True
    else:
        passed = set(required_atoms) == set(supported_atoms)
    atom_states = {
        a: ("Sufficient" if a in supported_atoms and scope_ok else "NS")
        for a in required_atoms
    }
    parent_evidence_state = (
        "Unknown" if not scope_ok or not supported_atoms else
        "Sufficient" if passed else "Partial"
    )
    return {"atom_states": atom_states,
            "parent_evidence_state": parent_evidence_state,
            "parent_rating": None,
            "parent_pass": passed and scope_ok,
            "scope_match": scope_ok}


# Each test returns True only when the original normative oracle is satisfied.
TESTS: list[tuple[str, Callable[[str | None], bool]]] = []


def case(test_id: str):
    def register(fn):
        TESTS.append((test_id, fn))
        return fn
    return register


@case("AVT-01")
def _(m):
    r = evidence_rating(present=False, sufficient=False, mutant=m)
    a = aggregate(scores=[4], material_ns=True, ns_present=True)
    provisional = aggregate(scores=[4], material_ns=True, ns_present=True,
        provisional_authority={"decision_id": "SYNTHETIC-DEC-01",
            "authorized_by": "SYNTHETIC-AUTH-01", "scope": "synthetic-only",
            "expiry": "2030-01-01", "disclosure_complete": True,
            "permitted_use": "non-selection-information-only"})
    nonmaterial = aggregate(scores=[4], material_ns=False, ns_present=True)
    return (r.state == "NOT_SCORED" and r.evidence_state == "Unknown" and r.rating is None
            and a.state == "BLOCKED" and provisional.state == "PROVISIONAL_NON_DECISIONAL"
            and nonmaterial.state == "UNRESOLVED")


@case("AVT-02")
def _(m):
    r = evidence_rating(present=True, sufficient=False,
                        demonstrated="absent_or_unacceptable", mutant=m)
    return (r.state == "NOT_SCORED" and r.evidence_state == "Insufficient"
            and r.rating is None)


@case("AVT-03")
def _(m):
    r = evidence_rating(present=True, sufficient=True,
                        demonstrated="absent_or_unacceptable", mutant=m)
    return r.state == "SCORED" and r.evidence_state == "Sufficient" and r.rating == 0


@case("AVT-04")
def _(m):
    r = evidence_rating(present=True, sufficient=True, demonstrated="meets", mutant=m)
    return r.state == "SCORED" and r.evidence_state == "Sufficient" and r.rating >= 3


@case("AVT-05")
def _(m):
    r = evidence_rating(present=True, sufficient=True, fresh=False, mutant=m)
    return r.state == "NOT_SCORED" and r.evidence_state == "Insufficient" and r.rating is None


@case("AVT-06")
def _(m):
    t1 = classify_tier(triggers=["T1"], synthetic_isolated=True, mutant=m)
    t2 = classify_tier(triggers=["T2"], synthetic_isolated=True, mutant=m)
    return t1 == "T1" and t2 == "T2"


@case("AVT-07")
def _(m):
    return classify_tier(triggers=["T1", "T3"], synthetic_isolated=False, mutant=m) == "T3"


@case("AVT-08")
def _(m):
    return classify_tier(triggers=["T2", "T3"], synthetic_isolated=False, mutant=m) == "T3"


@case("AVT-09")
def _(m):
    t2_plausible = classify_tier(triggers=["T1"], synthetic_isolated=False,
                                  highest_plausible_tier="T2", mutant=m)
    invalid = classify_tier(triggers=["T1", "T9"], synthetic_isolated=False, mutant=m)
    return t2_plausible == "T2" and invalid == "INVALID_INPUT"


@case("AVT-10")
def _(m):
    try:
        risk_record(scenario="service outage", horizon="next 12 months",
                    likelihood=3, impact=4, dimensions=("availability",), mutant=m)
        risk_record(scenario="service outage", horizon="",
                    likelihood=3, impact=4, dimensions=("availability",), mutant=m)
        return False
    except ValueError:
        return True


@case("AVT-11")
def _(m):
    a = risk_record(scenario="catastrophic rare", horizon="12m", likelihood=1,
                    impact=5, dimensions=("safety",))
    b = risk_record(scenario="minor frequent", horizon="12m", likelihood=5,
                    impact=1, dimensions=("availability",), mutant=m)
    return (a.get("likelihood") == 1 and a.get("impact") == 5
            and b.get("likelihood") == 5 and b.get("impact") == 1)


@case("AVT-12")
def _(m):
    a = risk_record(scenario="rare severe", horizon="12m", likelihood=1,
                    impact=5, dimensions=("safety",), mutant=m)
    b = risk_record(scenario="frequent minor", horizon="12m", likelihood=5,
                    impact=1, dimensions=("availability",), mutant=m)
    return a != b and "scenario" in a and "scenario" in b


@case("AVT-13")
def _(m):
    return not control_is_effective(claimed=True, operating_evidence=False, mutant=m)


@case("AVT-14")
def _(m):
    r = score_candidates(original_weights={"C1": 40, "C2": 30, "C3": 30},
                         excluded={"C3"}, approved_before_scoring=False,
                         mandatory_gates={}, candidates={"Alpha": {"C1": 1, "C2": 1}, "Beta": {"C1": 3, "C2": 3}},
                         scores_visible=True, mutant=m)
    return r["state"] == "BLOCKED"


@case("AVT-15")
def _(m):
    gate_marked_na = score_candidates(original_weights={"LEGAL": 100}, excluded=set(),
                                       approved_before_scoring=True, mandatory_gates={"LEGAL": "N/A"},
                                       candidates={}, mandatory_gate_criteria={"LEGAL"}, mutant=m)
    gate_removed_by_scoring_na = score_candidates(original_weights={"LEGAL": 100}, excluded={"LEGAL"},
                                                   approved_before_scoring=True, mandatory_gates={"LEGAL": "PASS"},
                                                   candidates={}, mandatory_gate_criteria={"LEGAL"}, mutant=m)
    return (gate_marked_na["state"] == "INELIGIBLE"
            and gate_removed_by_scoring_na["state"] == "INELIGIBLE")


@case("AVT-16")
def _(m):
    r = score_candidates(original_weights={"C1": 40, "C2": 30, "C3": 30},
                         excluded={"C3"}, approved_before_scoring=True,
                         mandatory_gates={}, candidates={
                             "A": {"C1": 5, "C2": 2}, "B": {"C1": 3, "C2": 4}},
                         mutant=m)
    return (r.get("denominator") == 70
            and r.get("effective_weights") == {"C1": 40, "C2": 30}
            and r.get("scores") == {"A": 74.29, "B": 68.57})


@case("AVT-17")
def _(m):
    before = score_candidates(original_weights={"C1": 40, "C2": 30, "C3": 30},
        excluded=set(), approved_before_scoring=True, mandatory_gates={},
        candidates={"A": {"C1": 5, "C2": 2, "C3": 0},
                    "B": {"C1": 3, "C2": 4, "C3": 5}}, mutant=m)
    after = score_candidates(original_weights={"C1": 40, "C2": 30, "C3": 30},
        excluded={"C3"}, approved_before_scoring=True, mandatory_gates={},
        candidates={"A": {"C1": 5, "C2": 2}, "B": {"C1": 3, "C2": 4}}, mutant=m)
    return (before.get("scores", {}).get("A") == 52.0
            and before.get("scores", {}).get("B") == 78.0
            and after.get("scores", {}).get("A") == 74.29
            and after.get("scores", {}).get("B") == 68.57
            and before["scores"]["A"] < before["scores"]["B"]
            and after["scores"]["A"] > after["scores"]["B"]
            and after.get("denominator") == 70)


@case("AVT-18")
def _(m):
    r = compound_criterion(required_atoms=("a", "b", "c", "d", "e"),
                           supported_atoms={"a", "b"}, evidenced_scope="v1/r1",
                           requested_scope="v1/r1", mutant=m)
    partial = evidence_rating(present=True, sufficient=True, coverage="partial")
    return (not r["parent_pass"] and r["parent_evidence_state"] == "Partial"
            and r["atom_states"]["c"] == "NS" and partial.evidence_state == "Partial"
            and partial.rating is None)


@case("AVT-19")
def _(m):
    r = compound_criterion(required_atoms=("a", "b", "c", "d", "e"),
                           supported_atoms={"a", "b", "c", "d"}, evidenced_scope="v1/r1",
                           requested_scope="v1/r1", mutant=m)
    return not r["parent_pass"] and r["atom_states"]["e"] == "NS"


@case("AVT-20")
def _(m):
    r = compound_criterion(required_atoms=("a", "b"), supported_atoms={"a", "b"},
                           evidenced_scope="v1/r1", requested_scope="v2/r2", mutant=m)
    return (not r["parent_pass"] and not r["scope_match"]
            and r["parent_evidence_state"] == "Unknown"
            and all(v == "NS" for v in r["atom_states"].values()))


@case("AVT-21")
def _(m):
    r = compound_criterion(required_atoms=("a", "b", "dependency"),
                           supported_atoms={"a", "b"}, evidenced_scope="v1/r1",
                           requested_scope="v1/r1", mutant=m)
    return not r["parent_pass"] and r["atom_states"]["dependency"] == "NS"


def _empty_compound_rejected() -> bool:
    try:
        compound_criterion(required_atoms=(), supported_atoms=set(),
                           evidenced_scope="v1", requested_scope="v1")
        return False
    except ValueError:
        return True


GUARD_TESTS: list[tuple[str, Callable[[], bool]]] = [
    ("GUARD-01-invalid-tier-trigger", lambda: classify_tier(
        triggers=["T1", "T9"], synthetic_isolated=False) == "INVALID_INPUT"),
    ("GUARD-02-empty-candidate-population", lambda: score_candidates(
        original_weights={"C1": 100}, excluded=set(), approved_before_scoring=True,
        mandatory_gates={}, candidates={})["state"] == "BLOCKED"),
    ("GUARD-03-negative-weight", lambda: score_candidates(
        original_weights={"C1": 110, "C2": -10}, excluded=set(),
        approved_before_scoring=True, mandatory_gates={},
        candidates={"A": {"C1": 3, "C2": 3}})["state"] == "BLOCKED"),
    ("GUARD-04-empty-compound-atoms", _empty_compound_rejected),
    ("GUARD-05-inconsistent-material-ns", lambda: aggregate(
        scores=[3], material_ns=True, ns_present=False).state == "INVALID_INPUT"),
    ("GUARD-06-incomplete-provisional-authority", lambda: aggregate(
        scores=[3], material_ns=True, ns_present=True,
        provisional_authority={"authorized_by": "synthetic"}).state == "UNRESOLVED"),
]


def execute() -> dict:
    registered_ids = [tid for tid, _ in TESTS]
    if len(registered_ids) != len(set(registered_ids)):
        raise RuntimeError("duplicate AVT test ID registration")
    if set(registered_ids) != set(EXPECTED_TEST_IDS):
        missing = sorted(set(EXPECTED_TEST_IDS) - set(registered_ids))
        unexpected = sorted(set(registered_ids) - set(EXPECTED_TEST_IDS))
        raise RuntimeError(f"unexpected AVT population: missing={missing}, unexpected={unexpected}")
    if len(MUTANTS) != len(set(MUTANTS)) or set(MUTANTS) != {f"MUT-{i:02d}" for i in range(1, 11)}:
        raise RuntimeError("unexpected or duplicate specification-mutant population")
    baseline = {tid: bool(fn(None)) for tid, fn in TESTS}
    mutation_results = {}
    for mutant in MUTANTS:
        failed = [tid for tid, fn in TESTS if not fn(mutant)]
        mutation_results[mutant] = {
            "status": "KILLED" if failed else "SURVIVED", "detected_by": failed}
    return {
        "model": "LOT-EVAL-RDM-001",
        "model_version": "0.1.0",
        "execution_scope": "synthetic/non-production only",
        "tests": {
            "designed": len(TESTS), "executed": len(TESTS),
            "coverage_status": "REGISTERED_AVT_CHECKS_ONLY; FULL_MATRIX_PROPERTY_COVERAGE_NOT_ESTABLISHED",
            "passed": sum(baseline.values()), "failed": len(TESTS) - sum(baseline.values()),
            "results": {tid: ("PASS" if ok else "FAIL") for tid, ok in baseline.items()}},
        "model_guard_tests": {
            "designed": len(GUARD_TESTS), "executed": len(GUARD_TESTS),
            "passed": sum(bool(fn()) for _, fn in GUARD_TESTS),
            "failed": sum(not bool(fn()) for _, fn in GUARD_TESTS),
            "results": {tid: ("PASS" if fn() else "FAIL") for tid, fn in GUARD_TESTS}},
        "mutations": {
            "generated": len(MUTANTS), "executed": len(MUTANTS),
            "mutant_test_executions": len(MUTANTS) * len(TESTS),
            "killed": sum(v["status"] == "KILLED" for v in mutation_results.values()),
            "survived": sum(v["status"] == "SURVIVED" for v in mutation_results.values()),
            "classification_status": "NOT_ASSESSED",
            "equivalent": None, "unreachable": None, "unresolved": None,
            "results": mutation_results},
        "limitations": [
            "Specification-level mutants are deterministic fault injections in this reference model, not third-party mutation-tool output.",
            "No independent reviewer, owner approval, production runtime, real data or external integration was used.",
            "Materiality and provisional authority are explicit synthetic inputs; the model does not decide owner authority.",
            "This suite covers AVT-01..AVT-21 only; it does not establish acceptance of every LOT-EVAL-001 requirement.",
            "Non-material NS aggregate treatment remains unresolved; the model refuses to infer a definitive rule.",
            "The model does not assess confidence, TCO, formal assurance, legal eligibility or any production control."
        ]}


if __name__ == "__main__":
    report = execute()
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    raise SystemExit(0 if report["tests"]["failed"] == 0
                     and report["model_guard_tests"]["failed"] == 0
                     and report["mutations"]["survived"] == 0 else 1)
