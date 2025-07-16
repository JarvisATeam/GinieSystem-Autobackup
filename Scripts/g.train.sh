#!/bin/bash DATE=$(date +%F) 
LOG="$HOME/GinieSystem/Health/Logs/training_$DATE.md" 
ICLOUD="$HOME/Library/Mobile 
Documents/com~apple~CloudDocs/GinieSystem/Health/Logs/training_$DATE.md" 
echo "# Trening $DATE" > "$LOG" echo "Velg 
treningsfokus:" select FOKUS in "Overkropp" 
"Underkropp" "Fullkropp"; do break; done 
echo "- Fokus: $FOKUS" >> "$LOG" echo "Velg 
muskelgruppe:" select MUSKEL in "Bryst" 
"Rygg" "Skuldre" "Biceps" "Triceps" "Mage" 
"Lr" "Rumpe" "Legger"; do break; done echo 
"- Muskelgruppe: $MUSKEL" >> "$LOG" echo 
"Velg velse:" read -p "velse: " OVELSE echo 
"- velse: $OVELSE" >> "$LOG" echo "Velg 
variasjon 
(manualer/stang/vinkel/kabel/etc):" read -p 
"Variasjon: " VARIASJON echo "- Variasjon: 
$VARIASJON" >> "$LOG" echo "Antall sett?" 
read -p "Sett: " SETT echo "Vekt i kg?" read 
-p "Kg: " KG echo "Reps per sett?" read -p 
"Reps: " REPS echo "- $SETT sett $KG kg 
$REPS reps" >> "$LOG" cp "$LOG" "$ICLOUD"
echo " Lagret og synket til iCloud."
