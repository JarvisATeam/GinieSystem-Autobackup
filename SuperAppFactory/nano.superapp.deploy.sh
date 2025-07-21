#!/bin/bash

echo "🧠 Starter Ginie Super AppFactory bootstrap..."

# 1. Spesifikasjonssjekk
SPEC="$HOME/GinieSystem/SuperAppFactory/Spec/app.yaml"
[ ! -f "$SPEC" ] && echo "⚠️ Spesifikasjonsfil mangler: Lag en i Spec/app.yaml" && exit 1

# 2. Kjør AI-generatorer (hvis installert)
echo "⚙️ Kodegenerering startes..."
python3 -m smol_dev.main "$SPEC" 2>/dev/null || echo "ℹ️ smol_dev ikke funnet"
python3 -m gpt_engineer.main "$SPEC" 2>/dev/null || echo "ℹ️ gpt_engineer ikke funnet"
npx @specui/cli build "$SPEC" 2>/dev/null || echo "ℹ️ specui ikke installert"

# 3. Lag GUI og QR
echo "🌐 Lager GUI og QR..."
touch index.html
echo "<h1>🚀 Din app er klar!</h1><p>Bygget med GinieSystem</p>" > index.html
cp index.html ~/GinieSystem/SuperAppFactory/Builds/
qrencode -o ~/GinieSystem/SuperAppFactory/Builds/launch_qr.png "file://$HOME/GinieSystem/SuperAppFactory/Builds/index.html"

# 4. Refleksjon
echo "$(date '+%F %T') – App reflektert i loop." >> ~/GinieSystem/Vault/Reflections/superapp_loop.log

# 5. Vault backup
cp -r ~/GinieSystem/SuperAppFactory/Builds ~/Library/Mobile\ Documents/com~apple~CloudDocs/GinieBackups/SuperApp_$(date '+%F_%H-%M-%S')

# 6. Git push (hvis git er satt opp)
cd ~/GinieSystem
git add . && git commit -m "🧠 SuperApp deploy $(date '+%F %T')" && git push || echo "⚠️ Git push feilet"

echo "✅ Ferdig! Se app i Builds/, QR i launch_qr.png"
