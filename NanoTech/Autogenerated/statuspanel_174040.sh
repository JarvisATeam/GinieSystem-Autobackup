# Improved: statuspanel.sh ons. 23 jul. 2025 17.40.40 CEST
##!/bin/bash

echo "🧠 GINIE SYSTEM STATUSPANEL – $(date '+%Y-%m-%d %H:%M:%S')"
echo "──────────────────────────────────────────────"

## iCloud status
echo -n "📂 iCloud sync: "
if [ -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieBackups/confirmed_actions.md" ]; then
  echo "✅ OK"
else
  echo "❌ Mangler"
fi

## Vault status
echo -n "🔐 Vault lastet: "
VAULT_FILE="$HOME/GinieSystem/Vault/keys/telegram_token.key"
[ -f "$VAULT_FILE" ] && echo "✅ OK" || echo "❌ Mangler"

## Trip-log status
echo -n "🧪 Trip-logg i dag: "
grep "$(date '+%F')" ~/GinieSystem/Logs/psilo_trips/*.log 2>/dev/null | wc -l | xargs -I{} echo "{} linjer"

## Git push status
echo -n "📦 Git push-sjekk: "
cd ~/GinieSystem && git status -s | grep -q . && echo "❌ Endringer finnes" || echo "✅ Oppdatert"

## Barnesystem
echo -n "🗣️ Meldt til barn (siste 24t): "
find ~/GinieSystem/Logs/ -name '*children*.log' -mtime -1 | wc -l | xargs -I{} echo "{} logg(er)"

## Daglig loop
echo -n "🔁 Daglig loop aktiv: "
pgrep -f "g.force.loop.sh" > /dev/null && echo "✅ Kjørende" || echo "❌ Ikke aktiv"

echo "──────────────────────────────────────────────"
