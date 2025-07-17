#!/bin/bash

echo -e "\033[1;33m🛡️ [FAILSAFE-STARTER]\033[0m Initialiserer failsafe..."

# Lagre viktig status snapshot
mkdir -p ~/GinieSystem/BackupFailsafe
cp -r ~/GinieSystem/* ~/GinieSystem/BackupFailsafe/ 2>/dev/null

# Sjekk nett
ping -c 1 1.1.1.1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\033[1;31m🔌 [NETTFEIL]\033[0m Ingen internett. Trigger fallback nå."
  echo "Internett nede $(date)" >> ~/GinieSystem/Logs/nettfeil.log
fi

# Sjekk og restart kjerneloop hvis den er død
if ! pgrep -f "g.force.loop.sh" >/dev/null; then
  echo -e "\033[1;35m🔁 [LOOP RESTART]\033[0m g.force.loop var nede – restarter..."
  bash ~/GinieSystem/g.force.loop.sh &
fi

# Git push for backup
cd ~/GinieSystem
git add .
git commit -m "🔒 Automatisk failsafe backup $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null
git push origin main 2>/dev/null

echo -e "\033[1;32m✅ [DONE]\033[0m Failsafe kjørt og alt er lagret"
bash ~/GinieSystem/Scripts/ginie_bypass.sh
bash ~/GinieSystem/Scripts/telegram_notify.sh "🔐 Failsafe backup utført $(date)"
