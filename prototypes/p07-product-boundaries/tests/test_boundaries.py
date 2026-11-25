from __future__ import annotations
import copy
import json
import unittest
from pathlib import Path
from validate_boundaries import validate

MANIFEST = json.loads(Path(__file__).parents[1].joinpath("architecture.json").read_text(encoding="utf-8"))

class ProductBoundaryTests(unittest.TestCase):
    def test_reference_graph_is_valid(self):
        self.assertEqual(validate(MANIFEST), [])

    def test_unknown_dependency_fails_closed(self):
        fixture = copy.deepcopy(MANIFEST)
        fixture["modules"][0]["depends_on"].append("affiliate.missing")
        self.assertTrue(any("unknown dependency" in error for error in validate(fixture)))

    def test_affiliate_cannot_import_lottery_domain(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "affiliate.application")
        module["depends_on"].append("lottery.domain")
        self.assertTrue(any("cross-product dependency" in error for error in validate(fixture)))

    def test_lottery_cannot_import_affiliate_adapter(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "lottery.adapters")
        module["depends_on"].append("affiliate.adapters")
        self.assertTrue(any("cross-product dependency" in error for error in validate(fixture)))

    def test_product_cannot_bypass_contract_into_platform_implementation(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "affiliate.application")
        module["depends_on"].append("platform.finance.impl")
        self.assertTrue(any("not implementation" in error for error in validate(fixture)))

    def test_platform_cannot_depend_on_product(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "platform.finance.impl")
        module["depends_on"].append("affiliate.domain")
        self.assertTrue(any("must not depend on product" in error for error in validate(fixture)))

    def test_contract_must_not_depend_on_implementation(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "platform.finance.contract")
        module["depends_on"].append("platform.finance.impl")
        self.assertTrue(any("contract must be dependency-free" in error for error in validate(fixture)))

    def test_dependency_cycle_is_rejected(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "affiliate.domain")
        module["depends_on"].append("affiliate.application")
        self.assertTrue(any("dependency cycle" in error for error in validate(fixture)))

    def test_duplicate_module_id_is_rejected(self):
        fixture = copy.deepcopy(MANIFEST)
        fixture["modules"].append(copy.deepcopy(fixture["modules"][0]))
        self.assertTrue(any("duplicate module id" in error for error in validate(fixture)))

    def test_missing_module_owner_is_rejected(self):
        fixture = copy.deepcopy(MANIFEST)
        fixture["modules"][0]["owner"] = ""
        self.assertTrue(any("owner is required" in error for error in validate(fixture)))

    def test_platform_contract_cannot_claim_product_ownership(self):
        fixture = copy.deepcopy(MANIFEST)
        module = next(item for item in fixture["modules"] if item["id"] == "platform.audit.contract")
        module["product"] = "affiliate"
        self.assertTrue(any("must not declare a product" in error for error in validate(fixture)))

    def test_shared_capability_must_have_explicit_deny_default(self):
        fixture = copy.deepcopy(MANIFEST)
        fixture["capabilities"][0]["default_access"] = "allow"
        self.assertTrue(any("default_access must be deny" in error for error in validate(fixture)))

    def test_shared_capability_requires_tenant_scope(self):
        fixture = copy.deepcopy(MANIFEST)
        fixture["capabilities"][1]["tenant_scope_required"] = False
        self.assertTrue(any("tenant_scope_required must be true" in error for error in validate(fixture)))

    def test_capability_implementation_must_match_owner(self):
        fixture = copy.deepcopy(MANIFEST)
        fixture["capabilities"][0]["implementation_module"] = "platform.audit.impl"
        self.assertTrue(any("platform owner does not match" in error for error in validate(fixture)))

    def test_finance_keeps_platform_ledger_and_product_policy_ownership_separate(self):
        finance = next(item for item in MANIFEST["capabilities"] if item["id"] == "finance")
        self.assertEqual(finance["data_owner"], "platform.finance")
        self.assertEqual(finance["domain_policy_owners"], {"affiliate":"affiliate-product","lottery":"lottery-product"})
        self.assertIn("No implicit cross-product balance pooling", finance["ownership_note"])

    def test_all_shared_capabilities_are_declared(self):
        self.assertEqual({item["id"] for item in MANIFEST["capabilities"]},
                         {"identity","tenant","authorization","finance","notifications","audit","events"})

if __name__ == "__main__":
    unittest.main(verbosity=2)
