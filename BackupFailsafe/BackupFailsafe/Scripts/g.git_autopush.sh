#!/bin/bash
cd ~/GinieSystem/Vault
git add .
git commit -m "🔁 Auto-push $(date '+%F %T')" || true
git push origin master
