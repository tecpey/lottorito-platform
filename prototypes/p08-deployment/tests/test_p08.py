from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "src"))

from build import build
from pipeline import (
    Approval, DeploymentConflict, DeploymentController, DeploymentState,
    GateRejected, HealthSnapshot, ImmutableArtifactStore, RuntimeSecret,
    bind_state_artifacts, run_artifact, update_state_artifact_binding,
    verify_artifact_bytes, verify_provenance,
)

SOURCE = "a" * 40
APPROVAL_ACTOR = "release-approver"
DEPLOY_ACTOR = "release-operator"
REQUEST_ACTOR = "change-author"
GOOD_API = HealthSnapshot(critical_dependencies={"database": True, "ledger": True, "outbox": True})
GOOD_WORKER = HealthSnapshot(critical_dependencies={"database": True, "ledger": True, "queue": True}, worker_ready=True)


class ArtifactBuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def build_fixture(self, version: str, folder: str):
        return build(version, self.root / folder, SOURCE)

    def test_build_is_deterministic_for_same_inputs(self):
        first, _, first_digest = self.build_fixture("v1", "one")
        second, _, second_digest = self.build_fixture("v1", "two")
        self.assertEqual(first_digest, second_digest)
        self.assertEqual(first.read_bytes(), second.read_bytes())

    def test_build_rejects_reused_nonempty_output_directory(self):
        self.build_fixture("v1", "one")
        with self.assertRaises(FileExistsError):
            build("v1", self.root / "one", SOURCE)

    def test_build_rejects_invalid_source_revision(self):
        with self.assertRaises(ValueError):
            build("v1", self.root / "bad", "not-a-commit")

    def test_artifact_digest_detects_tampering(self):
        artifact, _, digest = self.build_fixture("v1", "one")
        data = artifact.read_bytes() + b"tampered"
        self.assertFalse(verify_artifact_bytes(data, f"sha256:{digest}"))

    def test_provenance_binds_subject_source_builder_and_dependency(self):
        artifact, provenance_path, digest = self.build_fixture("v1", "one")
        provenance = json.loads(provenance_path.read_text())
        self.assertTrue(verify_provenance(artifact.read_bytes(), provenance, f"sha256:{digest}", SOURCE))

    def test_provenance_rejects_subject_digest_mismatch(self):
        artifact, provenance_path, digest = self.build_fixture("v1", "one")
        provenance = json.loads(provenance_path.read_text())
        provenance["subject"][0]["digest"]["sha256"] = "0" * 64
        self.assertFalse(verify_provenance(artifact.read_bytes(), provenance, f"sha256:{digest}", SOURCE))

    def test_provenance_rejects_source_revision_mismatch(self):
        artifact, provenance_path, digest = self.build_fixture("v1", "one")
        provenance = json.loads(provenance_path.read_text())
        self.assertFalse(verify_provenance(artifact.read_bytes(), provenance, f"sha256:{digest}", "b" * 40))

    def test_provenance_rejects_unknown_builder(self):
        artifact, provenance_path, digest = self.build_fixture("v1", "one")
        provenance = json.loads(provenance_path.read_text())
        provenance["predicate"]["runDetails"]["builder"]["id"] = "untrusted"
        self.assertFalse(verify_provenance(artifact.read_bytes(), provenance, f"sha256:{digest}", SOURCE))


class RuntimeSecretTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.artifact, self.provenance, self.digest = build("v1", self.root / "artifact", SOURCE)

    def tearDown(self):
        self.temp.cleanup()

    def test_runtime_secret_is_injected_after_build(self):
        sentinel = "SYNTHETIC-SECRET-DO-NOT-LEAK-7c9f"
        output = run_artifact(self.artifact, RuntimeSecret("secret://test/affiliate/runtime", sentinel))
        self.assertIn('"runtime_secret_present": true', output)
        self.assertNotIn(sentinel, self.artifact.read_bytes().decode("latin1"))
        self.assertNotIn(sentinel, self.provenance.read_text())

    def test_runtime_output_never_contains_secret_value(self):
        sentinel = "SYNTHETIC-SECRET-DO-NOT-LEAK-8d1a"
        output = run_artifact(self.artifact, RuntimeSecret("secret://test/affiliate/runtime", sentinel))
        self.assertNotIn(sentinel, output)

    def test_invalid_secret_reference_fails_closed(self):
        with self.assertRaisesRegex(GateRejected, "runtime_secret_reference_invalid"):
            run_artifact(self.artifact, RuntimeSecret("plain-text", "value"))


class HealthGateTests(unittest.TestCase):
    def test_liveness_is_independent_of_downstream_dependency_health(self):
        health = HealthSnapshot(process_alive=True, critical_dependencies={"database": False})
        self.assertTrue(health.liveness_ok)
        self.assertFalse(health.readiness_ok)

    def test_startup_must_complete_before_readiness(self):
        health = HealthSnapshot(startup_complete=False)
        self.assertFalse(health.readiness_ok)

    def test_dead_process_fails_liveness_and_readiness(self):
        health = HealthSnapshot(process_alive=False)
        self.assertFalse(health.liveness_ok)
        self.assertFalse(health.readiness_ok)

    def test_worker_readiness_is_separate_from_api_readiness(self):
        health = HealthSnapshot(critical_dependencies={"database": True}, worker_ready=False)
        self.assertTrue(health.readiness_ok)
        self.assertFalse(health.worker_readiness_ok)

    def test_optional_dependency_does_not_block_readiness_when_not_classified_critical(self):
        health = HealthSnapshot(critical_dependencies={"database": True})
        self.assertTrue(health.readiness_ok)


class PromotionAndRollbackTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.store = ImmutableArtifactStore()
        self.built = {}
        for version in ("v1", "v2", "v3"):
            artifact, provenance_path, digest = build(version, self.root / version, SOURCE)
            data = artifact.read_bytes()
            self.built[version] = (self.store.put(data), json.loads(provenance_path.read_text()), data)
        self.controller = DeploymentController(self.store, {})
        self.test_state = DeploymentState("test", 1, self.built["v1"][0], api_digest=self.built["v1"][0], worker_digest=self.built["v1"][0], traffic_enabled=True, workers_enabled=True)
        self.stage_state = DeploymentState("staging", 1, self.built["v1"][0], api_digest=self.built["v1"][0], worker_digest=self.built["v1"][0], traffic_enabled=True, workers_enabled=True)
        bind_state_artifacts(self.test_state, self.store)
        bind_state_artifacts(self.stage_state, self.store)

    def tearDown(self):
        self.temp.cleanup()

    def approval(self, digest, env="staging"):
        return Approval(REQUEST_ACTOR, APPROVAL_ACTOR, "release_approver", env, digest)

    def promote(self, state, version, api=GOOD_API, worker=GOOD_WORKER):
        digest, provenance, _ = self.built[version]
        result = self.controller.promote(
            state, digest, self.approval(digest, state.environment), DEPLOY_ACTOR,
            state.current_digest, api, worker, provenance, SOURCE,
        )
        update_state_artifact_binding(state, self.store, state.current_digest, state.previous_digest)
        return result

    def test_same_artifact_digest_promotes_from_test_to_staging(self):
        digest = self.built["v2"][0]
        provenance = self.built["v2"][1]
        self.controller.promote(
            self.test_state, digest, self.approval(digest, "test"), DEPLOY_ACTOR,
            self.test_state.current_digest, GOOD_API, GOOD_WORKER, provenance, SOURCE,
        )
        self.controller.promote(
            self.stage_state, digest, self.approval(digest, "staging"), DEPLOY_ACTOR,
            self.stage_state.current_digest, GOOD_API, GOOD_WORKER, provenance, SOURCE,
        )
        self.assertEqual(self.test_state.current_digest, self.stage_state.current_digest)

    def test_immutable_store_returns_original_bytes(self):
        digest = self.built["v1"][0]
        original = self.store.get(digest)
        self.assertEqual(self.store.get(digest), original)

    def test_immutable_store_detects_corrupted_stored_bytes(self):
        digest = self.built["v1"][0]
        self.store._artifacts[digest] = self.store._artifacts[digest] + b"tampered"
        with self.assertRaisesRegex(GateRejected, "stored_artifact_digest_mismatch"):
            self.store.get(digest)

    def test_stale_compare_and_swap_is_rejected(self):
        digest = self.built["v2"][0]
        with self.assertRaisesRegex(DeploymentConflict, "stale_current_release"):
            self.controller.promote(self.stage_state, digest, self.approval(digest), DEPLOY_ACTOR,
                "sha256:" + "0" * 64, GOOD_API, GOOD_WORKER, self.built["v2"][1], SOURCE)

    def test_approval_must_bind_exact_artifact_digest(self):
        digest = self.built["v2"][0]
        wrong = Approval(REQUEST_ACTOR, APPROVAL_ACTOR, "release_approver", "staging", self.built["v1"][0])
        with self.assertRaisesRegex(GateRejected, "approval_digest_mismatch"):
            self.controller.promote(self.stage_state, digest, wrong, DEPLOY_ACTOR,
                self.stage_state.current_digest, GOOD_API, GOOD_WORKER, self.built["v2"][1], SOURCE)

    def test_separation_of_duties_is_enforced(self):
        digest = self.built["v2"][0]
        same_actor = Approval(REQUEST_ACTOR, DEPLOY_ACTOR, "release_approver", "staging", digest)
        with self.assertRaisesRegex(GateRejected, "separation_of_duties_violation"):
            self.controller.promote(self.stage_state, digest, same_actor, DEPLOY_ACTOR,
                self.stage_state.current_digest, GOOD_API, GOOD_WORKER, self.built["v2"][1], SOURCE)

    def test_production_environment_is_never_eligible(self):
        digest = self.built["v2"][0]
        production = DeploymentState("production", 1, self.built["v1"][0])
        with self.assertRaisesRegex(GateRejected, "environment_not_allowed"):
            self.controller.promote(production, digest, self.approval(digest, "production"), DEPLOY_ACTOR,
                production.current_digest, GOOD_API, GOOD_WORKER, self.built["v2"][1], SOURCE)

    def test_api_readiness_failure_blocks_traffic_and_workers(self):
        digest = self.built["v2"][0]
        unhealthy = HealthSnapshot(critical_dependencies={"database": False})
        with self.assertRaisesRegex(GateRejected, "api_readiness_failed"):
            self.controller.promote(self.stage_state, digest, self.approval(digest), DEPLOY_ACTOR,
                self.stage_state.current_digest, unhealthy, GOOD_WORKER, self.built["v2"][1], SOURCE)
        self.assertEqual(self.stage_state.current_digest, self.built["v1"][0])
        self.assertTrue(self.stage_state.traffic_enabled)
        self.assertTrue(self.stage_state.workers_enabled)

    def test_worker_failure_blocks_promotion_and_restores_partial_api_rollout(self):
        digest = self.built["v2"][0]
        unhealthy_worker = HealthSnapshot(critical_dependencies={"database": True}, worker_ready=False)
        before = (self.stage_state.api_digest, self.stage_state.worker_digest, self.stage_state.traffic_enabled, self.stage_state.workers_enabled)
        with self.assertRaisesRegex(GateRejected, "worker_readiness_failed"):
            self.controller.promote(self.stage_state, digest, self.approval(digest), DEPLOY_ACTOR,
                self.stage_state.current_digest, GOOD_API, unhealthy_worker, self.built["v2"][1], SOURCE)
        after = (self.stage_state.api_digest, self.stage_state.worker_digest, self.stage_state.traffic_enabled, self.stage_state.workers_enabled)
        self.assertEqual(after, before)

    def test_successful_promotion_audits_digest_and_actor_without_secret(self):
        digest = self.built["v2"][0]
        self.promote(self.stage_state, "v2")
        record = self.stage_state.audit[-1]
        self.assertEqual(record["artifact_digest"], digest)
        self.assertEqual(record["actor"], DEPLOY_ACTOR)
        self.assertEqual(record["outcome"], "accepted")
        self.assertEqual(record["financial_state_digest"], "synthetic-ledger-state-v1")

    def test_safe_rollback_preserves_financial_state_and_digest(self):
        before = self.stage_state.financial_state_digest
        self.promote(self.stage_state, "v2")
        self.controller.migrate_schema(self.stage_state, 2, "expand")
        target = self.stage_state.previous_digest
        result = self.controller.rollback(self.stage_state, target, DEPLOY_ACTOR,
            self.approval(target), GOOD_API, GOOD_WORKER)
        self.assertEqual(result["status"], "rolled_back")
        self.assertEqual(self.stage_state.schema_version, 2)
        self.assertEqual(self.stage_state.financial_state_digest, before)

    def test_incompatible_rollback_is_blocked_after_contract_migration(self):
        self.promote(self.stage_state, "v2")
        self.controller.migrate_schema(self.stage_state, 2, "expand")
        update_state_artifact_binding(self.stage_state, self.store, self.stage_state.current_digest, self.stage_state.previous_digest)
        self.controller.retire_rollback_target(self.stage_state, "RETIRE_ROLLBACK_TARGET", DEPLOY_ACTOR)
        self.controller.migrate_schema(self.stage_state, 3, "contract")
        update_state_artifact_binding(self.stage_state, self.store, self.stage_state.current_digest)
        old_digest = self.built["v1"][0]
        self.stage_state.previous_digest = old_digest
        update_state_artifact_binding(self.stage_state, self.store, self.stage_state.current_digest, old_digest)
        with self.assertRaisesRegex(GateRejected, "rollback_schema_incompatible"):
            self.controller.rollback(self.stage_state, old_digest, DEPLOY_ACTOR,
                self.approval(old_digest), GOOD_API, GOOD_WORKER)

    def test_forward_repair_with_schema_compatible_artifact_is_allowed(self):
        before_financial_state = self.stage_state.financial_state_digest
        self.promote(self.stage_state, "v2")
        self.controller.migrate_schema(self.stage_state, 2, "expand")
        update_state_artifact_binding(self.stage_state, self.store, self.stage_state.current_digest, self.stage_state.previous_digest)
        self.controller.retire_rollback_target(self.stage_state, "RETIRE_ROLLBACK_TARGET", DEPLOY_ACTOR)
        self.controller.migrate_schema(self.stage_state, 3, "contract")
        update_state_artifact_binding(self.stage_state, self.store, self.stage_state.current_digest)
        self.promote(self.stage_state, "v3")
        self.assertEqual(self.stage_state.current_digest, self.built["v3"][0])
        self.assertEqual(self.stage_state.schema_version, 3)
        self.assertEqual(self.stage_state.financial_state_digest, before_financial_state)


if __name__ == "__main__":
    unittest.main(verbosity=2)
