#!/bin/bash

ICON_PATH="$HOME/GinieSystem/Symbiose/assets/icon.png"
LOG_DIR="$HOME/GinieSystem/Health/Logs"
LOG_FILE="$LOG_DIR/nutrition_log_$(date +%F).txt"
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieSystem/Health/Logs"
SHORTCUT_QR_PATH="$HOME/GinieSystem/Symbiose/assets/shortcut_qr.png"
SERVICE_FILE="$HOME/Library/LaunchAgents/com.ginie.symbiose.plist"
APP_PATH="$HOME/Applications/GinieSymbiose.app"
TELEGRAM_TOKEN="7970813653:AAEibNKz1Wc9hXdlMr-v4dyk3BQ9phF5zIM"
TELEGRAM_CHAT_ID="5624725784"

mkdir -p "$LOG_DIR" "$ICLOUD_DIR" "$HOME/Applications" "$HOME/GinieSystem/Symbiose/assets"

function show_icon_centered() {
  printf "\n"
  tput cols | awk -v icon="🌓" '{
    pad = int(($1 - length(icon)) / 2);
    for (i=0; i<pad; i++) printf " ";
    print icon;
  }'
  printf "\n"
}

function main_menu() {
  clear
  echo "\033[1;33m"
  echo "christerolsen@christers-MacBook-Pro-2"
  show_icon_centered
  echo "\n🎙️ Hei – dette er Ginie\n"
  echo "1. Snakk med Ginie selv 🧠"
  echo "2. Barna spør pappa via Ginie 👧"
  echo "3. Logg trening og tilskudd 🏋️"
  echo "4. Vis helselogg 📈"
  echo "5. Opprett macOS-app og tjeneste 💾"
  echo "6. Kjør 100 loops av alt 🔁"
  echo "7. Avslutt 🔚"
  echo -e "\033[0m"
  read -p "Skriv et tall og trykk Enter: " valg
  handle_input $valg
}

function handle_input() {
  case $1 in
    1) echo "\n🧠 Snakker med Ginie ..." ;;
    2) echo "\n👧 Barnegrensesnitt aktivert – fallback satt." ;;
    3) logg_postworkout ;;
    4) less "$LOG_FILE" ;;
    5) bygg_mac_app_og_service ;;
    6) repeat_loops ;;
    7) echo "Avslutter..."; exit 0 ;;
    *) echo "Ugyldig valg. Prøv igjen."; sleep 1; main_menu ;;
  esac
}

function logg_postworkout() {
  NOW=$(date +"%Y-%m-%d %H:%M")
  echo "[$NOW] Post-workout inntak:\n- Whey protein + BCAA\n- Gerimax multivitamin\n- K2-vitamin\n- 60 min trening, 20 min sol\n- ZMA før søvn" >> "$LOG_FILE"
  cp "$LOG_FILE" "$ICLOUD_DIR"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="Post-workout logg fullført og synket: $NOW 🧠💪"
  echo "\n✅ Logg lagret, synkronisert og sendt til Telegram."
  read -p "Trykk Enter for å gå tilbake til meny..." _
  main_menu
}

function bygg_mac_app_og_service() {
  echo "📦 Bygger .app-pakke og aktiverer LaunchAgent ..."
  mkdir -p "$APP_PATH/Contents/MacOS"
  cp "$0" "$APP_PATH/Contents/MacOS/GinieSymbiose"
  chmod +x "$APP_PATH/Contents/MacOS/GinieSymbiose"

  cat <<PLIST > "$SERVICE_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ginie.symbiose</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP_PATH/Contents/MacOS/GinieSymbiose</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

  launchctl unload "$SERVICE_FILE" 2>/dev/null
  launchctl load "$SERVICE_FILE"
  echo "✅ App og tjeneste aktivert. Starter nå..."
  sleep 1
  "$APP_PATH/Contents/MacOS/GinieSymbiose"
}

function repeat_loops() {
  echo "🔁 Kjører 100 loops med læring og forsterkning ..."
  for i in {1..100}; do
    logg_postworkout
    sleep 1
  done
  echo "✅ 100 runder fullført."
  read -p "Trykk Enter for å gå tilbake til meny..." _
  main_menu
}

main_menu
