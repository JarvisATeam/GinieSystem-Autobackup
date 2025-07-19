#!/bin/bash
PROFILE="${1:-christer}"
echo "🔁 Siste treningsøkt for $PROFILE:"
tail -n 1 "$HOME/GinieSystem/Training/profiles/$PROFILE.train"
