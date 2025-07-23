# Improved: g.shield_panel.sh ons. 23 jul. 2025 21.10.43 CEST
##!/bin/bash

SHIELD_PLIST="$HOME/Library/LaunchAgents/com.ginie.mic_shield.plist"
SHIELD_SCRIPT="$HOME/GinieSystem/Scripts/g.mic_shield.sh"
WHITELIST_FILE="$HOME/GinieSystem/Scripts/.ginie_mic_whitelist"
LOG="$HOME/GinieSystem/Logs/mic_shield.log"

mkdir -p "$(dirname "$LOG")"
touch "$WHITELIST_FILE"

show_menu() {
  clear
  echo "🛡️ Ginie Mic Shield Kontrollpanel"
  echo "────────────────────────────────"
  echo "[1] Skru AV/PÅ skjoldet"
  echo "[2] Vis whitelist"
  echo "[3] Legg til i whitelist"
  echo "[4] Vis drepte prosesser"
  echo "[5] Åpne loggfil"
  echo "[6] Synk logg til iCloud Vault"
  echo "[0] Avslutt"
  echo "────────────────────────────────"
  read -p "👉 Velg alternativ: " choice
  handle_choice "$choice"
}

handle_choice() {
  case $1 in
    1)
      if launchctl list | grep -q com.ginie.mic_shield; then
        launchctl unload "$SHIELD_PLIST"
        echo "🛑 Skjold deaktivert"
      else
        launchctl load "$SHIELD_PLIST"
        echo "✅ Skjold aktivert"
      fi
      ;;
    2)
      echo "📜 Whitelist:"
      grep -o '".*"' "$SHIELD_SCRIPT" | sed 's/"//g'
      ;;
    3)
      read -p "🔐 Prosessnavn du vil tillate (eks: discord): " newentry
      sed -i '' "s/WHITELIST=(/WHITELIST=(\"$newentry\" /" "$SHIELD_SCRIPT"
      echo "✅ $newentry lagt til i whitelist."
      ;;
    4)
      echo "🕵️ Siste drepte:"
      grep -i "bruker mikrofonen" "$LOG" | tail -n 10
      ;;
    5)
      open "$LOG"
      ;;
    6)
      cp "$LOG" ~/Library/Mobile\ Documents/com~apple~CloudDocs/GinieSystem/Vault/mic_shield_$(date '+%F_%H-%M').log
      echo "✅ Logg synket til iCloud Vault."
      ;;
    0)
      echo "👋 Farvel"
      exit 0
      ;;
    *)
      echo "Ugyldig valg."
      ;;
  esac
  read -p "↩️ Trykk Enter for å gå tilbake..."
  show_menu
}

show_menu
