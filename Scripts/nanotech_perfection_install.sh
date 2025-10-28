#!/usr/bin/env bash
# 🧠 Nanotech aktivert!
date
set -euo pipefail

# =========================
# NANOTECH "PERFEKSJON" INSTALL — MEMORY + REFLEXION + CBR
# (Resirkulerer >=2 gamle skript når de finnes, samler alt i en robust orkestrator)
# =========================

# ── Konfig (ingen hemmeligheter, kun lokale stier)
GS_HOME="${GS_HOME:-$HOME/GinieSystem}"
SCRIPTS_DIR="$GS_HOME/Scripts"
DOCS_DIR="$GS_HOME/Docs"
MEM_DIR="$GS_HOME/Memory"
ARCHIVE_DIR="$SCRIPTS_DIR/Archive_$(date +%Y%m%d_%H%M%S)"
DEMO_BASE="${DEMO_BASE:-$GS_HOME/NanotechAutonomousLoop}"     # Fra repo-demo eller lokal sandkasse
CORE_DIR="${CORE_DIR:-$DEMO_BASE/Core}"
HEIMDAL_PROJ_A="${HEIMDAL_PROJ_A:-$DEMO_BASE/Heimdal/vault/projects}"
HEIMDAL_PROJ_B="${HEIMDAL_PROJ_B:-$GS_HOME/Heimdal/vault/projects}"   # hvis ekte struktur finnes
THOR_QUEUE="${THOR_QUEUE:-$DEMO_BASE/Thor/queue}"

mkdir -p "$SCRIPTS_DIR" "$DOCS_DIR" "$MEM_DIR" "$ARCHIVE_DIR"

echo "==> Miljø:"
echo "GS_HOME=$GS_HOME"
echo "SCRIPTS_DIR=$SCRIPTS_DIR"
echo "DOCS_DIR=$DOCS_DIR"
echo "MEM_DIR=$MEM_DIR"
echo "DEMO_BASE=$DEMO_BASE"
echo "CORE_DIR=$CORE_DIR"
echo

# ── Avhengigheter: sqlite3 anbefalt, python3/ollama valgfritt
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "⚠️ sqlite3 mangler. Installer via: brew install sqlite3 (mac) / apt-get install sqlite3"
fi

# ── 1) Resirkuler >= 2 gamle skript hvis de finnes (policy: bærekraft)
RECYCLE_CANDIDATES=()
for f in \
  "$SCRIPTS_DIR/nanotech_autonomous_loop_setup.sh" \
  "$SCRIPTS_DIR/nanotech_queue_job.sh" \
  "$SCRIPTS_DIR/nanotech_jobpush.sh" \
  "$HOME/Desktop/nanotech_cashrun.sh" \
  "$HOME/Desktop/nanotech_status.sh" \
  "$SCRIPTS_DIR/nanotech_cashrun.sh" \
  "$SCRIPTS_DIR/nanotech_status.sh"
do
  [ -f "$f" ] && RECYCLE_CANDIDATES+=("$f")
done

if [ "${#RECYCLE_CANDIDATES[@]}" -ge 2 ]; then
  echo "♻️  Resirkulerer ${#RECYCLE_CANDIDATES[@]} eldre skript → $ARCHIVE_DIR"
  for f in "${RECYCLE_CANDIDATES[@]}"; do
    mv "$f" "$ARCHIVE_DIR/"
  done
  echo "✅ Flyttet. (Originaler fjernet i henhold til policy.)"
else
  echo "ℹ️  Fant under 2 gamle skript å resirkulere. Fortsetter uten resirkulering."
fi

# ── 2) MINNE-DATABASEN (FTS5) for DeepSearch (CBR + læring)
DB="$MEM_DIR/gs_memory.db"
SQL_INIT=$(cat <<'SQL'
PRAGMA journal_mode=WAL;
CREATE VIRTUAL TABLE IF NOT EXISTS artifacts USING fts5(
  mission_id UNINDEXED,
  role,
  path UNINDEXED,
  content,
  ts UNINDEXED,
  tokenize='porter'
);
CREATE TABLE IF NOT EXISTS artifact_hash (
  doc_hash TEXT PRIMARY KEY,
  mission_id TEXT,
  path TEXT,
  ts REAL
);
CREATE TABLE IF NOT EXISTS reflections (
  mission_id TEXT,
  note TEXT,
  ts REAL
);
CREATE INDEX IF NOT EXISTS idx_reflections_mid ON reflections(mission_id);
SQL
)
if command -v sqlite3 >/dev/null 2>&1; then
  echo "$SQL_INIT" | sqlite3 "$DB"
  echo "✅ Minne-DB klargjort: $DB"
fi

# ── 3) memory_ingest.sh — ingest Heimdal-prosjekter til FTS5
cat > "$SCRIPTS_DIR/memory_ingest.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
GS_HOME="${GS_HOME:-$HOME/GinieSystem}"
MEM_DIR="$GS_HOME/Memory"
DB="$MEM_DIR/gs_memory.db"

HEIMDAL_A="${HEIMDAL_A:-$GS_HOME/NanotechAutonomousLoop/Heimdal/vault/projects}"
HEIMDAL_B="${HEIMDAL_B:-$GS_HOME/Heimdal/vault/projects}"

scan_roots=()
[ -d "$HEIMDAL_A" ] && scan_roots+=("$HEIMDAL_A")
[ -d "$HEIMDAL_B" ] && scan_roots+=("$HEIMDAL_B")

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 mangler" >&2; exit 1
fi

sql_escape() { sed "s/'/''/g"; }

ingest_file() {
  local f="$1"
  local rel="$f"
  local mission_id="UNKNOWN"
  [[ "$f" =~ /projects/([^/]+)/ ]] && mission_id="${BASH_REMATCH[1]}"
  local role="artifact"
  [[ "$f" =~ PLAN_ ]] && role="plan"
  [[ "$f" =~ KRITIKK_ ]] && role="kritikk"
  [[ "$f" =~ LESSON ]] && role="lesson"

  local ts now
  now="$(date +%s)"
  ts="$now"

  local content
  content="$(cat "$f" 2>/dev/null || true)"
  local hash
  if command -v shasum >/dev/null 2>&1; then
    hash="$(printf '%s' "$content" | shasum -a 256 | awk '{print $1}')"
  else
    hash="$(printf '%s' "$content" | sha256sum | awk '{print $1}')"
  fi

  # skip hvis allerede sett
  if echo "SELECT 1 FROM artifact_hash WHERE doc_hash='$hash' LIMIT 1;" | sqlite3 "$DB" | grep -q 1; then
    return 0
  fi

  local esc_content esc_path esc_mid
  esc_content="$(printf '%s' "$content" | sql_escape)"
  esc_path="$(printf '%s' "$rel" | sql_escape)"
  esc_mid="$(printf '%s' "$mission_id" | sql_escape)"
  local esc_role
  esc_role="$(printf '%s' "$role" | sql_escape)"

  echo "INSERT INTO artifacts(mission_id,role,path,content,ts) VALUES('$esc_mid','$esc_role','$esc_path','$esc_content',$ts);
        INSERT INTO artifact_hash(doc_hash,mission_id,path,ts) VALUES('$hash','$esc_mid','$esc_path',$ts);" | sqlite3 "$DB"
  echo "• Ingest: $rel ($role)"
}

shopt -s nullglob globstar
count=0
for root in "${scan_roots[@]}"; do
  for f in "$root"/**/*.{md,markdown,txt,json,yaml,yml}; do
    [ -f "$f" ] || continue
    ingest_file "$f" && count=$((count+1))
  done
done

echo "✅ Ferdig: $count filer ingestet til $DB"
SH
chmod +x "$SCRIPTS_DIR/memory_ingest.sh"

# ── 4) deepsearch_query.sh — hent “primer” fra minne (CBR)
cat > "$SCRIPTS_DIR/deepsearch_query.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
GS_HOME="${GS_HOME:-$HOME/GinieSystem}"
MEM_DIR="$GS_HOME/Memory"
DB="$MEM_DIR/gs_memory.db"
OUT="${1:-}"
QUERY="${2:-}"

if [ -z "$OUT" ] || [ -z "$QUERY" ]; then
  echo "Bruk: deepsearch_query.sh <OUT_PRIMER.md> \"<forespørsel>\"" >&2
  exit 1
fi
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 mangler" >&2; exit 1
fi

# FTS5 match (porter stemming). Enkelt men robust.
SQL=$(cat <<SQL
SELECT mission_id, role, path, ts,
       snippet(artifacts, 3, '[[', ']]', '…', 10) AS snip
FROM artifacts
WHERE artifacts MATCH $(printf "'%s'" "$QUERY")
ORDER BY rank LIMIT 12;
SQL
)

mkdir -p "$(dirname "$OUT")"
{
  echo "# Context Primer — DeepSearch"
  echo "_Query:_ $QUERY"
  echo
  echo "## Nærmeste referanser"
  echo
  echo "| mission | role | path | snippet |"
  echo "|---|---|---|---|"
  while IFS='|' read -r mission role path ts snip; do
    [ -z "$mission" ] && continue
    echo "| $mission | $role | $path | ${snip//|/\\|} |"
  done < <(echo "$SQL" | sqlite3 -separator '|' "$DB")
  echo
  echo "— generert $(date -Iseconds)"
} > "$OUT"

echo "✅ Skrevet: $OUT"
SH
chmod +x "$SCRIPTS_DIR/deepsearch_query.sh"

# ── 5) reflexion_note.sh — selvrefleksjon (Reflexion) via etikk-porten + ollama (hvis tilgjengelig)
cat > "$SCRIPTS_DIR/reflexion_note.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
GS_HOME="${GS_HOME:-$HOME/GinieSystem}"
MEM_DIR="$GS_HOME/Memory"
DB="$MEM_DIR/gs_memory.db"

MISSION_ID="${1:-}"
PROJ_DIR="${2:-}"

if [ -z "$MISSION_ID" ] || [ -z "$PROJ_DIR" ]; then
  echo "Bruk: reflexion_note.sh <MISSION_ID> <PROJECT_DIR>" >&2
  exit 1
fi

PLAN="$(ls -t "$PROJ_DIR"/PLAN_V*.md 2>/dev/null | head -n1 || true)"
KRITIKK="$(ls -t "$PROJ_DIR"/KRITIKK_V*.md 2>/dev/null | head -n1 || true)"

PROMPT="Lag en kort LESSON.md (maks 15 punkt) som oppsummerer LÆRING fra mission $MISSION_ID.
Inkluder: feil, årsak, mottiltak, sjekkliste neste gang. Vær konkret, GDPR-sikker, og praktisk.
Kontekst (plan/kritikk kan mangle):
--- PLAN ---
$( [ -f "$PLAN" ] && sed -n '1,200p' "$PLAN" )
--- KRITIKK ---
$( [ -f "$KRITIKK" ] && sed -n '1,200p' "$KRITIKK" )
"

mkdir -p "$PROJ_DIR"
OUT="$PROJ_DIR/LESSON.md"

# Forsøk via etikkporten + ollama
CORE_GATE="${CORE_GATE:-$GS_HOME/NanotechAutonomousLoop/Core/ollama_gateway.sh}"
if [ -x "$CORE_GATE" ]; then
  RES="$("$CORE_GATE" "$PROMPT" || true)"
  if printf '%s' "$RES" | head -n1 | grep -q '^DENIED_BY_ETHICS::'; then
    echo "# LESSON\n- Etikk-porten nektet refleksjon. Revider PROMPT." > "$OUT"
  else
    printf '%s\n' "$RES" > "$OUT"
  fi
else
  # Fallback uten ollama
  {
    echo "# LESSON"
    echo "- (Fallback) Lag manuell refleksjon: list feil, årsak, tiltak."
  } > "$OUT"
fi

# Ingest til minne
if command -v sqlite3 >/dev/null 2>&1; then
  ts="$(date +%s)"
  content="$(cat "$OUT")"
  if command -v shasum >/dev/null 2>&1; then
    hash="$(printf '%s' "$content" | shasum -a 256 | awk '{print $1}')"
  else
    hash="$(printf '%s' "$content" | sha256sum | awk '{print $1}')"
  fi
  esc_content="$(printf '%s' "$content" | sed "s/'/''/g")"
  esc_path="$(printf '%s' "$OUT" | sed "s/'/''/g")"
  esc_mid="$(printf '%s' "$MISSION_ID" | sed "s/'/''/g")"
  echo "INSERT INTO artifacts(mission_id,role,path,content,ts) VALUES('$esc_mid','lesson','$esc_path','$esc_content',$ts);
        INSERT INTO artifact_hash(doc_hash,mission_id,path,ts) VALUES('$hash','$esc_mid','$esc_path',$ts);
        INSERT INTO reflections(mission_id,note,ts) VALUES('$esc_mid','LESSON.md generert',$ts);" | sqlite3 "$DB"
fi
echo "✅ LESSON skrevet: $OUT"
SH
chmod +x "$SCRIPTS_DIR/reflexion_note.sh"

# ── 6) nanotech_orchestrator.sh — én inngang til hele flyten
cat > "$SCRIPTS_DIR/nanotech_orchestrator.sh" <<'SH'
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
SH
chmod +x "$SCRIPTS_DIR/nanotech_orchestrator.sh"

# ── 7) Dokumentasjon
cat > "$DOCS_DIR/DeepSearch_Memory_Reflexion.md" <<'MD'
# DeepSearch — Memory + Reflexion + CBR (lokal)
**Hensikt:** Gjøre hver ny mission smartere enn forrige, uten tredjeparts avhengigheter.

## Komponenter
- **FTS5-minne (SQLite):** Lagrer plan/kritikk/lesson og artefakter for semantisk-liknende søk.
- **DeepSearch Primer:** Genererer kort referanse-ark for nye oppdrag basert på tidligere erfaring.
- **Reflexion (LESSON.md):** Etter oppdrag produseres læringsnotat via etikk-port + ollama (fallback manuelt).
- **CBR:** Nye oppdrag starter fra “nærmeste” tidligere case(r).

## Kommandoer
- `nanotech_orchestrator.sh ingest` — scanner Heimdal-prosjekter og oppdaterer minnet
- `nanotech_orchestrator.sh primer mission_<id>.yaml` — lager PRIMER_<id>.md i Thor/queue
- `nanotech_orchestrator.sh reflect <id> <project_dir>` — genererer LESSON.md og ingest
- `nanotech_orchestrator.sh install_launchd` — aktiverer time-jobb for ingest
- `nanotech_orchestrator.sh status` — teller artifacts/reflections

## Etikk
Bruk alltid `Core/ollama_gateway.sh` for modellkall. Ved nekt, revider prompt og forsøk igjen.
MD

# ── 8) Førstegangskjøring
echo
echo "▶️  Førstegangskjøring: ingest → status"
"$SCRIPTS_DIR/memory_ingest.sh" || true
"$SCRIPTS_DIR/nanotech_orchestrator.sh" status || true

echo
echo "✅ Ferdig. Klar for Codex-runde og fabrikk-integrasjon."
