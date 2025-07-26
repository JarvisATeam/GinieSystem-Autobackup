#!/bin/bash

LOGFIL=~/GinieSystem/Logs/jarvis_team_status.log
INDEX_QUERY_SCRIPT=~/JarvisATeam/ai-agents/core/test_index_query.py
REPOLIST=("frontend-portal" "backend-api" "ai-agents" "docs" "infra" "ci-cd")

mkdir -p ~/GinieSystem/Logs

echo "🔁 Starter permanent JarvisTeam overvåkning..." >> "$LOGFIL"

while true; do
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "🕒 [$TIMESTAMP] STATUSSJEKK STARTER" >> "$LOGFIL"

  for repo in "${REPOLIST[@]}"; do
    echo "📁 Repo: $repo" >> "$LOGFIL"
    if [ -d "$HOME/JarvisATeam/$repo" ]; then
      cd "$HOME/JarvisATeam/$repo" || continue
      echo "✅ Funnet. Sist commit:" >> "$LOGFIL"
      git log -1 --oneline >> "$LOGFIL"
    else
      echo "❌ Mangler repo: $repo" >> "$LOGFIL"
    fi
    echo "-----------------------------" >> "$LOGFIL"
  done

  echo "🐳 Docker containere:" >> "$LOGFIL"
  docker ps --format "📦 {{.Names}} - {{.Status}}" >> "$LOGFIL"
  echo "-----------------------------" >> "$LOGFIL"

  echo "📨 RabbitMQ køer:" >> "$LOGFIL"
  docker exec -i rabbitmq rabbitmqctl list_queues 2>>"$LOGFIL" >> "$LOGFIL"
  echo "-----------------------------" >> "$LOGFIL"

  echo "🧠 GPT DeepIndex-agent status:" >> "$LOGFIL"
  curl -s http://localhost:8001/status >> "$LOGFIL"
  echo "" >> "$LOGFIL"
  echo "-----------------------------" >> "$LOGFIL"

  echo "🔍 Eksempel GPT-oppslag (auth):" >> "$LOGFIL"
  python3 "$INDEX_QUERY_SCRIPT" "Hvordan fungerer auth i backend?" >> "$LOGFIL" 2>>"$LOGFIL"
  echo "-----------------------------" >> "$LOGFIL"

  echo "🔃 Siste CI-kjøring (backend-api):" >> "$LOGFIL"
  gh run list --limit 1 --repo JarvisATeam/backend-api >> "$LOGFIL" 2>>"$LOGFIL"
  echo "-----------------------------" >> "$LOGFIL"

  echo "📂 GPT-indexfiler:" >> "$LOGFIL"
  ls ~/JarvisATeam/ai-agents/core/index_data/ >> "$LOGFIL"
  echo "-----------------------------" >> "$LOGFIL"

  echo "🧠 Aktive agenter:" >> "$LOGFIL"
  ps aux | grep agent | grep -v grep >> "$LOGFIL"
  echo "=============================" >> "$LOGFIL"

  sleep 300 # Sjekk hvert 5. minutt
done

