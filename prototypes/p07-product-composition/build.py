#!/usr/bin/env python3
"""Build one synthetic product composition without the sibling product module."""
from __future__ import annotations

import argparse
import ast
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MANIFESTS = {
    "affiliate_agent": ROOT / "manifests" / "affiliate-agent.json",
    "lottery": ROOT / "manifests" / "lottery.json",
}
PRODUCT_SOURCES = {
    "affiliate_agent": ROOT / "src" / "products" / "affiliate_agent.py",
    "lottery": ROOT / "src" / "products" / "lottery.py",
}
ENTRYPOINTS = {
    "affiliate_agent": "products.affiliate_agent:run",
    "lottery": "products.lottery:run",
}
SIBLINGS = {"affiliate_agent": "lottery", "lottery": "affiliate_agent"}


def assert_no_cross_product_imports(source: str, forbidden_product: str) -> None:
    tree = ast.parse(source)
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imported = [alias.name for alias in node.names]
            relative_level = 0
        elif isinstance(node, ast.ImportFrom):
            imported = [node.module or ""]
            imported.extend(alias.name for alias in node.names)
            relative_level = node.level
        else:
            imported = []
            relative_level = 0

        if any(
            name == forbidden_product
            or name.startswith(f"products.{forbidden_product}")
            or (name == "products" and forbidden_product in imported)
            or (relative_level > 0 and forbidden_product in imported)
            for name in imported
        ):
            raise ValueError(f"forbidden cross-product import: {forbidden_product}")

        if isinstance(node, ast.Call):
            func = node.func
            if isinstance(func, ast.Name) and func.id == "__import__":
                raise ValueError("dynamic imports are not allowed in product entrypoints")
            if isinstance(func, ast.Attribute) and func.attr == "import_module":
                raise ValueError("importlib dynamic imports are not allowed in product entrypoints")


def build_product(product_id: str, output: Path) -> Path:
    if product_id not in MANIFESTS:
        raise ValueError(f"unsupported product: {product_id}")

    output = output.resolve()
    if output == ROOT or output.is_relative_to(ROOT):
        raise ValueError("artifact output must be outside the source tree")
    if output.exists() and any(output.iterdir()):
        raise ValueError("artifact output directory must be empty")

    manifest = json.loads(MANIFESTS[product_id].read_text(encoding="utf-8"))
    source_path = PRODUCT_SOURCES[product_id]
    assert_no_cross_product_imports(source_path.read_text(encoding="utf-8"), SIBLINGS[product_id])

    if manifest["product_id"] != product_id:
        raise ValueError("manifest/product identity mismatch")
    if manifest["entrypoint"] != ENTRYPOINTS[product_id]:
        raise ValueError("manifest entrypoint mismatch")
    if manifest["product_dependencies"]:
        raise ValueError("P-07A fixture does not permit product-to-product dependencies")
    if SIBLINGS[product_id] not in manifest["forbidden_product_dependencies"]:
        raise ValueError("sibling product must be explicitly forbidden")

    output.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "src" / "platform_core.py", output / "platform_core.py")
    shutil.copy2(source_path, output / "product.py")
    (output / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    runner = (
        "import json\n"
        "import product\n\n"
        "if __name__ == '__main__':\n"
        "    print(json.dumps(product.run(), sort_keys=True))\n"
    )
    (output / "run.py").write_text(runner, encoding="utf-8")
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("product", choices=sorted(MANIFESTS))
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    artifact = build_product(args.product, args.out)
    print(json.dumps({
        "product_id": args.product,
        "artifact": str(artifact),
        "files": sorted(path.name for path in artifact.iterdir()),
    }, sort_keys=True))


if __name__ == "__main__":
    main()
