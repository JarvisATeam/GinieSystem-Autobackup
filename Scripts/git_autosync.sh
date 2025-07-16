#!/bin/bash

VAULT_DIR="$HOME/GinieSystem/Vault/MINNE"
cd "$VAULT_DIR" || exit 1

if [ ! -d ".git" ]; then
  git init
  git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
fi

git add .
git commit -m "📦 Auto sync: $(date +'%F %T')" 2>/dev/null
git push origin main 2>&1
