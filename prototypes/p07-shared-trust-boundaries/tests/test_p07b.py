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
        "tenantid": "22222222-2222-4222-8222-222222222222",
        "scope": {"kind": "product", "id": "affiliate_agent"},
        "sourceeventid": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        "schemaversion": 1,
        "traceparent": "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01",
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
        result = enforce_capability(AFFILIATE_TOKEN, "11111111-1111-4111-8111-111111111111", "identity", "resolve_subject")
        self.assertEqual(result["status"], "accepted")

    def test_lottery_can_use_only_its_explicit_shared_platform_grants(self):
        for capability, operation in (
            ("identity", "resolve_subject"),
            ("tenant", "resolve_membership"),
            ("notifications", "request_delivery"),
            ("audit", "append_event"),
        ):
            with self.subTest(capability=capability):
                result = enforce_capability(LOTTERY_TOKEN, "22222222-2222-4222-8222-222222222222", capability, operation)
                self.assertEqual(result["status"], "accepted")

    def test_affiliate_can_post_through_shared_finance_capability(self):
        result = enforce_capability(AFFILIATE_TOKEN, "11111111-1111-4111-8111-111111111111", "finance", "post_journal")
        self.assertEqual(result["status"], "accepted")

    def test_lottery_cannot_use_affiliate_only_finance_capability(self):
        result = evaluate_capability(LOTTERY_TOKEN, "22222222-2222-4222-8222-222222222222", "finance", "post_journal")
        self.assertEqual((result["decision"], result["reason"]), ("deny", "operation_not_granted"))

    def test_product_owned_resource_is_accessible_to_its_owner(self):
        result = authorize_product_resource(AFFILIATE_TOKEN, "11111111-1111-4111-8111-111111111111", "affiliate_agent")
        self.assertEqual(result["decision"], "allow")

    def test_cross_product_resource_access_is_denied(self):
        result = authorize_product_resource(AFFILIATE_TOKEN, "22222222-2222-4222-8222-222222222222", "lottery")
        self.assertEqual((result["decision"], result["reason"]), ("deny", "cross_product_resource_access_forbidden"))

    def test_inactive_product_entitlement_is_denied(self):
        result = evaluate_capability(LOTTERY_TOKEN, "11111111-1111-4111-8111-111111111111", "identity", "resolve_subject")
        self.assertEqual(result["reason"], "product_not_entitled_for_tenant")

    def test_unknown_service_identity_is_denied(self):
        result = evaluate_capability("not-a-real-token", "22222222-2222-4222-8222-222222222222", "identity", "resolve_subject")
        self.assertEqual(result["reason"], "unknown_service_identity")

    def test_unknown_capability_is_denied(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "22222222-2222-4222-8222-222222222222", "super_admin", "execute")
        self.assertEqual(result["reason"], "unknown_capability")

    def test_policy_unavailability_fails_closed(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "22222222-2222-4222-8222-222222222222", "identity", "resolve_subject", policy_available=False)
        self.assertEqual(result["reason"], "policy_unavailable")

    def test_service_identity_is_scoped_to_approved_tenants(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "33333333-3333-4333-8333-333333333333", "identity", "resolve_subject")
        self.assertEqual(result["reason"], "service_tenant_scope_denied")

    def test_unknown_platform_capability_owner_is_rejected(self):
        registry = {"capabilities": {"identity": {
            "owner": "platform.unknown", "operations": ["resolve_subject"],
            "consumers": {"affiliate_agent": ["resolve_subject"]},
        }}}
        result = evaluate_capability(AFFILIATE_TOKEN, "22222222-2222-4222-8222-222222222222", "identity", "resolve_subject", capability_registry=registry)
        self.assertEqual(result["reason"], "invalid_capability_owner")

    def test_product_cannot_access_sibling_owned_capability(self):
        registry = {"capabilities": {"lottery_domain": {
            "owner": "lottery", "operations": ["read"],
            "consumers": {"affiliate_agent": ["read"]},
        }}}
        result = evaluate_capability(AFFILIATE_TOKEN, "22222222-2222-4222-8222-222222222222", "lottery_domain", "read", capability_registry=registry)
        self.assertEqual(result["reason"], "cross_product_capability_owner")

    def test_enforcement_point_blocks_denied_operation(self):
        with self.assertRaises(PermissionError):
            enforce_capability(LOTTERY_TOKEN, "22222222-2222-4222-8222-222222222222", "finance", "post_journal")

    def test_product_cannot_use_an_operation_not_in_its_grant(self):
        result = evaluate_capability(AFFILIATE_TOKEN, "22222222-2222-4222-8222-222222222222", "identity", "delete_subject")
        self.assertEqual(result["reason"], "operation_not_granted")


class CrossProductEventContractTests(unittest.TestCase):
    def setUp(self):
        AUDIT_DECISIONS.clear()

    def test_explicit_test_contract_allows_expected_consumer(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["decision"], "allow")
        self.assertEqual(result["contract_id"], "p07b-synthetic-affiliate-to-lottery-signal")

    def test_accepted_event_returns_canonical_source_identity_and_trace_id(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["source_event_identity"], {
            "tenant_id": "22222222-2222-4222-8222-222222222222",
            "scope_kind": "product",
            "scope_id": "affiliate_agent",
            "source_event_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        })
        self.assertEqual(result["trace_id"], "0123456789abcdef0123456789abcdef")
        self.assertEqual(result["schema_version"], 1)

    def test_scope_must_match_authenticated_producer_product(self):
        result = dispatch_event(event(scope={"kind": "product", "id": "lottery"}), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "event_scope_mismatch")

    def test_shared_and_platform_scopes_are_not_product_producer_scopes(self):
        for scope in ({"kind": "product", "id": "shared"}, {"kind": "platform", "id": "lottorito"}):
            with self.subTest(scope=scope):
                result = dispatch_event(event(scope=scope), AFFILIATE_TOKEN, LOTTERY_TOKEN)
                self.assertEqual(result["reason"], "event_scope_mismatch")

    def test_source_event_id_must_be_a_canonical_uuid(self):
        for value in ("not-a-uuid", "AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA"):
            with self.subTest(value=value):
                result = dispatch_event(event(sourceeventid=value), AFFILIATE_TOKEN, LOTTERY_TOKEN)
                self.assertEqual(result["reason"], "invalid_source_event_identity")

    def test_schema_version_must_be_positive_integer_and_match_contract(self):
        for value in (0, -1, True, "1", 2):
            with self.subTest(value=value):
                result = dispatch_event(event(schemaversion=value), AFFILIATE_TOKEN, LOTTERY_TOKEN)
                expected = "invalid_schema_version" if isinstance(value, bool) or not isinstance(value, int) or value < 1 else "unsupported_schema_version"
                self.assertEqual(result["reason"], expected)

    def test_w3c_traceparent_is_required_and_validated(self):
        for value in ("", "00-xyz-0123456789abcdef-01",
                      "00-00000000000000000000000000000000-0123456789abcdef-01",
                      "00-0123456789abcdef0123456789abcdef-0000000000000000-01"):
            with self.subTest(value=value):
                result = dispatch_event(event(traceparent=value), AFFILIATE_TOKEN, LOTTERY_TOKEN)
                self.assertEqual(result["reason"], "invalid_event_envelope" if value == "" else "invalid_trace_context")

    def test_registry_must_bind_the_authenticated_source_scope(self):
        registry = json.loads((ROOT / "registry" / "event-contracts.json").read_text(encoding="utf-8"))
        registry["contracts"][0]["source_scope"] = {"kind": "product", "id": "lottery"}
        result = dispatch_event(event(), AFFILIATE_TOKEN, LOTTERY_TOKEN, contract_registry=registry)
        self.assertEqual(result["reason"], "contract_source_scope_mismatch")

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
        result = dispatch_event(event(tenantid="11111111-1111-4111-8111-111111111111"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
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
        result = dispatch_event(event(tenantid="33333333-3333-4333-8333-333333333333"), AFFILIATE_TOKEN, LOTTERY_TOKEN)
        self.assertEqual(result["reason"], "service_tenant_scope_denied")

    def test_unknown_consumer_identity_is_denied(self):
        result = dispatch_event(event(), AFFILIATE_TOKEN, "unknown-service")
        self.assertEqual(result["reason"], "unknown_service_identity")

    def test_tenant_identifier_cannot_be_reintroduced_in_payload(self):
        result = dispatch_event(event(data={"reference": "x", "tenant_id": "11111111-1111-4111-8111-111111111111"}), AFFILIATE_TOKEN, LOTTERY_TOKEN)
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
