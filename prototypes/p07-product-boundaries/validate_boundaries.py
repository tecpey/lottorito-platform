#!/usr/bin/env python3
"""Fail-closed validator for the synthetic P-07A product-boundary manifest."""
from __future__ import annotations
import json
import sys
from pathlib import Path
from typing import Any

VALID_KINDS = {"product", "platform_contract", "platform_implementation"}
PRODUCTS = {"affiliate", "lottery"}
REQUIRED_CAPABILITIES = {"identity", "tenant", "authorization", "finance", "notifications", "audit", "events"}

def validate(document: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if document.get("schema_version") != 1:
        errors.append("schema_version must equal 1")
    if set(document.get("products", [])) != PRODUCTS:
        errors.append("products must declare exactly affiliate and lottery")
    modules = document.get("modules")
    if not isinstance(modules, list) or not modules:
        return errors + ["modules must be a non-empty array"]
    by_id: dict[str, dict[str, Any]] = {}
    for index, module in enumerate(modules):
        if not isinstance(module, dict):
            errors.append(f"modules[{index}] must be an object")
            continue
        module_id = module.get("id")
        if not isinstance(module_id, str) or not module_id:
            errors.append(f"modules[{index}] has no valid id")
            continue
        if module_id in by_id:
            errors.append(f"duplicate module id: {module_id}")
            continue
        by_id[module_id] = module
        if module.get("kind") not in VALID_KINDS:
            errors.append(f"{module_id}: invalid kind")
        if not isinstance(module.get("owner"), str) or not module["owner"].strip():
            errors.append(f"{module_id}: owner is required")
        dependencies = module.get("depends_on")
        if not isinstance(dependencies, list) or any(not isinstance(item, str) for item in dependencies):
            errors.append(f"{module_id}: depends_on must be an array of module ids")
            continue
        kind, product = module.get("kind"), module.get("product")
        if kind == "product" and product not in PRODUCTS:
            errors.append(f"{module_id}: product module must belong to affiliate or lottery")
        elif kind != "product" and product is not None:
            errors.append(f"{module_id}: platform module must not declare a product")

    graph: dict[str, list[str]] = {module_id: [] for module_id in by_id}
    for module_id, module in by_id.items():
        for dependency in module.get("depends_on", []):
            if dependency not in by_id:
                errors.append(f"{module_id}: unknown dependency {dependency}")
                continue
            graph[module_id].append(dependency)
            source_kind, target = module.get("kind"), by_id[dependency]
            target_kind = target.get("kind")
            if source_kind == "product":
                if target_kind == "product" and target.get("product") != module.get("product"):
                    errors.append(f"{module_id}: cross-product dependency on {dependency}")
                if target_kind == "platform_implementation":
                    errors.append(f"{module_id}: product may depend on platform contracts, not implementation {dependency}")
            elif source_kind == "platform_contract":
                errors.append(f"{module_id}: platform contract must be dependency-free; found {dependency}")
            elif source_kind == "platform_implementation" and target_kind == "product":
                errors.append(f"{module_id}: platform implementation must not depend on product module {dependency}")

    visiting: set[str] = set()
    visited: set[str] = set()
    def visit(node: str, stack: list[str]) -> None:
        if node in visiting:
            errors.append("dependency cycle: " + " -> ".join(stack + [node]))
            return
        if node in visited:
            return
        visiting.add(node)
        for child in graph.get(node, []):
            visit(child, stack + [node])
        visiting.remove(node)
        visited.add(node)
    for module_id in graph:
        visit(module_id, [])

    capabilities = document.get("capabilities")
    if not isinstance(capabilities, list):
        return errors + ["capabilities must be an array"]
    capability_ids = [item.get("id") for item in capabilities if isinstance(item, dict)]
    if len(capability_ids) != len(set(capability_ids)):
        errors.append("capability ids must be unique")
    if set(capability_ids) != REQUIRED_CAPABILITIES:
        errors.append("capabilities must declare exactly the seven required shared capabilities")
    for capability in capabilities:
        if not isinstance(capability, dict):
            errors.append("capability entries must be objects")
            continue
        capability_id = capability.get("id", "<unknown>")
        owner = capability.get("platform_owner")
        contract = by_id.get(capability.get("contract_module"))
        implementation = by_id.get(capability.get("implementation_module"))
        if not contract or contract.get("kind") != "platform_contract":
            errors.append(f"{capability_id}: contract_module must reference a platform_contract")
        if not implementation or implementation.get("kind") != "platform_implementation":
            errors.append(f"{capability_id}: implementation_module must reference a platform_implementation")
        for module in (contract, implementation):
            if module and module.get("owner") != owner:
                errors.append(f"{capability_id}: platform owner does not match contract/implementation owner")
        if capability.get("data_owner") != owner:
            errors.append(f"{capability_id}: data_owner must be explicit and match platform owner")
        policy_owners = capability.get("domain_policy_owners")
        if not isinstance(policy_owners, dict) or set(policy_owners) != PRODUCTS:
            errors.append(f"{capability_id}: domain_policy_owners must name both products")
        elif not all(isinstance(value, str) and value.strip() for value in policy_owners.values()):
            errors.append(f"{capability_id}: every product policy owner must be non-empty")
        if set(capability.get("consumers", [])) != PRODUCTS:
            errors.append(f"{capability_id}: both product consumers must be explicit")
        if capability.get("default_access") != "deny":
            errors.append(f"{capability_id}: default_access must be deny")
        if capability.get("tenant_scope_required") is not True:
            errors.append(f"{capability_id}: tenant_scope_required must be true")
        if capability.get("cross_product_access") != "explicit-contract-and-grant":
            errors.append(f"{capability_id}: cross-product access must require an explicit contract and grant")
        if not isinstance(capability.get("ownership_note"), str) or not capability["ownership_note"].strip():
            errors.append(f"{capability_id}: ownership_note is required")
    return sorted(set(errors))

def main() -> int:
    manifest_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name("architecture.json")
    try:
        document = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"P07A_MANIFEST_INVALID: {exc}", file=sys.stderr)
        return 2
    errors = validate(document)
    if errors:
        print("P07A_BOUNDARIES=FAIL")
        for error in errors:
            print(f"- {error}")
        return 1
    print("P07A_BOUNDARIES=PASS")
    print(f"modules={len(document['modules'])}")
    print(f"capabilities={len(document['capabilities'])}")
    print("products=affiliate,lottery")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
