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


@dataclass(frozen=True)
class Result:
    state: str
    rating: int | None = None
    reason: str = ""


def evidence_rating(*, present: bool, sufficient: bool, fresh: bool = True,
                    scope_match: bool = True, contradiction: bool = False,
                    demonstrated: str = "meets", mutant: str | None = None) -> Result:
    """Separate evidence sufficiency from capability rating; NS is not zero."""
    adequate = present and sufficient and fresh and scope_match and not contradiction
    if mutant == "MUT-01" and not adequate:
        return Result("Sufficient", 0, "mutant converted unknown evidence to zero")
    if mutant == "MUT-02" and not adequate:
        return Result("Neutral", None, "mutant neutralized/omitted NS")
    if mutant == "MUT-03":
        adequate = present and fresh and scope_match and not contradiction
    if not adequate:
        return Result("NS", None, "evidence missing, insufficient, stale, contradictory or out of scope")
    if demonstrated == "absent_or_unacceptable":
        return Result("Sufficient", 0, "sufficient evidence demonstrates unacceptable/absent capability")
    if demonstrated == "meets":
        return Result("Sufficient", 3, "predefined threshold demonstrated for evidenced scope")
    if demonstrated == "above":
        return Result("Sufficient", 4, "strong evidence demonstrates above-threshold capability")
    return Result("NS", None, "partial evidence cannot support a parent criterion")


def aggregate(*, scores: list[int], material_ns: bool, ns_present: bool,
              provisional_authority: str | None = None) -> Result:
    """Apply NS publication guard; never invent a definitive treatment for ambiguity."""
    if ns_present:
        if provisional_authority:
            return Result("PROVISIONAL", None,
                          f"NS disclosed; material_ns={material_ns}; authority={provisional_authority}")
        if material_ns:
            return Result("BLOCKED", None, "material NS prevents a definitive aggregate")
        return Result("UNRESOLVED", None,
                      "standard does not fully specify definitive treatment of non-material NS; do not infer a rule")
    if not scores:
        return Result("BLOCKED", None, "no applicable scored criteria")
    return Result("ELIGIBLE_FOR_AGGREGATION", None,
                  "no unresolved NS; weighted calculation requires a separately frozen rubric")


def classify_tier(*, triggers: list[str], synthetic_isolated: bool,
                  higher_tier_plausible_unresolved: bool = False,
                  baseline_tier: str | None = None,
                  mutant: str | None = None) -> str:
    ranks = {"T0": 0, "T1": 1, "T2": 2, "T3": 3}
    valid = [t for t in triggers if t in ranks]
    if mutant == "MUT-05":
        return "T3" if synthetic_isolated else "T0"
    if higher_tier_plausible_unresolved:
        valid.append("T3")
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
                      mutant: str | None = None) -> dict:
    if mutant == "MUT-09":
        # Deliberate mutant: bypass prior approval and allow candidate-selective N/A.
        approved_before_scoring = True
        if candidates:
            return {"state": "SCORED", "candidate_specific_na": True,
                    "scores": {next(iter(candidates)): 100.0}}
    if not approved_before_scoring:
        return {"state": "BLOCKED", "reason": "N/A not approved before scoring"}
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
    if mutant == "MUT-10":
        passed = bool(supported_atoms)
        scope_ok = True
    else:
        passed = set(required_atoms) == set(supported_atoms)
        scope_ok = evidenced_scope == requested_scope
    return {"atom_states": {a: ("Sufficient" if a in supported_atoms else "NS")
                            for a in required_atoms},
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
                            provisional_authority="SYNTHETIC-AUTH-01")
    nonmaterial = aggregate(scores=[4], material_ns=False, ns_present=True)
    return (r.state == "NS" and r.rating is None and a.state == "BLOCKED"
            and provisional.state == "PROVISIONAL" and nonmaterial.state == "UNRESOLVED")


@case("AVT-02")
def _(m):
    r = evidence_rating(present=True, sufficient=False,
                        demonstrated="absent_or_unacceptable", mutant=m)
    return r.state == "NS" and r.rating is None


@case("AVT-03")
def _(m):
    r = evidence_rating(present=True, sufficient=True,
                        demonstrated="absent_or_unacceptable", mutant=m)
    return r.state == "Sufficient" and r.rating == 0


@case("AVT-04")
def _(m):
    r = evidence_rating(present=True, sufficient=True, demonstrated="meets", mutant=m)
    return r.state == "Sufficient" and r.rating >= 3


@case("AVT-05")
def _(m):
    r = evidence_rating(present=True, sufficient=True, fresh=False, mutant=m)
    return r.state == "NS" and r.rating is None


@case("AVT-06")
def _(m):
    return classify_tier(triggers=["T1"], synthetic_isolated=True, mutant=m) == "T1"


@case("AVT-07")
def _(m):
    return classify_tier(triggers=["T1", "T3"], synthetic_isolated=False, mutant=m) == "T3"


@case("AVT-08")
def _(m):
    return classify_tier(triggers=["T2", "T3"], synthetic_isolated=False, mutant=m) == "T3"


@case("AVT-09")
def _(m):
    return classify_tier(triggers=["T1"], synthetic_isolated=False,
                         higher_tier_plausible_unresolved=True, mutant=m) == "T3"


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
                         mandatory_gates={}, candidates={"Alpha": {"C1": 1, "C2": 1}, "Beta": {"C1": 3, "C2": 3}}, mutant=m)
    return r["state"] == "BLOCKED"


@case("AVT-15")
def _(m):
    r = score_candidates(original_weights={"C1": 100}, excluded=set(),
                         approved_before_scoring=True, mandatory_gates={"LEGAL": "N/A"},
                         candidates={"A": {"C1": 3}}, mutant=m)
    return r["state"] == "INELIGIBLE"


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
    r = score_candidates(original_weights={"C1": 40, "C2": 30, "C3": 30},
                         excluded={"C3"}, approved_before_scoring=True,
                         mandatory_gates={}, candidates={
                             "A": {"C1": 5, "C2": 2}, "B": {"C1": 3, "C2": 4}},
                         mutant=m)
    return (r.get("scores", {}).get("A") == 74.29
            and r.get("scores", {}).get("B") == 68.57)


@case("AVT-18")
def _(m):
    r = compound_criterion(required_atoms=("a", "b", "c", "d", "e"),
                           supported_atoms={"a", "b"}, evidenced_scope="v1/r1",
                           requested_scope="v1/r1", mutant=m)
    return not r["parent_pass"] and r["atom_states"]["c"] == "NS"


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
    return not r["parent_pass"] and not r["scope_match"]


@case("AVT-21")
def _(m):
    r = compound_criterion(required_atoms=("a", "b", "dependency"),
                           supported_atoms={"a", "b"}, evidenced_scope="v1/r1",
                           requested_scope="v1/r1", mutant=m)
    return not r["parent_pass"] and r["atom_states"]["dependency"] == "NS"


def execute() -> dict:
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
            "passed": sum(baseline.values()), "failed": len(TESTS) - sum(baseline.values()),
            "results": {tid: ("PASS" if ok else "FAIL") for tid, ok in baseline.items()}},
        "mutations": {
            "generated": len(MUTANTS), "executed": len(MUTANTS),
            "mutant_test_executions": len(MUTANTS) * len(TESTS),
            "killed": sum(v["status"] == "KILLED" for v in mutation_results.values()),
            "survived": sum(v["status"] == "SURVIVED" for v in mutation_results.values()),
            "equivalent": 0, "unreachable": 0, "unresolved": 0,
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
                     and report["mutations"]["survived"] == 0 else 1)
