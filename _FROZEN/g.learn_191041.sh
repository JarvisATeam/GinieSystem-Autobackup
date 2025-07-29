# Improved: g.learn.sh ons. 23 jul. 2025 19.10.41 CEST
##!/bin/bash
BOOK="$1"
VAULT="$HOME/GinieSystem/Vault/Knowledge/raw/$BOOK"

if [[ ! -f "$VAULT" ]]; then
  echo "❌ Fant ikke $BOOK"
  exit 1
fi

echo "📖 Leser og lærer fra $BOOK ..."
tail -n +20 "$VAULT" | head -n 1000 > /tmp/_book_excerpt.txt
python3 -c "
from openai import OpenAI
client = OpenAI()
with open('/tmp/_book_excerpt.txt') as f:
    txt = f.read()
print(client.chat.completions.create(
    model='gpt-4',
    messages=[{'role': 'user', 'content': f'Gi et sammendrag og de viktigste innsiktene fra dette:\n{txt}'}]
).choices[0].message.content)
"
