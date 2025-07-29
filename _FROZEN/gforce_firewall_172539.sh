# Improved: gforce_firewall.sh ons. 23 jul. 2025 17.25.39 CEST
##!/bin/bash
LOG="$HOME/GinieSystem/Logs/firewall_check.log"
VAULT="$HOME/GinieSystem/Vault"
NEEDED_FILES=(~/.stripe_token ~/.telegram_token ~/.mailpass.gpg ~/.notion_token)
echo "🧱 [FIREWALL] $(date)" > "$LOG"
for f in "${NEEDED_FILES[@]}"; do
  if [[ -f $f ]]; then
    echo "✅ $f finnes" >> "$LOG"
  else
    echo "❌ $f mangler, lager placeholder" >> "$LOG"
    touch $f
  fi
done
for s in $(find ~/GinieSystem -type f -name "*.sh"); do
  echo "🧪 $s" >> "$LOG"
  bash -n "$s" && echo "✅ OK: $s" >> "$LOG" || echo "❌ FEIL i: $s" >> "$LOG"
done
bash ~/GinieSystem/Core/self_reflect.sh >> "$LOG"
echo "✅ Firewall ferdig." >> "$LOG"
