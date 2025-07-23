# Improved: logg_postworkout.sh ons. 23 jul. 2025 14.25.36 CEST
##!/bin/bash
NOW=$(date +"%Y-%m-%d %H:%M")
LOG="$HOME/GinieSystem/Health/Logs/nutrition_log_$(date +%F).txt"
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieSystem/Health/Logs"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ICLOUD"

echo "[$NOW] Post-workout inntak:
- Whey protein + BCAA
- Gerimax multivitamin
- K2-vitamin
- 60 min trening, 20 min sol
- ZMA før søvn" >> "$LOG"

cp "$LOG" "$ICLOUD"
echo "✅ Logg lagret og kopiert til iCloud"
