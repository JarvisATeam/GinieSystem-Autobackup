#!/bin/bash
MSG="🚨 Christer aktiverte FATHER_AI_PROTECTOR – barnebeskyttelse logget."
TIME=$(date +'%Y-%m-%d %H:%M:%S')
REPORT="$HOME/GinieSystem/Logs/father_protector_$(date +%s).log.gpg"
echo "Tid: $TIME" > /tmp/tmp_protect.log
echo "AI-melding: Nødhendelse utløst." >> /tmp/tmp_protect.log
gpg --yes --batch -o "$REPORT" -c /tmp/tmp_protect.log
rm /tmp/tmp_protect.log
if [[ -f ~/.telegram_token && -f ~/.telegram_chat ]]; then
  curl -s -X POST https://api.telegram.org/bot$(cat ~/.telegram_token)/sendMessage \
    -d chat_id=$(cat ~/.telegram_chat) \
    -d text="$MSG"
  echo "📤 Telegram sendt."
else
  echo "⚠️ Telegram ikke konfigurert."
fi
