#!/bin/bash

# 🧪 12-TIMERS STRESSTEST – Nanotec SelfDeploy
END=$(($(date +%s) + 43200))  # 12 timer = 43 200 sek

LOGFILE="$HOME/GinieSystem/Logs/stresstest.log"
mkdir -p "$(dirname "$LOGFILE")"

echo "🚀 Starter stresstest $(date)" >> "$LOGFILE"

while [ $(date +%s) -lt $END ]; do

  TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")

  echo "[$TIMESTAMP] 🚧 Ny testsyklus..." >> "$LOGFILE"

  # RAM-OVERVÅKNING
  RAM_MB=$(vm_stat | awk '/Pages active/ {a=$3} /Pages wired down/ {w=$3} END {print int((a + w)*4096/1024/1024)}')
  if [ "$RAM_MB" -gt "9000" ]; then
    echo "[$TIMESTAMP] ⚠️ RAM over 9000 MB ($RAM_MB MB)" >> "$LOGFILE"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
         -d chat_id="$TELEGRAM_CHAT" \
         -d text="⚠️ RAM-bruk overstiger 90%! Nå: $RAM_MB MB på $(hostname)"
  fi

  # Kjør noder parallelt
  bash "$HOME/GinieSystem/Earn/earn_mission.sh" &
  bash "$HOME/GinieSystem/Earn/reinvest.sh" &
  bash "$HOME/GinieSystem/Earn/fallback_watch.sh" &
  bash "$HOME/GinieSystem/Earn/breakthrough_notify.sh" &
  bash "$HOME/GinieSystem/Earn/vault_distributor.sh" &
  bash "$HOME/GinieSystem/Earn/learning_loop.sh" &

  wait
  echo "[$TIMESTAMP] ✅ Runde ferdig" >> "$LOGFILE"

  sleep 15
done

echo "✅ Fullført 12-timers stresstest kl. $(date)" >> "$LOGFILE"

