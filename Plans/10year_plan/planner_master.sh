#!/usr/bin/env bash
# planner_master.sh
# Dynamisk planlegger som leser milestones, oppdaterer oppgaver,
# henter løsningsforslag fra OpenAI og logger fremdrift.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MILESTONES_FILE="$BASE_DIR/milestones.json"
STATE_FILE="$BASE_DIR/state.json"
LOG_FILE="$BASE_DIR/planner.log"
MANIFEST_FILE="$BASE_DIR/manifest.md"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [[ -f "$MILESTONES_FILE" ]]; then
    GOALS=$(jq '.' "$MILESTONES_FILE")
else
    echo "Missing milestones.json" >&2
    exit 1
fi

if [[ -f "$STATE_FILE" ]]; then
    STATE=$(jq '.' "$STATE_FILE")
else
    STATE='{"completed_tasks":[]}'
fi

YEAR=$(date +%Y)
MONTH=$(date +%B)
MONTH_NUM=$(date +%m)
case "$MONTH_NUM" in
  01|02|03) QUARTER="Q1";;
  04|05|06) QUARTER="Q2";;
  07|08|09) QUARTER="Q3";;
  10|11|12) QUARTER="Q4";;
 esac

COMPLETED=$(echo "$STATE" | jq '.completed_tasks')
TODO_LIST=""

TASKS=$(echo "$GOALS" | jq -r --arg year "$YEAR" --arg quarter "$QUARTER" --arg month "$MONTH" '.[$year].quarters[$quarter].months[$month].tasks[]? | @base64')

for task in $TASKS; do
    TITLE=$(echo "$task" | base64 --decode | jq -r '.title')
    DONE=$(echo "$task" | base64 --decode | jq -r '.done')

    if [[ "$DONE" == "false" ]]; then
        if echo "$COMPLETED" | jq -e --arg t "$TITLE" '.[] == $t' >/dev/null; then
            GOALS=$(echo "$GOALS" | jq --arg year "$YEAR" --arg quarter "$QUARTER" --arg month "$MONTH" --arg title "$TITLE" '.[$year].quarters[$quarter].months[$month].tasks |= map(if .title == $title then .done = true else . end)')
            STATE=$(echo "$STATE" | jq --arg t "$TITLE" '.completed_tasks -= [$t]')
            echo "$TIMESTAMP: Completed task: $TITLE" >> "$LOG_FILE"
        else
            TODO_LIST+="- $TITLE\n"
        fi
    fi
done

echo -e "Dagens oppgaver:\n$TODO_LIST"

if [[ -n "$TODO_LIST" && -n "${OPENAI_API_KEY:-}" ]]; then
    RESPONSE=$(curl -sS -X POST https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d @- <<'JSON'
{
  "model": "gpt-4o-mini",
  "messages": [
    {"role": "system", "content": "Du er en assistent som lager handlingsplaner."},
    {"role": "user", "content": "Her er dagens oppgaver:\n$TODO_LIST\nGi et kort forslag til hvordan jeg kan løse dem."}
  ]
}
JSON
)
    PLAN=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')
    if [[ -n "$PLAN" ]]; then
        echo -e "\nForslag fra OpenAI:\n$PLAN"
        echo "$TIMESTAMP: $PLAN" >> "$LOG_FILE"
    fi
fi

echo "$GOALS" > "$MILESTONES_FILE"
echo "$STATE" > "$STATE_FILE"

if [[ -f "$MANIFEST_FILE" ]]; then
    sed -i "s/^## 🧬 Sist oppdatert.*/## 🧬 Sist oppdatert\n\`$TIMESTAMP\`/" "$MANIFEST_FILE"
fi
