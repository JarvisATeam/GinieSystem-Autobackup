# Improved: g.update_all.sh ons. 23 jul. 2025 23.25.46 CEST
##!/bin/bash

LOG=~/GinieSystem/Logs/update_all.log
mkdir -p "$(dirname "$LOG")"
echo "📦 Oppdatering startet: $(date '+%F %T')" | tee -a "$LOG"

## 1. Brew
if command -v brew &>/dev/null; then
    echo "🍺 Oppdaterer brew..." | tee -a "$LOG"
    brew update >> "$LOG" 2>&1
    brew upgrade >> "$LOG" 2>&1
else
    echo "🔧 Installerer Homebrew..." | tee -a "$LOG"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

## 2. Node & npm
if ! command -v node &>/dev/null; then
    echo "🧱 Installerer Node.js..." | tee -a "$LOG"
    brew install node >> "$LOG" 2>&1
else
    echo "📦 Oppdaterer npm..." | tee -a "$LOG"
    npm install -g npm >> "$LOG" 2>&1
fi

## 3. Python & pip
if ! command -v python3 &>/dev/null; then
    echo "🐍 Installerer Python..." | tee -a "$LOG"
    brew install python >> "$LOG" 2>&1
fi
echo "📦 Oppdaterer pip..." | tee -a "$LOG"
pip3 install --upgrade pip setuptools wheel >> "$LOG" 2>&1

## 4. fswatch
brew list fswatch &>/dev/null || brew install fswatch >> "$LOG" 2>&1

## 5. Git repo-push
echo "🚀 Pusher alle kjente prosjekter..." | tee -a "$LOG"
for dir in ~/GinieSystem ~/GinieSystem/ChildApp ~/GinieSystem/TrainApp; do
    if [ -d "$dir/.git" ]; then
        cd "$dir" || continue
        git add . >> "$LOG"
        git commit -m "🔄 Auto-update $(date '+%F %T')" >> "$LOG" 2>&1
        git push >> "$LOG" 2>&1
        echo "✅ Push: $dir" | tee -a "$LOG"
    fi
done

## 6. Telegram notify (valgfritt)
TOKEN=$(cat ~/.telegram_token 2>/dev/null)
CHAT=$(cat ~/.telegram_chat 2>/dev/null)
if [[ -n "$TOKEN" && -n "$CHAT" ]]; then
  curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage \
      -d chat_id=$CHAT \
      -d text="✅ Oppdatering fullført: $(date '+%F %T')" >> "$LOG"
fi

echo "✅ Ferdig: $(date '+%F %T')" | tee -a "$LOG"
