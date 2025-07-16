#!/bin/bash
echo "🛠️ Gjenoppretter Earn-modulen..."

bash ~/GinieSystem/Earn/earn_mission.sh || echo "earn_mission.sh mangler"
bash ~/GinieSystem/Earn/stripe_push.sh || echo "stripe_push.sh mangler"
bash ~/GinieSystem/Earn/reinvest.sh || echo "reinvest.sh mangler"
bash ~/GinieSystem/Earn/learning_loop.sh || echo "learning_loop.sh mangler"
bash ~/GinieSystem/Earn/vault_distributor.sh || echo "vault_distributor.sh mangler"
bash ~/GinieSystem/Earn/breakthrough_notify.sh || echo "breakthrough_notify.sh mangler"
bash ~/GinieSystem/Earn/fallback_watch.sh || echo "fallback_watch.sh mangler"
