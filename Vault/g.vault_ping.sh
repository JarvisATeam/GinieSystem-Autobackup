#!/bin/bash

VAULT_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieBackups"
LATEST_FILE=$(find "$VAULT_DIR" -type f -name "*.gpg" -exec stat -f "%m %N" {} + 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [[ -n "$LATEST_FILE" ]]; then
  echo "🔐 Ny Vault-fil funnet: $LATEST_FILE"
  echo "📦 Commit og push til Git..."

  cd "$HOME/GinieSystem"
  git add "$LATEST_FILE"
  git commit -m "VaultPing: Ny backup $(basename "$LATEST_FILE")"
  git push

  echo "✅ Push fullført."
else
  echo "⚠️ Ingen Vault-fil funnet."
fi
