# Improved: recover_binance_wallet.sh ons. 23 jul. 2025 13.45.36 CEST
##!/bin/bash

echo "🔍 Starter recovery-søk etter Binance Wallet-seed phrases og backup..."

LOG="$HOME/GinieSystem/Logs/recover_wallet_$(date +%F_%H%M).log"
OUT="$HOME/GinieSystem/BackupFailsafe/Vault/keys/binance_wallet_recovery.txt"

mkdir -p "$(dirname "$OUT")"

## === REGEX for seed phrases: 12-24 engelske ord
REGEX='([a-z]{4,}\s){11,23}[a-z]{4,}'

SEARCH_DIRS=(
  "$HOME/Documents"
  "$HOME/Desktop"
  "$HOME/Downloads"
  "$HOME/GinieSystem"
  "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
)

> "$OUT"

for DIR in "${SEARCH_DIRS[@]}"; do
  if [[ -d "$DIR" ]]; then
    echo "🔎 Søker i $DIR ..."
    grep -E -i -r "$REGEX" "$DIR" 2>/dev/null >> "$OUT"
  fi
done

FOUND=$(wc -l < "$OUT")
echo "✅ Fant $FOUND mulig(e) fraser eller backup-strenger" | tee -a "$LOG"

## === Krypter og slett
if [[ "$FOUND" -gt 0 ]]; then
  gpg --yes --batch -o "${OUT}.gpg" -c "$OUT"
  shred -u "$OUT"
  echo "🔐 Recovery-data kryptert i: ${OUT}.gpg" | tee -a "$LOG"
else
  echo "❌ Ingen fraser funnet." | tee -a "$LOG"
fi
