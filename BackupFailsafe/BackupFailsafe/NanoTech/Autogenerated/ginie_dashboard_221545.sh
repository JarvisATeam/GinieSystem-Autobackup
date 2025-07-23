# Improved: ginie_dashboard.sh ons. 23 jul. 2025 22.15.45 CEST
##!/bin/bash
clear
echo "📜 Siste loggposter:"
tail -n 5 ~/GinieSystem/Logs/fork_activity.log 2>/dev/null
tail -n 5 ~/GinieSystem/Vault/MailLogs/cron_mailproof.log 2>/dev/null

echo ""
echo "📊 Cron-jobber:"
crontab -l | grep -v '^##'

echo ""
echo "💾 Bruk av CPU og RAM for Ginie:"
ps aux | grep -i ginie | grep -v grep | awk '{print $2, $3, $4, $11}'

echo ""
echo "📂 Siste handlinger i Earn-noder:"
ls -lt ~/GinieSystem/Earn/active/ | head -n 5

echo ""
echo "✅ Fullført!"
