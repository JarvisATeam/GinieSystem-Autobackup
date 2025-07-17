#!/bin/bash
# GinieSystem Telegram Repair Script

TOKEN_FILE="$HOME/.telegram_token"
CHAT_ID_FILE="$HOME/.telegram_chat"
LOG="$HOME/GinieSystem/Logs/telegram_repair.log"
QUEUE_DIR="$HOME/GinieSystem/Messages/Queue"
NOTIFY_SCRIPT="$HOME/GinieSystem/Agents/telegram_notify.sh"

echo "🚀 Starter Telegram-repair $(date)" | tee -a "$LOG"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "❌ Ingen Telegram-token funnet på $TOKEN_FILE" | tee -a "$LOG"
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE" | tr -d '\r\n')

echo "🔍 Tester API-tilgang..." | tee -a "$LOG"
RESPONSE=$(curl -s "https://api.telegram.org/bot$TOKEN/getMe")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Tilkobling OK – Bot er live!" | tee -a "$LOG"
else
    echo "❌ Telegram API-feil: $RESPONSE" | tee -a "$LOG"
    exit 2
fi

if [ -f "$NOTIFY_SCRIPT" ]; then
    echo "🔁 Starter notify-agent..." | tee -a "$LOG"
    bash "$NOTIFY_SCRIPT" & disown
    echo "📡 Agent kjøres i bakgrunn" | tee -a "$LOG"
else
    echo "❌ notify-script ikke funnet: $NOTIFY_SCRIPT" | tee -a "$LOG"
fi

if [ -f "$CHAT_ID_FILE" ]; then
    CHAT_ID=$(cat "$CHAT_ID_FILE" | tr -d '\r\n')
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        --data-urlencode "text=✅ Telegram-agent er aktiv igjen! $(date '+%H:%M %d.%m.%Y')" >> "$LOG"
    echo "✅ Testbeskjed sendt til chat $CHAT_ID" | tee -a "$LOG"
else
    echo "⚠️ Ingen chat-ID funnet i $CHAT_ID_FILE – testbeskjed hoppet over" | tee -a "$LOG"
fi

if [ -d "$QUEUE_DIR" ]; then
    for file in "$QUEUE_DIR"/*.txt; do
        [ -e "$file" ] || continue
        echo "📤 Sender kø-melding: $file" | tee -a "$LOG"
        TEXT=$(cat "$file")
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$TEXT" >> "$LOG"
        mv "$file" "$file.sent"
        echo "✅ Meldingen sendt og flyttet til .sent" | tee -a "$LOG"
    done
else
    echo "ℹ️ Ingen meldingskø funnet i $QUEUE_DIR" | tee -a "$LOG"
fi

echo "✅ Telegram-repair ferdig kl $(date '+%H:%M:%S')" | tee -a "$LOG"
