#!/bin/bash
# GinieSystem Superloop :: Autoexecuted from boot, survives logout and termius close
# Last updated: 2025-07-15T16:24:35

# 📦 INIT - Paths
export GINIE_HOME="$HOME/GinieSystem"
export VAULT="$GINIE_HOME/Vault"
export LOGS="$GINIE_HOME/Logs"
export DASH="$GINIE_HOME/Dashboards"
export SCRIPTLOG="$LOGS/g.superloop.log"

mkdir -p "$LOGS"

# 🛡️ Logging
echo "🔁 GinieSystem Superloop starter 2025-07-15T16:24:35" >> "$SCRIPTLOG"

# 🔐 Start Vault og backup
nohup bash "$GINIE_HOME/Scripts/gforge_prime_autostart.sh" >> "$SCRIPTLOG" 2>&1 &

# 🌐 Start Dashboard HTTP server
nohup python3 -m http.server 8000 --directory "$DASH" >> "$LOGS/dashboard_http.log" 2>&1 &

# 🧠 Start AI-læringsloop (bok og psilo)
nohup bash "$GINIE_HOME/Scripts/psilo_2.sh" >> "$LOGS/psilo2.log" 2>&1 &

# 🧠 Lær fra bok 1342-0.txt hvis den finnes
BOOK="$VAULT/Knowledge/raw/1342-0.txt"
if [[ -f "$BOOK" ]]; then
  echo "📖 Leser bok 1342-0.txt ..." >> "$SCRIPTLOG"
  tail -n +20 "$BOOK" | head -n 1000 > /tmp/_book_excerpt.txt
  python3 -c "
from openai import OpenAI
client = OpenAI()
with open('/tmp/_book_excerpt.txt') as f:
    txt = f.read()
print(client.chat.completions.create(
    model='gpt-4',
    messages=[{'role': 'user', 'content': f'Gi et sammendrag og de viktigste innsiktene fra dette:\n{txt}'}]
).choices[0].message.content)
" >> "$LOGS/book_learn.log" 2>&1
else
  echo "❌ Fant ikke bokfil: $BOOK" >> "$SCRIPTLOG"
fi

# 📤 Sync til iCloud
nohup bash "$GINIE_HOME/Scripts/sync_learning_to_icloud.sh" >> "$LOGS/icloud_sync.log" 2>&1 &

# 📶 Warp server og refleksjon
nohup bash "$GINIE_HOME/Scripts/start_all_visible.sh" >> "$LOGS/warp_loop.log" 2>&1 &

echo "✅ [g.superloop] Alt startet vedvarende og skjult." >> "$SCRIPTLOG"
