#!/bin/bash
clear
echo "🧠 Velkommen til GinieTrainApp"
echo "-----------------------------"
echo "1) Start ny treningsøkt"
echo "2) Vis progresjon"
echo "3) Endre bruker"
echo "4) Avslutt"
read -p "Velg: " CHOICE
PROFILE_FILE="$HOME/GinieSystem/TrainApp/active_profile"
if [ ! -f "$PROFILE_FILE" ]; then bash "$HOME/GinieSystem/TrainApp/g.profiles.sh"; fi
PROFILE=$(cat "$PROFILE_FILE")
case $CHOICE in
  1) bash "$HOME/GinieSystem/TrainApp/g.log_train.sh" "$PROFILE" ;;
  2) bash "$HOME/GinieSystem/TrainApp/g.muscle_ai.sh" "$PROFILE" ;;
  3) bash "$HOME/GinieSystem/TrainApp/g.profiles.sh" ;;
  4) echo "Avslutter..."; exit 0 ;;
  *) echo "Ugyldig valg" ;;
esac

