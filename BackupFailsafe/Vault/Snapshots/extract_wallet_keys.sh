#!/bin/bash
echo "🔑 Starter automatisk Wallet Key Extraction..."

# Søkeord
KEYWORDS="wallet|Binance|private key|privat nøkkel|seed phrase"

# Filer å søke i direkte:
TEXT_FILES=(
    "$HOME/Downloads/GINIE_Termius_Sølvfat.txt"
    "$HOME/Downloads/GINIE_MASTER_PROMPT_OVERSIKT.txt"
    "$HOME/Documents/Scripts/backup_gini.sh"
)

echo "📑 Søker i tekstfiler:"
for FILE in "${TEXT_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo "🔎 Sjekker fil: $FILE"
        grep -iE "$KEYWORDS" "$FILE" && echo "✅ Treff funnet i $FILE" || echo "❌ Ingen treff i $FILE"
    else
        echo "⚠️ Filen finnes ikke: $FILE"
    fi
done

# Søker i Meldinger-databasen
CHAT_DB="$HOME/Library/Messages/chat.db"
if [ -f "$CHAT_DB" ]; then
    echo "💬 Søker i meldinger etter Binance-relatert innhold:"
    sqlite3 "$CHAT_DB" "SELECT text FROM message WHERE text LIKE '%wallet%' OR text LIKE '%Binance%' OR text LIKE '%private key%' OR text LIKE '%seed phrase%';" | tee ~/GinieSystem/Logs/extracted_chat_matches.txt
    echo "✅ Meldinger lagret til ~/GinieSystem/Logs/extracted_chat_matches.txt"
else
    echo "⚠️ Meldingsdatabase finnes ikke: $CHAT_DB"
fi

echo "🔑 Wallet Key Extraction ferdig."
