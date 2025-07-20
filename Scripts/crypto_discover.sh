#!/bin/bash

echo "🔍 Søker etter crypto-adresser i systemet..."

SEARCH_DIRS=(
  "$HOME/Downloads"
  "$HOME/Documents"
  "$HOME/Desktop"
  "$HOME/iCloud Drive"
  "$HOME/GinieSystem"
)

REGEX='(0x[a-fA-F0-9]{40}|bc1[q|p][a-z0-9]{38,}|rev1q[a-z0-9]{20,})'
LOG="$HOME/GinieSystem/Logs/crypto_discover.log"
OUT="$HOME/GinieSystem/BackupFailsafe/Vault/keys/crypto_rev_addresses.txt"
VAULT="$OUT.gpg"

mkdir -p "$(dirname "$OUT")"
echo "# AUTO-GENERERT CRYPTO-ADRESSE-FUNN $(date '+%F %T')" > "$OUT"

for DIR in "${SEARCH_DIRS[@]}"; do
  if [[ -d "$DIR" ]]; then
    find "$DIR" -type f \( -iname "*.txt" -o -iname "*.json" -o -iname "*.csv" -o -iname "*.log" \) 2>/dev/null | \
    xargs grep -Eo "$REGEX" 2>/dev/null | sort -u >> "$OUT"
  fi
done

echo "✅ Fant $(wc -l < "$OUT") adresser. Krypterer..."
gpg --yes --batch -o "$VAULT" -c "$OUT"
shred -u "$OUT"

echo "🔐 Lagret til: $VAULT"
echo "📜 Full logg i: $LOG"
