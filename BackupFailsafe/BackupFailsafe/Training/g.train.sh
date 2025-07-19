#!/bin/bash
PROFILE="${1:-christer}"
DATE=$(date '+%F %T')
LOG="$HOME/GinieSystem/Training/logs/train_log.txt"

echo "🧠 Velkommen til GinieTrain [$PROFILE]"
echo "📅 Dato: $DATE"
read -p "➡️ Muskelgruppe: " muscle
read -p "➡️ Øvelse: " exercise
read -p "➡️ Vekt (kg): " weight
read -p "➡️ Reps: " reps
read -p "➡️ Antall sett: " sets
read -p "➡️ Form (1-10): " form

echo "$DATE | $PROFILE | $muscle | $exercise | ${weight}kg | $reps reps x $sets sett | Form: $form" | tee -a "$LOG"
echo "$DATE;$muscle;$exercise;$weight;$reps;$sets;$form" >> "$HOME/GinieSystem/Training/profiles/$PROFILE.train"

if [[ "$form" -lt 5 ]]; then
  echo "🤖 AI: Ta en lettere økt neste gang eller hvil lenger."
elif [[ "$form" -gt 8 ]]; then
  echo "🤖 AI: Vurder å øke vekt eller legge til et ekstra sett neste gang."
else
  echo "🤖 AI: Fortsett på samme nivå og fokuser på teknikk."
fi
