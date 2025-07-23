# Improved: g.talk_loop.sh ons. 23 jul. 2025 16.15.38 CEST
##!/bin/bash

AUDIO_FILE="/tmp/ginie_speak.wav"
TRANSCRIBE_API="https://api.openai.com/v1/audio/transcriptions"
OPENAI_API=$(cat ~/GinieSystem/Vault/keys/openai.key)
MODEL="whisper-1"
LOG="$HOME/GinieSystem/Logs/voice_loop.log"
mkdir -p "$(dirname "$LOG")"

echo "🌀 Ginie samtaleloop aktivert – trykk Ctrl+C for å avslutte."

while true; do
  echo "🎤 Lytter..."
  ffmpeg -f avfoundation -i ":0" -t 10 -ac 1 -ar 16000 "$AUDIO_FILE" -y &> /dev/null

  RAW_TRANS=$(curl -s -X POST "$TRANSCRIBE_API" \
    -H "Authorization: Bearer $OPENAI_API" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$AUDIO_FILE" \
    -F "model=$MODEL")

  TRANSCRIPT=$(echo "$RAW_TRANS" | jq -r .text)
  [[ -z "$TRANSCRIPT" || "$TRANSCRIPT" == "null" ]] && {
    echo "🚫 Hørte ikke noe."
    continue
  }

  echo "🗣️ Du: $TRANSCRIPT"
  echo "$(date '+%F %T') | 🎙️ $TRANSCRIPT" >> "$LOG"

  RAW_GPT=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API" \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4","messages":[{"role":"user","content":"'"$TRANSCRIPT"'"}]}')

  ANSWER=$(echo "$RAW_GPT" | jq -r '.choices[0].message.content')

  if [[ -z "$ANSWER" || "$ANSWER" == "null" || "$ANSWER" == "0" ]]; then
    echo "🧠 Ginie: [ingen svar]"
    echo "$(date '+%F %T') | ❌ GPT returnerte NULL" >> "$LOG"
    continue
  fi

  echo "🤖 Ginie: $ANSWER"
  echo "$(date '+%F %T') | 🤖 $ANSWER" >> "$LOG"
  bash ~/GinieSystem/Scripts/g.temp_mic_pause.sh "$ANSWER" >/dev/null 2>&1
done
