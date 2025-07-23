# Improved: g.autosave.sh ons. 23 jul. 2025 18.55.41 CEST
##!/bin/bash mkdir -p 
~/GinieSystem/Vault/{greetings,medals} find 
~/Downloads -type f \( -iname "*ginie*.png" 
-o -iname "*medalje*.png" -o -iname 
"*hilsen*.txt" \) -exec mv {} 
~/GinieSystem/Vault/ \;
echo "[Autosave] Kjrt $(date)" >> ~/GinieSystem/Logs/autosave.log
