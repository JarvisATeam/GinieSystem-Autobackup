#!/bin/bash echo " [GINIEAUTOMAGIC] Starter 
full installasjon og kjring..." mkdir -p 
~/GinieSystem/Earn/Logs echo "[1/6] Lager 
stripe_push.sh..." cat << 'EOF' > 
~/GinieSystem/Earn/stripe_push.sh 
#!/bin/bash echo " Viser Stripe QR-kode..." 
open 
"https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://linktr.ee/Achildsecho" 
EOF echo "[2/6] Lager reinvest.sh..." cat << 
'EOF' > ~/GinieSystem/Earn/reinvest.sh 
#!/bin/bash echo " Reinvesterer og fordeler 
overskudd..." echo "[OK] 1% til Sol | 1% til 
Silke | 0.1% til Pernille | 10% buffer | 50% 
reinvestert" >> 
~/GinieSystem/Earn/Logs/vault_dist.log EOF 
echo "[3/6] Lager learning_loop.sh..." cat 
<< 'EOF' > 
~/GinieSystem/Earn/learning_loop.sh 
#!/bin/bash echo " Lrer fra daglig loop og 
forbedrer modell..." echo "[LOOP] $(date): 
Lrt 1 nytt grep / forbedret 
inntjeningsstrategi." >> 
~/GinieSystem/Earn/Logs/earn_daily.log EOF 
echo "[4/6] Lager push_linktree.sh..." cat 
<< 'EOF' > 
~/GinieSystem/Earn/push_linktree.sh 
#!/bin/bash open 
https://linktr.ee/Achildsecho EOF echo 
"[5/6] Lager earn_mission.sh..." cat << 
'EOF' > ~/GinieSystem/Earn/earn_mission.sh 
#!/bin/bash echo " Starter earn-mission for 
i dag..." bash 
~/GinieSystem/Earn/stripe_push.sh bash 
~/GinieSystem/Earn/reinvest.sh bash 
~/GinieSystem/Earn/learning_loop.sh bash 
~/GinieSystem/Earn/push_linktree.sh EOF 
chmod +x ~/GinieSystem/Earn/*.sh echo "[6/6] 
Starter earn_mission.sh..." bash 
~/GinieSystem/Earn/earn_mission.sh
