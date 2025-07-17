#!/bin/bash

TOKEN=$(cat ~/.telegram_token)
CHAT_ID=$(cat ~/.telegram_chat)
MESSAGE="✅ Systemet kjører – $(date '+%H:%M:%S')"

RESPONSE=$(curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE")

echo "$(date '+%F %T') – $MESSAGE" >> ~/GinieSystem/Logs/telegram_notify.log
echo "$RESPONSE" | grep -q '"ok":true'

if [ $? -eq 0 ]; then
  echo "✅ Telegram-melding sendt OK"
else
  echo "❌ Feil: Telegram-melding kunne ikke sendes"
  echo "$RESPONSE" >> ~/GinieSystem/Logs/telegram_notify_errors.log
fi
