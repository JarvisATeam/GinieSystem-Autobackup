#!/usr/bin/env bash
set -euo pipefail

# Masterløkken som kjører agentene hver time.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$BASE_DIR/Logs"
AGENT_LOOP="$BASE_DIR/Scripts/g_agentloop.sh"

mkdir -p "$LOG_DIR"

while true; do
  echo "$(date -Iseconds) starting agent loop" >> "$LOG_DIR/g_superloop.log"
  bash "$AGENT_LOOP" >> "$LOG_DIR/g_agentloop.log" 2>&1
  sleep 3600
done
