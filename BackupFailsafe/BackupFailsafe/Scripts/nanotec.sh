#!/bin/bash
LOG="$HOME/GinieSystem/Logs/nanotec_yes.out"
mkdir -p "$(dirname "$LOG")"
echo "🔬 NanoTec overvåkning startet: $(date)" >> "$LOG"
if [ -f "$HOME/GinieSystem/Flags/emergency.flag" ]; then
  echo "⚠️ NØDFLAGG funnet! $(date)" >> "$LOG"
fi
echo "✅ NanoTec kjørte ferdig: $(date)" >> "$LOG"
