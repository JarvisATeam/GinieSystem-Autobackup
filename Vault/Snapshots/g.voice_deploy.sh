#!/bin/bash

echo "🎤 Deploying Ginie Voice Loop i stealth-modus..."

VOICE_KEY_FILE="$HOME/GinieSystem/Vault/keys/elevenlabs.key"
OPENAI_KEY_FILE="$HOME/GinieSystem/Vault/keys/openai.key"
mkdir -p ~/GinieSystem/{Scripts,Logs,Vault/keys}

# 🔐 Sjekk ElevenLabs API
if [[ ! -f "$VOICE_KEY_FILE" ]]; then
  echo "⚠️ Mangler ElevenLabs API. Lim inn nå:"
  read -r VOICE_KEY
  echo "$VOICE_KEY" > "$VOICE_KEY_FILE"
fi

# 🔐 Sjekk OpenAI API
if [[ ! -f "$OPENAI_KEY_FILE" ]]; then
  echo "⚠️ Mangler OpenAI API. Lim inn nå:"
  read -r OPENAI_KEY
  echo "$OPENAI_KEY" > "$OPENAI_KEY_FILE"
fi

# 🎙️ g.voice_reply.sh
cat << 'EOV' > ~/GinieSystem/Scripts/g.voice_reply.sh
#!/bin/bash
TEXT="$1"
API_KEY=$(cat ~/GinieSystem/Vault/keys/elevenlabs.key)
VOICE_ID="EXAVITQu4vr4xnSDxMaL"
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
  -H "xi-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "'"$TEXT"'", "voice_settings": {"stability": 0.5,"similarity_boost": 0.75}}' \
  --output /tmp/ginie_talk.mp3
afplay /tmp/ginie_talk.mp3
EOV

# 🛡️ g.temp_mic_pause.sh
cat << 'EOT' > ~/GinieSystem/Scripts/g.temp_mic_pause.sh
#!/bin/bash
launchctl unload ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null
bash ~/GinieSystem/Scripts/g.voice_reply.sh "$1"
sleep 1
launchctl load ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null
EOT

# 🔁 g.talk_loop.sh
cat << 'EOLOOP' > ~/GinieSystem/Scripts/g.talk_loop.sh
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
EOLOOP

chmod +x ~/GinieSystem/Scripts/g.voice_reply.sh
chmod +x ~/GinieSystem/Scripts/g.temp_mic_pause.sh
chmod +x ~/GinieSystem/Scripts/g.talk_loop.sh

# 🎯 Start loop i bakgrunnen
nohup bash ~/GinieSystem/Scripts/g.talk_loop.sh > ~/GinieSystem/Logs/voice_loop.log 2>&1 &

echo "✅ Ginie samtaleloop kjører nå i bakgrunnen."
echo "📄 Logg: tail -f ~/GinieSystem/Logs/voice_loop.log"
