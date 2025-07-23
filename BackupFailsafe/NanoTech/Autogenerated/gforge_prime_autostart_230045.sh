# Improved: gforge_prime_autostart.sh ons. 23 jul. 2025 23.00.45 CEST
##!/bin/bash
LOCK="$HOME/GinieSystem/Vault/Proof/.lockfile"
if [ ! -f "$LOCK" ]; then
  echo "🚀 Starter G.FORGE Prime og VaultSync..."
  bash ~/GinieSystem/Scripts/gforge_prime_backup.sh & disown
  bash ~/GinieSystem/Scripts/launch_nanotec.sh & disown
  echo "$(date): Restartet via autostart" >> ~/GinieSystem/Vault/Logs/gforge_autostart.log
fi
