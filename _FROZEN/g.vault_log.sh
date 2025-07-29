#!/bin/bash
echo "🔐 Vault-filer lagret i iCloud:"
VAULT_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieBackups"
find "$VAULT_DIR" -type f -name "*.gpg" | sort
