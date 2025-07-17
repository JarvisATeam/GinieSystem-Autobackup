#!/bin/bash

# Din bot-token og chat ID
BOT_TOKEN="7970813653:AAGKQgJBsAG5YUsi-ukg5KIXdrwi07X0RCM"
CHAT_ID="5624725784"
MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
  MESSAGE="🤖 Standard melding fra GinieSystem – alt virker!"
fi

curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
  -d chat_id=$CHAT_ID \
  -d text="$MESSAGE" \
  -d parse_mode="Markdown"
