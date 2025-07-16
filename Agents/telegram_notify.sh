#!/bin/bash
TOKEN=$(gpg --decrypt ~/GinieSystem/Vault/keys/telegram_token.gpg 2>/dev/null)
CHAT_ID=$(cat ~/.telegram_chat)
TEXT="$1"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  --data-urlencode "text=$TEXT"
