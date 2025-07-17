#!/bin/bash
VAULT_DIR="$HOME/GinieSystem/Vault"
LOG="$HOME/GinieSystem/Logs/vault_sync.log"
mkdir -p "$VAULT_DIR"
echo "🔑 Keyload kjøres: $(date)" >> "$LOG"

for file in "$VAULT_DIR"/*; do
  case "$file" in
    *.env|*.token|*.key)
      export $(cat "$file" | xargs) && echo "✅ Lastet: $file" >> "$LOG"
      ;;
    *.gpg)
      gpg -d "$file" > /tmp/dec_$(basename "$file").env 2>/dev/null && \
      export $(cat /tmp/dec_*.env | xargs) && echo "🔐 Dekryptert: $file" >> "$LOG"
      ;;
    *)
      echo "ℹ️  Hoppet over: $file" >> "$LOG"
      ;;
  esac
done
