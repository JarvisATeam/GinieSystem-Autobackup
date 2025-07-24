#!/bin/bash

TOKEN=$(cat ~/.telegram_token)
CHAT_ID=$(cat ~/.telegram_chat)
OFFSET_FILE="$HOME/GinieSystem/Vault/telegram_offset.txt"
[[ -f "$OFFSET_FILE" ]] || echo 0 > "$OFFSET_FILE"
OFFSET=$(cat "$OFFSET_FILE")

RESPONSE=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates?offset=$OFFSET&timeout=10")
NEW_OFFSET=$(echo "$RESPONSE" | grep -o '"update_id":[0-9]*' | cut -d ':' -f2 | tail -n1)
[[ -n "$NEW_OFFSET" ]] && echo $((NEW_OFFSET + 1)) > "$OFFSET_FILE"

MESSAGE=$(echo "$RESPONSE" | grep -o '"text":"[^"]*"' | cut -d ':' -f2- | tr -d '"')

case "$MESSAGE" in
  status)
    bash ~/GinieSystem/Vault/telegram_notify.sh "📊 STATUS: Systemet er live – $(date)"
    ;;
  zip)
    bash ~/GinieSystem/Scripts/ginie_zip_to_icloud.sh
    ;;
  push)
    bash ~/GinieSystem/Scripts/gforce_git_push.sh
    ;;
  reboot)
    bash ~/GinieSystem/Scripts/ginie_system_start.sh
    ;;
  shutdown)
    pkill -f g.force.loop
    bash ~/GinieSystem/Vault/telegram_notify.sh "🛑 Loop stoppet midlertidig av bruker"
    ;;
  *)
    [[ -n "$MESSAGE" ]] && bash ~/GinieSystem/Vault/telegram_notify.sh "❓ Ugyldig kommando: $MESSAGE"
    ;;
esac
