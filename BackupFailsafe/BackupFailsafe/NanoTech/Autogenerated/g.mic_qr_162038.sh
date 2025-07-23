# Improved: g.mic_qr.sh ons. 23 jul. 2025 16.20.38 CEST
##!/bin/bash
LOG="$HOME/GinieSystem/Logs/mic_shield.log"
LAST=$(tail -n 15 "$LOG" | sed 's/"/'\''/g')

echo "🔲 Genererer QR med siste mic-aktivitet..."
echo "$LAST" | qrencode -t ANSIUTF8
