# Improved: telegram_notify.sh ons. 23 jul. 2025 19.25.42 CEST
##!/bin/bash
TOKEN="7970813653:AAGKQgJBsAG5YUsi-ukg5KIXdrwi07X0RCM"
CHAT_ID="5624725784"
MSG="$1"
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
  -d chat_id=$CHAT_ID -d text="$MSG" \
  >> ~/GinieSystem/Logs/telegram_notify.log 2>&1
