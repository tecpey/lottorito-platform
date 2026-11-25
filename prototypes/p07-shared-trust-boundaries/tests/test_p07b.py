from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from events import dispatch_event
from policy import AUDIT_DECISIONS, authorize_product_resource, enforce_capability, evaluate_capability


AFFILIATE_TOKEN = "synthetic-affiliate-service-token"
LOTTERY_TOKEN = "synthetic-lottery-service-token"


def event(**overrides):
    value = {
        "id": "evt-p07b-001",
        "source": "urn:lottorito:product:affiliate_agent",
        "specversion": "1.0",
        "type": "com.lottorito.p07b.demo.signal.v1",
        "tenantid": "tenant-beta",
        "dataschema": "urn:lottorito:schema:affiliate.demo.signal:1",
        "classification": "internal",
        "data": {"reference": "synthetic-ref-001"},
    }
    value.update(overrides)
    return value


class SharedCapabilityPolicyTests(unittest.TestCase):
    def setUp(self):
        AUDIT_DECISIONS.clear()

    def test_affiliate_can_use_explicitly_granted_shared_identity_capability(self):
        result = enforce_capability(AFFILIATE_TOKEN, "tenant-alpha", "identity", "resolve_subject")
        self.assertEqual(result["status"], "accepted")

    def test_lottery_can_use_only_its_explicit_shared_platform_grants(self):
        for capability, operation in (
            ("identity", "resolve_subject"),
            ("tenant", "resolve_membership"),
            ("notifications", "request_delivery"),
            ("audit", "append_event"),
        ):
            with self.subTest(capability=capability):
                result = enforce_capability(LOTTERY_TOKEN, "tenant-beta", capability, operation)
                self.assertEqual(result["status"], "accepted")

    def test_affiliate_can_post_through_shared_finance_capability(self):
        result = enforce_capability(AFFILIATE_TOKEN, "tenant-alpha", "finance", "post_journal")
        self.assertEqual(result["status"], "accepted")

    def test_lottery_cannot_use_affiliate_only_finance_capability(self):
        result = evaluate_capability(LOTTERY_TOKEN, "tenant-beta", "finance", "post_journal")
        self.assertEqual((result["decision"], result["reason"]), ("deny", "operation_not_granted"))

    def test_product_owned_resource_is_accessible_to_its_owner(self):
        result = authorize_product_resource(AFFILIATE_TOKEN, "tenant-alpha", "affiliate_agent")
        self.assertEqual(result["decision"], "allow")

    def test_cross_product_resource_access_is_denied(self):
        result = authorize_product_resource(AFFILIATE_TOKEN, "tenant-beta", "lottery")
        self.assertEqual((result["decision"], result["reason"]), ("deny", "cross_product_resource_access_forbidden"))

    def test_inactive_product_entitlement_is_denied(self):
        result = evaluate_capability(LOTTERY_TOKEN, "tenant-alpha", "identity", "resolve_subject")
        self.assertEqual(result["reason"], "product_not_entitled_for_tenant")

    def test_unknown_service_identity_is_denied(self):
        result = evaluate_capability("not-a-real-token", "tenant-beta", "identity", "resolve_subject")
        self.assertEqual(result["reason"], "unknown_service_identity")

    def test_unknown_capability_is_denied(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "tenant-beta", "super_admin", "execute")
        self.assertEqual(result["reason"], "unknown_capability")

    def test_policy_unavailability_fails_closed(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "tenant-beta", "identity", "resolve_subject", policy_available=False)
        self.assertEqual(result["reason"], "policy_unavailable")

    def test_service_identity_is_scoped_to_approved_tenants(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "tenant-gamma", "identity", "resolve_subject")
        self.assertEqual(result["reason"], "service_tenant_scope_denied")

    def test_unknown_platform_capability_owner_is_rejected(self):
        registry = {"capabilities": {"identity": {
            "owner": "platform.unknown", "operations": ["resolve_subject"],
            "consumers": {"affiliate_agent": ["resolve_subject"]},
        }}}
        result = evaluate_capability(AFFILIATE_TOKEN, "tenant-beta", "identity", "resolve_subject", capability_registry=registry)
        self.assertEqual(result["reason"], "invalid_capability_owner")

    def test_product_cannot_access_sibling_owned_capability(self):
        registry = {"capabilities": {"lottery_domain": {
            "owner": "lottery", "operations": ["read"],
            "consumers": {"affiliate_agent": ["read"]},
        }}}
        result = evaluate_capability(AFFILIATE_TOKEN, "tenant-beta", "lottery_domain", "read", capability_registry=registry)
        self.assertEqual(result["reason"], "cross_product_capability_owner")

    def test_enforcement_point_blocks_denied_operation(self):
        with self.assertRaises(PermissionError):
            enforce_capability(LOTTERY_TOKEN, "tenant-beta", "finance", "post_journal")

    def test_product_cannot_use_an_operation_not_in_its_grant(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "tenant-beta", "identity", "delete_subject")
        self.assertEqual(result["reason"], "operation_not_granted")


class CrossProductEventContractTests(unittest.TestCase):
    def setUp(self):
        AUDIT_DECISIONS.clear()

    def test_explicit_test_contract_allows_expected_consumer(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["decision"], "allow")
        self.assertEqual(result["contract_id"], "p07b-synthetic-affiliate-to-lottery-signal")

    def test_event_without_contract_is_denied(self):
        result = dispatch_event(event(type="com.lottorito.affiliate.unsolicited.v1"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "missing_event_contract")

    def test_producer_cannot_spoof_another_product_source(self):
        result = dispatch_event(event(source="urn:lottorito:product:lottery"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "producer_source_mismatch")

    def test_consumer_not_named_in_contract_is_denied(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, AFFILIATE_TOKEN)
        self.assertEqual(result["reason"], "consumer_not_permitted_by_contract")

    def test_consumer_without_tenant_entitlement_is_denied(self):
        result = dispatch_event(event(tenantid="tenant-alpha"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "product_not_entitled_for_tenant")

    def test_unsupported_event_schema_version_is_denied(self):
        result = dispatch_event(event(dataschema="urn:lottorito:schema:affiliate.demo.signal:2"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "unsupported_schema_version")

    def test_event_classification_must_match_registered_contract(self):
        result = dispatch_event(event(classification="public"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "data_classification_mismatch")

    def test_financial_classification_exceeding_contract_is_denied(self):
        result = dispatch_event(event(classification="restricted_financial"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "data_classification_mismatch")

    def test_missing_required_payload_field_is_denied(self):
        result = dispatch_event(event(data={}), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "event_payload_missing_required_field")

    def test_invalid_cloudevents_attribute_type_is_denied(self):
        result = dispatch_event(event(id=123), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "invalid_event_envelope")

    def test_missing_cloudevents_required_attribute_is_denied(self):
        value = event()
        del value["id"]
        result = dispatch_event(value, AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "invalid_event_envelope")

    def test_sensitive_payload_keys_are_denied(self):
        result = dispatch_event(event(data={"reference": "x", "profile": {"email": "person@example.invalid"}}), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "sensitive_data_key_forbidden")

    def test_event_consumer_service_scope_is_enforced(self):
        result = dispatch_event(event(tenantid="tenant-gamma"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "service_tenant_scope_denied")

    def test_unknown_consumer_identity_is_denied(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, "unknown-service")
        self.assertEqual(result["reason"], "unknown_service_identity")

    def test_tenant_identifier_cannot_be_reintroduced_in_payload(self):
        result = dispatch_event(event(data={"reference": "x", "tenant_id": "tenant-alpha"}), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "sensitive_data_key_forbidden")

    def test_event_registry_without_matching_contract_fails_closed(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, LOTTERY_TOKEN, contract_registry={"contracts": []})
        self.assertEqual(result["reason"], "missing_event_contract")

    def test_unregistered_sensitive_extension_is_denied(self):
        result = dispatch_event(event(email="person@example.invalid"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "unsupported_event_extension")

    def test_authorization_audit_does_not_store_credentials_or_payload(self):
        dispatch_event(event(), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        serialized = json.dumps(AUDIT_DECISIONS)
        self.assertNotIn(AFFILIATE_TOKEN, serialized)
        self.assertNotIn("synthetic-ref-001", serialized)
        self.assertNotIn("person@example.invalid", serialized)


if __name__ == "__main__":
    unittest.main()
