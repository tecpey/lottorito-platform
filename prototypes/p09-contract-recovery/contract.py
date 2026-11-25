"""Canonical P-09 identity contract validator; stdlib-only and synthetic fixtures."""
from __future__ import annotations

import re
import uuid
from typing import Any

PRODUCT_IDS = frozenset({"affiliate_agent", "lottery"})
PLATFORM_ID = "lottorito"
TRACE_ID = re.compile(r"^[0-9a-f]{32}$")
TRACEPARENT_V00 = re.compile(r"^00-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})$")
SCHEMA_VERSION_MIN = 1


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
    if not all(isinstance(event[key], str) and event[key] for key in ("id", "source", "type", "time", "dataschema")):
        raise ContractViolation("event_attribute_invalid")
    version = event["schemaversion"]
    if isinstance(version, bool) or not isinstance(version, int) or version < SCHEMA_VERSION_MIN:
        raise ContractViolation("schema_version_invalid")
    identity = source_event_identity(event["tenantid"], event["scope"], event["sourceeventid"])
    trace_id = _validate_traceparent(event["traceparent"])
    return {"identity": identity, "schema_version": version, "event_type": event["type"],
            "trace_id": trace_id}
