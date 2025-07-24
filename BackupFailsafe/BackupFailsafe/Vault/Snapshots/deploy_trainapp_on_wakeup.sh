#!/bin/bash

echo "🌅 God morgen, Christer – deployer Ginie Training App v1.0..."

APP_DIR="$HOME/GinieSystem/TrainApp"
cd "$HOME/GinieSystem" || exit

if [ ! -d "$APP_DIR" ]; then
  echo "❌ TrainApp mangler! Oppretter..."
  mkdir -p "$APP_DIR/profiles/children"
fi

# 🏋️ Treningsscript
cat << 'EOS' > "$APP_DIR/g.train.sh"
#!/bin/bash
echo "🏋️ Ginie Training App v1.0"
echo "📅 Dato: \$(date '+%Y-%m-%d')"
read -p "Øvelse (f.eks. Knebøy): " exercise
read -p "Vekt (kg): " weight
read -p "Reps: " reps
read -p "Kommentar: " notes
echo "\$(date '+%Y-%m-%d %H:%M:%S'),\$exercise,\$weight,\$reps,\"\$notes\"" >> "$APP_DIR/train_log.csv"
echo "✅ Lagret. Kjør 'g.log_train.sh' for oversikt."
EOS

# 📊 Loggvisning
cat << 'EOS' > "$APP_DIR/g.log_train.sh"
#!/bin/bash
echo "📈 Treningslogg:"
column -s, -t < "$APP_DIR/train_log.csv" | less
EOS

# 🤖 AI-analyse
cat << 'EOS' > "$APP_DIR/g.muscle_ai.sh"
#!/bin/bash
echo "🔍 Analyserer progresjon..."
awk -F, '{print \$2,\$3,\$4}' "$APP_DIR/train_log.csv" | sort | uniq -c | sort -nr | head
EOS

# 💊 Kosttilskudd
cat << 'EOS' > "$APP_DIR/supplements.json"
{
  "BCAA": "5g før trening",
  "Omega-3": "1g morgen",
  "Vitamin D": "20ug daglig",
  "Kreatin": "5g etter økt"
}
EOS

# 👶 Barnemotivasjon
for kid in perny sol silk; do
  echo "{\"navn\":\"$kid\",\"motivasjon\":\"Du er en del av grunnen til at pappa trener 💪\"}" > "$APP_DIR/profiles/children/$kid.json"
done

chmod +x "$APP_DIR/"*.sh

# 🔐 Git push
git add TrainApp/
git commit -m "🧠 Auto-deploy: Ginie Training App v1.0 – full fysisk installasjon"
git push origin main

# 📜 Logg tidspunkt
echo "Deploy kjørt: \$(date '+%Y-%m-%d %H:%M:%S')" >> "$HOME/GinieSystem/Logs/trainapp_push.log"
echo "✅ Deploy fullført!"
