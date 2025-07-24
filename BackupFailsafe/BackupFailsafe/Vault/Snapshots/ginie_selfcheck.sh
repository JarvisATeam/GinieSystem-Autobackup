#!/bin/bash

echo "GinieSystem: SELFCHECK $(date '+%Y-%m-%d %H:%M:%S')"
echo "───────────────────────────────────────"

echo "[PROSESSER]"
ps aux | grep -Ei 'g.force.loop|ginie|psilo|vault|g.train|g.log|p.shillosybe' | grep -v grep

echo ""
echo "[VAULT-NØKLER]"
find ~/GinieSystem/Vault/keys -type f

echo ""
echo "[CRONJOBS]"
crontab -l | grep -Ei 'ginie|train|backup|watchdog' || echo "Ingen relevante cronjobs"

echo ""
echo "[MAPPESTRUKTUR OG FILANTALL]"
for dir in ~/GinieSystem/{Scripts,TrainApp,Vault,Logs,Docs,Profiles,BackupFailsafe}; do
  echo -n "$(basename "$dir"): "
  find "$dir" -type f 2>/dev/null | wc -l
done

echo ""
echo "[GIT STATUS]"
cd ~/GinieSystem && git status -s 2>/dev/null || echo "Ikke et Git-repo"

echo ""
echo "[SISTE LOGG - TRENING]"
tail -n 5 ~/GinieSystem/Logs/g.train.log 2>/dev/null || echo "Ingen treningslogg"

echo ""
echo "[SISTE LOGG - BACKUP]"
tail -n 5 ~/GinieSystem/Logs/g.backup.log 2>/dev/null || echo "Ingen backup-logg"

echo ""
echo "SELF-CHECK FERDIG"
