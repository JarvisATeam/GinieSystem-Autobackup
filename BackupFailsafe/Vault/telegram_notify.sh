#!/bin/bash

### 🔐 Last inn Telegram-nøkler
TOKEN=$(cat ~/.telegram_token 2>/dev/null | head -n1 | tr -d '\r')
CHAT_ID=$(cat ~/.telegram_chat 2>/dev/null | grep -E '^[0-9]+$' | head -n1 | tr -d '\r')

### 🧪 Kontroller at begge er satt
if [[ -z "$TOKEN" || -z "$CHAT_ID" ]]; then
  echo "❌ Telegram-token eller chat_id mangler. Avbryter." >&2
  exit 1
fi

### 📨 Lag meldingen
MESSAGE="✅ GinieSystem kjører – $(date '+%F %T')"

### 📤 Send meldingen
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$MESSAGE")

### 🧾 Logg alltid forsøk
mkdir -p ~/GinieSystem/Logs
LOGFILE=~/GinieSystem/Logs/telegram_notify.log
echo "$(date '+%F %T') – $MESSAGE" >> "$LOGFILE"

### 📌 Sjekk om det fungerte
if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "✅ Telegram-melding sendt OK"
else
  echo "❌ Telegram-feil: $RESPONSE" | tee -a ~/GinieSystem/Logs/telegram_notify_errors.log
  exit 2
fi
