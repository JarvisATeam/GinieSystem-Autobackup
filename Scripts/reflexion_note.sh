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
