# Improved: record_voice_note.sh ons. 23 jul. 2025 18.25.40 CEST
##!/bin/bash DATE=$(date +%F) TIME=$(date 
+%H-%M) FILENAME="voice_note_${TIME}.wav" 
MEDIA_DIR="$HOME/GinieSystem/Health/Media/$DATE" 
ICLOUD_DIR="$HOME/Library/Mobile 
Documents/com~apple~CloudDocs/GinieSystem/Health/Media/$DATE" 
LOG_FILE="$HOME/GinieSystem/Health/Logs/training_nutrition_$DATE.txt" 
mkdir -p "$MEDIA_DIR" "$ICLOUD_DIR" echo " 
Tar opp lyd... Trykk Ctrl + C nr du er 
ferdig." rec "$MEDIA_DIR/$FILENAME" ## Kopier 
til iCloud cp "$MEDIA_DIR/$FILENAME" 
"$ICLOUD_DIR/" ## Logg det echo "[Media] 
$FILENAME" >> "$LOG_FILE"
echo " Lydopptak lagret, synket og logget: $FILENAME"
