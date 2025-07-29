#!/bin/bash

echo "🛠️ Starter G.FORCE TotalRepair — evolve i 12t..."
export YES_TO_ALL="yes"
export SCRIPT_HOME="$HOME/GinieSystem/Scripts"
export EARN_HOME="$HOME/GinieSystem/Earn"
export LOG_HOME="$HOME/GinieSystem/Logs"
export CORE_HOME="$HOME/GinieSystem/Core"

mkdir -p "$SCRIPT_HOME" "$EARN_HOME" "$LOG_HOME" "$CORE_HOME"

# --- nano_wizard
cat << 'EON' > "$SCRIPT_HOME/nano_wizard.sh"
#!/bin/bash
SCRIPT="$1"
LINE_NUMBER="$2"
[ -z "$SCRIPT" ] && echo "Bruk: nano_wizard.sh <fil> [linje]" && exit 1
cp "$SCRIPT" "$SCRIPT.bak"
[ -n "$LINE_NUMBER" ] && nano +$LINE_NUMBER "$SCRIPT" || nano "$SCRIPT"
echo "🧠 Endringer:"
diff "$SCRIPT.bak" "$SCRIPT" || echo "🔍 Ingen forskjell"
EON

# --- gfix_backup
cat << 'EOB' > "$SCRIPT_HOME/gfix_backup.sh"
#!/bin/bash
SCRIPT="$HOME/GinieSystem/Scripts/gforge_prime_backup.sh"
cp "$SCRIPT.bak" "$SCRIPT" && chmod +x "$SCRIPT" && nano "$SCRIPT"
EOB

# --- ginie_keyload
cat << 'EOK' > "$SCRIPT_HOME/ginie_keyload.sh"
#!/bin/bash
export STRIPE_TOKEN=$(cat ~/.stripe_token 2>/dev/null)
export TELEGRAM_TOKEN=$(cat ~/.telegram_token 2>/dev/null)
export TELEGRAM_CHAT=$(cat ~/.telegram_chat 2>/dev/null)
export NOTION_TOKEN=$(cat ~/.notion_token 2>/dev/null)
export NOTION_DB_ID=$(cat ~/.notion_db_id 2>/dev/null)
export GMAIL_PASS=$(gpg --batch --quiet --decrypt ~/.mailpass.gpg 2>/dev/null)
export GITHUB_PAT="github_pat_..."
export TWILIO_SID="ACxxx"
export TWILIO_AUTH="xxx"
echo "✅ Nøkler lastet til miljøvariabler"
EOK

# --- self_reflect
cat << 'EOS' > "$CORE_HOME/self_reflect.sh"
#!/bin/bash
echo "🧠 Oppdaterer memory_init.prompt..."
cat <<EOF > ~/GinieSystem/Prompts/memory_init.prompt
SYSTEM: Du er Ginie. Du eies av Christer Olsen. Du er selvutviklende og bruker filene i ~/GinieSystem for å forstå deg selv. Din logikk er: Lær – Evaluer – Utfør – Gjenta.
