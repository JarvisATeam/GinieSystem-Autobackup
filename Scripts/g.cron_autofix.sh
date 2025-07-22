#!/bin/bash

echo "🔧 Starter automatisk opprydding av cronjobber..."

CRON_TMP=$(mktemp)
CRON_BACKUP=~/GinieSystem/Vault/cron_backup_$(date '+%Y-%m-%d_%H-%M').bak

# Hent alle nåværende cronjobber
crontab -l > "$CRON_TMP" 2>/dev/null || echo "" > "$CRON_TMP"

# Lag backup
cp "$CRON_TMP" "$CRON_BACKUP"
echo "🗄️ Backup lagret til $CRON_BACKUP"

# Fjern dubletter og tomme linjer
awk '!seen[$0]++' "$CRON_TMP" | grep -vE '^\s*$' > "$CRON_TMP.clean"

# Fiks linjer som mangler feilbehandling
sed -i '' -E 's|(/[^|&;]+)(\s*>>[^|&;]+)?(\s*2>&1)?$|\1 || echo "❌ Cron-feil i \1" | mail -s "Cron Error" you@example.com|' "$CRON_TMP.clean"

# Lagre ny crontab
crontab "$CRON_TMP.clean"

echo "✅ Cronjobber er nå renset, optimalisert og sikret."
rm "$CRON_TMP" "$CRON_TMP.clean"
