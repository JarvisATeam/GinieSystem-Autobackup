#!/bin/bash
PROFILE="$HOME/GinieSystem/Health/Profiles/training_ai_profile.json" 
if [ ! -f "$PROFILE" ]; then
  echo " Fant ikke AI-profilen: $PROFILE" 
  exit 1
fi 

FOKUS=$(jq -r '.fokus' "$PROFILE") 
MUSKEL=$(jq -r '.muskel' "$PROFILE") 
OVELSE=$(jq -r '.ovelse' "$PROFILE") 
VARIASJON=$(jq -r '.variasjon' "$PROFILE") 
MENGDE=$(jq -r '.mengde' "$PROFILE") echo " 
Forrige kt: $FOKUS $MUSKEL $OVELSE 
($VARIASJON)" echo " Belastning: $MENGDE"
echo " Forslag neste kt: +2.5 kg eller +12 reps hvis du fullfrte alt "
