#!/bin/bash

CRON_SNAPSHOT="/tmp/cron_snapshot_last.txt"
CURRENT_CRON="/tmp/cron_snapshot_now.txt"
LOG="$HOME/GinieSystem/Logs/cron_monitor.log"
TELEGRAM_TOKEN=$(cat "$HOME/GinieSystem/Vault/keys/telegram_token.key")
CHAT_ID=$(cat "$HOME/GinieSystem/Vault/keys/telegram_chat.key")

mkdir -p "$(dirname "$LOG")"

# Hent nåværende crontab
crontab -l | sort > "$CURRENT_CRON"

# Første gang? Lag snapshot
if [ ! -f "$CRON_SNAPSHOT" ]; then
    cp "$CURRENT_CRON" "$CRON_SNAPSHOT"
    echo "$(date '+%F %T') ✅ Første snapshot lagret." >> "$LOG"
    exit 0
fi

# Sammenlign snapshot og nåværende
DIFF=$(diff "$CURRENT_CRON" "$CRON_SNAPSHOT")

if [[ -n "$DIFF" ]]; then
    MSG="⚠️ Endring i crontab oppdaget på $(date '+%F %T'):

$DIFF

Sjekk rot i cron, potensiell duplikat eller utilsiktet endring."
    
    echo "$MSG" >> "$LOG"

    # Send Telegram-varsling
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$MSG"
    
    cp "$CURRENT_CRON" "$CRON_SNAPSHOT"
else
    echo "$(date '+%F %T') ✅ Ingen endringer i cron. Alt ser ok ut." >> "$LOG"
fi
