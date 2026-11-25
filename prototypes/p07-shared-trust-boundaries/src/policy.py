"""Synthetic PDP/PEP fixture for P-07B; no production identity or authorization."""
from __future__ import annotations
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CAPABILITY_REGISTRY_PATH = ROOT / "registry" / "capabilities.json"
ENTITLEMENTS_PATH = ROOT / "registry" / "tenant-entitlements.json"

# Opaque synthetic test credentials with explicit service-to-tenant scopes.
SERVICE_PRINCIPALS = {
    "synthetic-affiliate-service-token": {
        "service_id": "affiliate-agent-worker",
        "product_id": "affiliate_agent",
        "allowed_tenants": ["11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222"],
    },
    "synthetic-lottery-service-token": {
        "service_id": "lottery-worker",
        "product_id": "lottery",
        "allowed_tenants": ["11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222"],
    },
}
AUDIT_DECISIONS: list[dict[str, Any]] = []


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _record(decision: dict[str, Any]) -> dict[str, Any]:
    # Credentials, payloads and personal data are deliberately excluded.
    AUDIT_DECISIONS.append({
        key: decision.get(key)
        for key in ("decision", "reason", "product_id", "tenant_id", "capability", "operation")
    })
    return decision


def resolve_principal(token: str) -> dict[str, Any] | None:
    principal = SERVICE_PRINCIPALS.get(token)
    return dict(principal) if principal else None


def evaluate_capability(
    token: str,
    tenant_id: str,
    capability: str,
    operation: str,
    capability_registry: dict[str, Any] | None = None,
    entitlements: dict[str, Any] | None = None,
    policy_available: bool = True,
) -> dict[str, Any]:
    """PDP: evaluate trusted service identity, tenant scope, entitlement and capability policy."""
    if not policy_available:
        return _record({"decision": "deny", "reason": "policy_unavailable", "tenant_id": tenant_id, "capability": capability, "operation": operation})
    try:
        if capability_registry is None:
            capability_registry = _load_json(CAPABILITY_REGISTRY_PATH)
        if entitlements is None:
            entitlements = _load_json(ENTITLEMENTS_PATH)
    except (OSError, ValueError, json.JSONDecodeError):
        return _record({"decision": "deny", "reason": "policy_unavailable", "tenant_id": tenant_id, "capability": capability, "operation": operation})

    principal = resolve_principal(token)
    if principal is None:
        return _record({"decision": "deny", "reason": "unknown_service_identity", "tenant_id": tenant_id, "capability": capability, "operation": operation})

    product_id = principal["product_id"]
    if tenant_id not in principal["allowed_tenants"]:
        return _record({"decision": "deny", "reason": "service_tenant_scope_denied", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation})

    tenant = entitlements.get("tenants", {}).get(tenant_id)
    if tenant is None or tenant.get(product_id) is not True:
        return _record({"decision": "deny", "reason": "product_not_entitled_for_tenant", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation})

    definition = capability_registry.get("capabilities", {}).get(capability)
    if definition is None:
        return _record({"decision": "deny", "reason": "unknown_capability", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation})

    owner = definition.get("owner", "")
    consumers = definition.get("consumers", {})
    permitted_operations = consumers.get(product_id, [])
    valid_platform_owners = {
        "platform.identity", "platform.tenant", "platform.finance",
        "platform.notifications", "platform.audit",
    }
    valid_product_owners = {"affiliate_agent", "lottery"}
    if owner not in valid_platform_owners | valid_product_owners:
        return _record({"decision": "deny", "reason": "invalid_capability_owner", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation})
    if owner in valid_product_owners and owner != product_id:
        return _record({"decision": "deny", "reason": "cross_product_capability_owner", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation})
    if operation not in definition.get("operations", []) or operation not in permitted_operations:
        return _record({"decision": "deny", "reason": "operation_not_granted", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation})

    return _record({"decision": "allow", "reason": "explicit_capability_grant", "product_id": product_id, "tenant_id": tenant_id, "capability": capability, "operation": operation, "owner": owner})


def enforce_capability(token: str, tenant_id: str, capability: str, operation: str) -> dict[str, Any]:
    """PEP: a protected operation cannot proceed unless the PDP explicitly allows it."""
    result = evaluate_capability(token, tenant_id, capability, operation)
    if result["decision"] != "allow":
        raise PermissionError(result["reason"])
    return {"status": "accepted", "product_id": result["product_id"], "tenant_id": tenant_id, "capability": capability, "operation": operation}


def authorize_product_resource(token: str, tenant_id: str, resource_owner: str) -> dict[str, Any]:
    principal = resolve_principal(token)
    if principal is None:
        return _record({"decision": "deny", "reason": "unknown_service_identity", "tenant_id": tenant_id})
    product_id = principal["product_id"]
    if tenant_id not in principal["allowed_tenants"]:
        return _record({"decision": "deny", "reason": "service_tenant_scope_denied", "product_id": product_id, "tenant_id": tenant_id})
    tenant = _load_json(ENTITLEMENTS_PATH).get("tenants", {}).get(tenant_id, {})
    if tenant.get(product_id) is not True:
        return _record({"decision": "deny", "reason": "product_not_entitled_for_tenant", "product_id": product_id, "tenant_id": tenant_id})
    if resource_owner != product_id:
        return _record({"decision": "deny", "reason": "cross_product_resource_access_forbidden", "product_id": product_id, "tenant_id": tenant_id})
    return _record({"decision": "allow", "reason": "product_owned_resource", "product_id": product_id, "tenant_id": tenant_id})
