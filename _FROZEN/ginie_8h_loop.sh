#!/bin/bash
END=$((SECONDS+8*3600))
echo "🔁 Starter 8-timers Ginie Evolusjonsloop: $(date)"
while [ $SECONDS -lt $END ]; do
  echo "▶️ Kjøring: $(date)"
  bash ~/GinieSystem/Core/gforge_warp.sh
  sleep 1800 # 30 minutter
done
echo "✅ Loop ferdig: $(date)"
