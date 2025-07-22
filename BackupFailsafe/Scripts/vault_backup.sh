#!/bin/bash
DST="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieBackups/Mac_$(date '+%F_%H-%M-%S')"
mkdir -p "$DST"
cp -R ~/GinieSystem "$DST"
echo "$(date '+%F %T') – Vault backup lagret til $DST" >> ~/GinieSystem/Vault/Reflections/backup.log
