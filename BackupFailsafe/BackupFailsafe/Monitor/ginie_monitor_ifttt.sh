#!/bin/bash
LOG="$HOME/GinieSystem/Logs/ginie_ifttt_monitor_$(date +%Y%m%d).log"
mkdir -p "$(dirname "$LOG")"
IFTTT_URL="https://maker.ifttt.com/trigger/ginie_error/with/key/jANkJGu"
PROSESSER=("vaultsync.sh" "earn_mission.sh" "gforge_prime_autostart.sh")

check_process() {
  pgrep -f "$1" >/dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Prosess: $1 mangler!" >> "$LOG"
    return 1
  else
    echo "✅ Prosess: $1 OK" >> "$LOG"
    return 0
  fi
}

check_cronlog() {
  grep "$1" ~/GinieSystem/Logs/*.log | tail -n 1 | grep "$(date +%Y-%m-%d)" >/dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Cron for $1 ikke aktiv i dag" >> "$LOG"
    return 1
  else
    echo "✅ Cron for $1 aktiv" >> "$LOG"
    return 0
  fi
}

notify_if_fail() {
  if grep "❌" "$LOG" >/dev/null; then
    curl -s -X POST "$IFTTT_URL" \
      -H "Content-Type: application/json" \
      -d "{\"value1\":\"GinieMonitor Feil\",\"value2\":\"$(date)\",\"value3\":\"$(grep '❌' $LOG | tr '\n' '; ')\"}"
  fi
}

echo "🧠 Overvåking startet $(date)" > "$LOG"
for p in "${PROSESSER[@]}"; do check_process "$p"; done
check_cronlog "earn_daily"
notify_if_fail
