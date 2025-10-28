#!/usr/bin/env python3
"""Utility commands for maintaining the AIL glossary pipeline."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Dict

ROOT = Path(__file__).resolve().parent.parent
GLOSSARY_YAML = ROOT / "docs" / "AIL" / "glossary.yml"
GLOSSARY_JSON = ROOT / "courses" / "ail-app" / "public" / "glossary.json"
REPORTS_DIR = ROOT / "policies" / "reports"

DEFAULT_GLOSSARY: Dict[str, str] = {
    "KI": "Kunstig intelligens – dataprogrammer som lærer mønstre og foreslår svar.",
    "AI": "Artificial Intelligence (engelsk for KI).",
    "ML": "Maskinlæring – måten KI lærer av data på.",
    "LLM": "Stor språkmodell – KI som forstår/skriv tekst.",
    "RAG": "Søk + svar – KI henter kilder og svarer med henvisning.",
    "NLP": "Språkbehandling – datamaskiner som forstår menneskespråk.",
    "API": "Koblingspunkt – lar programmer snakke sammen.",
    "PWA": "Nettapp – nettside du kan installere som app.",
    "GPU": "Grafikkbrikke – gjør KI-beregninger raskt.",
    "2FA": "To-trinns bekreftelse – ekstra kode i tillegg til passord.",
    "VPN": "Kryptert nett-tunnel som beskytter forbindelsen.",
    "Cookie": "Liten fil som husker innstillinger/innlogging.",
    "TOS": "Terms of Service – tjenestens vilkår.",
    "GDPR": "Personvernregelverk i EU/EØS.",
}


def _escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _dump_yaml(data: Dict[str, str]) -> str:
    lines = [f"{key}: \"{_escape(value)}\"" for key, value in data.items()]
    return "\n".join(lines) + "\n"


def _parse_yaml(text: str) -> Dict[str, str]:
    result: Dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value.startswith("\"") and value.endswith("\""):
            value = value[1:-1]
        value = value.replace("\\\"", '"').replace("\\\\", "\\")
        result[key] = value
    return result


def ensure_structure() -> None:
    """Create required directories and seed the glossary file if missing."""
    (ROOT / "docs" / "AIL").mkdir(parents=True, exist_ok=True)
    (ROOT / "courses" / "ail-app" / "public").mkdir(parents=True, exist_ok=True)
    (ROOT / "courses" / "ail-app" / "src").mkdir(parents=True, exist_ok=True)
    (ROOT / "courses" / "ail-app" / "scripts").mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    if not GLOSSARY_YAML.exists():
        ordered = dict(sorted(DEFAULT_GLOSSARY.items(), key=lambda item: item[0].lower()))
        GLOSSARY_YAML.write_text(_dump_yaml(ordered), encoding="utf-8")


def write_glossary(data: Dict[str, str]) -> None:
    ordered = dict(sorted(data.items(), key=lambda item: item[0].lower()))
    GLOSSARY_YAML.write_text(_dump_yaml(ordered), encoding="utf-8")


def load_glossary() -> Dict[str, str]:
    ensure_structure()
    if not GLOSSARY_YAML.exists():  # pragma: no cover - guarded by ensure_structure
        raise FileNotFoundError(f"Glossary file mangler: {GLOSSARY_YAML}")
    data = _parse_yaml(GLOSSARY_YAML.read_text(encoding="utf-8"))
    return dict(sorted(data.items(), key=lambda item: item[0].lower()))


def glossary_to_json() -> Dict[str, str]:
    """Synchronise the YAML glossary to the public JSON representation."""
    glossary = load_glossary()
    payload = json.dumps(glossary, ensure_ascii=False, indent=2)
    GLOSSARY_JSON.write_text(payload, encoding="utf-8")
    return glossary


def verify_glossary_sync() -> Dict[str, str]:
    """Ensure the JSON file is in sync with the YAML glossary."""
    glossary = load_glossary()
    if not GLOSSARY_JSON.exists():
        raise FileNotFoundError("glossary.json mangler – kjør `ail_ops.py glossary` først")
    json_payload = json.loads(GLOSSARY_JSON.read_text(encoding="utf-8"))
    if json_payload != glossary:
        raise ValueError("glossary.json er ute av synk med YAML-kilden")
    return glossary


def command_glossary(args: argparse.Namespace) -> None:
    glossary = glossary_to_json()
    print(json.dumps({"wrote": str(GLOSSARY_JSON), "count": len(glossary)}, ensure_ascii=False))


def command_verify(args: argparse.Namespace) -> None:
    glossary = verify_glossary_sync()
    print(json.dumps({"verified": str(GLOSSARY_JSON), "count": len(glossary)}, ensure_ascii=False))


def command_bootstrap(args: argparse.Namespace) -> None:
    glossary = glossary_to_json()
    verify_glossary_sync()
    print(json.dumps({"bootstrap": "ok", "count": len(glossary)}, ensure_ascii=False))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("glossary", help="Synkroniser glossary.yml til glossary.json").set_defaults(
        func=command_glossary
    )
    sub.add_parser("verify", help="Valider at glossary.yml og glossary.json matcher").set_defaults(
        func=command_verify
    )
    sub.add_parser("bootstrap", help="Opprett struktur og bygg glossary.json").set_defaults(
        func=command_bootstrap
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        args.func(args)
    except Exception as exc:  # pragma: no cover - CLI convenience
        print(json.dumps({"error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
