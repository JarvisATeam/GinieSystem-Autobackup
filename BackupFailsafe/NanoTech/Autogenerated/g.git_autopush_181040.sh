# Improved: g.git_autopush.sh ons. 23 jul. 2025 18.10.40 CEST
##!/bin/bash
cd ~/GinieSystem/Vault
git add .
git commit -m "🔁 Auto-push $(date '+%F %T')" || true
git push origin master
