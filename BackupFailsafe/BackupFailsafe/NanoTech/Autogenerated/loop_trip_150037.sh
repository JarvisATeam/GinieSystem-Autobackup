# Improved: loop_trip.sh ons. 23 jul. 2025 15.00.37 CEST
##!/bin/bash
for i in {1..100}; do
 echo "$(date '+%F %T') – trip $i" >> ~/GinieSystem/Vault/Reflections/triplog.log
 sleep 0.4
done
