# Improved: ginie_bootstrap.sh ons. 23 jul. 2025 19.15.41 CEST
##!/bin/bash
LOG="$HOME/GinieSystem/Vault/Logs/bootstrap.log"
mkdir -p "$(dirname "$LOG")"

echo "🔁 [$(date)] Ginie Bootstrap starter..." >> "$LOG"

## 🛡 Lag tomme mapper/filer hvis mangler
mkdir -p "$HOME/GinieSystem/Vault/Proof"
mkdir -p "$HOME/GinieSystem/Vault/Security"
touch "$HOME/GinieSystem/Vault/Proof/proof.json"
touch "$HOME/GinieSystem/Vault/Security/pin_breach.json"

## 🚀 Start G.FORGE Prime-autofix
if [ -x "$HOME/GinieSystem/Scripts/autofix_gforge.sh" ]; then
  echo "🚀 Starter G.FORGE Prime via autofix_gforge.sh" >> "$LOG"
  bash "$HOME/GinieSystem/Scripts/autofix_gforge.sh" >> "$LOG" 2>&1 &
fi

## 🧠 Start NanoTec (uten virtualenv om det mangler)
if [ -x "$HOME/GinieSystem/Scripts/launch_nanotec.sh" ]; then
  echo "🧠 Starter NanoTec..." >> "$LOG"
  bash "$HOME/GinieSystem/Scripts/launch_nanotec.sh" >> "$LOG" 2>&1 &
fi

## ☁️ iCloud autosync Vault → iCloud Drive
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieVaultBackup"
if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
  mkdir -p "$ICLOUD"
  echo "☁️ iCloud Drive synkronisering aktivert" >> "$LOG"
  rsync -a --delete "$HOME/GinieSystem/Vault/" "$ICLOUD/" >> "$LOG" 2>&1 &
else
  echo "⚠️ iCloud Drive ikke tilgjengelig – sync hoppet over." >> "$LOG"
fi

echo "✅ [$(date)] Ginie Bootstrap fullført." >> "$LOG"
