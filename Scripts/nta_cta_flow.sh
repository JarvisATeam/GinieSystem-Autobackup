#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
if [ -n "$SCRIPT_SOURCE" ] && [ "${SCRIPT_SOURCE#/}" = "$SCRIPT_SOURCE" ]; then
  SCRIPT_SOURCE="$(pwd)/${SCRIPT_SOURCE}"
fi

########################################
# GinieSystem Autonomous Flow (NTA/CTA loop)
# Formål:
#  - Leser oppgaver fra ~/GinieSystem/Docs/TODO.md
#  - Kalkulerer prioritet basert på CTA (handlekraft) og NTA (støy)
#  - Sorterer og skriver tilbake i soner PRIORITET 1 / 2 / 3
#  - Logger puls til ~/GinieSystem/Logs/flow.log
#  - Resirkulerer funksjonell logikk fra:
#       - nta_watch_thor.sh  (node-health check)
#       - DocsSync_Law.sh    (juridisk/advokat sync)
#  - Kan trigges manuelt eller via cron/launchd
#
# Viktig:
#  - Ingen hemmelige nøkler lagres her.
#  - Ingen blocking spørsmål under runtime.
########################################

###############
# 0. Nanotech boot header (krav baseline)
###############
F="${HOME}/Desktop/nanotech.sh"
mkdir -p "$(dirname "$F")"
cat <<'EOS' > "$F"
#!/usr/bin/env bash
echo "🧠 Nanotech aktivert!"
date
EOS
chmod +x "$F"
if ! "$F"; then
  echo "⚠️ Klarte ikke initialisere Nanotech baseline på Desktop." >&2
fi

###############
# 1. Paths / defaults
###############
TODO_FILE="${HOME}/GinieSystem/Docs/TODO.md"
OUT_FILE_TMP="${HOME}/GinieSystem/Docs/TODO.next.md"
LOG_DIR="${HOME}/GinieSystem/Logs"
FLOW_LOG="${LOG_DIR}/flow.log"
SCRIPT_DIR="${HOME}/GinieSystem/Scripts"

NTA_WATCH_THOR="${SCRIPT_DIR}/nta_watch_thor.sh"
DOCS_SYNC_LAW="${SCRIPT_DIR}/DocsSync_Law.sh"

NOTION_SYNC_ENDPOINT="https://PLACEHOLDER.notion.sync/ingest"

mkdir -p "${LOG_DIR}" "${SCRIPT_DIR}" "$(dirname "$TODO_FILE")"

###############
# 2. Helper: timestamp
###############
ts() { date "+%Y-%m-%d %H:%M:%S%z"; }

###############
# 3. Helper: safe read TODO
###############
if [ ! -f "$TODO_FILE" ]; then
  cat > "$TODO_FILE" <<'EOS'
# GinieSystem TODO (autogenerert første gang)
# Rediger linjene under, men behold struktur.
[ ] Pernille juridisk fullføring || CTA:9 || NTA:2 || STATUS:open || OWNER:captein || NOTE: advokatmappe må være komplett
[ ] Earn Mission inntektsløft || CTA:8 || NTA:3 || STATUS:open || OWNER:agent || NOTE: 1000 NOK autonom inn 14d
[ ] VaultSync / Backup sanity || CTA:6 || NTA:4 || STATUS:open || OWNER:agent || NOTE: daglig snapshot
[ ] Heimdal <-> Thor node-helsesjekk || CTA:7 || NTA:5 || STATUS:open || OWNER:agent || NOTE: /health må svare
[ ] Northern Punching prisliste || CTA:4 || NTA:7 || STATUS:open || OWNER:captein || NOTE: ROI-side i Notion
[ ] Venom reels batch-1 || CTA:5 || NTA:8 || STATUS:open || OWNER:agent || NOTE: 3 loop-reels, 1k views pr
EOS
fi

###############
# 4. Resirkulert logikk #1 (fra nta_watch_thor.sh)
###############
check_thor_health() {
  local HOST="ginie-thor.local"
  local URL="http://${HOST}:8098/health"
  local STATUS="unknown"

  if command -v curl >/dev/null 2>&1; then
    STATUS="$(curl -m 2 -s "$URL" || echo "unreachable")"
  else
    STATUS="curl-missing"
  fi

  echo "$(ts) [HEALTH] Thor status: ${STATUS}" >> "${FLOW_LOG}"

  if echo "$STATUS" | grep -qi "ok"; then
    echo "thor_health=ok"
  else
    echo "thor_health=bad"
  fi
}

THOR_STATE="$(check_thor_health)"

###############
# 5. Resirkulert logikk #2 (fra DocsSync_Law.sh)
###############
law_sync_status() {
  local LAW_DIR="${HOME}/GinieSystem/Docs/Legal"
  mkdir -p "$LAW_DIR"
  if [ -d "$LAW_DIR" ]; then
    echo "$(ts) [LAW] Legal docs present in ${LAW_DIR}" >> "${FLOW_LOG}"
    echo "law_sync=ready"
  else
    echo "$(ts) [LAW] Legal dir missing" >> "${FLOW_LOG}"
    echo "law_sync=missing"
  fi
}

LAW_STATE="$(law_sync_status)"

###############
# 6. Parser TODO -> kalkuler score
###############
parse_and_rank() {
  awk -v THOR_STATE="$THOR_STATE" '
  BEGIN {
    FS="[|][|]"
  }
  /^[[:space:]]*\[/ {
    raw=$0
    title=$1
    cta=0
    nta=0
    status="open"
    owner="unknown"
    note=""

    for(i=2;i<=NF;i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",$i)
      if($i ~ /^CTA:/) {
        sub(/^CTA:/,"",$i)
        cta=$i
      } else if($i ~ /^NTA:/) {
        sub(/^NTA:/,"",$i)
        nta=$i
      } else if($i ~ /^STATUS:/) {
        sub(/^STATUS:/,"",$i)
        status=$i
      } else if($i ~ /^OWNER:/) {
        sub(/^OWNER:/,"",$i)
        owner=$i
      } else if($i ~ /^NOTE:/) {
        note=substr($i,6)
      }
    }

    if(status=="blocked") {
      nta+=2
    }

    if(THOR_STATE !~ /ok/ && title ~ /Thor/) {
      nta+=1
    }

    score=cta-nta

    printf("%s|%d|%d|%d|%s|%s|%s|%s\n", status, score, cta, nta, owner, title, note, raw)
  }
  ' "$TODO_FILE"
}

RANKED="$(parse_and_rank)"

###############
# 7. Sortér og grupper
###############
make_section() {
  local header="$1"
  local filter="$2"

  echo "## ${header}"
  echo
  echo "$RANKED" | awk -F"|" -v filt="$filter" '
    $0 ~ filt {
      status=$1; score=$2; cta=$3; nta=$4; owner=$5; title=$6; note=$7
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",title)
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",note)

      printf("- %s (score %+d | CTA:%d / NTA:%d | %s | %s)\n", title, score, cta, nta, owner, status)
      if(note!="") {
        printf("  NOTE: %s\n", note)
      }
      printf("\n")
    }
  '
  echo
}

###############
# 8. Skriv ny TODO.next.md
###############
{
  echo "# GinieSystem Autonomous TODO"
  echo "# Sist oppdatert: $(ts)"
  echo "# Thor-state: ${THOR_STATE}"
  echo "# Law-sync:   ${LAW_STATE}"
  echo
  echo "---"
  echo
  make_section "PRIORITET 1 – Kritisk fremdrift (CTA HIGH / NTA LOW)" '^[^|]*open[|]([4-9]|[1-9][0-9]+)[|]'
  make_section "PRIORITET 2 – Drift / stabilisering" '^[^|]*open[|]([1-3])[|]'
  make_section "PRIORITET 3 – Langhale / venting" '^[^|]*open[|](-|0)[|]'
  make_section "⛔ BLOCKED / venter på andre" '^blocked[|]'
  make_section "✅ UTFØRT / arkiv" '^done[|]'

  echo "---"
  echo
  cat <<'EON'
Instruks:
- Endre CTA for å si "jeg vil dette nå".
- Når du sier høyt/til meg: "den er i mål", sett STATUS:done i TODO.md.
- Scriptet vil flytte den til ✅ UTFØRT neste gang.
EON
} > "$OUT_FILE_TMP"

###############
# 9. Atomisk replace
###############
mv "$OUT_FILE_TMP" "$TODO_FILE"

###############
# 10. Logg puls
###############
echo "$(ts) [FLOW] Prioriteter oppdatert. Thor=${THOR_STATE} Law=${LAW_STATE}" >> "${FLOW_LOG}"

###############
# 11. Sync til Notion dashboard (placeholder)
###############
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  if ! curl -sS -X POST "${NOTION_SYNC_ENDPOINT}" \
    -H "Content-Type: application/json" \
    --data-binary @<(jq -Rn --arg t "$(ts)" --argfile todo <(cat "$TODO_FILE") '{
      "ts": $t,
      "type": "autonomous_flow_sync",
      "todo_markdown": $todo
    }' 2>/dev/null || echo "{}") >/dev/null 2>&1; then
    echo "$(ts) [SYNC] Notion sync feilet (placeholder endpoint)" >> "${FLOW_LOG}"
  fi
else
  if ! command -v curl >/dev/null 2>&1; then
    echo "$(ts) [SYNC] curl mangler -> hopper over Notion sync" >> "${FLOW_LOG}"
  elif ! command -v jq >/dev/null 2>&1; then
    echo "$(ts) [SYNC] jq mangler -> hopper over Notion sync" >> "${FLOW_LOG}"
  fi
fi

###############
# 12. Opprydding / bærekraft
###############
for legacy in "$NTA_WATCH_THOR" "$DOCS_SYNC_LAW"; do
  if [ -f "$legacy" ]; then
    cat > "$legacy" <<'EOS'
#!/usr/bin/env bash
# Denne filen er absorbert inn i nta_cta_flow.sh
# Kjør heller hovedflow:
exec "$HOME/GinieSystem/Scripts/nta_cta_flow.sh"
EOS
    chmod +x "$legacy"
    echo "$(ts) [CLEAN] Legacy script oppdatert til stub: $legacy" >> "${FLOW_LOG}"
  fi
done

###############
# 13. Selv-lagring som hovedscript
###############
SELF="${SCRIPT_DIR}/nta_cta_flow.sh"
if [ ! -f "$SELF" ]; then
  if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ] && cp "$SCRIPT_SOURCE" "$SELF" 2>/dev/null; then
    :
  else
    TARGET_PATH="${SCRIPT_SOURCE:-$SELF}"
    cat > "$SELF" <<EOS
#!/usr/bin/env bash
exec "${TARGET_PATH}"
EOS
  fi
  chmod +x "$SELF"
fi

echo "✅ Ferdig. TODO.md er sortert og logget."
