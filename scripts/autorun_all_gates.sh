#!/usr/bin/env bash
# ALL-IN AUTORUN: starter dev-server, finner minimal gyldig /api/telemetry body automatisk (uten gjetting),
# kjører alle gates, logger alt, stopper serveren, og gir exit-code riktig.
# Kjør fra repo-roten.

set -euo pipefail

ROOT="${ROOT:-$(pwd)}"
PORT="${PORT:-3001}"
BASE_URL="${BASE_URL:-http://127.0.0.1:${PORT}}"
LOGDIR="$ROOT/03_Workspace/Logs"
TS="$(date +%Y%m%d_%H%M%S)"
RUNLOG="$LOGDIR/autorun_all_gates_${TS}.log"
SERVER_LOG="$LOGDIR/dev_server_${TS}.log"

mkdir -p "$LOGDIR"
cd "$ROOT"

log(){ printf "%s %s\n" "[$(date '+%F %T')]" "$*" | tee -a "$RUNLOG"; }

cleanup() {
  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    log "== stopping dev-server pid=$SERVER_PID =="
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    sleep 1
    kill -9 "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

log "== AUTORUN START =="
log "ROOT=$ROOT"
log "BASE_URL=$BASE_URL"
log "RUNLOG=$RUNLOG"
log "SERVER_LOG=$SERVER_LOG"

log "== gate: lint =="
npm run lint 2>&1 | tee -a "$RUNLOG"

log "== gate: build =="
npm run build 2>&1 | tee -a "$RUNLOG"

log "== start dev-server (background) =="
export PORT="$PORT"
( npm run dev >"$SERVER_LOG" 2>&1 ) &
SERVER_PID="$!"
log "dev-server pid=$SERVER_PID"

log "== wait for server ready =="
for i in $(seq 1 60); do
  if curl -fsS "$BASE_URL/" >/dev/null 2>&1; then
    log "server ready (attempt $i)"
    break
  fi
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    log "❌ dev-server died early. tail:"
    tail -n 120 "$SERVER_LOG" | tee -a "$RUNLOG" || true
    exit 1
  fi
  sleep 0.5
  if [ "$i" = "60" ]; then
    log "❌ server not reachable after 30s. tail:"
    tail -n 120 "$SERVER_LOG" | tee -a "$RUNLOG" || true
    exit 1
  fi
done

log "== gate: api import (happy+negative) =="
bash scripts/verify_api_import.sh 2>&1 | tee -a "$RUNLOG"

log "== gate: api export/pdf (method-probe) =="
bash scripts/verify_api_export_pdf.sh 2>&1 | tee -a "$RUNLOG"

log "== build minimal valid telemetry payload (feedback-driven, no guessing) =="
TELEMETRY_PAYLOAD_JSON="$LOGDIR/telemetry_payload_${TS}.json"

node - <<'NODE' "$BASE_URL" "$TELEMETRY_PAYLOAD_JSON" "$RUNLOG"
const base = process.argv[1];
const out = process.argv[2];
const runlog = process.argv[3];
const fs = require("fs");

function log(s){
  const line = `[${new Date().toISOString().replace('T',' ').replace('Z','')}] ${s}\n`;
  fs.appendFileSync(runlog, line);
  process.stdout.write(line);
}

function placeholderFor(field){
  const f = field.toLowerCase();
  if (f.includes("customerid")) return "test-customer";
  if (f === "ts" || f.includes("timestamp") || f.includes("time")) return Date.now();
  if (f === "year") return new Date().getFullYear();
  if (f === "week") return 1;
  if (f.includes("metric") || f.includes("value") || f.includes("val") || f.includes("count")) return 1;
  if (f === "type" || f === "event" || f === "name") return "test";
  if (f.includes("id")) return "test-id";
  return "test";
}

function extractRequired(msg){
  // Handles: "customerId is required" / "X required" / "Invalid ... required"
  const m1 = msg.match(/([A-Za-z0-9_]+)\s+is\s+required/i);
  if (m1) return m1[1];
  const m2 = msg.match(/required:\s*([A-Za-z0-9_]+)/i);
  if (m2) return m2[1];
  const m3 = msg.match(/missing\s+([A-Za-z0-9_]+)/i);
  if (m3) return m3[1];
  return null;
}

async function post(body){
  const res = await fetch(`${base}/api/telemetry`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  let json = null;
  try { json = await res.json(); } catch {}
  return { status: res.status, json };
}

(async () => {
  let body = {};
  for (let i=0;i<20;i++){
    const { status, json } = await post(body);

    if (status === 200 && json && json.ok === true){
      fs.writeFileSync(out, JSON.stringify(body, null, 2));
      log(`telemetry happy OK (200). payload saved: ${out}`);
      return;
    }

    if (status !== 400 || !json || typeof json.error !== "string"){
      log(`telemetry not solvable via feedback loop (status=${status}). response=${JSON.stringify(json)}`);
      process.exit(1);
    }

    const field = extractRequired(json.error);
    if (!field){
      log(`telemetry 400 but no parsable 'required field' in error: ${json.error}`);
      process.exit(1);
    }

    if (body[field] !== undefined){
      log(`telemetry required field repeats (${field}) -> stop. error=${json.error}`);
      process.exit(1);
    }

    body[field] = placeholderFor(field);
    log(`telemetry: added required field '${field}' -> retry`);
  }

  log("telemetry: exceeded max iterations without 200");
  process.exit(1);
})();
NODE

log "== gate: telemetry integrity (uses generated payload) =="
cat > scripts/verify_telemetry_integrity_autorun.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE_URL:-http://127.0.0.1:3001}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGDIR="$ROOT/03_Workspace/Logs"
TS="$(date +%Y%m%d_%H%M%S)"
LOG="$LOGDIR/verify_telemetry_integrity_${TS}.log"

PAYLOAD="${1:-}"
if [ -z "${PAYLOAD:-}" ] || [ ! -f "$PAYLOAD" ]; then
  echo "❌ payload json missing. usage: $0 /path/to/payload.json" | tee -a "$LOG"
  exit 1
fi

log(){ printf "%s %s\n" "[$(date '+%F %T')]" "$*" | tee -a "$LOG"; }

mkdir -p "$LOGDIR"
log "== VERIFY TELEMETRY INTEGRITY START =="
log "BASE=$BASE"
log "PAYLOAD=$PAYLOAD"

# Happy POST must return 200 JSON ok:true
HDR="$(mktemp)"
BODY="$(mktemp)"
trap 'rm -f "$HDR" "$BODY"' EXIT

curl -sS -D "$HDR" -o "$BODY" -X POST "$BASE/api/telemetry" \
  -H "content-type: application/json" \
  --data-binary @"$PAYLOAD" || true

code="$(awk 'NR==1{print $2}' "$HDR" 2>/dev/null || true)"
ctype="$(awk 'BEGIN{IGNORECASE=1} /^content-type:/{print $2}' "$HDR" | tr -d '\r' | head -n1 || true)"
log "HTTP=$code"
log "Content-Type=$ctype"
[ "${code:-}" = "200" ] || { log "❌ expected 200"; head -n 80 "$BODY" | tee -a "$LOG" >/dev/null || true; exit 1; }
echo "${ctype:-}" | grep -qi 'application/json' || { log "❌ expected application/json"; exit 1; }

# Response should be ok:true and must not leak obvious PII keys
node - <<'NODE' "$BODY" "$LOG"
const fs = require("fs");
const p = process.argv[1];
const logp = process.argv[2];
function w(s){ fs.appendFileSync(logp, s + "\n"); }
let obj;
try { obj = JSON.parse(fs.readFileSync(p, "utf8")); }
catch(e){ w("❌ invalid JSON response: " + e.message); process.exit(1); }

if (obj?.ok !== true) { w("❌ expected response ok:true"); process.exit(1); }

const piiKeys = ["email","e-mail","mail","phone","telephone","tlf","mobil","mobile","address","adresse","ssn","fødselsnummer","personnummer","passport","creditcard","cardnumber","iban"];
function hasPII(o){
  const stack=[o];
  while(stack.length){
    const x=stack.pop();
    if (x && typeof x === "object"){
      for(const k of Object.keys(x)){
        const lk = String(k).toLowerCase();
        if (piiKeys.some(p=>lk.includes(p))) return k;
        const v=x[k];
        if (v && typeof v === "object") stack.push(v);
      }
    }
  }
  return null;
}
const pii = hasPII(obj);
if (pii) { w(`❌ PII-like key found in response: ${pii}`); process.exit(1); }

w("OK: telemetry POST happy + response PII-scan");
NODE

log "== VERIFY TELEMETRY INTEGRITY OK =="
log "LOG=$LOG"
SH
chmod +x scripts/verify_telemetry_integrity_autorun.sh

BASE_URL="$BASE_URL" bash scripts/verify_telemetry_integrity_autorun.sh "$TELEMETRY_PAYLOAD_JSON" 2>&1 | tee -a "$RUNLOG"

log "== AUTORUN OK =="
log "Artifacts:"
log "  RUNLOG=$RUNLOG"
log "  SERVER_LOG=$SERVER_LOG"
log "  TELEMETRY_PAYLOAD_JSON=$TELEMETRY_PAYLOAD_JSON"
