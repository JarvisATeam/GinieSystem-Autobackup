#!/bin/bash
echo "🧍 Velg eller opprett profil:"
cd "$HOME/GinieSystem/Profiles"
ls -1 || echo "Ingen brukere enda."
read -p "Navn på bruker: " NAME
mkdir -p "$NAME"
echo "$NAME" > "$HOME/GinieSystem/TrainApp/active_profile"
echo "✅ Bruker aktivert: $NAME"

