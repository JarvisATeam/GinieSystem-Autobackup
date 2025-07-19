#!/bin/bash
echo "🔍 Starter søk etter Pi passphrase (seed phrase) i Apple Notater..."

NOTES_DIR="$HOME/Library/Group Containers/group.com.apple.notes"

# Søker etter typiske seed phrase-mønstre (12-24 ord)
grep -riE "([a-z]+ ){11,23}[a-z]+" "$NOTES_DIR" | grep -i "pi\|passphrase\|seed" | tee ~/GinieSystem/Logs/pi_passphrase_notes_matches.txt

if [ -s ~/GinieSystem/Logs/pi_passphrase_notes_matches.txt ]; then
    echo "✅ Passphrase funnet! Resultatet er lagret i: ~/GinieSystem/Logs/pi_passphrase_notes_matches.txt"
else
    echo "❌ Ingen Pi passphrase funnet i Apple Notater."
fi
