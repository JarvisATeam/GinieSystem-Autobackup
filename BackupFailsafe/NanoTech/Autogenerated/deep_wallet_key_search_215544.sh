# Improved: deep_wallet_key_search.sh ons. 23 jul. 2025 21.55.44 CEST
##!/bin/bash

echo "🔎 Starter dyp skanning etter Binance-wallet og nøkler på Mac..."

SEARCH_TERMS="Binance-wallet|wallet|Binance|private key|privat nøkkel|seed phrase"
SEARCH_LOCATIONS=(
    "$HOME/Library/Containers/com.apple.Notes/Data/Library"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Library/Messages"
    "$HOME/Downloads"
    "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
)

MATCH_COUNT=0

for LOCATION in "${SEARCH_LOCATIONS[@]}"; do
    echo "📁 Søker i: $LOCATION"
    if [ -d "$LOCATION" ]; then
        MATCHES=$(grep -rilE "$SEARCH_TERMS" "$LOCATION" 2>/dev/null)
        if [ ! -z "$MATCHES" ]; then
            while IFS= read -r match; do
                echo "✅ Match funnet: $match"
                MATCH_COUNT=$((MATCH_COUNT + 1))
            done <<< "$MATCHES"
        else
            echo "❌ Ingen treff i $LOCATION"
        fi
    else
        echo "⚠️ Fant ikke katalogen: $LOCATION"
    fi
done

echo "🔍 Totalt antall treff funnet: $MATCH_COUNT"
