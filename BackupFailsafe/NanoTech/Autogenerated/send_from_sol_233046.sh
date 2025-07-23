# Improved: send_from_sol.sh ons. 23 jul. 2025 23.30.46 CEST
##!/bin/bash
MSG="Hei pappa – dette er Sol 🧸 $(date '+%H:%M')"
TOKEN=$(cat ~/.telegram_token)
CHAT_ID=$(cat ~/.telegram_chat)
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$MSG"
