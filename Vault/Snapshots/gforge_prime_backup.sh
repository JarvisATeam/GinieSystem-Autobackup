#!/bin/bash

NOW=$(date +%Y-%m-%dT%H:%M:%S)
VAULT="$HOME/GinieSystem/Vault"
DEST="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieBackups"
LOG="$HOME/GinieSystem/Logs/gforge_prime.log"
GPG_KEY="1D8F4860C92A0B878ABFE8BDF450932E14DAFEB5"
EMAIL="coolsen86@gmail.com"
TELEGRAM_BOT="7906102069:AAGSnFyA2Klh9NDbRtfWgCo7..."  # <- sett inn full token
TELEGRAM_CHAT_ID="5624725784"

echo "???? [g.forge.prime] Starter sikkerhetskopi $NOW" | tee -a "$LOG"
mkdir -p "$DEST"

SRC_FILES=(
  "$VAULT/Security/pin_breach.json"
  "$VAULT/MailLogs/cron_mailproof.log"
)

for SRC in "${SRC_FILES[@]}"; do
  if [[ -f "$SRC" ]]; then
    FILENAME=$(basename "$SRC")
    DESTFILE="$DEST/${FILENAME%.log}_$NOW.gpg"

    gpg --yes --batch --output "$DESTFILE" --encrypt --recipient "$GPG_KEY" "$SRC" \
    && echo "??????? Kryptert og lagret: $DESTFILE" | tee -a "$LOG" \
    && curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT/sendMessage \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="??? G.FORGE: Backup av $FILENAME fullf??rt kl $NOW" > /dev/null
  else
    echo "?????? Fil ikke funnet: $SRC" | tee -a "$LOG"
  fi
done

echo "??????? Backup fullf??rt kl $NOW" | tee -a "$LOG"
