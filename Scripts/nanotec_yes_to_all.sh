#!/bin/bash
END=$((SECONDS + 43200)) # 12 timer
LOG="$HOME/GinieSystem/Logs/nanotec_loop.log"
echo "🌀 Starter 12-timers NanoTec-overvåkning: $(date)" > "$LOG"
while [ $SECONDS -lt $END ]; do
  bash ~/GinieSystem/Scripts/nanotec.sh
  bash ~/GinieSystem/Monitor/ginie_monitor_ifttt.sh
  sleep 300 # hvert 5. minutt
done
echo "✅ NanoTec loop ferdig: $(date)" >> "$LOG"
