#!/usr/bin/env python3
"""Sanity checks that confirm the Codex pipeline is configured correctly."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import ail_ops

ROOT = Path(__file__).resolve().parent.parent
COMPONENT_FILE = ROOT / "courses" / "ail-app" / "src" / "GlossaryHint.jsx"
REPORT_FILE = ROOT / "policies" / "reports" / "codex_report.json"


class SelfCheckError(RuntimeError):
    pass


def assert_condition(condition: bool, message: str) -> None:
    if not condition:
        raise SelfCheckError(message)


def check_glossary_sync() -> dict:
    glossary_yaml = ail_ops.load_glossary()
    ail_ops.verify_glossary_sync()
    return glossary_yaml


def check_component() -> None:
    if not COMPONENT_FILE.exists():
        raise SelfCheckError(f"Komponent mangler: {COMPONENT_FILE}")
    content = COMPONENT_FILE.read_text(encoding="utf-8")
    required_tokens = ["Forkortelser på denne siden", "GlossaryHint"]
    for token in required_tokens:
        assert_condition(token in content, f"Tekst '{token}' mangler i GlossaryHint.jsx")


def check_report() -> None:
    if not REPORT_FILE.exists():
        return
    data = json.loads(REPORT_FILE.read_text(encoding="utf-8"))
    assert_condition("added" in data, "Rapport mangler 'added'-nøkkel")


def main() -> int:
    try:
        glossary = check_glossary_sync()
        check_component()
        check_report()
    except SelfCheckError as exc:  # pragma: no cover - CLI helper
        print(json.dumps({"status": "failed", "error": str(exc)}, ensure_ascii=False))
        return 1
    except Exception as exc:  # pragma: no cover - CLI helper
        print(json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False))
        return 1
    print(json.dumps({"status": "ok", "glossary_entries": len(glossary)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
