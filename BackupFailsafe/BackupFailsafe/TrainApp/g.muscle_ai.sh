#!/bin/bash
PROFILE=$1
LOGFILE="$HOME/GinieSystem/Profiles/$PROFILE/train_log.md"
echo "📈 Progresjon for $PROFILE"
grep -i "kg" "$LOGFILE" | awk -F'–' '{print $2 " - " $3}' | sort | uniq -c | sort -nr | head -n 10

