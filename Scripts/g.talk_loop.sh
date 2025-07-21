#!/bin/bash
AUDIO_FILE="/tmp/ginie_speak.wav"
TRANSCRIBE_API="https://api.openai.com/v1/audio/transcriptions"
OPENAI_API=$(cat ~/GinieSystem/Vault/keys/openai.key)
MODEL="whisper-1"
LOG="$HOME/GinieSystem/Logs/voice_loop.log"
mkdir -p "$(dirname "$LOG")"

while true; do
  echo "🎙️ Opptak (10s)..."
  ffmpeg -f avfoundation -i ":0" -t 10 -ac 1 -ar 16000 "$AUDIO_FILE" -y &> /dev/null

  echo "🧠 Transkriberer..."
  RAW_TRANS=$(curl -s -X POST "$TRANSCRIBE_API" \
    -H "Authorization: Bearer $OPENAI_API" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$AUDIO_FILE" \
    -F "model=$MODEL")

  TRANSCRIPT=$(echo "$RAW_TRANS" | jq -r .text)
  [[ -z "$TRANSCRIPT" || "$TRANSCRIPT" == "null" ]] && {
    echo "$(date '+%F %T') | 🚫 Ikke hørte noe." >> "$LOG"
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
    echo "🧠 Ginie: [feil i svar]"
    echo "$(date '+%F %T') | ❌ GPT returnerte NULL eller 0" >> "$LOG"
    bash ~/GinieSystem/Scripts/g.temp_mic_pause.sh "Beklager, jeg hørte deg ikke tydelig." >/dev/null 2>&1
    continue
  fi

  echo "🤖 Ginie: $ANSWER"
  echo "$(date '+%F %T') | 🤖 $ANSWER" >> "$LOG"
  bash ~/GinieSystem/Scripts/g.temp_mic_pause.sh "$ANSWER" >/dev/null 2>&1
done
