#!/bin/bash

# === 📍 LOKASJONER ===
VAULT_DIR="$HOME/GinieSystem/BackupFailsafe/Vault/keys"
VAULT_FILE="$VAULT_DIR/crypto_rev_addresses.gpg"
TEMP_FILE="/tmp/crypto_rev.tmp"
LOGFILE="$HOME/GinieSystem/Logs/vault_access.log"

# === 📢 TELEGRAM VARSLING ===
TELEGRAM_TOKEN=$(gpg -dq ~/.telegram_token.gpg)
TELEGRAM_CHAT_ID=$(cat ~/.telegram_chat)

notify_telegram() {
  MESSAGE="🚨 Crypto Vault aksessert $(date '+%F %T') fra: $(whoami)@$(hostname)"
  curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MESSAGE"
}

# === 📜 OPPRETT HVIS MANGLER ===
mkdir -p "$VAULT_DIR"

if [ ! -f "$VAULT_FILE" ]; then
  echo "[+] Lager nytt crypto vault..."
  cat << 'CRYPTO' > "$TEMP_FILE"
# REV CRYPTO ADDRESSES
# ---------------------
# Binance Smart Chain: 0x123456...
# Ethereum ERC20: 0xabcdef...
# REVolution: rev1qxyz9x...
# Bitcoin: bc1qabcdef...
# Solana: 6YxLkd...

# Legg til flere her.
CRYPTO

  gpg --yes --batch -o "$VAULT_FILE" -c "$TEMP_FILE"
  shred -u "$TEMP_FILE"
  echo "[+] Vault opprettet og kryptert."
fi

# === 🔓 TILGANG TIL INNHOLD ===
echo "[*] Aksesserer Crypto Vault..."
notify_telegram
echo "[Vault Access] $(date '+%F %T')" >> "$LOGFILE"
gpg -d "$VAULT_FILE"
