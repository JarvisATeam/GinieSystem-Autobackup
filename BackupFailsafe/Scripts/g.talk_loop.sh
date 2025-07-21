#!/bin/bash
AUDIO_FILE="/tmp/ginie_speak.wav"
TRANSCRIBE_API="https://api.openai.com/v1/audio/transcriptions"
API_KEY=$(cat ~/GinieSystem/Vault/keys/openai.key)
MODEL="whisper-1"

echo "🌀 Samtaleloop startet i stealth. Ctrl+C for å avslutte."

while true; do
  ffmpeg -f avfoundation -i ":0" -t 10 -ac 1 -ar 16000 "$AUDIO_FILE" -y &> /dev/null
  TRANSCRIPT=$(curl -s -X POST "$TRANSCRIBE_API" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$AUDIO_FILE" \
    -F "model=$MODEL" | jq -r .text)
  [[ -z "$TRANSCRIPT" ]] && continue
  echo "🗣️ Du: $TRANSCRIPT"
  ANSWER=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model": "gpt-4","messages": [{"role": "user", "content": "'"$TRANSCRIPT"'"}]}' \
    | jq -r '.choices[0].message.content')
  echo "🧠 Ginie: $ANSWER"
  bash ~/GinieSystem/Scripts/g.temp_mic_pause.sh "$ANSWER"
done
