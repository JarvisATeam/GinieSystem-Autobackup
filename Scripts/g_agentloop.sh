#!/usr/bin/env bash
set -euo pipefail

# Løper gjennom alle agentdefinisjoner og starter aktiverte agenter.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$BASE_DIR/Agents"
LOG_DIR="$BASE_DIR/Logs"
mkdir -p "$LOG_DIR"

python3 - <<'PY'
import json, os, glob, subprocess
base = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
agents_dir = os.path.join(base, 'Agents')
log_dir = os.path.join(base, 'Logs')
os.makedirs(log_dir, exist_ok=True)

for path in glob.glob(os.path.join(agents_dir, '*.json')):
    with open(path) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            continue
    if not data.get('enabled'):
        continue
    script = data.get('script')
    if not script:
        continue
    script_path = os.path.join(base, script)
    log_file = os.path.join(log_dir, f"{data.get('name', os.path.basename(path))}.log")
    with open(log_file, 'a') as log:
        log.write(f"\n--- Starting {data.get('name','agent')} ---\n")
        subprocess.call(['bash', script_path], stdout=log, stderr=log)
PY
