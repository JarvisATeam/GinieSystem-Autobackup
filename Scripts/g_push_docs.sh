#!/usr/bin/env bash
set -euo pipefail

# Generates a simple status report and logs whether it could be pushed to Notion.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC_DIR="$BASE_DIR/Docs"
LOG_DIR="$BASE_DIR/Logs"
KEY_DIR="$BASE_DIR/Vault/Keys"
mkdir -p "$DOC_DIR" "$LOG_DIR" "$KEY_DIR"

REPORT="$DOC_DIR/status_$(date +%Y%m%d).md"
{
  echo "# Daglig status"
  echo "Generert: $(date -Iseconds)"
} > "$REPORT"

TOKEN_FILE="$KEY_DIR/notion_token.key"
if [ -s "$TOKEN_FILE" ]; then
  echo "$(date -Iseconds) would push $REPORT to Notion" >> "$LOG_DIR/g_push_docs.log"
else
  echo "$(date -Iseconds) missing Notion token" >> "$LOG_DIR/g_push_docs.log"
fi
