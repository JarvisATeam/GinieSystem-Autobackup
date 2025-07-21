#!/bin/bash
launchctl unload ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null
bash ~/GinieSystem/Scripts/g.voice_reply.sh "$1"
sleep 1
launchctl load ~/Library/LaunchAgents/com.ginie.mic_shield.plist 2>/dev/null
