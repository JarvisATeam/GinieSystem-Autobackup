#!/usr/bin/env bash
set -euo pipefail

# Terminates processes using more than 20% RAM that are not part of GinieSystem.
THRESHOLD=${1:-20}
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$BASE_DIR/Logs"
mkdir -p "$LOG_DIR"

EXCLUDE="g_superloop|g_agentloop|g_proc_killer|g_key_checker|g_push_docs"

ps -eo pid,%mem,command | tail -n +2 | while read -r pid mem cmd; do
  mem_int=${mem%.*}
  if [ "$mem_int" -gt "$THRESHOLD" ] && ! echo "$cmd" | grep -qE "$EXCLUDE"; then
    kill -9 "$pid" 2>/dev/null || true
    echo "$(date -Iseconds) killed $pid ($cmd) using $mem% RAM" >> "$LOG_DIR/g_proc_killer.log"
  fi
done
