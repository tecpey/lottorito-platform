"""Synthetic independent lifecycle control plane for P-07C.

This module models lifecycle policy and metadata only. It does not deploy,
migrate a real database, provision infrastructure, or manage real secrets.
"""
from __future__ import annotations

import copy
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "registry"
AUDIT_LOG: list[dict[str, Any]] = []

class LifecycleError(ValueError):
    pass

class AuthorizationError(PermissionError):
    pass

class LifecycleConflict(RuntimeError):
    pass


def _load(name: str) -> dict[str, Any]:
    return json.loads((REGISTRY / name).read_text(encoding="utf-8"))


def load_fixture() -> dict[str, Any]:
    return copy.deepcopy(_load("tenant-state.json"))


def _actors() -> dict[str, Any]:
    return _load("actors.json")["actors"]


def _actor(token: str) -> dict[str, Any]:
    actor = _actors().get(token)
    if actor is None:
        raise AuthorizationError("unknown_actor")
    return dict(actor)


def _tenant(state: dict[str, Any], tenant_id: str) -> dict[str, Any]:
    tenant = state.get("tenants", {}).get(tenant_id)
    if tenant is None:
        raise LifecycleError("unknown_tenant")
    return tenant


def _product(tenant: dict[str, Any], product_id: str) -> dict[str, Any]:
    product = tenant.get("products", {}).get(product_id)
    if product is None:
        raise LifecycleError("unknown_product")
    return product


def _require_tenant_operator(state: dict[str, Any], tenant_id: str, token: str) -> dict[str, Any]:
    actor = _actor(token)
    tenant = _tenant(state, tenant_id)
    if actor["role"] == "platform_admin":
        return actor
    if actor["role"] != "tenant_operator":
        raise AuthorizationError("tenant_operator_required")
    if actor.get("tenant_id") != tenant_id or actor.get("operator_id") != tenant["operator_id"]:
        raise AuthorizationError("operator_tenant_mismatch")
    return actor


def _require_release_manager(token: str, product_id: str) -> dict[str, Any]:
    actor = _actor(token)
    if actor["role"] == "platform_admin":
        return actor
    if actor["role"] != "release_manager" or actor.get("product_id") != product_id:
        raise AuthorizationError("product_release_manager_required")
    return actor


def _audit(
    actor: dict[str, Any], tenant_id: str, product_id: str, action: str,
    before: Any, after: Any, correlation_id: str,
) -> None:
    # Never include configuration values, secret references or credentials.
    AUDIT_LOG.append({
        "actor_id": actor["actor_id"],
        "operator_id": actor.get("operator_id"),
        "tenant_id": tenant_id,
        "product_id": product_id,
        "action": action,
        "before": before,
        "after": after,
        "correlation_id": correlation_id,
        "outcome": "accepted",
    })


def set_product_enabled(
    state: dict[str, Any], tenant_id: str, product_id: str, enabled: bool,
    token: str, correlation_id: str = "corr-p07c-toggle",
) -> dict[str, Any]:
    actor = _require_tenant_operator(state, tenant_id, token)
    if product_id not in _load("products.json")["products"]:
        raise LifecycleError("unknown_or_non_product_capability")
    if not isinstance(enabled, bool):
        raise LifecycleError("enabled_must_be_boolean")
    product = _product(_tenant(state, tenant_id), product_id)
    before = product["enabled"]
    product["enabled"] = enabled
    _audit(actor, tenant_id, product_id, "product.enable" if enabled else "product.disable", before, enabled, correlation_id)
    return {"tenant_id": tenant_id, "product_id": product_id, "enabled": enabled}


def run_product_operation(state: dict[str, Any], tenant_id: str, product_id: str, operation: str) -> dict[str, str]:
    product = _product(_tenant(state, tenant_id), product_id)
    if not product["enabled"]:
        raise LifecycleError("product_disabled")
    return {"status": "accepted", "product_id": product_id, "operation": operation}


def _validate_config_value(spec: dict[str, Any], value: Any) -> None:
    kind = spec["type"]
    if kind == "string":
        if not isinstance(value, str) or len(value) > spec["max_length"]:
            raise LifecycleError("invalid_config_string")
    elif kind == "integer":
        if isinstance(value, bool) or not isinstance(value, int):
            raise LifecycleError("invalid_config_integer")
        if value < spec["minimum"] or value > spec["maximum"]:
            raise LifecycleError("config_integer_out_of_range")
    elif kind == "secret_ref":
        if not isinstance(value, str) or not value.startswith("secret://") or any(ch.isspace() for ch in value):
            raise LifecycleError("secret_reference_required")
    else:
        raise LifecycleError("unsupported_config_schema_type")


def update_product_config(
    state: dict[str, Any], tenant_id: str, product_id: str, updates: dict[str, Any],
    token: str, correlation_id: str = "corr-p07c-config",
) -> dict[str, Any]:
    actor = _require_tenant_operator(state, tenant_id, token)
    product = _product(_tenant(state, tenant_id), product_id)
    if not product["enabled"]:
        raise LifecycleError("product_disabled")
    schemas = _load("config-schemas.json")
    schema = schemas.get(product_id)
    if schema is None:
        raise LifecycleError("unknown_product_config_schema")
    if not isinstance(updates, dict) or not updates:
        raise LifecycleError("config_updates_required")
    for key, value in updates.items():
        spec = schema.get(key)
        if spec is None:
            raise LifecycleError("unknown_product_config_key")
        _validate_config_value(spec, value)
    before = product["config_version"]
    product["config"].update(copy.deepcopy(updates))
    product["config_version"] += 1
    _audit(actor, tenant_id, product_id, "product.config.update", before, product["config_version"], correlation_id)
    return {"product_id": product_id, "config_version": product["config_version"]}


def read_product_config(
    state: dict[str, Any], tenant_id: str, product_id: str, token: str,
) -> dict[str, Any]:
    _require_tenant_operator(state, tenant_id, token)
    product = _product(_tenant(state, tenant_id), product_id)
    if not product["enabled"]:
        raise LifecycleError("product_disabled")
    return copy.deepcopy(product["config"])


def plan_migrations(owner: str) -> list[str]:
    migrations = _load("migrations.json")["migrations"]
    return sorted(migration_id for migration_id, item in migrations.items() if item["owner"] == owner)


def _migration_actor(token: str, owner: str, tenant_id: str) -> dict[str, Any]:
    actor = _actor(token)
    if actor["role"] == "platform_admin":
        return actor
    if owner == "platform":
        if actor["role"] != "platform_migration_runner":
            raise AuthorizationError("platform_migration_runner_required")
        if tenant_id not in actor.get("allowed_tenants", []):
            raise AuthorizationError("migration_tenant_scope_denied")
    else:
        if actor["role"] != "migration_runner" or actor.get("product_id") != owner:
            raise AuthorizationError("product_migration_owner_mismatch")
        if tenant_id not in actor.get("allowed_tenants", []):
            raise AuthorizationError("migration_tenant_scope_denied")
    return actor


def apply_migration(
    state: dict[str, Any], tenant_id: str, migration_id: str, token: str,
    migrations: dict[str, Any] | None = None, releases: dict[str, Any] | None = None,
    correlation_id: str = "corr-p07c-migration",
) -> dict[str, Any]:
    if migrations is None:
        migrations = _load("migrations.json")["migrations"]
    if releases is None:
        releases = _load("releases.json")["releases"]
    migration = migrations.get(migration_id)
    if migration is None:
        raise LifecycleError("unknown_migration")
    owner = migration["owner"]
    actor = _migration_actor(token, owner, tenant_id)
    tenant = _tenant(state, tenant_id)
    schema = migration["schema"]
    if schema != owner:
        raise LifecycleError("migration_schema_owner_mismatch")
    if owner == "platform":
        if not all(tenant["shared_services"].values()):
            raise LifecycleError("shared_platform_not_ready")
    else:
        product = _product(tenant, owner)
        if not product["enabled"]:
            raise LifecycleError("product_disabled")

    current = tenant["schemas"].get(schema)
    if migration_id in tenant["applied_migrations"].get(schema, []):
        return {"status": "already_applied", "migration_id": migration_id, "schema_version": current}
    if current == migration["to_version"]:
        raise LifecycleConflict("schema_version_already_advanced_without_migration_record")
    if current != migration["from_version"]:
        raise LifecycleConflict("migration_from_version_mismatch")

    if owner != "platform":
        active_release_id = tenant["products"][owner]["active_release"]
        active_release = releases.get(active_release_id)
        if active_release is None or current not in active_release["supported_schema_versions"]:
            raise LifecycleError("active_release_schema_incompatible")
        if migration["to_version"] not in active_release["supported_schema_versions"]:
            raise LifecycleError("active_release_cannot_read_target_schema")
        required_release = migration.get("required_active_release")
        if required_release and active_release_id != required_release:
            raise LifecycleError("contract_migration_requires_new_release")
        if migration["phase"] == "contract":
            previous_id = tenant["products"][owner].get("previous_release")
            if previous_id:
                previous_release = releases.get(previous_id)
                if previous_release is None or migration["to_version"] not in previous_release["supported_schema_versions"]:
                    raise LifecycleError("incompatible_rollback_release_retained")

    tenant["schemas"][schema] = migration["to_version"]
    tenant["applied_migrations"].setdefault(schema, []).append(migration_id)
    _audit(actor, tenant_id, owner, "schema.migration.apply", current, migration["to_version"], correlation_id)
    return {"status": "applied", "migration_id": migration_id, "schema_version": migration["to_version"]}


def verify_release(release: dict[str, Any]) -> bool:
    digest = release.get("artifact_digest", "")
    revision = release.get("source_revision", "")
    if not re.fullmatch(r"sha256:[a-f0-9]{64}", digest):
        return False
    if not re.fullmatch(r"[a-f0-9]{40}", revision):
        return False
    provenance = release.get("provenance", {})
    try:
        subject_digest = provenance["subject"][0]["digest"]["sha256"]
        source_revision = provenance["predicate"]["buildDefinition"]["externalParameters"]["source_revision"]
        builder_id = provenance["predicate"]["runDetails"]["builder"]["id"]
    except (KeyError, IndexError, TypeError):
        return False
    return (
        provenance.get("_type") == "https://in-toto.io/Statement/v1"
        and provenance.get("predicateType") == "https://slsa.dev/provenance/v1"
        and subject_digest == digest.removeprefix("sha256:")
        and source_revision == revision
        and bool(builder_id)
    )


def _release_registry(releases: dict[str, Any] | None) -> dict[str, Any]:
    return releases if releases is not None else _load("releases.json")["releases"]


def promote_release(
    state: dict[str, Any], tenant_id: str, product_id: str, release_id: str,
    expected_current_release: str, token: str, releases: dict[str, Any] | None = None,
    environment: str = "staging", correlation_id: str = "corr-p07c-promote",
) -> dict[str, Any]:
    actor = _require_release_manager(token, product_id)
    tenant = _tenant(state, tenant_id)
    product = _product(tenant, product_id)
    if environment != "staging" or tenant["environment"] != "staging":
        raise LifecycleError("production_promotion_not_enabled_in_fixture")
    if not product["enabled"]:
        raise LifecycleError("product_disabled")
    registry = _release_registry(releases)
    release = registry.get(release_id)
    if release is None:
        raise LifecycleError("unknown_release")
    if release["product_id"] != product_id:
        raise LifecycleError("release_product_mismatch")
    if release["environment"] != environment or release["status"] != "validated" or not verify_release(release):
        raise LifecycleError("release_provenance_or_status_invalid")
    if tenant["schemas"][product_id] not in release["supported_schema_versions"]:
        raise LifecycleError("release_schema_incompatible")
    if product["active_release"] != expected_current_release:
        raise LifecycleConflict("stale_release_compare_and_swap")
    before = product["active_release"]
    if before == release_id:
        return {"status": "already_active", "release_id": release_id}
    product["previous_release"] = before
    product["active_release"] = release_id
    _audit(actor, tenant_id, product_id, "release.promote", before, release_id, correlation_id)
    return {"status": "promoted", "product_id": product_id, "release_id": release_id}


def retire_previous_release(
    state: dict[str, Any], tenant_id: str, product_id: str, expected_previous_release: str,
    token: str, confirmation: str, correlation_id: str = "corr-p07c-retire",
) -> dict[str, Any]:
    actor = _require_release_manager(token, product_id)
    tenant = _tenant(state, tenant_id)
    product = _product(tenant, product_id)
    previous_id = product["previous_release"]
    if previous_id is None:
        raise LifecycleError("no_previous_release")
    if previous_id != expected_previous_release:
        raise LifecycleConflict("stale_previous_release_compare_and_swap")
    if confirmation != "RETIRE_PREVIOUS_RELEASE":
        raise AuthorizationError("explicit_retirement_confirmation_required")
    # Retire only the rollback pointer; do not delete the artifact or product data.
    product["previous_release"] = None
    _audit(actor, tenant_id, product_id, "release.rollback_target.retire", previous_id, None, correlation_id)
    return {"status": "retired", "product_id": product_id, "retired_release_id": previous_id}


def rollback_release(
    state: dict[str, Any], tenant_id: str, product_id: str, token: str,
    releases: dict[str, Any] | None = None, correlation_id: str = "corr-p07c-rollback",
) -> dict[str, Any]:
    actor = _require_release_manager(token, product_id)
    tenant = _tenant(state, tenant_id)
    if tenant["environment"] != "staging":
        raise LifecycleError("production_rollback_not_enabled_in_fixture")
    product = _product(tenant, product_id)
    registry = _release_registry(releases)
    target_id = product["previous_release"]
    if target_id is None:
        raise LifecycleError("no_previous_release")
    target = registry.get(target_id)
    if target is None or target["product_id"] != product_id or not verify_release(target):
        raise LifecycleError("rollback_release_invalid")
    if tenant["schemas"][product_id] not in target["supported_schema_versions"]:
        raise LifecycleError("rollback_release_schema_incompatible")
    before = product["active_release"]
    product["active_release"] = target_id
    product["previous_release"] = before
    _audit(actor, tenant_id, product_id, "release.rollback", before, target_id, correlation_id)
    return {"status": "rolled_back", "product_id": product_id, "release_id": target_id}


def read_white_label_trace(
    state: dict[str, Any], tenant_id: str, product_id: str, token: str,
    correlation_id: str,
) -> dict[str, Any]:
    actor = _require_tenant_operator(state, tenant_id, token)
    tenant = _tenant(state, tenant_id)
    product = _product(tenant, product_id)
    if not correlation_id or not correlation_id.startswith("corr-"):
        raise LifecycleError("correlation_id_required")
    # Metadata-only trace; no config values or secret references are exposed.
    return {
        "tenant_id": tenant_id,
        "operator_id": tenant["operator_id"],
        "brand_id": tenant["brand_id"],
        "product_id": product_id,
        "release_id": product["active_release"],
        "config_version": product["config_version"],
        "schema_version": tenant["schemas"][product_id],
        "environment": tenant["environment"],
        "correlation_id": correlation_id,
        "actor_id": actor["actor_id"],
    }


def product_ownership(product_id: str) -> dict[str, str]:
    product = _load("products.json")["products"].get(product_id)
    if product is None:
        raise LifecycleError("unknown_product")
    return {"owner_team": product["owner_team"], "runbook_ref": product["runbook_ref"]}


def audit_snapshot() -> list[dict[str, Any]]:
    return copy.deepcopy(AUDIT_LOG)
