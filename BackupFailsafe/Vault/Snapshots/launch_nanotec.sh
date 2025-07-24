#!/bin/bash

LOG="$HOME/GinieSystem/Logs/nanotec_launch.log"
mkdir -p "$(dirname "$LOG")"

echo "📦 Starter NanoTec $(date)" | tee -a "$LOG"

# 🔐 Aktiver venv først
source ~/GinieSystem/env/bin/activate

# 🧠 Kjør NanoTec med korrekt python
nohup python ~/nanotec_yes_to_all.sh > ~/GinieSystem/Logs/nanotec_yes.out 2>&1 & disown

echo "✅ NanoTec kjøres nå i bakgrunnen" | tee -a "$LOG"
echo "📄 Se logg med: tail -f ~/GinieSystem/Logs/nanotec_yes.out"
