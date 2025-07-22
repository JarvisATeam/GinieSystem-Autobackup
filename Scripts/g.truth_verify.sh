#!/bin/bash
echo "🔍 Verifiserer status..."
F=(
  "$HOME/GinieSystem/Scripts/g.git_autopush.sh"
  "$HOME/GinieSystem/Scripts/g.cron_autofix.sh"
  "$HOME/GinieSystem/Scripts/g.voice_reply.sh"
  "$HOME/GinieSystem/Scripts/g.talk_loop.sh"
  "$HOME/GinieSystem/Scripts/g.manual_update_now.sh"
  "$HOME/GinieSystem/Vault/cron_backup_*.bak"
  "$HOME/GinieSystem/Logs/update.log"
  "$HOME/GinieSystem/Core/g.internal_reflection.log"
)
for f in "${F[@]}"; do
  ls $f &>/dev/null && echo "✅ $f" || echo "❌ $f MISSING!"
done
cd ~/GinieSystem/Vault && git status -s && git log -1 --pretty=oneline
