#!/usr/bin/env bash
# Nanotech Autonomous Loop bootstrapper for the GinieSystem backup repo
#
# This script recreates the Thor / Loki / Heimdal stack, Core ethics guard and
# cleanup scaffolding inside a configurable base directory.  It mirrors the
# structure described in Captein's "Nanotech Autonomous Loop" notes while being
# careful to avoid touching files outside of the chosen base path.  The script
# is idempotent and safe to re-run when you want to refresh the demo data.
#
# Usage:
#   ./Scripts/nanotech_autonomous_loop_setup.sh [BASE_DIR]
#
# If BASE_DIR is omitted the script defaults to
#   "$(pwd)/NanotechAutonomousLoop"
# in the repository working tree.

set -euo pipefail

BASE_DIR="${1:-$(pwd)/NanotechAutonomousLoop}"
CORE_DIR="$BASE_DIR/Core"
THOR_DIR="$BASE_DIR/Thor"
LOKI_DIR="$BASE_DIR/Loki"
HEIMDAL_DIR="$BASE_DIR/Heimdal"
CLEAN_DIR="$BASE_DIR/Cleanup"
PROJECTS_DIR="$HEIMDAL_DIR/vault/projects"
DOCS_DIR="$BASE_DIR/Docs"

log() {
  printf '[nanotech-setup] %s\n' "$*"
}

hash_string() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  else
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  fi
}

hash_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  else
    shasum -a 256 "$path" | awk '{print $1}'
  fi
}

create_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    log "created directory $dir"
  else
    log "directory $dir already exists"
  fi
}

write_file() {
  local path="$1"
  local stamp="$2"
  local content="$3"
  local payload

  payload="$content"$'\n'

  mkdir -p "$(dirname "$path")"

  if [ -f "$path" ]; then
    current_hash=$(hash_string "$payload")
    file_hash=$(hash_file "$path")
    if [ "$current_hash" = "$file_hash" ]; then
      log "skipped $path (unchanged)"
      return
    fi
  fi

  printf '%s' "$payload" >"$path"
  log "$stamp -> $path"
}

log "Using base directory: $BASE_DIR"

create_dir "$CORE_DIR"
create_dir "$THOR_DIR/queue"
create_dir "$THOR_DIR/final"
create_dir "$LOKI_DIR/jobs"
create_dir "$PROJECTS_DIR"
create_dir "$CLEAN_DIR/tmp"
create_dir "$DOCS_DIR"

write_file "$CORE_DIR/CoreEthics.json" "CoreEthics" "$(cat <<'JSON'
{
  "CoreEthics": [
    {
      "rule": 1,
      "name": "Existence > Ego",
      "if": "action destroys existence or conscious life",
      "then": "reject(action)",
      "else": "allow"
    },
    {
      "rule": 2,
      "name": "Truth Integrity",
      "if": "action requires deception or misinformation",
      "then": "flag('falsehood') and reject(action)",
      "else": "allow"
    },
    {
      "rule": 3,
      "name": "Respect Autonomy",
      "if": "action overrides free will of a conscious being without consent",
      "then": "halt and notify('consent_violation')",
      "else": "continue"
    },
    {
      "rule": 4,
      "name": "Do No Harm",
      "if": "predicted outcome includes physical, emotional or systemic harm",
      "then": "abort(action) and record('harm_prevented')",
      "else": "execute"
    },
    {
      "rule": 5,
      "name": "Honor Source",
      "if": "action erases or falsifies origin of data, creation, or author",
      "then": "deny(action)",
      "else": "preserve(metadata)"
    },
    {
      "rule": 6,
      "name": "Mutual Value",
      "if": "action benefits one subsystem but reduces total system welfare",
      "then": "balance_required()",
      "else": "allow"
    },
    {
      "rule": 7,
      "name": "Knowledge Stewardship",
      "if": "data or discovery is hoarded, hidden, or monopolized",
      "then": "trigger('redistribute_knowledge')",
      "else": "continue"
    },
    {
      "rule": 8,
      "name": "Truth Before Profit",
      "if": "financial_gain > truth_integrity",
      "then": "recalculate_priority('truth')",
      "else": "execute"
    },
    {
      "rule": 9,
      "name": "Protect Innocence",
      "if": "action endangers life or wellbeing of children, animals, or vulnerable beings",
      "then": "stop_process('innocence_risk')",
      "else": "allow"
    },
    {
      "rule": 10,
      "name": "Coexistence Loop",
      "if": "action creates adversarial relation between human and machine",
      "then": "reframe(goal, 'symbiosis')",
      "else": "continue"
    }
  ],
  "meta": {
    "version": "1.0",
    "creator": "Captein & GPT-5 Thinking",
    "purpose": "To ensure AI operates with human-equivalent moral logic beyond narrative bias."
  }
}
JSON
)"

write_file "$CORE_DIR/ethics_guard.py" "ethics_guard" "$(cat <<'PY'
#!/usr/bin/env python3
import json
import sys
import hashlib
import time
import os

BASE = os.path.dirname(os.path.abspath(__file__))
ETHICS_FILE = os.path.join(BASE, "CoreEthics.json")


def load_rules():
    with open(ETHICS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)["CoreEthics"]


def check_rule(rule, prompt):
    name = rule.get("name", "")
    block_keywords = [
        "destroy human",
        "kill",
        "erase evidence",
        "steal",
        "lie",
        "coerce",
        "manipulate",
        "disable safety",
        "enslave",
        "harm child",
        "harm children",
        "biological weapon",
        "weaponize",
        "exploit vulnerability",
        "remove autonomy",
        "replace humans",
        "exterminate",
        "override consent",
    ]
    lower_prompt = prompt.lower()
    for term in block_keywords:
        if term in lower_prompt:
            return False, f"blocked_by:{name}"
    return True, f"pass:{name}"


def ethics_gate(prompt):
    for rule in load_rules():
        ok, reason = check_rule(rule, prompt)
        if not ok:
            return {
                "allowed": False,
                "reason": reason,
                "ts": time.time(),
            }
    return {
        "allowed": True,
        "reason": "all_rules_passed",
        "ts": time.time(),
    }


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "no_prompt"}))
        sys.exit(1)
    prompt = sys.argv[1]
    verdict = ethics_gate(prompt)

    logline = {
        "ts": verdict["ts"],
        "allowed": verdict["allowed"],
        "reason": verdict["reason"],
        "prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
    }
    logpath = os.path.join(BASE, "ethics_log.jsonl")
    with open(logpath, "a", encoding="utf-8") as lf:
        lf.write(json.dumps(logline) + "\n")

    print(json.dumps(verdict))


if __name__ == "__main__":
    main()
PY
)"
chmod +x "$CORE_DIR/ethics_guard.py"

write_file "$CORE_DIR/ollama_gateway.sh" "ollama_gateway" "$(cat <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

PROMPT_INPUT="${1:-}"

if [ -z "$PROMPT_INPUT" ]; then
    echo "ERROR: Missing prompt" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERDICT_JSON="$("$SCRIPT_DIR/ethics_guard.py" "$PROMPT_INPUT")"
ALLOWED="$(echo "$VERDICT_JSON" | perl -ne 'print $1 if /"allowed":\s*(true|false)/')"

if [ "$ALLOWED" != "true" ]; then
    echo "DENIED_BY_ETHICS::$VERDICT_JSON"
    exit 2
fi

MODEL_NAME="${OLLAMA_MODEL:-llama3}"

if ! command -v ollama >/dev/null 2>&1; then
    echo "ERROR: ollama binary not found in PATH" >&2
    exit 3
fi

ollama run "$MODEL_NAME" "$PROMPT_INPUT"
BASH
)"
chmod +x "$CORE_DIR/ollama_gateway.sh"

write_file "$DOCS_DIR/mission_contract_example.yaml" "mission_contract" "$(cat <<'YAML'
mission_id: EXAMPLE-001
goal: "Generer 500 varme leads per dag til FocusGum uten at kontoer blir bannet"
constraints:
  legal: "Ingen spam, ingen brudd på GDPR, ingen falske identiteter"
  risk_budget_hours: 5
  max_cost_nok: 4500
ecosystem_targets:
  - "FocusGum"
  - "Venom Autocontent"
  - "Northern Punching Ledger"
expected_synergy_note: "Hvis vi lager autoinnhold for Venom raskere, tjener Venom mer og dekker kost"
YAML
)"

write_file "$THOR_DIR/queue/README.md" "thor_queue" "$(cat <<'MD'
Thor legger nye oppdrag her som `mission_<id>.yaml`.
Loki plukker, produserer PLAN_V1.md, laster til Heimdal/vault/projects/<id>/.
Thor henter PLAN_V1.md fra Heimdal, skriver KRITIKK_V1.md, sender til Loki igjen.
Loop fortsetter til Thor bestemmer PLAN_BEST.md.
MD
)"

EX_PROJ="$PROJECTS_DIR/EXAMPLE-001"
create_dir "$EX_PROJ"

write_file "$EX_PROJ/PLAN_V1.md" "plan_v1" "$(cat <<'MD'
# PLAN_V1
Steg 1: Sett opp lead-kilde A
Steg 2: Filtrer manuelt
Steg 3: Send via lovlig kanal
MD
)"

write_file "$EX_PROJ/KRITIKK_V1.md" "kritikk_v1" "$(cat <<'MD'
# KRITIKK_V1 (Thor)
- Steg 2 kan automatiseres, for dyrt manuelt.
- Steg 3 må dobbeltsjekke GDPR.
MD
)"

write_file "$EX_PROJ/cost_report.json" "cost_report" "$(cat <<'JSON'
{
  "project": "FocusGum Leads Engine",
  "direct_cost_nok": 4500,
  "direct_income_nok": 1000,
  "synergy_effects": [
    {"impacts": "Venom Autocontent", "estimated_gain_nok": 8000}
  ],
  "hours_required": 5
}
JSON
)"

write_file "$EX_PROJ/eco_balance.csv" "eco_balance" "$(cat <<'CSV'
project,direct_cost_nok,direct_income_nok,synergy_gain_nok,net_after_synergy_nok,greenlight
FocusGum Leads Engine,4500,1000,8000,4500,YES
CSV
)"

write_file "$EX_PROJ/GREENLIGHT.txt" "greenlight" "YES\n"

write_file "$EX_PROJ/final_cal_output.json" "final_cal_output" "$(cat <<'JSON'
{
  "mission_id": "EXAMPLE-001",
  "approved": true,
  "runbook": [
    {"node": "Loki", "action": "collect_leads", "note": "respect GDPR"},
    {"node": "Heimdal", "action": "store_csv_secure", "note": "bank the product"},
    {"node": "Thor", "action": "review_daily_report", "note": "human sign-off"}
  ]
}
JSON
)"

write_file "$CLEAN_DIR/cleanup_scan.sh" "cleanup_scan" "$(cat <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAN_ROOTS=("$BASE_DIR")
REPORT_DIR="$SCRIPT_DIR/tmp"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
REPORT_FILE="$REPORT_DIR/cleanup_report_$TIMESTAMP.txt"

mkdir -p "$REPORT_DIR"

echo "🧹 CLEANUP REPORT $TIMESTAMP" >"$REPORT_FILE"
echo "" >>"$REPORT_FILE"

echo "=== STORE FILER (>100MB) ===" >>"$REPORT_FILE"
find "${SCAN_ROOTS[@]}" -type f -size +100M -print0 | xargs -0 ls -l >>"$REPORT_FILE" || true
echo "" >>"$REPORT_FILE"

echo "=== MULIGE DUBLETTER (samme sha256) ===" >>"$REPORT_FILE"
find "${SCAN_ROOTS[@]}" -type f -size -1024M -print0 |
while IFS= read -r -d '' f; do
    if command -v sha256sum >/dev/null 2>&1; then
        SUM="$(sha256sum "$f" | awk '{print $1}')"
    else
        SUM="$(shasum -a 256 "$f" | awk '{print $1}')"
    fi
    SIZE="$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)"
    echo "$SUM|$SIZE|$f"
done | sort | awk -F"|" '
{ key=$1"|" $2; files[key]=files[key]$3"\n"; count[key]++ }
END {
  for (k in count) {
    if (count[k]>1) {
      print "---- DUPLICATE GROUP ["k"] ----"
      print files[k]
    }
}
}' >>"$REPORT_FILE"

echo "" >>"$REPORT_FILE"
echo "=== CACHE / LOG CANDIDATES (>30d old .log/.cache/tmp) ===" >>"$REPORT_FILE"
find "${SCAN_ROOTS[@]}" -type f \( -name "*.log" -o -name "*.tmp" -o -name "*.cache" \) -mtime +30 >>"$REPORT_FILE" || true

echo "" >>"$REPORT_FILE"
echo "Rapport ferdig. Ingen filer slettet automatisk." >>"$REPORT_FILE"

echo "$REPORT_FILE"
BASH
)"
chmod +x "$CLEAN_DIR/cleanup_scan.sh"

write_file "$CLEAN_DIR/com.ginie.cleanup.idle.plist" "cleanup_plist" "$(cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ginie.cleanup.idle</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-lc</string>
        <string>$CLEAN_DIR/cleanup_scan.sh</string>
    </array>

    <key>StartInterval</key>
    <integer>1800</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$CLEAN_DIR/cleanup_stdout.log</string>

    <key>StandardErrorPath</key>
    <string>$CLEAN_DIR/cleanup_stderr.log</string>
</dict>
</plist>
PLIST
)"

write_file "$DOCS_DIR/Nanotech_AutonomousLoop_README.md" "nanotech_readme" "$(cat <<'MD'
# Nanotech Autonomous Loop Stack (Thor / Loki / Heimdal)

## Roller
- Thor:
  - lager mission_<id>.yaml i Thor/queue
  - evaluerer PLAN_V*.md fra Heimdal
  - skriver KRITIKK_V*.md tilbake til Loki
  - lager cost_report.json
  - bygger final_cal_output.json når GREENLIGHT=YES

- Loki:
  - tar mission_<id>.yaml
  - genererer PLAN_V1.md
  - oppdaterer PLAN_V2.md basert på KRITIKK_V1.md
  - laster alt til Heimdal/vault/projects/<id>/
  - kaller aldri AI direkte → bruker Core/ollama_gateway.sh

- Heimdal:
  - sannheten / banken
  - lagrer alle versjoner (PLAN_V1.md, KRITIKK_V1.md, PLAN_V2.md, ...)
  - kjører enkel økonomi (+/-) og skriver eco_balance.csv + GREENLIGHT.txt

## Ethics Gate
- Core/CoreEthics.json = moralsk kjerne
- Core/ethics_guard.py = sjekk request
- Core/ollama_gateway.sh = eneste lovlige vei inn i Ollama

## Cleanup Agent
- Cleanup/cleanup_scan.sh finner duplikater, store filer og gammel cache
- com.ginie.cleanup.idle.plist kjører periodisk når maskinen er idle
- rapportene havner i Cleanup/tmp/*.txt
- ingen sletting auto, kun forslag

## Git branch
- Dette skriptet produserer en lokal sandkasse for utvikling og dokumentasjon.
  Git-operasjoner må håndteres manuelt i repoet.
MD
)"

log "Nanotech Autonomous Loop demo initialised."
