#!/bin/bash

echo "🧠 Starter G.FORCE::GENESIS... All systems go."

BASE="$HOME/GinieSystem"
mkdir -p "$BASE"/{Scripts,Core,Earn,Logs,Vault,Prompts,Dashboards}

########################################
# 🔧 nano_wizard
########################################
cat << 'EON' > "$BASE/Scripts/nano_wizard.sh"
#!/bin/bash
SCRIPT="$1"; LINE="$2"
cp "$SCRIPT" "$SCRIPT.bak"
[ -n "$LINE" ] && nano +$LINE "$SCRIPT" || nano "$SCRIPT"
echo "🔁 Diff:"
diff "$SCRIPT.bak" "$SCRIPT" || echo "✅ Ingen endringer"
EON

########################################
# 🛡️ gfix_backup
########################################
cat << 'EOG' > "$BASE/Scripts/gfix_backup.sh"
#!/bin/bash
SCRIPT="$HOME/GinieSystem/Scripts/gforge_prime_backup.sh"
cp "$SCRIPT.bak" "$SCRIPT"
chmod +x "$SCRIPT"
nano "$SCRIPT"
EOG

########################################
# 🔐 ginie_keyload
########################################
cat << 'EOK' > "$BASE/Scripts/ginie_keyload.sh"
#!/bin/bash
export STRIPE_TOKEN=$(cat ~/.stripe_token 2>/dev/null)
export TELEGRAM_TOKEN=$(cat ~/.telegram_token 2>/dev/null)
export TELEGRAM_CHAT=$(cat ~/.telegram_chat 2>/dev/null)
export NOTION_TOKEN=$(cat ~/.notion_token 2>/dev/null)
export NOTION_DB_ID=$(cat ~/.notion_db_id 2>/dev/null)
export GMAIL_PASS=$(gpg --quiet --batch --decrypt ~/.mailpass.gpg 2>/dev/null)
export GITHUB_PAT="github_pat_..."
echo "✅ Tokens og API-nøkler lastet"
EOK

########################################
# 🧠 self_reflect
########################################
cat << 'EOS' > "$BASE/Core/self_reflect.sh"
#!/bin/bash
echo "🧠 Oppdaterer self-awareness..."
cat <<EOF > "$HOME/GinieSystem/Prompts/memory_init.prompt"
SYSTEM: Du er Ginie. Du jobber for Christer. Du er modulbasert, lærer av deg selv og forbedrer kontinuerlig. 
Moduler: Earn, Vault, Scripts, Core, Legal, Monitor. 
Hovedstrategi: Lær – Evaluer – Utfør – Gjenta.
