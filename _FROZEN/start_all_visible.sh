#!/bin/bash
echo "🔁 Starter evolusjonsloop"
bash ~/GinieSystem/Scripts/g.force.loop.sh > ~/GinieSystem/Logs/force_loop.log 2>&1 &

echo "🛰️ Starter warp-server"
python3 ~/GinieSystem/Scripts/ginie_warp_server.py > ~/GinieSystem/Logs/warp_server.log 2>&1 &

echo "📡 Starter dashboard-server"
cd ~/GinieSystem/Vault && http-server -p 8000 > ~/GinieSystem/Logs/dashboard_server.log 2>&1 &
