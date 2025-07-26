#!/bin/bash
# 🚀 GinieSystem NanoTech Permanent Autosetup 🚀

# 🔐 Hent sikre variabler fra GinieSystem Vault
source ~/GinieSystem/vault.conf || { echo "❌ Fant ikke vault.conf"; exit 1; }

# Sjekk for nødvendige variabler
[[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]] && { echo "❌ Telegram varsler mangler"; exit 1; }

# 📌 Generer selvhelbredende Telegram-varsling og backup-script (NanoTech-standard)
cat << EOF > ~/GinieSystem/Scripts/telegram_backup_notify.sh
#!/bin/bash
BACKUP_PATH=~/Dropbox/NanoBackup/\$(basename "\$PWD")-\$(date +%F-%H%M)
mkdir -p "\$BACKUP_PATH" && cp -r . "\$BACKUP_PATH"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \\
-d chat_id="${TELEGRAM_CHAT_ID}" \\
-d text="✅ [NanoTech] Backup utført for \$(basename "\$PWD") ⏱️ \$(date '+%Y-%m-%d %H:%M'). 📂 \${BACKUP_PATH}"
EOF

chmod +x ~/GinieSystem/Scripts/telegram_backup_notify.sh

# ⚙️ Auto-Git Hook-installasjon for ALLE repos, med NanoTech selvreparasjon
setup_git_hooks() {
  cd ~/NanoRepos || { echo "❌ NanoRepos ikke funnet"; exit 1; }
  for repo in */; do
    [[ -d "\$repo/.git" ]] || continue
    HOOK="\$repo/.git/hooks/post-commit"
    cat << HOOKEOF > "\$HOOK"
#!/bin/bash
~/GinieSystem/Scripts/telegram_backup_notify.sh || bash ~/GinieSystem/Scripts/ginie_nanotech_autosetup.sh
HOOKEOF
    chmod +x "\$HOOK"
  done
}

# Utfør hook-oppsett automatisk
setup_git_hooks

# 🛡️ Automatisk test og selvvalidering
TEST_BACKUP_PATH=~/Dropbox/NanoBackup/testrepo-\$(date +%F-%H%M)
mkdir -p ~/NanoRepos/testrepo && cd ~/NanoRepos/testrepo
git init &>/dev/null && touch testfile
git add testfile && git commit -m "NanoTech autovalidering" &>/dev/null

# Bekreft testbackup
sleep 2
if [[ -d "\$TEST_BACKUP_PATH" ]]; then
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d text="✅ [NanoTech] Autosetup-test bekreftet OK ⏱️ \$(date '+%Y-%m-%d %H:%M'). Alt er klart!"
  rm -rf ~/NanoRepos/testrepo
else
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d text="❌ [NanoTech] Autosetup-test feilet ⏱️ \$(date '+%Y-%m-%d %H:%M'). Kjør manuell sjekk."
fi

echo "🎯 NanoTech Autosetup fullført. Alt klart for alltid!"

