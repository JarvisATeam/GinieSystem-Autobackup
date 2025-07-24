#!/bin/bash
TEXT="$1"
[[ -z "$TEXT" || "$TEXT" == "null" || "$TEXT" == "0" ]] && exit 0
VOICE_ID="EXAVITQu4vr4xnSDxMaL"
KEY=$(cat ~/GinieSystem/Vault/keys/elevenlabs.key)
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
 -H "xi-api-key: $KEY" -H "Content-Type: application/json" \
 -d '{"text": "'"$TEXT"'", "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}}' \
 --output /tmp/ginie.mp3 && afplay /tmp/ginie.mp3
