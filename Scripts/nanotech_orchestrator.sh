#!/usr/bin/env bash
set -euo pipefail
GS_HOME="${GS_HOME:-$HOME/GinieSystem}"
SCRIPTS_DIR="$GS_HOME/Scripts"
MEM_DIR="$GS_HOME/Memory"
DB="$MEM_DIR/gs_memory.db"
DEMO_BASE="${DEMO_BASE:-$GS_HOME/NanotechAutonomousLoop}"
THOR_QUEUE="${THOR_QUEUE:-$DEMO_BASE/Thor/queue}"

cmd="${1:-}"

case "$cmd" in
  ingest)
    "$SCRIPTS_DIR/memory_ingest.sh"
    ;;
  primer)
    mission_yaml="${2:-}"
    if [ -z "$mission_yaml" ] || [ ! -f "$mission_yaml" ]; then
      echo "Bruk: nanotech_orchestrator.sh primer <path/to/mission.yaml>" >&2
      exit 1
    fi
    mid="UNKNOWN"
    [[ "$(basename "$mission_yaml")" =~ mission_(.+)\.(yml|yaml)$ ]] && mid="${BASH_REMATCH[1]}"
    OUT="$THOR_QUEUE/PRIMER_${mid}.md"
    query="$(printf 'mission:%s %s' "$mid" "$(tr '\n' ' ' < "$mission_yaml")")"
    "$SCRIPTS_DIR/deepsearch_query.sh" "$OUT" "$query"
    echo "▶️  Primer generert for $mid → $OUT"
    ;;
  reflect)
    mid="${2:-}"
    proj="${3:-}"
    if [ -z "$mid" ] || [ -z "$proj" ] || [ ! -d "$proj" ]; then
      echo "Bruk: nanotech_orchestrator.sh reflect <MISSION_ID> <PROJECT_DIR>" >&2
      exit 1
    fi
    "$SCRIPTS_DIR/reflexion_note.sh" "$mid" "$proj"
    ;;
  install_launchd)
    LAUNCH_DIR="$HOME/Library/LaunchAgents"
    mkdir -p "$LAUNCH_DIR"

    # Ingest hver time
    cat > "$LAUNCH_DIR/com.ginie.memory.ingest.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.ginie.memory.ingest</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string><string>-lc</string>
    <string>$SCRIPTS_DIR/memory_ingest.sh</string>
  </array>
  <key>StartInterval</key><integer>3600</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$MEM_DIR/ingest_stdout.log</string>
  <key>StandardErrorPath</key><string>$MEM_DIR/ingest_stderr.log</string>
</dict></plist>
PL

    launchctl unload "$LAUNCH_DIR/com.ginie.memory.ingest.plist" >/dev/null 2>&1 || true
    launchctl load "$LAUNCH_DIR/com.ginie.memory.ingest.plist"

    echo "✅ launchd: com.ginie.memory.ingest aktivert"

    ;;
  status)
    if command -v sqlite3 >/dev/null 2>&1; then
      echo "— MINNE STATUS —"
      echo "SELECT count(*) AS artifacts FROM artifacts;" | sqlite3 "$DB"
      echo "SELECT count(*) AS reflections FROM reflections;" | sqlite3 "$DB"
    else
      echo "sqlite3 mangler"
    fi
    ;;
  *)
    cat <<USAGE
Bruk:
  nanotech_orchestrator.sh ingest
  nanotech_orchestrator.sh primer <path/to/mission.yaml>
  nanotech_orchestrator.sh reflect <MISSION_ID> <PROJECT_DIR>
  nanotech_orchestrator.sh install_launchd
  nanotech_orchestrator.sh status
USAGE
    ;;
esac
