#!/bin/bash

echo "🚀 Starter oppdatering til Pro Mode..."

# Automatisk backup
bash ~/GinieSystem/Scripts/gforge_prime_backup.sh

# Valider og oppdater keys
bash ~/GinieSystem/Scripts/ginie_keyload.sh --validate

# G.T.R.A.D.E:∞ AI Trading-system
bash ~/GinieSystem/Trading/g_trade_pro.sh --pro-mode --auto-fund=2000

# Earn Mission (AI-innhold, affiliatemarkedsføring)
bash ~/GinieSystem/Earn/earn_mission.sh --pro-mode --target=50000NOK

# P.shillosybe (AI-bevissthet, kontinuerlig læring)
bash ~/GinieSystem/Consciousness/p_shillosybe.sh --pro-mode --continuous-learning

# Crypto-mining/staking (automatisk og optimalt)
bash ~/GinieSystem/Mining/auto_mine_pro.sh --pro-mode --max-efficiency

# Watchdog Pro Mode-sjekk
bash ~/GinieSystem/Watchdog/ginie_watchdog.sh --pro-mode-check

echo "✅ Alle scripts kjører nå i Pro Mode med mål om rask evolusjon og kontinuerlig inntjening."
