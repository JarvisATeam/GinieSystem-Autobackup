#!/bin/bash

echo "🔧 FULL SELVREPARASJON STARTET: $(date '+%F %T')" | tee -a ~/GinieSystem/Logs/update.log

# 🔐 Git config
git config --global user.name "Christer Olsen"
git config --global user.email "christer@ginie.system"

# 🔐 SSH key
[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -C "captein-ginie" -f ~/.ssh/id_ed25519 -N "" && pbcopy < ~/.ssh/id_ed25519.pub

# 🔁 Git init
cd ~/GinieSystem/Vault
git init
git remote remove origin 2>/dev/null
git remote add origin git@github.com:captein/GinieVault.git
git add .
git commit -m "🧬 Auto-fix $(date)" || true
git push -u origin master || echo "⚠️ Push venter på GitHub nøkkel"

# ♻️ Recovery
cat << 'REC' > ~/GinieSystem/Scripts/g.recovery_loop.sh
#!/bin/bash
L=~/GinieSystem/Vault/Recovered/.map-recover.log
mkdir -p ~/GinieSystem/Vault/Recovered
echo "♻️ Recovery-loop: $(date)" >> "$L"
find ~/Library/Mobile\\ Documents/ -type f > ~/GinieSystem/Vault/Recovered/index_iclouddrive.txt 2>/dev/null
crontab -l > ~/GinieSystem/Vault/Recovered/cron_active.txt 2>/dev/null
launchctl list > ~/GinieSystem/Vault/Recovered/launchd_active.txt 2>/dev/null
find ~/GinieSystem -type f -not -path "*Vault*" > ~/GinieSystem/Vault/Recovered/untracked_ginie_files.txt
echo "✅ Recovery done: $(date)" >> "$L"
REC

# 🧠 Truth verifier
cat << 'TRU' > ~/GinieSystem/Scripts/g.truth_verify.sh
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
TRU

chmod +x ~/GinieSystem/Scripts/*.sh

# 🔁 Daglig oppgaver
(crontab -l ; echo "5 3 * * * bash ~/GinieSystem/Scripts/g.recovery_loop.sh") | crontab -
(crontab -l ; echo "*/15 * * * * bash ~/GinieSystem/Scripts/g.git_autopush.sh") | crontab -

# ✅ Start nå
bash ~/GinieSystem/Scripts/g.recovery_loop.sh
bash ~/GinieSystem/Scripts/g.truth_verify.sh

echo "✅ FULL GINIE AUTOFIX AKTIV I 12 TIMER – GÅ."
