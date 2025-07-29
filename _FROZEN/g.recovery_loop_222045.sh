# Improved: g.recovery_loop.sh ons. 23 jul. 2025 22.20.45 CEST
##!/bin/bash
L=~/GinieSystem/Vault/Recovered/.map-recover.log
mkdir -p ~/GinieSystem/Vault/Recovered
echo "♻️ Recovery-loop: $(date)" >> "$L"
find ~/Library/Mobile\\ Documents/ -type f > ~/GinieSystem/Vault/Recovered/index_iclouddrive.txt 2>/dev/null
crontab -l > ~/GinieSystem/Vault/Recovered/cron_active.txt 2>/dev/null
launchctl list > ~/GinieSystem/Vault/Recovered/launchd_active.txt 2>/dev/null
find ~/GinieSystem -type f -not -path "*Vault*" > ~/GinieSystem/Vault/Recovered/untracked_ginie_files.txt
echo "✅ Recovery done: $(date)" >> "$L"
