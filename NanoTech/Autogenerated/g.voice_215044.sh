# Improved: g.voice.sh ons. 23 jul. 2025 21.50.44 CEST
##!/bin/bash
echo "🎙️ Voice activated. Si 'warp', 'status', 'stopp', eller 'loop'..."
while true; do
  arecord -d 3 -f cd -t wav -r 16000 -q - | ffmpeg -i - -ar 16000 -ac 1 -f wav -y /tmp/voice.wav &>/dev/null
  CMD=$(whisper /tmp/voice.wav --model base --language no --output_format txt --fp16 False | tail -n 1 | tr '[:upper:]' '[:lower:]')
  echo "🧠 Du sa: $CMD"
  case "$CMD" in
    *warp*) bash ~/GinieSystem/Core/gforge_warp.sh ;;
    *status*) open ~/GinieSystem/Vault/vault_status.html ;;
    *loop*) bash ~/GinieSystem/Scripts/g.force.loop.sh ;;
    *stopp*) pkill -f force.loop; pkill -f g.voice.sh; exit ;;
  esac
done
