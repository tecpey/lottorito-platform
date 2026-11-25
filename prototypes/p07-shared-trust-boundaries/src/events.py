"""Synthetic CloudEvents profile and explicit cross-product contract enforcement."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from policy import AUDIT_DECISIONS, resolve_principal

ROOT = Path(__file__).resolve().parents[1]
CONTRACTS_PATH = ROOT / "registry" / "event-contracts.json"
ENTITLEMENTS_PATH = ROOT / "registry" / "tenant-entitlements.json"
PRODUCT_SOURCES = {
    "affiliate_agent": "urn:lottorito:product:affiliate_agent",
    "lottery": "urn:lottorito:product:lottery",
}
CLASSIFICATION = {"public": 0, "internal": 1, "confidential": 2, "restricted_financial": 3}
FORBIDDEN_DATA_KEYS = {"password", "secret", "token", "email", "phone", "national_id", "iban", "account_number"}


def _deny(reason: str, product_id: str | None = None, tenant_id: str | None = None) -> dict[str, Any]:
    AUDIT_DECISIONS.append({
        "decision": "deny", "reason": reason, "product_id": product_id,
        "tenant_id": tenant_id, "capability": "event_contract", "operation": "consume",
    })
    return {"decision": "deny", "reason": reason}


def dispatch_event(
    event: dict[str, Any],
    producer_token: str,
    consumer_token: str,
    contract_registry: dict[str, Any] | None = None,
    entitlements: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Event PEP: authenticate both services and enforce contract, tenant and schema scope."""
    if contract_registry is None:
        contract_registry = json.loads(CONTRACTS_PATH.read_text(encoding="utf-8"))
    if entitlements is None:
        entitlements = json.loads(ENTITLEMENTS_PATH.read_text(encoding="utf-8"))

    producer = resolve_principal(producer_token)
    consumer = resolve_principal(consumer_token)
    if producer is None or consumer is None:
        return _deny("unknown_service_identity")

    required = ("id", "source", "specversion", "type", "tenantid", "schemaversion", "classification", "data")
    if any(key not in event or event[key] in (None, "") for key in required):
        return _deny("invalid_event_envelope", producer["product_id"], event.get("tenantid"))
    if event["specversion"] != "1.0" or not isinstance(event["data"], dict):
        return _deny("invalid_event_envelope", producer["product_id"], event.get("tenantid"))

    source_product = producer["product_id"]
    if event["source"] != PRODUCT_SOURCES.get(source_product):
        return _deny("producer_source_mismatch", source_product, event["tenantid"])

    tenant = entitlements.get("tenants", {}).get(event["tenantid"])
    if tenant is None or tenant.get(source_product) is not True or tenant.get(consumer["product_id"]) is not True:
        return _deny("product_not_entitled_for_tenant", source_product, event["tenantid"])

    contract = next((
        item for item in contract_registry.get("contracts", [])
        if item.get("source_product") == source_product and item.get("event_type") == event["type"]
    ), None)
    if contract is None:
        return _deny("missing_event_contract", source_product, event["tenantid"])
    if consumer["product_id"] not in contract.get("allowed_consumers", []):
        return _deny("consumer_not_permitted_by_contract", consumer["product_id"], event["tenantid"])
    if event["schemaversion"] != contract.get("schema_version"):
        return _deny("unsupported_schema_version", consumer["product_id"], event["tenantid"])
    if event["classification"] not in CLASSIFICATION or contract.get("max_data_classification") not in CLASSIFICATION:
        return _deny("unknown_data_classification", consumer["product_id"], event["tenantid"])
    if CLASSIFICATION[event["classification"]] > CLASSIFICATION[contract["max_data_classification"]]:
        return _deny("data_classification_exceeds_contract", consumer["product_id"], event["tenantid"])
    if not set(contract.get("required_data_fields", [])).issubset(event["data"]):
        return _deny("event_payload_missing_required_field", consumer["product_id"], event["tenantid"])
    if FORBIDDEN_DATA_KEYS.intersection(key.lower() for key in event["data"]):
        return _deny("sensitive_data_key_forbidden", consumer["product_id"], event["tenantid"])

    AUDIT_DECISIONS.append({
        "decision": "allow", "reason": "explicit_event_contract",
        "product_id": consumer["product_id"], "tenant_id": event["tenantid"],
        "capability": "event_contract", "operation": "consume",
    })
    return {
        "decision": "allow",
        "reason": "explicit_event_contract",
        "contract_id": contract["contract_id"],
        "producer_product": source_product,
        "consumer_product": consumer["product_id"],
        "tenant_id": event["tenantid"],
        "event_id": event["id"],
    }
