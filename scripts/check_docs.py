#!/usr/bin/env python3
"""Validate Lottorito's bilingual documentation structure and local links.

This is a deterministic structural check. It does not claim semantic translation
parity, product approval, implementation correctness, or legal/security compliance.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
LANGUAGES = ("en", "fa")
DOC_ID_RE = re.compile(
    r"^\*\*(?:Document ID|شناسه(?: سند)?)\s*:\*\*\s*([A-Z0-9][A-Z0-9-]+)",
    re.MULTILINE,
)
LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")


def markdown_files(language: str) -> dict[str, Path]:
    base = DOCS / language
    if not base.is_dir():
        raise ValueError(f"Missing documentation directory: {base.relative_to(ROOT)}")
    return {
        path.relative_to(base).as_posix(): path
        for path in base.rglob("*.md")
        if path.is_file()
    }


def extract_doc_id(path: Path) -> str | None:
    match = DOC_ID_RE.search(path.read_text(encoding="utf-8"))
    return match.group(1) if match else None


def normalize_doc_id(doc_id: str) -> str:
    """Normalize language-qualified index IDs while preserving all other IDs."""
    return doc_id.replace("-EN-", "-LANG-").replace("-FA-", "-LANG-")


def check_pairs(errors: list[str]) -> int:
    files = {lang: markdown_files(lang) for lang in LANGUAGES}
    en_paths, fa_paths = set(files["en"]), set(files["fa"])
    for relative in sorted(en_paths - fa_paths):
        errors.append(f"Missing Persian counterpart: docs/fa/{relative}")
    for relative in sorted(fa_paths - en_paths):
        errors.append(f"Missing English counterpart: docs/en/{relative}")

    ids_by_language: dict[str, dict[str, str]] = {lang: {} for lang in LANGUAGES}
    for relative in sorted(en_paths & fa_paths):
        en_id = extract_doc_id(files["en"][relative])
        fa_id = extract_doc_id(files["fa"][relative])
        if not en_id:
            errors.append(f"Missing stable document ID: docs/en/{relative}")
        if not fa_id:
            errors.append(f"Missing stable document ID: docs/fa/{relative}")
        if en_id and fa_id and normalize_doc_id(en_id) != normalize_doc_id(fa_id):
            errors.append(
                f"Document ID mismatch for {relative}: English={en_id}, Persian={fa_id}"
            )
        for lang, doc_id in (("en", en_id), ("fa", fa_id)):
            if not doc_id:
                continue
            previous = ids_by_language[lang].get(doc_id)
            if previous and previous != relative:
                errors.append(
                    f"Duplicate {lang} document ID {doc_id}: {previous} and {relative}"
                )
            ids_by_language[lang][doc_id] = relative

    for required in ("README.md",):
        if required not in en_paths or required not in fa_paths:
            errors.append(f"Both language indexes are required: {required}")
    return len(en_paths & fa_paths)


def check_local_links(errors: list[str]) -> int:
    checked = 0
    for language in LANGUAGES:
        for source in sorted((DOCS / language).rglob("*.md")):
            text = source.read_text(encoding="utf-8")
            for match in LINK_RE.finditer(text):
                destination = match.group(1).strip()
                if destination.startswith("<") and ">" in destination:
                    destination = destination[1:destination.index(">")]
                else:
                    destination = destination.split()[0] if destination else ""
                if not destination:
                    continue
                parsed = urlsplit(destination)
                if parsed.scheme or parsed.netloc or destination.startswith("#"):
                    continue
                raw_path = unquote(parsed.path)
                if not raw_path:
                    continue
                target = (source.parent / raw_path).resolve()
                checked += 1
                if not target.exists():
                    rel_source = source.relative_to(ROOT)
                    errors.append(
                        f"Broken local link in {rel_source}: {destination}"
                    )
    return checked


def main() -> int:
    errors: list[str] = []
    try:
        paired = check_pairs(errors)
        links = check_local_links(errors)
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"Documentation validation could not complete: {exc}", file=sys.stderr)
        return 2

    if errors:
        print("Documentation governance: FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print(
        "Documentation governance: PASSED "
        f"({paired} bilingual Markdown pairs; {links} local links checked)."
    )
    print(
        "Note: structural validation only; semantic translation parity still "
        "requires human review."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
