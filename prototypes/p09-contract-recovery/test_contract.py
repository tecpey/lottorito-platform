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
TRACEPARENT = "00-" + TRACE + "-0123456789abcdef-01"


def event(scope, source_event_id=EVENT):
    return {
        "specversion": "1.0", "id": "provider-envelope-1",
        "source": "urn:lottorito:synthetic:provider", "type": "ledger.journal.posted",
        "time": "2026-11-25T00:00:00Z", "dataschema": "urn:lottorito:event:ledger-posted:1",
        "tenantid": TENANT, "scope": scope, "sourceeventid": source_event_id,
        "schemaversion": 1, "traceparent": TRACEPARENT,
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

    def test_scope_rejects_non_string_identifiers_without_type_errors(self):
        with self.assertRaisesRegex(ContractViolation, "scope_unknown_or_mismatched"):
            source_event_identity(TENANT, {"kind": "product", "id": ["lottery"]}, EVENT)
        with self.assertRaisesRegex(ContractViolation, "financial_scope_must_be_product"):
            financial_identity(TENANT, ["lottery"], EFFECT, "economic_effect_id")

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
        self.assertEqual(valid["trace_id"], TRACE)
        missing = event({"kind": "product", "id": "lottery"})
        del missing["scope"]
        with self.assertRaisesRegex(ContractViolation, "event_required_attribute_missing"):
            validate_event(missing)
        missing_trace = event({"kind": "product", "id": "lottery"})
        del missing_trace["traceparent"]
        with self.assertRaisesRegex(ContractViolation, "event_required_attribute_missing"):
            validate_event(missing_trace)

    def test_event_rejects_malformed_or_invalid_w3c_traceparent(self):
        invalid_values = (
            "00-" + "0" * 32 + "-0123456789abcdef-01",
            "00-" + TRACE + "-" + "0" * 16 + "-01",
            "00-" + TRACE.upper() + "-0123456789abcdef-01",
            "ff-" + TRACE + "-0123456789abcdef-01",
            "00-" + TRACE + "-0123456789abcdef-0g",
            "00-" + TRACE + "-0123456789abcde-01",
        )
        for value in invalid_values:
            candidate = event({"kind": "product", "id": "lottery"})
            candidate["traceparent"] = value
            with self.subTest(value=value), self.assertRaisesRegex(ContractViolation, "traceparent_invalid"):
                validate_event(candidate)

    def test_correlation_rejects_all_zero_trace_id(self):
        with self.assertRaisesRegex(ContractViolation, "trace_id_invalid"):
            correlation_identity(TENANT, {"kind": "product", "id": "lottery"}, EVENT, "0" * 32)

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



    def test_event_requires_rfc3339_timestamp_with_valid_calendar_and_offset(self):
        for value in ("2026-11-25T12:30:45Z", "2026-11-25T12:30:45.123+05:30",
                      "2026-11-25t12:30:45-04:00", "2026-12-31T23:59:60Z"):
            candidate = event({"kind": "product", "id": "lottery"})
            candidate["time"] = value
            self.assertEqual(validate_event(candidate)["time"], value)
        for value in ("2026-02-30T12:30:45Z", "2026-11-25 12:30:45Z",
                      "2026-11-25T24:00:00Z", "2026-11-25T12:60:00Z",
                      "2026-11-25T12:30:61Z", "2026-11-25T12:30:45",
                      "2026-11-25T12:30:45+24:00", "", None):
            candidate = event({"kind": "product", "id": "lottery"})
            candidate["time"] = value
            with self.subTest(value=value), self.assertRaisesRegex(ContractViolation, "event_time_invalid"):
                validate_event(candidate)

    def test_source_and_dataschema_must_be_nonempty_uri_references(self):
        for field, value in (("source", "urn:lottorito:provider:one"),
                             ("dataschema", "../schemas/event-v1.json"),
                             ("source", "https://example.test/provider?q=1#v1")):
            candidate = event({"kind": "product", "id": "lottery"})
            candidate[field] = value
            validate_event(candidate)
        for field, value in (("source", ""), ("dataschema", "not a uri"),
                             ("source", "urn:bad:%Q0"), ("dataschema", "https://[::1")):
            candidate = event({"kind": "product", "id": "lottery"})
            candidate[field] = value
            with self.subTest(field=field, value=value), self.assertRaises(ContractViolation):
                validate_event(candidate)

    def test_cloud_event_id_and_type_must_be_nonempty_strings(self):
        for field, value in (("id", ""), ("id", None), ("type", ""), ("type", 1)):
            candidate = event({"kind": "product", "id": "lottery"})
            candidate[field] = value
            with self.subTest(field=field, value=value), self.assertRaisesRegex(ContractViolation, "event_attribute_invalid"):
                validate_event(candidate)

    def test_financial_event_type_is_rejected_for_platform_scope(self):
        candidate = event({"kind": "platform", "id": "lottorito"})
        candidate["type"] = "ledger.journal.posted"
        with self.assertRaisesRegex(ContractViolation, "financial_event_requires_product_scope"):
            validate_event(candidate)

    def test_platform_scope_remains_valid_for_non_financial_event(self):
        candidate = event({"kind": "platform", "id": "lottorito"})
        candidate["type"] = "platform.tenant.provisioned"
        self.assertEqual(validate_event(candidate)["identity"][1:3], ("platform", "lottorito"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
