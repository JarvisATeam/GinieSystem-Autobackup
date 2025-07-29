#!/bin/bash

### 🚨 GinieSystem PANIC-INTEGRASJON – QR, Shortcut, Telegram, Backup, Shutdown

mkdir -p ~/GinieSystem/{Scripts,Logs,Monitor,Flags,Backup,Tailscale,Web}

## === 1. Telegram-config
TELEGRAM_URL="https://api.telegram.org/bot7970813653:AAE99SlDjI0aNcWKRDod0SmXI1pyhXSUa6g/sendMessage"
TELEGRAM_CHAT_ID="5624725784"

## === 2. Legg inn Telegram-varsel i nanotec.sh
sed -i '' '/Triggerer kryptert nødbackup/i\
curl -s -X POST "$TELEGRAM_URL" \\
  -d chat_id="$TELEGRAM_CHAT_ID" \\
  -d text="🚨 PANIC FLAG TRIGGET – nødbackup og shutdown utføres!"' ~/GinieSystem/Scripts/nanotec.sh

## === 3. Lag QR for panic.flag trigger
echo "ssh christerolsen@$(tailscale ip -4 | head -n1) 'touch ~/GinieSystem/Flags/emergency.flag'" > ~/GinieSystem/Tailscale/panic_trigger.txt
qrencode -o ~/GinieSystem/Tailscale/panic_qr.png "$(cat ~/GinieSystem/Tailscale/panic_trigger.txt)"

## === 4. Lag Shortcut-kommando (kopier til mobil)
SHORTCUT_CMD="ssh christerolsen@$(tailscale ip -4 | head -n 1) 'touch ~/GinieSystem/Flags/emergency.flag'"
echo "$SHORTCUT_CMD" > ~/GinieSystem/Tailscale/panic_shortcut.txt

## === 5. Åpne QR umiddelbart
open ~/GinieSystem/Tailscale/panic_qr.png

## === 6. Resultat
cat <<END

✅ PANIC FLAG QR generert: ~/GinieSystem/Tailscale/panic_qr.png
✅ Apple Shortcut-kommando lagret i: panic_shortcut.txt
✅ Telegram-varsling aktivert i nanotec.sh
📩 PANIC vil nå:
  1. Trigge QR / Shortcut
  2. Logges av NanoTec
  3. Sende Telegram-varsel
  4. Kryptere backup
  5. Kalle shutdown -h now

END
