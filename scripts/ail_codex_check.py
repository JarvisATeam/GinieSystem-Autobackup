#!/usr/bin/env python3
"""Scan the repository for acronyms and keep the glossary in sync."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Iterable, List, Set

from ail_ops import (GLOSSARY_JSON, GLOSSARY_YAML, ensure_structure, glossary_to_json, load_glossary, write_glossary)

ROOT = Path(__file__).resolve().parent.parent
REPORT_FILE = ROOT / "policies" / "reports" / "codex_report.json"
SCAN_ROOTS = [ROOT / "docs", ROOT / "courses", ROOT / "scripts", ROOT / "Scripts"]
ACRONYM_RE = re.compile(r"\b[A-ZØÅÆ][A-Z0-9ØÅÆ]{1,5}\b")
COMMON_SKIP = {
    "HTML",
    "CSS",
    "JSON",
    "MD",
    "PDF",
    "PNG",
    "SVG",
    "JPG",
    "HTTP",
    "HTTPS",
    "URL",
    "CPU",
    "RAM",
    "SQL",
    "CSV",
    "ID",
    "OK",
    "UI",
    "UX",
    "Z0",
    "ZØÅÆ",
}
TARGET_EXTENSIONS = {
    ".md",
    ".mdx",
    ".jsx",
    ".js",
    ".ts",
    ".tsx",
    ".py",
    ".yml",
    ".yaml",
    ".json",
    ".html",
    ".css",
    ".txt",
}


def iter_files() -> Iterable[Path]:
    for root in SCAN_ROOTS:
        if not root.exists():
            continue
        for candidate in root.rglob("*"):
            if not candidate.is_file():
                continue
            if candidate.suffix.lower() not in TARGET_EXTENSIONS:
                continue
            parts = set(candidate.parts)
            if "node_modules" in parts or ".venv" in parts:
                continue
            yield candidate


def scan_acronyms(files: Iterable[Path]) -> Set[str]:
    hits: Set[str] = set()
    for file_path in files:
        try:
            text = file_path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for match in ACRONYM_RE.finditer(text):
            hits.add(match.group(0))
    return hits


def update_glossary(acronyms: Iterable[str]) -> List[str]:
    ensure_structure()
    glossary = load_glossary()
    added: List[str] = []
    for acronym in sorted(acronyms):
        if acronym in COMMON_SKIP:
            continue
        if acronym not in glossary:
            glossary[acronym] = "Mangler forklaring (TODO) – legg til en enkel setning på norsk."
            added.append(acronym)
    if added:
        write_glossary(glossary)
    glossary_to_json()
    return added


def run_codespell(paths: Iterable[Path]) -> str:
    cmd = [
        "codespell",
        "-w",
        "-I",
        "/dev/null",
        *[str(path) for path in paths if path.exists()],
    ]
    try:
        completed = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return completed.stdout.strip()
    except FileNotFoundError:
        return "codespell not installed"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-codespell", action="store_true", help="Skip codespell auto-fix")
    args = parser.parse_args(argv)

    ensure_structure()
    files = list(iter_files())
    acronyms = scan_acronyms(files)
    added = update_glossary(acronyms)
    codespell_stdout = ""
    if not args.no_codespell:
        codespell_stdout = run_codespell(SCAN_ROOTS)

    REPORT_FILE.parent.mkdir(parents=True, exist_ok=True)
    REPORT_FILE.write_text(
        json.dumps({"added": added, "codespell_stdout": codespell_stdout}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(
        json.dumps(
            {"added": added, "codespell": bool(codespell_stdout), "report": str(REPORT_FILE)},
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
