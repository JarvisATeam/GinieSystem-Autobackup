# Improved: g.manual_update_now.sh ons. 23 jul. 2025 22.25.45 CEST
##!/bin/bash
echo "🛠️ Manuell Ginie-oppdatering startet..."
bash ~/GinieSystem/Scripts/g.git_autopush.sh
bash ~/GinieSystem/Scripts/g.cron_autofix.sh
echo "$(date '+%F %T') | 🆙 Manuell oppdatering utført" >> ~/GinieSystem/Logs/update.log
echo "✅ Oppdatering fullført."
