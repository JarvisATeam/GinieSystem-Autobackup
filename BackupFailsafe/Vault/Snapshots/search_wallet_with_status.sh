#!/bin/bash
echo "🔎 Starter søk etter Binance-wallet på iCloud..."

WALLET="Binance-wallet"
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

MATCHES=$(find "$ICLOUD_DIR" -type f -iname "*${WALLET}*")
TOTAL_FILES=$(echo "$MATCHES" | wc -l | tr -d '[:space:]')

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "❌ Fant ingen filer med navn: ${WALLET}"
else
    echo "✅ Fant totalt $TOTAL_FILES filer med navn: ${WALLET}"
    COUNT=0
    echo "$MATCHES" | while read -r file; do
        COUNT=$((COUNT + 1))
        if [ $((COUNT % 10)) -eq 0 ] || [ "$COUNT" -eq "$TOTAL_FILES" ]; then
            PERCENT=$((COUNT * 100 / TOTAL_FILES))
            echo "📁 $COUNT/$TOTAL_FILES ($PERCENT%) – $file"
        fi
    done
fi
