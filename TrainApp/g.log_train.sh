#!/bin/bash
PROFILE=$1
LOGFILE="$HOME/GinieSystem/Profiles/$PROFILE/train_log.md"
read -p "Muskelgruppe: " MUSCLE
read -p "Øvelse: " EXERCISE
read -p "Vekt (kg): " KG
read -p "Reps: " REPS
read -p "Kommentar/emojier: " NOTE
DATE=$(date '+%Y-%m-%d %H:%M')
echo "- [$DATE] $MUSCLE – $EXERCISE – ${KG}kg x $REPS – $NOTE" >> "$LOGFILE"
echo "✅ Økt lagret"
cd "$HOME/GinieSystem"
git add .
git commit -m "📌 Ny treningsøkt: $PROFILE – $MUSCLE – $EXERCISE"
git push

