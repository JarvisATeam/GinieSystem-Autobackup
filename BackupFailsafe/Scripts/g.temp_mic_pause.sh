#!/bin/bash
INPUT="$1"

# ❌ Ikke spill av null, tom eller 0
if [[ -z "$INPUT" || "$INPUT" == "null" || "$INPUT" == "0" ]]; then
  echo "⚠️ Skipper avspilling av ugyldig svar."
  exit 0
fi

# 🛡️ Pause shield
launchctl unload ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null

# 🔊 Spill svaret
bash ~/GinieSystem/Scripts/g.voice_reply.sh "$INPUT"

# 🔐 Restart shield
sleep 1
launchctl load ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null

exit 0
