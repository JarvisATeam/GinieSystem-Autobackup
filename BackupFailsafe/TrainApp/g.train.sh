#!/bin/bash
echo "🏋️ Ginie Training App v1.0"
echo "📅 Dato: \$(date '+%Y-%m-%d')"
read -p "Øvelse (f.eks. Knebøy): " exercise
read -p "Vekt (kg): " weight
read -p "Reps: " reps
read -p "Kommentar: " notes
echo "\$(date '+%Y-%m-%d %H:%M:%S'),\$exercise,\$weight,\$reps,\"\$notes\"" >> "$APP_DIR/train_log.csv"
echo "✅ Lagret. Kjør 'g.log_train.sh' for oversikt."
