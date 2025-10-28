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
