#!/bin/bash
LOG="$HOME/GinieSystem/Logs/mic_shield.log"
LAST=$(tail -n 15 "$LOG" | sed 's/"/'\''/g')

echo "🔲 Genererer QR med siste mic-aktivitet..."
echo "$LAST" | qrencode -t ANSIUTF8
