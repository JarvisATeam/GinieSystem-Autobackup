# Improved: gfix_backup.sh ons. 23 jul. 2025 15.10.37 CEST
##!/bin/bash
SCRIPT="$HOME/GinieSystem/Scripts/gforge_prime_backup.sh"
cp "$SCRIPT.bak" "$SCRIPT"
chmod +x "$SCRIPT"
nano "$SCRIPT"
