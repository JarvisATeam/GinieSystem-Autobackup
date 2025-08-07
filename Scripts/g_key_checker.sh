#!/usr/bin/env bash
set -euo pipefail

# Checks that key and token files exist; creates dummy files if missing.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_DIR="$BASE_DIR/Vault/Keys"
LOG_DIR="$BASE_DIR/Logs"
mkdir -p "$LOG_DIR" "$KEY_DIR"

missing=0
for expected in notion_token.key notion_db_id.key; do
  path="$KEY_DIR/$expected"
  if [ ! -s "$path" ]; then
    echo "DUMMY" > "$path"
    echo "$(date -Iseconds) missing key $expected – created dummy" >> "$LOG_DIR/g_key_checker.log"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "$(date -Iseconds) key check completed with missing keys" >> "$LOG_DIR/g_key_checker.log"
else
  echo "$(date -Iseconds) all keys present" >> "$LOG_DIR/g_key_checker.log"
fi
