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
