#!/bin/bash

THRESHOLD=80  # Prosent RAM-bruk før tiltak
USED=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
TOTAL=$(sysctl -n hw.memsize)
USED_MB=$((USED * 4096 / 1024 / 1024))
TOTAL_MB=$((TOTAL / 1024 / 1024))
PERCENT=$((100 * USED_MB / TOTAL_MB))

if [ "$PERCENT" -gt "$THRESHOLD" ]; then
  echo "[⚠️ RAM ALERT] $PERCENT % brukt – rydder..."
  
  # Kill RAM-slukere
  kill -9 $(ps aux | grep -E 'VideoToolbox|WebKit|docker' | awk '{print $2}') 2>/dev/null
  
  # Rens komprimert RAM
  sudo purge
  
  # Restart app
  echo "🔁 Starter GinieSymbiose Terminal App..."
  open -a Terminal "$HOME/GinieSystem/App/GinieSymbiose.sh"
  
  # Send Telegram-varsel (hvis aktivert)
  if [ -f "$HOME/GinieSystem/Vault/keys/telegram_token.key" ]; then
    TOKEN=$(cat "$HOME/GinieSystem/Vault/keys/telegram_token.key")
    CHAT_ID=$(cat "$HOME/GinieSystem/Vault/keys/telegram_chat.key")
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d text="⚠️ RAM oversteg ${PERCENT}%. Renset og restartet GinieSystem Terminal App."
  fi
fi

chmod +x ~/GinieSystem/Scripts/g.auto_ramwatch.sh

