#!/bin/bash
APP_DIR="$HOME/GinieSystem/SuperAppFactory/Builds/treningsapp"
TEST_INPUTS=~/GinieSystem/Verifier/Tests/inputs.txt
FAIL_LOG=~/GinieSystem/Verifier/Logs/fails.log
FIX_DIR=~/GinieSystem/Verifier/Fixes

mkdir -p "$FIX_DIR"
touch "$TEST_INPUTS" "$FAIL_LOG"

# Fyll med 1000 testscenarier om nødvendig
if [[ $(wc -l < "$TEST_INPUTS") -lt 1000 ]]; then
  for i in {1..1000}; do echo "test scenario $i" >> "$TEST_INPUTS"; done
fi

echo "🔁 Starter testloop: 1000 innfallsvinkler"
n=1
while IFS= read -r line; do
  echo "🧪 Test $n: $line"
  result=$(curl -s --fail "file://$APP_DIR/index.html" | grep -i "$line")
  if [[ -z "$result" ]]; then
    echo "❌ Feil på test $n: $line" >> "$FAIL_LOG"
    
    # Send prompt til GPT-4 for fiks
    FIX=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $(cat ~/GinieSystem/Vault/keys/openai.key)" \
      -H "Content-Type: application/json" \
      -d '{
        "model": "gpt-4",
        "messages": [{"role":"user", "content":"Denne appen feiler på test: '"$line"'. Forsøk å rette index.html:\n'"$(cat $APP_DIR/index.html | head -n 100)"'"}]
      }' | jq -r '.choices[0].message.content')

    echo "$FIX" > "$FIX_DIR/fix_$n.html"
    cp "$FIX_DIR/fix_$n.html" "$APP_DIR/index.html"
    echo "🔧 GPT-fiks brukt på test $n"
  fi
  ((n++))
  sleep 0.2
done < "$TEST_INPUTS"

echo "✅ Fullført testloop. Feil logget i $FAIL_LOG"
