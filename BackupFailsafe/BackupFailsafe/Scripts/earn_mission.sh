#!/bin/bash

echo "🚀 Starter EARN MISSION: $(date '+%F %T')"
LOGFILE="$HOME/GinieSystem/Logs/earn_mission.log"
VAULT_SCRIPT="$HOME/GinieSystem/Scripts/crypto_vault.sh"

# === STEG 1: Last nøkler
bash ~/GinieSystem/Scripts/ginie_keyload.sh

# === STEG 2: Sync Vault og Backup
bash ~/GinieSystem/Scripts/gforge_prime_autostart.sh

# === STEG 3: Aksesser Crypto Vault
echo "🔐 Aksesserer crypto vault..."
bash "$VAULT_SCRIPT" >> "$LOGFILE" 2>&1

# === STEG 4: Utfør mining/trading
echo "💸 Starter verdigenererende handling..."
bash ~/GinieSystem/Scripts/reinvest.sh >> "$LOGFILE" 2>&1
bash ~/GinieSystem/Scripts/learning_loop.sh >> "$LOGFILE" 2>&1

# === STEG 5: Push status
bash ~/GinieSystem/Scripts/push_linktree.sh >> "$LOGFILE" 2>&1

# === SLUTT
echo "✅ Earn mission fullført: $(date '+%F %T')" | tee -a "$LOGFILE"
