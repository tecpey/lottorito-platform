from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from lifecycle import (
    AUDIT_LOG,
    AuthorizationError,
    LifecycleConflict,
    LifecycleError,
    apply_migration,
    audit_snapshot,
    load_fixture,
    plan_migrations,
    product_ownership,
    promote_release,
    read_product_config,
    read_white_label_trace,
    retire_previous_release,
    rollback_release,
    run_product_operation,
    set_product_enabled,
    update_product_config,
    verify_release,
)

OP_ALPHA = "operator-alpha-token"
OP_BETA = "operator-beta-token"
AFF_RELEASE = "affiliate-release-token"
LOT_RELEASE = "lottery-release-token"
AFF_MIGRATOR = "affiliate-migration-token"
LOT_MIGRATOR = "lottery-migration-token"
PLATFORM_MIGRATOR = "platform-migration-token"
PLATFORM_ADMIN = "platform-admin-token"


class ProductEnablementTests(unittest.TestCase):
    def setUp(self):
        self.state = load_fixture()
        AUDIT_LOG.clear()

    def test_disabling_lottery_does_not_disable_affiliate(self):
        set_product_enabled(self.state, "tenant-alpha", "lottery", False, OP_ALPHA)
        products = self.state["tenants"]["tenant-alpha"]["products"]
        self.assertFalse(products["lottery"]["enabled"])
        self.assertTrue(products["affiliate_agent"]["enabled"])

    def test_disabling_affiliate_does_not_disable_lottery(self):
        set_product_enabled(self.state, "tenant-beta", "affiliate_agent", False, OP_BETA)
        products = self.state["tenants"]["tenant-beta"]["products"]
        self.assertFalse(products["affiliate_agent"]["enabled"])
        self.assertTrue(products["lottery"]["enabled"])

    def test_disable_preserves_data_ledger_config_release_and_schema(self):
        tenant = self.state["tenants"]["tenant-alpha"]
        before = copy.deepcopy(tenant)
        set_product_enabled(self.state, "tenant-alpha", "affiliate_agent", False, OP_ALPHA)
        after = self.state["tenants"]["tenant-alpha"]
        self.assertEqual(after["products"]["affiliate_agent"]["records_count"], before["products"]["affiliate_agent"]["records_count"])
        self.assertEqual(after["products"]["affiliate_agent"]["ledger_entry_count"], before["products"]["affiliate_agent"]["ledger_entry_count"])
        self.assertEqual(after["products"]["affiliate_agent"]["config"], before["products"]["affiliate_agent"]["config"])
        self.assertEqual(after["products"]["affiliate_agent"]["active_release"], before["products"]["affiliate_agent"]["active_release"])
        self.assertEqual(after["schemas"], before["schemas"])

    def test_disabling_product_does_not_disable_shared_platform_services(self):
        shared = copy.deepcopy(self.state["tenants"]["tenant-alpha"]["shared_services"])
        set_product_enabled(self.state, "tenant-alpha", "lottery", False, OP_ALPHA)
        self.assertEqual(self.state["tenants"]["tenant-alpha"]["shared_services"], shared)
        self.assertTrue(all(shared.values()))

    def test_disabled_product_rejects_new_product_operation(self):
        with self.assertRaisesRegex(LifecycleError, "product_disabled"):
            run_product_operation(self.state, "tenant-alpha", "lottery", "synthetic_smoke")

    def test_reenable_restores_product_without_recreating_state(self):
        before = copy.deepcopy(self.state["tenants"]["tenant-alpha"]["products"]["lottery"])
        set_product_enabled(self.state, "tenant-alpha", "lottery", True, OP_ALPHA)
        after = self.state["tenants"]["tenant-alpha"]["products"]["lottery"]
        self.assertTrue(after["enabled"])
        self.assertEqual(after["records_count"], before["records_count"])
        self.assertEqual(after["active_release"], before["active_release"])
        self.assertEqual(after["config_version"], before["config_version"])

    def test_shared_capability_cannot_be_disabled_as_a_product(self):
        with self.assertRaisesRegex(LifecycleError, "unknown_or_non_product_capability"):
            set_product_enabled(self.state, "tenant-alpha", "identity", False, OP_ALPHA)

    def test_operator_cannot_change_another_tenants_product_state(self):
        with self.assertRaisesRegex(AuthorizationError, "operator_tenant_mismatch"):
            set_product_enabled(self.state, "tenant-beta", "lottery", False, OP_ALPHA)


class ProductConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.state = load_fixture()
        AUDIT_LOG.clear()

    def test_affiliate_config_update_does_not_change_lottery_config(self):
        lottery_before = copy.deepcopy(self.state["tenants"]["tenant-alpha"]["products"]["lottery"]["config"])
        result = update_product_config(
            self.state, "tenant-alpha", "affiliate_agent",
            {"portal_title": "Updated Affiliate", "commission_rate_bps": 500},
            OP_ALPHA,
        )
        self.assertEqual(result["config_version"], 2)
        self.assertEqual(self.state["tenants"]["tenant-alpha"]["products"]["lottery"]["config"], lottery_before)

    def test_unknown_product_config_key_is_rejected(self):
        with self.assertRaisesRegex(LifecycleError, "unknown_product_config_key"):
            update_product_config(self.state, "tenant-alpha", "affiliate_agent", {"lottery_draw_label": "oops"}, OP_ALPHA)

    def test_raw_secret_value_is_rejected(self):
        with self.assertRaisesRegex(LifecycleError, "secret_reference_required"):
            update_product_config(self.state, "tenant-alpha", "affiliate_agent", {"payout_secret_ref": "plain-secret-value"}, OP_ALPHA)

    def test_secret_reference_is_accepted_without_logging_value(self):
        update_product_config(self.state, "tenant-alpha", "affiliate_agent", {"payout_secret_ref": "secret://vault/alpha/new-payout"}, OP_ALPHA)
        self.assertNotIn("secret://vault/alpha/new-payout", json.dumps(audit_snapshot()))

    def test_disabled_product_config_cannot_be_changed(self):
        with self.assertRaisesRegex(LifecycleError, "product_disabled"):
            update_product_config(self.state, "tenant-alpha", "lottery", {"display_label": "New label"}, OP_ALPHA)

    def test_operator_cannot_read_another_tenants_config(self):
        with self.assertRaisesRegex(AuthorizationError, "operator_tenant_mismatch"):
            read_product_config(self.state, "tenant-beta", "affiliate_agent", OP_ALPHA)

    def test_product_config_read_is_namespaced(self):
        config = read_product_config(self.state, "tenant-alpha", "affiliate_agent", OP_ALPHA)
        self.assertIn("portal_title", config)
        self.assertNotIn("display_label", config)
        self.assertNotIn("notification_secret_ref", config)


class MigrationIsolationTests(unittest.TestCase):
    def setUp(self):
        self.state = load_fixture()
        AUDIT_LOG.clear()

    def test_migration_plan_is_filtered_by_owner(self):
        self.assertEqual(plan_migrations("affiliate_agent"), ["affiliate-contract-v3", "affiliate-expand-v2"])
        self.assertEqual(plan_migrations("lottery"), ["lottery-expand-v2"])
        self.assertEqual(plan_migrations("platform"), ["platform-expand-v2"])

    def test_affiliate_migration_changes_only_affiliate_schema(self):
        before = copy.deepcopy(self.state["tenants"]["tenant-alpha"]["schemas"])
        result = apply_migration(self.state, "tenant-alpha", "affiliate-expand-v2", AFF_MIGRATOR)
        after = self.state["tenants"]["tenant-alpha"]["schemas"]
        self.assertEqual(result["status"], "applied")
        self.assertEqual(after["affiliate_agent"], 2)
        self.assertEqual(after["lottery"], before["lottery"])
        self.assertEqual(after["platform"], before["platform"])

    def test_lottery_migration_changes_only_lottery_schema(self):
        before = copy.deepcopy(self.state["tenants"]["tenant-beta"]["schemas"])
        result = apply_migration(self.state, "tenant-beta", "lottery-expand-v2", LOT_MIGRATOR)
        after = self.state["tenants"]["tenant-beta"]["schemas"]
        self.assertEqual(result["status"], "applied")
        self.assertEqual(after["lottery"], 2)
        self.assertEqual(after["affiliate_agent"], before["affiliate_agent"])
        self.assertEqual(after["platform"], before["platform"])

    def test_cross_product_migration_is_denied(self):
        with self.assertRaisesRegex(AuthorizationError, "product_migration_owner_mismatch"):
            apply_migration(self.state, "tenant-beta", "lottery-expand-v2", AFF_MIGRATOR)

    def test_disabled_product_migration_is_denied(self):
        with self.assertRaisesRegex(LifecycleError, "product_disabled"):
            apply_migration(self.state, "tenant-alpha", "lottery-expand-v2", PLATFORM_ADMIN)

    def test_migration_is_idempotent(self):
        apply_migration(self.state, "tenant-alpha", "affiliate-expand-v2", AFF_MIGRATOR)
        result = apply_migration(self.state, "tenant-alpha", "affiliate-expand-v2", AFF_MIGRATOR)
        self.assertEqual(result["status"], "already_applied")
        self.assertEqual(self.state["tenants"]["tenant-alpha"]["schemas"]["affiliate_agent"], 2)

    def test_product_runner_cannot_apply_platform_migration(self):
        with self.assertRaisesRegex(AuthorizationError, "platform_migration_runner_required"):
            apply_migration(self.state, "tenant-alpha", "platform-expand-v2", AFF_MIGRATOR)

    def test_platform_migration_changes_only_platform_schema(self):
        before = copy.deepcopy(self.state["tenants"]["tenant-alpha"]["schemas"])
        result = apply_migration(self.state, "tenant-alpha", "platform-expand-v2", PLATFORM_MIGRATOR)
        after = self.state["tenants"]["tenant-alpha"]["schemas"]
        self.assertEqual(result["status"], "applied")
        self.assertEqual(after["platform"], 2)
        self.assertEqual(after["affiliate_agent"], before["affiliate_agent"])
        self.assertEqual(after["lottery"], before["lottery"])

    def test_contract_migration_requires_expand_and_compatible_release(self):
        apply_migration(self.state, "tenant-alpha", "affiliate-expand-v2", AFF_MIGRATOR)
        with self.assertRaisesRegex(LifecycleError, "active_release_cannot_read_target_schema"):
            apply_migration(self.state, "tenant-alpha", "affiliate-contract-v3", AFF_MIGRATOR)

    def test_contract_migration_waits_for_old_rollback_target_retirement(self):
        apply_migration(self.state, "tenant-alpha", "affiliate-expand-v2", AFF_MIGRATOR)
        promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "affiliate-v1", AFF_RELEASE)
        with self.assertRaisesRegex(LifecycleError, "incompatible_rollback_release_retained"):
            apply_migration(self.state, "tenant-alpha", "affiliate-contract-v3", AFF_MIGRATOR)
        with self.assertRaisesRegex(AuthorizationError, "explicit_retirement_confirmation_required"):
            retire_previous_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v1", AFF_RELEASE, "YES")
        retire_previous_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v1", AFF_RELEASE, "RETIRE_PREVIOUS_RELEASE")
        result = apply_migration(self.state, "tenant-alpha", "affiliate-contract-v3", AFF_MIGRATOR)
        self.assertEqual(result["schema_version"], 3)
        with self.assertRaisesRegex(LifecycleError, "no_previous_release"):
            rollback_release(self.state, "tenant-alpha", "affiliate_agent", AFF_RELEASE)

    def test_platform_runner_cannot_migrate_outside_allowed_tenant_scope(self):
        with self.assertRaisesRegex(AuthorizationError, "migration_tenant_scope_denied"):
            apply_migration(self.state, "tenant-unknown", "platform-expand-v2", PLATFORM_MIGRATOR)


class ReleaseAndRollbackTests(unittest.TestCase):
    def setUp(self):
        self.state = load_fixture()
        AUDIT_LOG.clear()

    def test_release_provenance_fixture_is_consistent(self):
        releases = json.loads((ROOT / "registry" / "releases.json").read_text())["releases"]
        self.assertTrue(verify_release(releases["affiliate-v1"]))
        self.assertTrue(verify_release(releases["affiliate-v2"]))

    def test_invalid_artifact_digest_breaks_provenance_verification(self):
        releases = json.loads((ROOT / "registry" / "releases.json").read_text())["releases"]
        corrupted = copy.deepcopy(releases["affiliate-v2"])
        corrupted["artifact_digest"] = "sha256:not-a-digest"
        self.assertFalse(verify_release(corrupted))

    def test_wrong_product_release_is_rejected(self):
        with self.assertRaisesRegex(LifecycleError, "release_product_mismatch"):
            promote_release(self.state, "tenant-alpha", "affiliate_agent", "lottery-v1", "affiliate-v1", AFF_RELEASE)

    def test_release_promotion_changes_only_selected_product(self):
        lottery_before = self.state["tenants"]["tenant-alpha"]["products"]["lottery"]["active_release"]
        result = promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "affiliate-v1", AFF_RELEASE)
        products = self.state["tenants"]["tenant-alpha"]["products"]
        self.assertEqual(result["status"], "promoted")
        self.assertEqual(products["affiliate_agent"]["active_release"], "affiliate-v2")
        self.assertEqual(products["lottery"]["active_release"], lottery_before)

    def test_stale_release_compare_and_swap_is_rejected(self):
        with self.assertRaisesRegex(LifecycleConflict, "stale_release_compare_and_swap"):
            promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "stale-release", AFF_RELEASE)

    def test_rollback_changes_only_selected_product(self):
        lottery_before = self.state["tenants"]["tenant-alpha"]["products"]["lottery"]["active_release"]
        promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "affiliate-v1", AFF_RELEASE)
        result = rollback_release(self.state, "tenant-alpha", "affiliate_agent", AFF_RELEASE)
        products = self.state["tenants"]["tenant-alpha"]["products"]
        self.assertEqual(result["release_id"], "affiliate-v1")
        self.assertEqual(products["lottery"]["active_release"], lottery_before)

    def test_tenant_operator_cannot_promote_global_release(self):
        with self.assertRaisesRegex(AuthorizationError, "product_release_manager_required"):
            promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "affiliate-v1", OP_ALPHA)

    def test_production_promotion_is_not_enabled_in_fixture(self):
        with self.assertRaisesRegex(LifecycleError, "production_promotion_not_enabled_in_fixture"):
            promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "affiliate-v1", AFF_RELEASE, environment="production")

    def test_product_release_manager_cannot_promote_sibling_product(self):
        with self.assertRaisesRegex(AuthorizationError, "product_release_manager_required"):
            promote_release(self.state, "tenant-alpha", "affiliate_agent", "affiliate-v2", "affiliate-v1", LOT_RELEASE)


class WhiteLabelTraceabilityTests(unittest.TestCase):
    def setUp(self):
        self.state = load_fixture()
        AUDIT_LOG.clear()

    def test_white_label_trace_contains_tenant_operator_product_and_release(self):
        trace = read_white_label_trace(self.state, "tenant-alpha", "affiliate_agent", OP_ALPHA, "corr-alpha-001")
        self.assertEqual(trace["tenant_id"], "tenant-alpha")
        self.assertEqual(trace["operator_id"], "operator-alpha")
        self.assertEqual(trace["brand_id"], "brand-alpha")
        self.assertEqual(trace["product_id"], "affiliate_agent")
        self.assertEqual(trace["release_id"], "affiliate-v1")
        self.assertEqual(trace["config_version"], 1)
        self.assertEqual(trace["schema_version"], 1)

    def test_white_label_trace_does_not_expose_config_or_secret_values(self):
        trace = read_white_label_trace(self.state, "tenant-alpha", "affiliate_agent", OP_ALPHA, "corr-alpha-002")
        serialized = json.dumps(trace)
        self.assertNotIn("secret://", serialized)
        self.assertNotIn("Affiliate Alpha", serialized)

    def test_operator_cannot_read_other_operator_trace(self):
        with self.assertRaisesRegex(AuthorizationError, "operator_tenant_mismatch"):
            read_white_label_trace(self.state, "tenant-beta", "affiliate_agent", OP_ALPHA, "corr-alpha-003")

    def test_trace_requires_correlation_id(self):
        with self.assertRaisesRegex(LifecycleError, "correlation_id_required"):
            read_white_label_trace(self.state, "tenant-alpha", "affiliate_agent", OP_ALPHA, "missing")

    def test_product_ownership_exposes_team_and_runbook(self):
        ownership = product_ownership("affiliate_agent")
        self.assertEqual(ownership["owner_team"], "team-affiliate-agent")
        self.assertEqual(ownership["runbook_ref"], "runbooks/affiliate-agent.md")

    def test_lifecycle_audit_records_metadata_without_secret_values(self):
        update_product_config(self.state, "tenant-alpha", "affiliate_agent", {"payout_secret_ref": "secret://vault/alpha/rotated"}, OP_ALPHA)
        set_product_enabled(self.state, "tenant-alpha", "lottery", False, OP_ALPHA)
        serialized = json.dumps(audit_snapshot())
        self.assertIn("corr-p07c-config", serialized)
        self.assertIn("product.disable", serialized)
        self.assertNotIn("secret://vault/alpha/rotated", serialized)
        self.assertNotIn("plain-secret-value", serialized)


if __name__ == "__main__":
    unittest.main()
