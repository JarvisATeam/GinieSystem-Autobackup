#!/bin/bash

echo "🧠 Initierer balansert AI-spiker-loop..."

# Agents setup
for AGENT in consciousness whisper control trip trader trainer vault qr stealth trigger; do
  mkdir -p ~/GinieSystem/Agents/$AGENT
  echo "📦 Agent '$AGENT' aktivert." >> ~/GinieSystem/Core/spiker_map.txt
done

# Trip refleksjon
cat << 'TRIP' > ~/GinieSystem/Core/Evolve/loop_trip.sh
#!/bin/bash
for i in {1..100}; do
  echo "$(date '+%F %T') – Trip $i: Hva lærer jeg nå..." >> ~/GinieSystem/Vault/Reflections/loop_trip.log
  sleep 1
done
TRIP

chmod +x ~/GinieSystem/Core/Evolve/loop_trip.sh
bash ~/GinieSystem/Core/Evolve/loop_trip.sh &

# Selvrefleksjon
cat << 'SELF' > ~/GinieSystem/Core/Evolve/self_mirror.sh
#!/bin/bash
for i in {1..100}; do
  echo "$(date '+%F %T') – AI reflekterer over seg selv..." >> ~/GinieSystem/Vault/Reflections/mirrorloop.log
  sleep 1
done
SELF

chmod +x ~/GinieSystem/Core/Evolve/self_mirror.sh
bash ~/GinieSystem/Core/Evolve/self_mirror.sh &

# Registrer stemmestyring som triggere
echo "🗣️ Alt du sier tolkes som instruks" > ~/GinieSystem/Triggers/voice_command_map.md

echo "✅ System: Balansert loop aktivert."
