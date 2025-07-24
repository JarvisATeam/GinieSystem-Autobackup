#!/bin/bash
LOG="$HOME/GinieSystem/Logs/force_loop.log"
echo "💠 Start warp-loop: $(date)" >> "$LOG"
for i in {1..16}; do
  echo "🔁 Runde $i: $(date)" >> "$LOG"
  bash ~/GinieSystem/Core/gforge_warp.sh >> "$LOG" 2>&1
  sleep 1800
done
echo "✅ Ferdig: $(date)" >> "$LOG"
