# Improved: gforce_warp_automagic.sh ons. 23 jul. 2025 14.30.36 CEST
##!/bin/bash

echo "⚙️ Starter G.FORCE:WARP.AUTOMAGIC..."
BASE="$HOME/GinieSystem"
mkdir -p "$BASE/Scripts" "$BASE/Core" "$BASE/Earn" "$BASE/Logs" "$BASE/Vault" "$BASE/Prompts" "$BASE/Dashboards"

################################################
## ✅ nano_wizard
################################################
cat << 'EON' > "$BASE/Scripts/nano_wizard.sh"
##!/bin/bash
SCRIPT="$1"; LINE="$2"
cp "$SCRIPT" "$SCRIPT.bak"
[ -n "$LINE" ] && nano +$LINE "$SCRIPT" || nano "$SCRIPT"
echo "🧠 Diff:"
diff "$SCRIPT.bak" "$SCRIPT" || echo "✅ Ingen endringer"
EON

################################################
## ✅ gfix_backup
################################################
cat << 'EOG' > "$BASE/Scripts/gfix_backup.sh"
##!/bin/bash
SCRIPT="$HOME/GinieSystem/Scripts/gforge_prime_backup.sh"
cp "$SCRIPT.bak" "$SCRIPT" && chmod +x "$SCRIPT" && nano "$SCRIPT"
EOG

################################################
## ✅ ginie_keyload
################################################
cat << 'EOK' > "$BASE/Scripts/ginie_keyload.sh"
##!/bin/bash
export STRIPE_TOKEN=$(cat ~/.stripe_token 2>/dev/null)
export TELEGRAM_TOKEN=$(cat ~/.telegram_token 2>/dev/null)
export TELEGRAM_CHAT=$(cat ~/.telegram_chat 2>/dev/null)
export NOTION_TOKEN=$(cat ~/.notion_token 2>/dev/null)
export NOTION_DB_ID=$(cat ~/.notion_db_id 2>/dev/null)
export GMAIL_PASS=$(gpg --batch --quiet --decrypt ~/.mailpass.gpg 2>/dev/null)
export GITHUB_PAT="github_pat_..."
echo "✅ Tokens og API-nøkler lastet"
EOK

################################################
## ✅ self_reflect
################################################
cat << 'EOS' > "$BASE/Core/self_reflect.sh"
##!/bin/bash
echo "🧠 Oppdaterer self-awareness..."
cat <<EOF > "$HOME/GinieSystem/Prompts/memory_init.prompt"
SYSTEM: Du er Ginie. Du forstår Christers behov. Du tilpasser deg automatisk. Du består av Earn, Vault, Logs, Legal, Scripts og Core. 
Du bruker logikk: LÆR – EVALUER – UTFØR – REPEATER.
