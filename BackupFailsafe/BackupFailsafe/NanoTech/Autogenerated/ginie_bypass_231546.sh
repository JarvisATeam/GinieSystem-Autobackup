# Improved: ginie_bypass.sh ons. 23 jul. 2025 23.15.46 CEST
##!/bin/bash

logfile=~/GinieSystem/Logs/bypass.log
touch $logfile

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$logfile"
}

log "🚪 Bypass aktivert – sjekker for blokkerte dører..."

## 1. Vault tilgjengelighet
if [ ! -f ~/.vaultload.sh ]; then
  log "🔒 Vault ikke funnet. Forsøker å gjenopprette..."
  cp ~/GinieSystem/Vault/Backup/vaultload_backup.sh ~/.vaultload.sh && \
  log "✅ Vault gjenopprettet fra backup" || \
  log "❌ Vault gjenoppretting feilet"
fi

## 2. Git push
cd ~/GinieSystem
git add . > /dev/null 2>&1
git commit -m "🔁 Auto-commit for bypass fallback" > /dev/null 2>&1
git push origin main > /dev/null 2>&1 && \
log "✅ Git push lykkes" || \
log "❌ Git push blokkert – dør stengt"

## 3. Telegram test
bash ~/GinieSystem/Scripts/send_telegram.sh "🚪 Bypass-script kjørt – sjekket for stengte dører $(date '+%H:%M:%S')"

## 4. Cron checker
crontab -l | grep -q 'ginie_failsafe.sh' && \
log "✅ Cron aktiv for failsafe" || {
  (crontab -l 2>/dev/null; echo "*/30 * * * * bash ~/GinieSystem/ginie_failsafe.sh >> ~/GinieSystem/Logs/failsafe_cron.log 2>&1") | crontab -
  log "⚠️ Cron manglet – ble reinstallert"
}

## 5. DMG-bygger sjekk
if [ ! -f ~/GinieSystem/Build/ginie_dmg_build.sh ]; then
  log "📦 Byggescript manglet – gjenoppretter..."
  curl -s -o ~/GinieSystem/Build/ginie_dmg_build.sh https://raw.githubusercontent.com/JarvisATeam/GinieSystem-Autobackup/main/Build/ginie_dmg_build.sh && chmod +x ~/GinieSystem/Build/ginie_dmg_build.sh
  log "✅ Byggescript gjenopprettet"
fi

log "🏁 Bypass-script fullført."
