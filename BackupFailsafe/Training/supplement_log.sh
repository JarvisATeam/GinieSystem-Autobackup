#!/bin/bash
DATE=$(date '+%F %T')
LOG="$HOME/GinieSystem/Training/logs/supplements.txt"

echo "💊 Kosttilskudd logg [$DATE]"
read -p "➡️ Hva tok du? (Eks: BCAA 10g): " supp
read -p "➡️ Effekt/følelse nå: " effect

echo "$DATE | $supp | Effekt: $effect" | tee -a "$LOG"
