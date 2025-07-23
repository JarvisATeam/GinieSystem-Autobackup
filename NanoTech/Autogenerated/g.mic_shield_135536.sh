# Improved: g.mic_shield.sh ons. 23 jul. 2025 13.55.36 CEST
##!/bin/bash

## CONFIG
TELEGRAM_TOKEN=$(cat "$HOME/GinieSystem/Vault/keys/telegram_token.key")
CHAT_ID=$(cat "$HOME/GinieSystem/Vault/keys/telegram_chat.key")
LOG="$HOME/GinieSystem/Logs/mic_shield.log"
WHITELIST=("zoom.us" "FaceTime" "coreaudiod" "ginie_voice.sh")

mkdir -p "$(dirname "$LOG")"
touch "$LOG"

check_mic_use() {
    lsof | grep -i "coreaudio" | grep -v grep | while read -r line; do
        PROC=$(echo "$line" | awk '{print $1}')
        
        ## Sjekk whitelist
        if [[ ! " ${WHITELIST[*]} " =~ " ${PROC} " ]]; then
            TIMESTAMP=$(date '+%F %T')
            MSG="⚠️ $PROC bruker mikrofonen! [$TIMESTAMP]"

            echo "$MSG" >> "$LOG"

            ## Send Telegram-varsel
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                -d chat_id="$CHAT_ID" \
                -d text="$MSG"

            ## Drep prosess (grov metode)
            pkill -f "$PROC"
        fi
    done
}

while true; do
    check_mic_use
    sleep 10
done
