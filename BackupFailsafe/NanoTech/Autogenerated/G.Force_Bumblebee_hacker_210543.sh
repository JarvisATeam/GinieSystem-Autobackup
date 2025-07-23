# Improved: G.Force_Bumblebee_hacker.sh ons. 23 jul. 2025 21.05.43 CEST
##!/bin/bash ## G.Forces.Bumblebee.hacker 
stealth & speed logprobe NOW=$(date 
+"%Y-%m-%dT%H:%M:%S") 
LOG="$HOME/GinieSystem/Logs/bumblebee.log" 
VAULT="$HOME/GinieSystem/Vault" 
CLOUD="$HOME/Library/Mobile 
Documents/com~apple~CloudDocs/GinieBackups" 
echo " [$NOW] BUMBLEBEE INITIATED..." | tee 
-a "$LOG" sleep 0.5 ## Sjekk aktive noder og 
bakgrunnsprosesser echo " Sjekker aktive 
prosesser..." | tee -a "$LOG" ps aux | grep 
-Ei 'ginie|nano|cron|backup' | grep -v grep 
| tee -a "$LOG" ## Lringslogg og varsler echo 
" Lagrer lringslogg og krypterer..." | tee 
-a "$LOG" for FILE in 
"$VAULT"/Learning/*.md; do
  [ -f "$FILE" ] || continue 
  DEST="$CLOUD/$(basename $FILE)_$NOW.gpg" 
  gpg --yes --batch --encrypt -r 
  coolsen86@gmail.com -o "$DEST" "$FILE" \ 
  && echo " Kryptert $FILE $DEST" | tee -a 
  "$LOG"
done ## Valider mapper og fallbackfiler echo 
" Validerer Vault-struktur..." | tee -a 
"$LOG" for DIR in "$VAULT/Security" 
"$VAULT/Keys" "$VAULT/Learning"; do
  if [ -d "$DIR" ]; then
    echo " Mappe OK: $DIR" | tee -a "$LOG"
  else
    echo " Mangler: $DIR" | tee -a "$LOG" 
    mkdir -p "$DIR" && echo " Opprettet: 
    $DIR" | tee -a "$LOG"
  fi done ## Push til Telegram (valgfritt, 
hvis aktivert) if [[ -f 
"$VAULT/keys/telegram.env" ]]; then
  source "$VAULT/keys/telegram.env" curl -s 
  -X POST 
  https://api.telegram.org/bot$TELEGRAM_BOT/sendMessage 
  \
    -d chat_id="$TELEGRAM_CHAT_ID" \ -d 
    text=" G.FORCE Bumblebee ble kjrt $NOW 
    alt logget." > /dev/null
  echo " Varsel sendt til Telegram." | tee 
-a "$LOG" else
  echo " Telegram-integrasjon ikke 
aktivert." | tee -a "$LOG" fi
echo " [$NOW] BUMBLEBEE MISSION COMPLETE" | tee -a "$LOG"
