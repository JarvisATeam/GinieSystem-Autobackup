#!/bin/bash

DATE=$(date +%F)
VAULT_DIR="$HOME/GinieSystem/Health/Profiles"
LOG_FILE="$HOME/GinieSystem/Health/Logs/training_$DATE.md"
MEMORY_FILE="$VAULT_DIR/training_ai_profile.json"

mkdir -p "$VAULT_DIR"

if [ ! -f "$LOG_FILE" ]; then
  echo "🚫 Fant ikke treningsloggen for $DATE: $LOG_FILE"
  exit 1
fi

FOKUS=$(grep -i "Fokus" "$LOG_FILE" | awk -F':' '{print $2}' | xargs)
MUSKEL=$(grep -i "Muskelgruppe" "$LOG_FILE" | awk -F':' '{print $2}' | xargs)
OVELSE=$(grep -i "Øvelse" "$LOG_FILE" | awk -F':' '{print $2}' | xargs)
VARIASJON=$(grep -i "Variasjon" "$LOG_FILE" | awk -F':' '{print $2}' | xargs)
MENGDE=$(grep -i "sett" "$LOG_FILE" | tail -1 | awk -F':' '{print $2}' | xargs)

jq -n \
  --arg dato "$DATE" \
  --arg fokus "$FOKUS" \
  --arg muskel "$MUSKEL" \
  --arg ovelse "$OVELSE" \
  --arg variasjon "$VARIASJON" \
  --arg mengde "$MENGDE" \
  '{dato: $dato, fokus: $fokus, muskel: $muskel, ovelse: $ovelse, variasjon: $variasjon, mengde: $mengde}' \
  >> "$MEMORY_FILE"

echo "✅ AI-profil oppdatert i $MEMORY_FILE"
