#!/bin/bash

LOG="$HOME/GinieSystem/Vault/Logs/ginie_implement.log"
mkdir -p "$(dirname "$LOG")"
echo "[$(date)] 🧠 Starter JA TIL ALT-FIX..." >> "$LOG"

# ✅ 1. Lag venv hvis den ikke finnes
if [ ! -d "$HOME/GinieSystem/env" ]; then
  echo "[$(date)] 📦 Lager virtualenv..." >> "$LOG"
  python3 -m venv "$HOME/GinieSystem/env" >> "$LOG" 2>&1
  source "$HOME/GinieSystem/env/bin/activate"
  pip install --upgrade pip >> "$LOG" 2>&1
  echo "[$(date)] ✅ Virtualenv opprettet og pip klar." >> "$LOG"
else
  echo "[$(date)] ✅ Virtualenv eksisterer allerede." >> "$LOG"
fi

# ✅ 2. Sikre pin_breach.json
PIN_JSON="$HOME/GinieSystem/Vault/Security/pin_breach.json"
mkdir -p "$(dirname "$PIN_JSON")"
if [ ! -f "$PIN_JSON" ]; then
  echo '{}' > "$PIN_JSON"
  echo "[$(date)] 🛡️ Opprettet tom pin_breach.json." >> "$LOG"
else
  echo "[$(date)] 🔐 pin_breach.json eksisterer." >> "$LOG"
fi

# ✅ 3. Sync til iCloud
SYNC_SCRIPT="$HOME/GinieSystem/Scripts/sync_learning_to_icloud.sh"
if [ -x "$SYNC_SCRIPT" ]; then
  echo "[$(date)] ☁️ Kjøring av iCloud sync..." >> "$LOG"
  bash "$SYNC_SCRIPT" >> "$LOG" 2>&1
  echo "[$(date)] ✅ iCloud sync fullført." >> "$LOG"
else
  echo "[$(date)] ❌ sync_learning_to_icloud.sh ikke kjørbar." >> "$LOG"
fi

# ✅ 4. Ferdig
echo "[$(date)] ✅ FULLFØRT JA TIL ALT-FIX" >> "$LOG"
