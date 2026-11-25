from __future__ import annotations
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build import ROOT, assert_no_cross_product_imports, build_product


class ProductCompositionTests(unittest.TestCase):
    def build_and_run(self, product_id: str):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        artifact = build_product(product_id, Path(temp.name) / product_id)
        result = subprocess.run(
            [sys.executable, "run.py"], cwd=artifact,
            env={"PATH": os.environ["PATH"], "PYTHONPATH": str(artifact)},
            check=True, capture_output=True, text=True,
        )
        return artifact, json.loads(result.stdout)

    def test_affiliate_agent_builds_and_runs_without_lottery(self):
        artifact, result = self.build_and_run("affiliate_agent")
        self.assertEqual(result["product_id"], "affiliate_agent")
        self.assertEqual(result["status"], "ok")
        self.assertFalse((artifact / "lottery.py").exists())

    def test_lottery_builds_and_runs_without_affiliate_agent(self):
        artifact, result = self.build_and_run("lottery")
        self.assertEqual(result["product_id"], "lottery")
        self.assertEqual(result["status"], "ok")
        self.assertFalse((artifact / "affiliate_agent.py").exists())

    def test_affiliate_manifest_has_no_lottery_dependency(self):
        manifest = json.loads((ROOT / "manifests" / "affiliate-agent.json").read_text())
        self.assertEqual(manifest["product_dependencies"], [])
        self.assertIn("lottery", manifest["forbidden_product_dependencies"])

    def test_lottery_manifest_has_no_affiliate_dependency(self):
        manifest = json.loads((ROOT / "manifests" / "lottery.json").read_text())
        self.assertEqual(manifest["product_dependencies"], [])
        self.assertIn("affiliate_agent", manifest["forbidden_product_dependencies"])

    def test_artifact_contains_only_selected_entrypoint(self):
        for product_id in ("affiliate_agent", "lottery"):
            with self.subTest(product=product_id), tempfile.TemporaryDirectory() as temp:
                artifact = build_product(product_id, Path(temp) / "artifact")
                self.assertEqual({p.name for p in artifact.iterdir()}, {"platform_core.py", "product.py", "manifest.json", "run.py"})

    def test_cross_product_import_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "forbidden cross-product import"):
            assert_no_cross_product_imports("from products import lottery", "lottery")

    def test_dynamic_import_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "dynamic imports"):
            assert_no_cross_product_imports("__import__('products.lottery')", "lottery")

    def test_importlib_dynamic_import_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "importlib dynamic imports"):
            assert_no_cross_product_imports("import importlib" + chr(10) + "importlib.import_module('products.lottery')", "lottery")

    def test_smoke_audit_is_scoped_to_selected_product(self):
        for product_id in ("affiliate_agent", "lottery"):
            with self.subTest(product=product_id):
                _, result = self.build_and_run(product_id)
                self.assertEqual(result["audit"]["product_id"], product_id)
                self.assertEqual(result["audit"]["outcome"], "accepted")
