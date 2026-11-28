#!/usr/bin/env python3
"""LOT-EVAL-RDM-005: bidirectional rule/test/source traceability audit.

Static structural audit only. It validates registered IDs, declared links,
source-clause existence, reverse links, and explicit coverage classifications.
It does not prove semantic correctness, oracle independence, or test adequacy.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

RULE_TRACE = {
    "RDM-R01": {"clauses": ["§2.1", "§4"], "avt": ["AVT-06", "AVT-09"], "dt": ["DT01-R5", "DT01-R6"], "status": "PARTIAL_EXECUTABLE", "gap": "Decision-unit completeness schema and real-world scope evidence remain unresolved."},
    "RDM-R02": {"clauses": ["§4", "§17.10.3"], "avt": ["AVT-07", "AVT-08", "AVT-09"], "dt": ["DT01-R1", "DT01-R2", "DT01-R3", "DT01-R4", "DT01-R5", "DT01-R6"], "status": "PARTIAL_EXECUTABLE", "gap": "Tier triggers are classified synthetic inputs; legal status and complete decision-unit semantics are not inferred."},
    "RDM-R03": {"clauses": ["§4", "§17.10.3"], "avt": ["AVT-06"], "dt": ["DT01-R4", "DT01-R5", "DT01-R6"], "status": "PARTIAL_EXECUTABLE", "gap": "Containment and experiment permissions are synthetic fixtures; no operational permission is tested."},
    "RDM-R04": {"clauses": ["§7"], "avt": [], "dt": ["DT02-R1", "DT02-R2", "DT02-R3", "DT02-R6"], "status": "PARTIAL_EXECUTABLE", "gap": "The minimum gate registry is closed-world, but real applicability, evidence and control-owner approval are not authenticated."},
    "RDM-R05": {"clauses": ["§7"], "avt": ["AVT-15"], "dt": ["DT02-R4", "DT02-R5", "DT02-R7"], "status": "PARTIAL_EXECUTABLE", "gap": "Conditional experiment versus genuine N/A remains RDM-U02; approvals are synthetic."},
    "RDM-R06": {"clauses": ["§8.3", "§17.10.1"], "avt": ["AVT-01", "AVT-02", "AVT-05"], "dt": ["DT03-R1", "DT03-R9"], "status": "PARTIAL_EXECUTABLE", "gap": "Evidence provenance, authority, freshness and scope are represented by synthetic flags."},
    "RDM-R07": {"clauses": ["§8.3"], "avt": ["AVT-02", "AVT-03", "AVT-04"], "dt": ["DT03-R2", "DT03-R3", "DT03-R4", "DT03-R5", "DT03-R6", "DT03-R7"], "status": "PARTIAL_EXECUTABLE", "gap": "Generic anchors do not replace criterion-specific pre-approved measurable thresholds."},
    "RDM-R08": {"clauses": ["§8.3", "§17.10.1"], "avt": ["AVT-18", "AVT-19", "AVT-20", "AVT-21"], "dt": ["DT03-R8", "DT03-R9"], "status": "PARTIAL_EXECUTABLE", "gap": "The harness does not establish real evidence atomization or semantic dependencies in arbitrary compound criteria."},
    "RDM-R09": {"clauses": ["§8.3", "§17.10.1"], "avt": ["AVT-14"], "dt": ["DT04-R1", "DT04-R2"], "status": "PARTIAL_EXECUTABLE", "gap": "Prior approval, authority and scope-change legitimacy are synthetic inputs."},
    "RDM-R10": {"clauses": ["§8.3"], "avt": ["AVT-16", "AVT-17"], "dt": ["DT04-R3", "DT04-R7"], "status": "PARTIAL_EXECUTABLE", "gap": "Arithmetic and candidate invariance are bounded fixtures; rubric approval and candidate completeness are not independently verified."},
    "RDM-R11": {"clauses": ["§8.3", "§17.10.1"], "avt": ["AVT-01"], "dt": ["DT04-R4", "DT04-R5"], "status": "PARTIAL_UNRESOLVED", "gap": "Materiality criteria and definitive treatment of non-material NS remain RDM-U01."},
    "RDM-R12": {"clauses": ["§8.3", "§17.10.1"], "avt": ["AVT-01"], "dt": ["DT04-R6"], "status": "PARTIAL_UNRESOLVED", "gap": "Delegation, expiry, disclosure schema and permitted downstream use remain unresolved; authority is a synthetic fixture."},
    "RDM-R13": {"clauses": ["§5.1", "§17.10.2"], "avt": [], "dt": [], "status": "HUMAN_REVIEW_REQUIRED", "gap": "No direct executable test for source authority, independence, directness, provenance, freshness, reproducibility or conflicts."},
    "RDM-R14": {"clauses": ["§5.2", "§17.10.2"], "avt": [], "dt": [], "status": "HUMAN_REVIEW_REQUIRED", "gap": "No direct executable test for High/Medium/Low confidence rationale or its separation from capability score."},
    "RDM-R15": {"clauses": ["§17.10.4"], "avt": ["AVT-10", "AVT-13"], "dt": ["DT05-R1", "DT05-R2", "DT05-R3", "DT05-R4", "DT05-R6", "DT05-R7"], "status": "PARTIAL_EXECUTABLE", "gap": "Synthetic risk fields do not validate real scenarios, control operation, horizon calibration or acceptance authority."},
    "RDM-R16": {"clauses": ["§17.10.4"], "avt": ["AVT-11", "AVT-12"], "dt": ["DT05-R5"], "status": "PARTIAL_EXECUTABLE", "gap": "Per-dimension anchors and separate pairs are structurally checked; no calibrated quantitative risk measure is established."},
    "RDM-R17": {"clauses": ["§17.10.6"], "avt": [], "dt": [], "status": "HUMAN_REVIEW_REQUIRED", "gap": "No executable test establishes assurance-provider competence, objectivity, independence, scope or acceptance authority."},
    "RDM-R18": {"clauses": ["§4", "§7", "§8.3", "§17.10"], "avt": [], "dt": [], "status": "STATIC_TRACEABILITY_GUARD_ONLY", "gap": "This RDM-005 audit checks declared static links only; RDM-R18 is a derived guard awaiting owner confirmation, not adopted policy."},
}

AVT_RULES = {
    "AVT-01": ["RDM-R06", "RDM-R11", "RDM-R12"],
    "AVT-02": ["RDM-R06", "RDM-R07"],
    "AVT-03": ["RDM-R07"],
    "AVT-04": ["RDM-R07"],
    "AVT-05": ["RDM-R06"],
    "AVT-06": ["RDM-R01", "RDM-R03"],
    "AVT-07": ["RDM-R02"],
    "AVT-08": ["RDM-R02"],
    "AVT-09": ["RDM-R01", "RDM-R02"],
    "AVT-10": ["RDM-R15"],
    "AVT-11": ["RDM-R16"],
    "AVT-12": ["RDM-R16"],
    "AVT-13": ["RDM-R15"],
    "AVT-14": ["RDM-R09"],
    "AVT-15": ["RDM-R05"],
    "AVT-16": ["RDM-R10"],
    "AVT-17": ["RDM-R10"],
    "AVT-18": ["RDM-R08"],
    "AVT-19": ["RDM-R08"],
    "AVT-20": ["RDM-R08"],
    "AVT-21": ["RDM-R08"],
}

MUT_RULES = {
    "MUT-01": ["RDM-R06"], "MUT-02": ["RDM-R06", "RDM-R11"],
    "MUT-03": ["RDM-R07"], "MUT-04": ["RDM-R02"],
    "MUT-05": ["RDM-R03"], "MUT-06": ["RDM-R15"],
    "MUT-07": ["RDM-R16"], "MUT-08": ["RDM-R15"],
    "MUT-09": ["RDM-R09", "RDM-R10", "RDM-R11"],
    "MUT-10": ["RDM-R08"],
}

GUARD_RULES = {
    "GUARD-01-invalid-tier-trigger": ["RDM-R02"],
    "GUARD-02-empty-candidate-population": ["RDM-R10"],
    "GUARD-03-negative-weight": ["RDM-R10"],
    "GUARD-04-empty-compound-atoms": ["RDM-R08"],
    "GUARD-05-inconsistent-material-ns": ["RDM-R11", "RDM-R12"],
    "GUARD-06-incomplete-provisional-authority": ["RDM-R12"],
    "GUARD-07-boolean-capability-rating": ["RDM-R06", "RDM-R07"],
    "GUARD-08-boolean-risk-anchor": ["RDM-R15", "RDM-R16"],
}

MT_RULES = {
    "MT-01-tier-monotonicity": ["RDM-R02"],
    "MT-02-unknown-scope-no-definitive-lower-tier": ["RDM-R01", "RDM-R02"],
    "MT-03-uniform-na-denominator-and-candidate-invariance": ["RDM-R10"],
    "MT-04-missing-risk-field-non-improving": ["RDM-R15"],
    "MT-05-partial-evidence-no-parent-score": ["RDM-R08"],
    "MT-06-experiment-does-not-grant-production": ["RDM-R03", "RDM-R04", "RDM-R05"],
    "MT-07-failed-mandatory-gate-blocks-provisional-output": ["RDM-R04", "RDM-R05", "RDM-R12"],
    "MT-08-partial-coverage-precedes-insufficient-evidence": ["RDM-R06", "RDM-R08"],
    "MT-09-inherent-and-residual-risk-pairs-are-required": ["RDM-R15", "RDM-R16"],
    "MT-10-risk-anchors-reject-boolean-and-non-integer-values": ["RDM-R15", "RDM-R16"],
    "MT-11-risk-schema-rejects-duplicate-dimensions-and-blank-evidence": ["RDM-R15", "RDM-R16"],
}

TARGETED_MUTATION_RULES = {
    "MUT-TIER-LOWEST-killed": ["RDM-R02"],
    "MUT-OMIT-GATE-PASS-killed": ["RDM-R04", "RDM-R05"],
    "MUT-EVIDENCE-ZERO-killed": ["RDM-R06", "RDM-R07"],
    "MUT-RISK-PRODUCT-killed": ["RDM-R16"],
}

DT_RULES = {
    "DT01-R1": ["RDM-R02"], "DT01-R2": ["RDM-R02"],
    "DT01-R3": ["RDM-R02"], "DT01-R4": ["RDM-R02", "RDM-R03"],
    "DT01-R5": ["RDM-R01", "RDM-R02", "RDM-R03"],
    "DT01-R6": ["RDM-R01", "RDM-R02", "RDM-R03"],
    "DT02-R1": ["RDM-R04"], "DT02-R2": ["RDM-R04"],
    "DT02-R3": ["RDM-R04"], "DT02-R4": ["RDM-R05"],
    "DT02-R5": ["RDM-R05"], "DT02-R6": ["RDM-R04"],
    "DT02-R7": ["RDM-R05"],
    "DT03-R1": ["RDM-R06"], "DT03-R2": ["RDM-R07"],
    "DT03-R3": ["RDM-R07"], "DT03-R4": ["RDM-R07"],
    "DT03-R5": ["RDM-R07"], "DT03-R6": ["RDM-R07"],
    "DT03-R7": ["RDM-R07"], "DT03-R8": ["RDM-R08"],
    "DT03-R9": ["RDM-R06", "RDM-R08"],
    "DT04-R1": ["RDM-R09"], "DT04-R2": ["RDM-R09"],
    "DT04-R3": ["RDM-R10"], "DT04-R4": ["RDM-R11"],
    "DT04-R5": ["RDM-R11"], "DT04-R6": ["RDM-R12"],
    "DT04-R7": ["RDM-R10"],
    "DT05-R1": ["RDM-R15"], "DT05-R2": ["RDM-R15"],
    "DT05-R3": ["RDM-R15"], "DT05-R4": ["RDM-R15"],
    "DT05-R5": ["RDM-R16"], "DT05-R6": ["RDM-R15"],
    "DT05-R7": ["RDM-R15"],
}

def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")

def ids(text: str, pattern: str) -> set[str]:
    return set(re.findall(pattern, text))


def heading_exists(text: str, section_number: str) -> bool:
    # Avoid f-string brace interpolation changing the regex quantifier.
    pattern = r"^\s*#{2,3}\s+" + re.escape(section_number) + r"(?:\s|\.|$)"
    return bool(re.search(pattern, text, re.M))


def source_clauses_by_rule(catalogue_text: str) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    for line in catalogue_text.splitlines():
        if not line.startswith("| RDM-R"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) >= 3:
            result[cells[0]] = set(re.findall(r"§\s*([0-9]+(?:\.[0-9]+)*)", cells[2]))
    return result


CHECK_RESULTS: list[bool] = []

def check(condition: bool, label: str, failures: list[str]) -> None:
    result = bool(condition)
    CHECK_RESULTS.append(result)
    if not result:
        failures.append(label)

def run() -> dict:
    CHECK_RESULTS.clear()
    failures: list[str] = []
    catalogue = read("docs/en/governance/enterprise-evaluation-decision-rule-catalogue-001.md")
    matrix = read("docs/en/governance/enterprise-evaluation-adversarial-test-matrix-001.md")
    standard = read("docs/en/governance/enterprise-evaluation-standard.md")
    rdm001_doc = read("docs/en/governance/enterprise-evaluation-reference-decision-model-001.md")
    rdm001 = read("tools/lot_eval_rdm.py")
    rdm004 = read("tools/lot_eval_rdm004.py")
    fa_catalogue = read("docs/fa/governance/enterprise-evaluation-decision-rule-catalogue-001.md")
    fa_matrix = read("docs/fa/governance/enterprise-evaluation-adversarial-test-matrix-001.md")
    fa_standard = read("docs/fa/governance/enterprise-evaluation-standard.md").translate(str.maketrans("۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩", "01234567890123456789"))

    expected_rules = set(RULE_TRACE)
    expected_avt = {f"AVT-{i:02d}" for i in range(1, 22)}
    expected_mut = {f"MUT-{i:02d}" for i in range(1, 11)}
    expected_dt = set(DT_RULES)
    expected_guards = set(GUARD_RULES)
    expected_mt = set(MT_RULES)
    expected_targeted = set(TARGETED_MUTATION_RULES)

    actual_rules = ids(catalogue, r"\bRDM-R\d{2}\b")
    actual_avt_matrix = ids(matrix, r"\bAVT-\d{2}\b")
    actual_avt_code = ids(rdm001, r"\bAVT-\d{2}\b")
    actual_mut_matrix = ids(matrix, r"\bMUT-\d{2}\b")
    actual_mut_code = ids(rdm001, r"\bMUT-\d{2}\b")
    actual_dt_catalogue = ids(catalogue, r"\bDT0[1-5]-R\d{1,2}\b")
    actual_dt_code = ids(rdm004, r"\bDT0[1-5]-R\d{1,2}\b")
    actual_guards = ids(rdm001, r"GUARD-\d{2}-[a-z-]+")
    actual_mt = ids(rdm004, r"MT-\d{2}-[a-z-]+")
    actual_targeted = ids(rdm004, r"MUT-[A-Z-]+-killed")

    check(actual_rules == expected_rules, f"rule population mismatch: missing={sorted(expected_rules-actual_rules)} extra={sorted(actual_rules-expected_rules)}", failures)
    check(actual_avt_matrix == expected_avt, f"matrix AVT population mismatch: missing={sorted(expected_avt-actual_avt_matrix)} extra={sorted(actual_avt_matrix-expected_avt)}", failures)
    check(actual_avt_code == expected_avt, f"RDM-001 AVT population mismatch: missing={sorted(expected_avt-actual_avt_code)} extra={sorted(actual_avt_code-expected_avt)}", failures)
    check(actual_mut_matrix == expected_mut, f"matrix mutation population mismatch: missing={sorted(expected_mut-actual_mut_matrix)} extra={sorted(actual_mut_matrix-expected_mut)}", failures)
    check(expected_mut.issubset(actual_mut_code), f"RDM-001 mutation IDs missing: {sorted(expected_mut-actual_mut_code)}", failures)
    check(actual_dt_catalogue == expected_dt, f"catalogue DT population mismatch: missing={sorted(expected_dt-actual_dt_catalogue)} extra={sorted(actual_dt_catalogue-expected_dt)}", failures)
    check(actual_dt_code == expected_dt, f"RDM-004 DT population mismatch: missing={sorted(expected_dt-actual_dt_code)} extra={sorted(actual_dt_code-expected_dt)}", failures)
    check(actual_guards == expected_guards, f"RDM-001 guard population mismatch: missing={sorted(expected_guards-actual_guards)} extra={sorted(actual_guards-expected_guards)}", failures)
    check(actual_mt == expected_mt, f"RDM-004 metamorphic population mismatch: missing={sorted(expected_mt-actual_mt)} extra={sorted(actual_mt-expected_mt)}", failures)
    check(actual_targeted == expected_targeted, f"RDM-004 targeted mutation population mismatch: missing={sorted(expected_targeted-actual_targeted)} extra={sorted(actual_targeted-expected_targeted)}", failures)

    # Source declarations must agree with the source column in the normative
    # catalogue; checking only that a heading exists would miss wrong links.
    catalogue_sources = source_clauses_by_rule(catalogue)
    check(set(catalogue_sources) == expected_rules,
          "catalogue source-clause register population mismatch", failures)

    # Parser regression guards for heading levels, nested sections, Persian
    # numerals and token boundaries (AVT-001 must not become AVT-00).
    check(heading_exists("## 4. Heading", "4"),
          "heading parser: level-2 section failed", failures)
    check(heading_exists("### 17.10.3 Heading", "17.10.3"),
          "heading parser: nested section failed", failures)
    fa_digits = str.maketrans("۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩", "01234567890123456789")
    fa_section = "۱۷.۱۰.۳".translate(fa_digits)
    check(heading_exists("### ۱۷.۱۰.۳ عنوان", fa_section),
          "heading parser: Persian numeral section failed", failures)
    check(ids("LOT-EVAL-AVT-001 AVT-01", r"\bAVT-\d{2}\b") == {"AVT-01"},
          "identifier parser: AVT-001 prefix false positive", failures)

    # Every rule must have a real parent clause and an explicit coverage state.
    for rule, spec in RULE_TRACE.items():
        check(set(spec["clauses"]) == catalogue_sources.get(rule, set()),
              f"{rule}: declared parent clauses differ from catalogue source column",
              failures)
        check(bool(spec["clauses"]), f"{rule}: no parent clause", failures)
        check(spec["status"] in {"PARTIAL_EXECUTABLE", "PARTIAL_UNRESOLVED", "HUMAN_REVIEW_REQUIRED", "STATIC_TRACEABILITY_GUARD_ONLY"}, f"{rule}: invalid coverage status", failures)
        check(bool(spec["gap"].strip()), f"{rule}: coverage limitation missing", failures)
        for clause in spec["clauses"]:
            number = clause.replace("§", "")
            check(heading_exists(standard, number),
                  f"{rule}: source clause {clause} not found in parent standard", failures)
        check(set(spec["avt"]).issubset(expected_avt), f"{rule}: unknown AVT link", failures)
        check(set(spec["dt"]).issubset(expected_dt), f"{rule}: unknown DT link", failures)
        if spec["status"] == "HUMAN_REVIEW_REQUIRED":
            check(not spec["avt"] and not spec["dt"], f"{rule}: human-only status contradicts test links", failures)
        if spec["status"] == "STATIC_TRACEABILITY_GUARD_ONLY":
            check(not spec["avt"] and not spec["dt"], f"{rule}: static-only status contradicts AVT/DT links", failures)

    # Forward and reverse mappings must agree for every registered test item.
    def reverse_from_rules(field: str) -> dict[str, set[str]]:
        rev: dict[str, set[str]] = {}
        for rule, spec in RULE_TRACE.items():
            for item in spec[field]:
                rev.setdefault(item, set()).add(rule)
        return rev

    for field, mapping, expected, label in [
        ("avt", AVT_RULES, expected_avt, "AVT"),
        ("dt", DT_RULES, expected_dt, "DT"),
    ]:
        forward = reverse_from_rules(field)
        check(set(mapping) == expected, f"{label} reverse map population mismatch", failures)
        for item in expected:
            check(bool(mapping.get(item)), f"{label} {item}: no source rule", failures)
            check(set(mapping.get(item, [])) == forward.get(item, set()), f"{label} {item}: forward/reverse mapping mismatch", failures)

    for label, mapping, expected in [
        ("MUT", MUT_RULES, expected_mut),
        ("GUARD", GUARD_RULES, expected_guards),
        ("MT", MT_RULES, expected_mt),
        ("TARGETED_MUTATION", TARGETED_MUTATION_RULES, expected_targeted),
    ]:
        check(set(mapping) == expected, f"{label} mapping population mismatch", failures)
        for item, linked_rules in mapping.items():
            check(bool(linked_rules), f"{label} {item}: no source rule", failures)
            check(set(linked_rules).issubset(expected_rules), f"{label} {item}: unknown rule reference", failures)

    # Source clauses and test IDs must also exist in both language baselines.
    check(ids(fa_catalogue, r"RDM-R\d{2}") == expected_rules, "FA rule population differs from EN", failures)
    check(ids(fa_matrix, r"AVT-\d{2}") == expected_avt, "FA AVT population differs from EN", failures)
    check(ids(fa_matrix, r"MUT-\d{2}") == expected_mut, "FA mutation population differs from EN", failures)
    for section in ["4", "7", "8.3", "5.1", "5.2", "17.10.1", "17.10.2", "17.10.3", "17.10.4", "17.10.6"]:
        number = re.escape(section)
        check(heading_exists(fa_standard, section), f"FA parent section {section} missing", failures)

    # Rule coverage is reported honestly; the static audit does not promote it.
    human_only = sorted(r for r, s in RULE_TRACE.items() if s["status"] == "HUMAN_REVIEW_REQUIRED")
    unresolved = sorted(r for r, s in RULE_TRACE.items() if s["status"] == "PARTIAL_UNRESOLVED")
    static_only = sorted(r for r, s in RULE_TRACE.items() if s["status"] == "STATIC_TRACEABILITY_GUARD_ONLY")
    linked_rules = sum(bool(s["avt"] or s["dt"]) for s in RULE_TRACE.values())

    return {
        "model": "LOT-EVAL-RDM-005",
        "scope": "static bidirectional traceability and source-ID integrity only",
        "populations": {
            "rules": len(expected_rules), "AVT": len(expected_avt), "specification_mutations": len(expected_mut),
            "decision_table_rows": len(expected_dt), "RDM001_guards": len(expected_guards),
            "RDM004_metamorphic": len(expected_mt), "RDM004_targeted_mutations": len(expected_targeted),
        },
        "coverage_classification": {
            "rules_with_AVT_or_DT_links": linked_rules,
            "human_review_required": human_only,
            "partially_unresolved": unresolved,
            "static_guard_only": static_only,
        },
        "traceability_checks": {
            "executed": len(CHECK_RESULTS), "failed": len(failures), "passed": sum(CHECK_RESULTS),
            "failures": failures,
        },
        "limitations": [
            "A syntactically valid link is not proof that the linked test semantically verifies the rule.",
            "AVT checks and decision-table row fixtures are bounded and do not establish complete parent-standard coverage.",
            "RDM-R13, RDM-R14 and RDM-R17 remain human-review requirements; RDM-R18 remains a proposed derived guard awaiting owner confirmation.",
            "RDM-R11 and RDM-R12 remain partially unresolved because materiality, authority, expiry and downstream-use policy are not fully specified.",
            "No independent oracle, reviewer, assurance provider, legal eligibility, owner approval or production readiness is established.",
            "This checker is not imported by product/runtime code and uses no external services or production data.",
        ],
    }

if __name__ == "__main__":
    report = run()
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    raise SystemExit(1 if report["traceability_checks"]["failed"] else 0)
