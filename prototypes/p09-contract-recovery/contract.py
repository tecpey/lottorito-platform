"""Canonical P-09 identity contract validator; stdlib-only and synthetic fixtures."""
from __future__ import annotations

import re
import uuid
from datetime import datetime
from urllib.parse import urlsplit
from typing import Any

PRODUCT_IDS = frozenset({"affiliate_agent", "lottery"})
PLATFORM_ID = "lottorito"
TRACE_ID = re.compile(r"^[0-9a-f]{32}$")
TRACEPARENT_V00 = re.compile(r"^00-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})$")
SCHEMA_VERSION_MIN = 1
FINANCIAL_PRODUCT_ONLY_TYPES = frozenset({"ledger.journal.posted", "com.synthetic.settlement.posted.v1"})
URI_CHARS = re.compile(r"^[A-Za-z0-9._~:/?#@!$&'()*+,;=%\[\]-]*$")
BAD_PERCENT = re.compile(r"%(?![0-9A-Fa-f]{2})")


def _validate_uri_reference(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value or not URI_CHARS.fullmatch(value) or BAD_PERCENT.search(value):
        raise ContractViolation(f"{field}_uri_reference_invalid")
    try:
        urlsplit(value)
    except ValueError:
        raise ContractViolation(f"{field}_uri_reference_invalid") from None
    return value


def _validate_rfc3339(value: Any) -> str:
    if not isinstance(value, str):
        raise ContractViolation("event_time_invalid")
    match = re.fullmatch(r"(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:[Zz]|([+-])(\d{2}):(\d{2}))", value)
    if match is None:
        raise ContractViolation("event_time_invalid")
    _year, _month, _day, hour, minute, second = map(int, match.groups()[:6])
    if hour > 23 or minute > 59 or second > 60:
        raise ContractViolation("event_time_invalid")
    if match.group(7) is not None and (int(match.group(8)) > 23 or int(match.group(9)) > 59):
        raise ContractViolation("event_time_invalid")
    normalized = value.replace("t", "T").replace("z", "+00:00").replace("Z", "+00:00")
    if second == 60:
        normalized = normalized[:17] + "59" + normalized[19:]
    try:
        datetime.fromisoformat(normalized)
    except ValueError:
        raise ContractViolation("event_time_invalid") from None
    return value


class ContractViolation(ValueError):
    """Raised when a cross-prototype identity violates the canonical contract."""


def _uuid(value: Any, field: str) -> str:
    if not isinstance(value, str):
        raise ContractViolation(f"{field}_invalid")
    try:
        parsed = uuid.UUID(value)
    except (ValueError, AttributeError):
        raise ContractViolation(f"{field}_invalid") from None
    if str(parsed) != value:
        raise ContractViolation(f"{field}_noncanonical")
    return str(parsed)


def normalize_scope(scope: Any) -> tuple[str, str]:
    if not isinstance(scope, dict) or set(scope) != {"kind", "id"}:
        raise ContractViolation("scope_shape_invalid")
    kind, identifier = scope["kind"], scope["id"]
    if kind == "product" and isinstance(identifier, str) and identifier in PRODUCT_IDS:
        return kind, identifier
    if kind == "platform" and isinstance(identifier, str) and identifier == PLATFORM_ID:
        return kind, identifier
    raise ContractViolation("scope_unknown_or_mismatched")


def source_event_identity(tenant_id: Any, scope: Any, source_event_id: Any) -> tuple[str, str, str, str]:
    tenant = _uuid(tenant_id, "tenant_id")
    kind, identifier = normalize_scope(scope)
    event_id = _uuid(source_event_id, "source_event_id")
    return tenant, kind, identifier, event_id


def financial_identity(tenant_id: Any, product_id: Any, identifier: Any, field: str) -> tuple[str, str, str]:
    tenant = _uuid(tenant_id, "tenant_id")
    if not isinstance(product_id, str) or product_id not in PRODUCT_IDS:
        raise ContractViolation("financial_scope_must_be_product")
    value = _uuid(identifier, field)
    return tenant, product_id, value


def _validate_traceparent(value: Any) -> str:
    """Validate the contract's W3C Trace Context version-00 profile."""
    if not isinstance(value, str):
        raise ContractViolation("traceparent_invalid")
    match = TRACEPARENT_V00.fullmatch(value)
    if match is None:
        raise ContractViolation("traceparent_invalid")
    trace_id, parent_id, _flags = match.groups()
    if trace_id == "0" * 32 or parent_id == "0" * 16:
        raise ContractViolation("traceparent_invalid")
    return trace_id


def correlation_identity(tenant_id: Any, scope: Any, source_event_id: Any, trace_id: Any) -> tuple[str, str, str, str, str]:
    tenant, kind, identifier, event_id = source_event_identity(tenant_id, scope, source_event_id)
    if not isinstance(trace_id, str) or not TRACE_ID.fullmatch(trace_id) or trace_id == "0" * 32:
        raise ContractViolation("trace_id_invalid")
    return tenant, kind, identifier, event_id, trace_id


def validate_event(event: Any) -> dict[str, Any]:
    if not isinstance(event, dict):
        raise ContractViolation("event_not_object")
    required = {"specversion", "id", "source", "type", "time", "dataschema",
                "tenantid", "scope", "sourceeventid", "schemaversion", "traceparent"}
    if not required.issubset(event):
        raise ContractViolation("event_required_attribute_missing")
    if event["specversion"] != "1.0":
        raise ContractViolation("cloudevents_version_unsupported")
    if not isinstance(event["id"], str) or not event["id"] or not isinstance(event["type"], str) or not event["type"]:
        raise ContractViolation("event_attribute_invalid")
    _validate_uri_reference(event["source"], "source")
    _validate_uri_reference(event["dataschema"], "dataschema")
    _validate_rfc3339(event["time"])
    version = event["schemaversion"]
    if isinstance(version, bool) or not isinstance(version, int) or version < SCHEMA_VERSION_MIN:
        raise ContractViolation("schema_version_invalid")
    identity = source_event_identity(event["tenantid"], event["scope"], event["sourceeventid"])
    trace_id = _validate_traceparent(event["traceparent"])
    scope_kind, _scope_id = normalize_scope(event["scope"])
    if event["type"] in FINANCIAL_PRODUCT_ONLY_TYPES and scope_kind != "product":
        raise ContractViolation("financial_event_requires_product_scope")
    return {"identity": identity, "schema_version": version, "event_type": event["type"],
            "trace_id": trace_id, "time": event["time"],
            "source": event["source"], "dataschema": event["dataschema"]}
