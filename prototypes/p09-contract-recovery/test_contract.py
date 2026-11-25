import unittest

from contract import (
    ContractViolation, correlation_identity, financial_identity,
    source_event_identity, validate_event,
)

TENANT = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
EVENT = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
EFFECT = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
JOURNAL = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
TRACE = "0123456789abcdef0123456789abcdef"


def event(scope, source_event_id=EVENT):
    return {
        "specversion": "1.0", "id": "provider-envelope-1",
        "source": "urn:lottorito:synthetic:provider", "type": "ledger.journal.posted",
        "time": "2026-11-25T00:00:00Z", "dataschema": "urn:lottorito:event:ledger-posted:1",
        "tenantid": TENANT, "scope": scope, "sourceeventid": source_event_id,
        "schemaversion": 1,
    }


class ScopeContractTests(unittest.TestCase):
    def test_affiliate_and_lottery_are_distinct_product_scopes(self):
        affiliate = source_event_identity(TENANT, {"kind": "product", "id": "affiliate_agent"}, EVENT)
        lottery = source_event_identity(TENANT, {"kind": "product", "id": "lottery"}, EVENT)
        self.assertNotEqual(affiliate, lottery)

    def test_platform_is_a_separate_scope_not_a_product_alias(self):
        platform = source_event_identity(TENANT, {"kind": "platform", "id": "lottorito"}, EVENT)
        product = source_event_identity(TENANT, {"kind": "product", "id": "affiliate_agent"}, EVENT)
        self.assertNotEqual(platform, product)

    def test_shared_is_not_accepted_as_a_product_or_platform_id(self):
        with self.assertRaisesRegex(ContractViolation, "scope_unknown_or_mismatched"):
            source_event_identity(TENANT, {"kind": "product", "id": "shared"}, EVENT)
        with self.assertRaisesRegex(ContractViolation, "scope_unknown_or_mismatched"):
            source_event_identity(TENANT, {"kind": "platform", "id": "shared"}, EVENT)

    def test_scope_shape_rejects_ambiguous_extra_fields(self):
        with self.assertRaisesRegex(ContractViolation, "scope_shape_invalid"):
            source_event_identity(TENANT, {"kind": "product", "id": "lottery", "tenant_id": TENANT}, EVENT)

    def test_same_event_uuid_in_two_tenants_is_not_a_collision(self):
        other = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
        self.assertNotEqual(
            source_event_identity(TENANT, {"kind": "product", "id": "lottery"}, EVENT),
            source_event_identity(other, {"kind": "product", "id": "lottery"}, EVENT),
        )

    def test_financial_effect_and_journal_are_product_scoped(self):
        self.assertEqual(financial_identity(TENANT, "lottery", EFFECT, "economic_effect_id"),
                         (TENANT, "lottery", EFFECT))
        self.assertEqual(financial_identity(TENANT, "affiliate_agent", JOURNAL, "journal_id"),
                         (TENANT, "affiliate_agent", JOURNAL))

    def test_financial_identity_rejects_platform_and_shared(self):
        for scope in ("platform", "shared", None):
            with self.subTest(scope=scope), self.assertRaises(ContractViolation):
                financial_identity(TENANT, scope, EFFECT, "economic_effect_id")

    def test_correlation_includes_tenant_product_scope_event_and_trace(self):
        affiliate = correlation_identity(TENANT, {"kind": "product", "id": "affiliate_agent"}, EVENT, TRACE)
        lottery = correlation_identity(TENANT, {"kind": "product", "id": "lottery"}, EVENT, TRACE)
        self.assertNotEqual(affiliate, lottery)
        self.assertEqual(len(affiliate), 5)

    def test_invalid_trace_id_is_rejected(self):
        with self.assertRaisesRegex(ContractViolation, "trace_id_invalid"):
            correlation_identity(TENANT, {"kind": "product", "id": "lottery"}, EVENT, "A" * 32)

    def test_event_envelope_requires_explicit_scope_and_schema_version(self):
        valid = validate_event(event({"kind": "product", "id": "lottery"}))
        self.assertEqual(valid["identity"], (TENANT, "product", "lottery", EVENT))
        self.assertEqual(valid["schema_version"], 1)
        missing = event({"kind": "product", "id": "lottery"})
        del missing["scope"]
        with self.assertRaisesRegex(ContractViolation, "event_required_attribute_missing"):
            validate_event(missing)

    def test_event_rejects_non_integer_or_boolean_schema_version(self):
        for value in (0, -1, True, "1"):
            candidate = event({"kind": "product", "id": "lottery"})
            candidate["schemaversion"] = value
            with self.subTest(value=value), self.assertRaises(ContractViolation):
                validate_event(candidate)

    def test_noncanonical_and_invalid_uuid_values_fail_closed(self):
        with self.assertRaises(ContractViolation):
            source_event_identity(TENANT, {"kind": "product", "id": "lottery"}, "not-a-uuid")
        with self.assertRaises(ContractViolation):
            source_event_identity(TENANT, {"kind": "product", "id": "lottery"}, EVENT.upper())


if __name__ == "__main__":
    unittest.main(verbosity=2)
