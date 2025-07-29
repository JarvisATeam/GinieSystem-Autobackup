# Improved: ginie_implement.sh ons. 23 jul. 2025 16.30.38 CEST
##!/bin/bash
LOG="$HOME/GinieSystem/Vault/Logs/ginie_implement.log"
mkdir -p "$(dirname "$LOG")"

echo "[$(date)] 🧠 Starter Ginie implementasjon..." >> "$LOG"

## 👉 Læring ⇒ iCloud-sync
SCRIPT="$HOME/GinieSystem/Scripts/sync_learning_to_icloud.sh"
if [ -x "$SCRIPT" ]; then
  echo "[$(date)] 📂 Kjører iCloud sync..." >> "$LOG"
  bash "$SCRIPT" >> "$LOG" 2>&1
else
  echo "[$(date)] ❌ sync_learning_to_icloud.sh ikke funnet eller ikke kjørbar." >> "$LOG"
fi

echo "[$(date)] ✅ Fullført Ginie implementasjon." >> "$LOG"
