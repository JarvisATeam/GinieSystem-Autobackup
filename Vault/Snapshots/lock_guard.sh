#!/bin/bash
LOCK=~/GinieSystem/Vault/Proof/.lockfile
if [ -f "$LOCK" ]; then
  echo "⚠️ Lås funnet $(date) – rebooter..." >> ~/GinieSystem/Vault/Logs/lock_guard.log
  rm -f "$LOCK"
  bash ~/GinieSystem/Scripts/launch_nanotec.sh & disown
else
  echo "✅ OK $(date)" >> ~/GinieSystem/Vault/Logs/lock_guard.log
fi
