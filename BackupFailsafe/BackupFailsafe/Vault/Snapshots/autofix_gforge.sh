#!/bin/bash

echo "🔧 Fixer G.FORGE Prime-oppsett..."

mkdir -p ~/GinieSystem/Vault/{Proof,Security,Logs,Barna/{Pernille,Sol,Silke}}

echo '{}' > ~/GinieSystem/Vault/Proof/proof.json
echo '{}' > ~/GinieSystem/Vault/Security/pin_breach.json
touch ~/GinieSystem/Vault/Logs/gforge_autostart.log

# Fjerner farlige linjer i gforge_prime_backup.sh som prøver å regne på en .json
sed -i '' '/proof.json/ d' ~/GinieSystem/Scripts/gforge_prime_backup.sh

# Starter G.FORGE & NanoTec
bash ~/GinieSystem/Scripts/gforge_prime_backup.sh & disown
bash ~/GinieSystem/Scripts/launch_nanotec.sh & disown

# Cron for lock_guard
(crontab -l | grep -v 'lock_guard.sh'; echo "*/5 * * * * bash ~/GinieSystem/Scripts/lock_guard.sh >> ~/GinieSystem/Vault/Logs/lock_guard.log 2>&1") | crontab -

echo "✅ Ferdig! Du kan nå følge med med: tail -f ~/GinieSystem/Vault/Logs/lock_guard.log"
