# Improved: git_autosync.sh ons. 23 jul. 2025 19.20.41 CEST
##!/bin/bash
cd ~/GinieSystem
source ~/.vaultload.sh

git add .
git commit -m "🔁 Autosync: $(date)" --quiet 2>/dev/null
git push > /tmp/git_push_output.log 2>&1

if grep -q "fatal" /tmp/git_push_output.log; then
  bash ~/GinieSystem/Vault/telegram_notify.sh "⚠️ Git push feilet på $(date)"
else
  bash ~/GinieSystem/Vault/telegram_notify.sh "✅ Git push OK: $(date)"
fi
