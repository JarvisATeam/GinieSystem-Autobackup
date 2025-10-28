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
