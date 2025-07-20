#!/bin/bash
for i in {1..100}; do
  echo "$(date '+%F %T') – Trip $i: Hva lærer jeg nå..." >> ~/GinieSystem/Vault/Reflections/loop_trip.log
  sleep 1
done
