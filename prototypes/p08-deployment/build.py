#!/usr/bin/env python3
"""Build deterministic synthetic zipapp artifacts and detached provenance fixtures."""
from __future__ import annotations

import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE_REVISION_LENGTH = 40
PRODUCT_IDS = ("affiliate_agent", "lottery")
PRODUCT_SLUGS = {"affiliate_agent": "affiliate-agent", "lottery": "lottery"}
SCHEMA_SUPPORT = {
    "v1": {"version": "1.0.0", "min_schema": 1, "max_schema": 2},
    "v2": {"version": "2.0.0", "min_schema": 1, "max_schema": 3},
    "v3": {"version": "3.0.0", "min_schema": 3, "max_schema": 3},
}
BUILD_TYPE = "https://tecpey.example/build-types/p08-python-zipapp/v1"
BUILDER_ID = "https://tecpey.example/builders/synthetic-local-builder/v1"


def canonical_json(value: object) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def build(version_key: str, output_dir: Path, source_revision: str, product_id: str = "affiliate_agent") -> tuple[Path, Path, str]:
    if version_key not in SCHEMA_SUPPORT:
        raise ValueError("unknown_fixture_version")
    if product_id not in PRODUCT_IDS:
        raise ValueError("unknown_product_id")
    if len(source_revision) != SOURCE_REVISION_LENGTH or any(ch not in "0123456789abcdef" for ch in source_revision):
        raise ValueError("source_revision_must_be_40_lowercase_hex")
    output_dir.mkdir(parents=True, exist_ok=True)
    if any(output_dir.iterdir()):
        raise FileExistsError("build_output_directory_must_be_empty")
    product_slug = PRODUCT_SLUGS[product_id]
    artifact_path = output_dir / f"{product_slug}-{version_key}.pyz"
    provenance_path = output_dir / f"{product_slug}-{version_key}.provenance.json"

    entrypoint_template = (ROOT / "fixtures" / version_key / "__main__.py").read_bytes()
    entrypoint = entrypoint_template.replace(b"__P08_PRODUCT_ID__", product_id.encode("ascii"))
    metadata = {
        "product": product_id,
        "version": SCHEMA_SUPPORT[version_key]["version"],
        "min_schema": SCHEMA_SUPPORT[version_key]["min_schema"],
        "max_schema": SCHEMA_SUPPORT[version_key]["max_schema"],
    }
    files = {"__main__.py": entrypoint, "release.json": canonical_json(metadata)}
    with zipfile.ZipFile(artifact_path, "w", compression=zipfile.ZIP_STORED) as archive:
        for name in sorted(files):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_STORED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, files[name])

    artifact_bytes = artifact_path.read_bytes()
    digest = sha256(artifact_bytes)
    provenance = {
        "_type": "https://in-toto.io/Statement/v1",
        "subject": [{"name": artifact_path.name, "digest": {"sha256": digest}}],
        "predicateType": "https://slsa.dev/provenance/v1",
        "predicate": {
            "buildDefinition": {
                "buildType": BUILD_TYPE,
                "externalParameters": {
                    "product": product_id,
                    "version": metadata["version"],
                    "source_revision": source_revision,
                },
                "resolvedDependencies": [{
                    "uri": f"file:fixtures/{version_key}/__main__.py",
                    "digest": {"sha256": sha256(entrypoint)},
                }],
            },
            "runDetails": {
                "builder": {"id": BUILDER_ID},
                "metadata": {"invocationId": f"synthetic-{version_key}-{source_revision[:12]}"},
            },
        },
    }
    provenance_path.write_bytes(canonical_json(provenance))
    return artifact_path, provenance_path, digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("version", choices=sorted(SCHEMA_SUPPORT))
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--product", choices=PRODUCT_IDS, required=True)
    args = parser.parse_args()
    artifact, provenance, digest = build(args.version, args.out, args.source_revision, args.product)
    print(f"artifact={artifact.name}")
    print(f"sha256={digest}")
    print(f"provenance={provenance.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
