# Improved: g.cron_autofix.sh ons. 23 jul. 2025 14.35.36 CEST
##!/bin/bash
TMP=$(mktemp)
BACKUP=~/GinieSystem/Vault/cron_backup_$(date '+%F_%H-%M').bak
mkdir -p ~/GinieSystem/Vault
crontab -l > "$TMP" 2>/dev/null || touch "$TMP"
cp "$TMP" "$BACKUP"
awk '!seen[$0]++' "$TMP" | grep -vE '^\s*$' > "$TMP.clean"
crontab "$TMP.clean"
mkdir -p ~/GinieSystem/Dashboard && crontab -l > ~/GinieSystem/Dashboard/cron_gui.txt
echo "✅ Cron renset. Backup lagret til $BACKUP"
