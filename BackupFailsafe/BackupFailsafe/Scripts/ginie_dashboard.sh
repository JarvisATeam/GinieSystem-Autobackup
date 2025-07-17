#!/bin/bash

echo "🧠 GinieSystem LIVE Dashboard – $(date '+%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------------------------"

echo "🛰 Aktive noder:"
ps aux | grep -i ginie | grep -v grep | awk '{print $2, $11, $12, $13}'

echo ""
echo "📜 Siste loggposter:"
tail -n 5 ~/GinieSystem/Logs/fork_activity.log 2>/dev/null
tail -n 5 ~/GinieSystem/Vault/MailLogs/cron_mailproof.log 2>/dev/null

echo ""
echo "📊 Cron-jobber:"
crontab -l | grep -v '^#'

echo ""
echo "💾 Bruk av CPU og RAM for Ginie:"
ps aux | grep -i ginie | grep -v grep | awk '{print $2, $3, $4, $11}'

echo ""
echo "📂 Siste handlinger i Earn-noder:"
ls -lt ~/GinieSystem/Earn/active/ | head -n 5

echo ""
echo "✅ Fullført!"
