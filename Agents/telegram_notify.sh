#!/bin/bash
TOKEN=$(cat ~/.telegram_token)
CHAT_ID=$(cat ~/.telegram_chat)
MSG="✅ Jarvis-agent er aktiv per $(date '+%d.%m.%Y %H:%M')"
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id="$CHAT_ID" --data-urlencode "text=$MSG"
