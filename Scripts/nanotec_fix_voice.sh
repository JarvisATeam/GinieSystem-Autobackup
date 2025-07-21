#!/bin/bash

echo "🛠️ NanoTec starter total reparasjon av Ginie Voice System..."

mkdir -p ~/GinieSystem/{Scripts,Logs,Vault/keys}

VOICE_KEY=$(cat ~/GinieSystem/Vault/keys/elevenlabs.key 2>/dev/null)
OPENAI_KEY=$(cat ~/GinieSystem/Vault/keys/openai.key 2>/dev/null)

[[ -z "$VOICE_KEY" ]] && { echo "❌ ElevenLabs-nøkkel mangler."; exit 1; }
[[ -z "$OPENAI_KEY" ]] && { echo "❌ OpenAI-nøkkel mangler."; exit 1; }

# 🎙️ Reinstaller voice_reply
cat << 'EOV' > ~/GinieSystem/Scripts/g.voice_reply.sh
#!/bin/bash
TEXT="$1"
API_KEY=$(cat ~/GinieSystem/Vault/keys/elevenlabs.key)
VOICE_ID="EXAVITQu4vr4xnSDxMaL"
[ -z "$TEXT" ] && exit 1
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
  -H "xi-api-key: $API_KEY" -H "Content-Type: application/json" \
  -d '{"text": "'"$TEXT"'", "voice_settings": {"stability": 0.5,"similarity_boost": 0.75}}' \
  --output /tmp/ginie_talk.mp3
afplay /tmp/ginie_talk.mp3 >/dev/null 2>&1
exit 0
EOV

# 🛡️ Shield pause-script
cat << 'EOT' > ~/GinieSystem/Scripts/g.temp_mic_pause.sh
#!/bin/bash
launchctl unload ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null
bash ~/GinieSystem/Scripts/g.voice_reply.sh "$1"
sleep 1
launchctl load ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null
EOT

# 🔁 Reinstaller samtaleloop
cat << 'EOLOOP' > ~/GinieSystem/Scripts/g.talk_loop.sh
#!/bin/bash
AUDIO_FILE="/tmp/ginie_speak.wav"
TRANSCRIBE_API="https://api.openai.com/v1/audio/transcriptions"
API_KEY=$(cat ~/GinieSystem/Vault/keys/openai.key)
MODEL="whisper-1"
LOG="$HOME/GinieSystem/Logs/voice_loop.log"
mkdir -p "$(dirname "$LOG")"

while true; do
  echo "🎤 Opptak..."
  ffmpeg -f avfoundation -i ":0" -t 10 -ac 1 -ar 16000 "$AUDIO_FILE" -y &> /dev/null

  RAW=$(curl -s -X POST "$TRANSCRIBE_API" \
    -H "Authorization: Bearer $API_KEY" -H "Content-Type: multipart/form-data" \
    -F "file=@$AUDIO_FILE" -F "model=$MODEL")

  TRANSCRIPT=$(echo "$RAW" | jq -r .text)
  [[ -z "$TRANSCRIPT" || "$TRANSCRIPT" == "null" ]] && continue
  echo "🗣️ Du: $TRANSCRIPT"
  echo "$(date '+%F %T') | 🎙️ $TRANSCRIPT" >> "$LOG"

  RAWGPT=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
    -d '{"model":"gpt-4","messages":[{"role":"user","content":"'"$TRANSCRIPT"'"}]}')

  ANSWER=$(echo "$RAWGPT" | jq -r '.choices[0].message.content')
  [[ -z "$ANSWER" || "$ANSWER" == "null" ]] && continue
  echo "🤖 Ginie: $ANSWER"
  echo "$(date '+%F %T') | 🤖 $ANSWER" >> "$LOG"
  bash ~/GinieSystem/Scripts/g.temp_mic_pause.sh "$ANSWER" >/dev/null 2>&1
done
EOLOOP

chmod +x ~/GinieSystem/Scripts/g.voice_reply.sh
chmod +x ~/GinieSystem/Scripts/g.temp_mic_pause.sh
chmod +x ~/GinieSystem/Scripts/g.talk_loop.sh

echo "✅ Full NanoTec-reparasjon ferdig. Starter loopen nå..."
nohup bash ~/GinieSystem/Scripts/g.talk_loop.sh > /dev/null 2>&1 &
