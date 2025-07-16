#!/bin/bash
SCRIPT="$HOME/GinieSystem/Scripts/gforge_prime_backup.sh"
cp "$SCRIPT.bak" "$SCRIPT"
chmod +x "$SCRIPT"
nano "$SCRIPT"
