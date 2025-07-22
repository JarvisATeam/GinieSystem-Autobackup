#!/bin/bash

echo "🔍 Verifiserer ekte filer og systemstatus..."

declare -a files=(
  "$HOME/GinieSystem/Scripts/g.git_autopush.sh"
  "$HOME/GinieSystem/Scripts/g.cron_autofix.sh"
  "$HOME/GinieSystem/Scripts/g.voice_reply.sh"
  "$HOME/GinieSystem/Scripts/g.talk_loop.sh"
  "$HOME/GinieSystem/Scripts/g.manual_update_now.sh"
  "$HOME/GinieSystem/Vault/cron_backup_*.bak"
  "$HOME/GinieSystem/Logs/update.log"
  "$HOME/GinieSystem/Core/g.internal_reflection.log"
)

for file in "${files[@]}"; do
  if ls $file &>/dev/null; then
    echo "✅ $file finnes."
  else
    echo "❌ $file mangler!"
  fi
done

echo "🧠 Siste Git-status:"
cd ~/GinieSystem/Vault && git status -s

echo "📄 Siste commit:"
git log -1 --pretty=oneline
