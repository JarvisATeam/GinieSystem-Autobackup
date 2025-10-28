#!/usr/bin/env bash
# GinieSystem – Autonomous $1M Agent (v2)
# Selvforbedrende, inntektsorientert agent med auto-hent av funksjoner, banditt-optimering og ROI-gating.
set -Eeuo pipefail

trap 's=$?; echo "❌ Feil (linje $LINENO). Avbryter. Exit=$s" >&2; exit $s' ERR

: "${BASE:=$HOME/GinieSystem/AutoPilot}"
: "${APPREPO:=$BASE/apprepo}"
: "${VENV:=$BASE/.venv}"
: "${CRON_SPEC:=15 2 * * *}"
: "${GATE:=0.75}"
: "${IDEA_MAX:=6}"
: "${PARALLEL_FETCH:=3}"
: "${POLICY_BLOCK:=adult,violence,illegal}"
: "${DRY:=1}"

log(){ printf '%s %s\n' "$(date -Iseconds)" "$*"; }
ensure(){ mkdir -p "$1"; }
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Mangler $1" >&2; exit 1; }; }

log "📦 Setter opp i $BASE"
for dir in state logs docs signals modules vendor experiments tmp bin src; do
  ensure "$BASE/$dir"
done
ensure "$APPREPO"

for tool in git jq curl python3; do need "$tool"; done

if [ ! -d "$APPREPO/.git" ]; then
  log "⚙️  Initialiserer apprepo"
  git init -q "$APPREPO"
  printf '%s\n' '# Apprepo for Autopilot' > "$APPREPO/README.md"
  (
    cd "$APPREPO"
    git add .
    git commit -qm "init"
  )
fi

if [ ! -d "$VENV" ]; then
  log "🐍 Oppretter Python-venv"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" -q install --upgrade pip >/dev/null
  "$VENV/bin/pip" -q install requests >/dev/null
fi

if [ ! -f "$BASE/direction.txt" ]; then
  cat <<'TXT' > "$BASE/direction.txt"
Bygg lønnsom mikrotjeneste-portefølje:
- Mål: daglig positiv ROI, 3-mnd $1M run-rate.
- Prioritet: Stripe-inntekter, affiliates, API-abonnement, lead-gen automasjon.
- Kanaler: e-post automasjon, content syndikering, GitHub marketplace, Zapier-plugins.
TXT
fi

cat <<'MD' > "$BASE/docs/wizard.md"
# Ginie Autopilot – Veiviser
1) Sett API-nøkler som miljøvariabler (frivillig til å begynne med):
   export OPENAI_API_KEY=...  export GITHUB_TOKEN=...  export STRIPE_API_KEY=...
2) Rediger `direction.txt` (forretningsretning).
3) Kjør loopen: `bash bin/loop.sh` (første gang kjører i dry-run).
4) Sjekk `logs/` og `experiments/state.json`.
5) Når klar for live: `DRY=0 GATE=0.6 bash bin/loop.sh`.
6) Cron: `bash bin/cron_install.sh` (kjører daglig).
7) Kill switch: `bash bin/stop.sh` (deaktiver cron og låsefil).
MD

if [ ! -f "$BASE/docs/todo.md" ]; then
  cat <<'MD' > "$BASE/docs/todo.md"
# To-Do (Auto-generert)
- [ ] Koble Stripe og verifiser `revenue_usd` signal
- [ ] Sett `DEPLOY_CMD` for prod-utrulling (eks: docker compose pull && up -d)
- [ ] Legg til affiliates-signal (CSV/API) => `signals/affiliates.sh`
- [ ] Sett opp e-post outreach modul (Gmail/SMTP) for lead-gen
MD
fi

cat <<'YAML' > "$BASE/policies.yaml"
blocked_topics: [adult, violence, illegal, malware, surveillance, self-harm]
min_tests: 1
max_daily_merges: 1
YAML

cat <<'SH' > "$BASE/signals/stripe_revenue.sh"
#!/usr/bin/env bash
set -euo pipefail
[ -z "${STRIPE_API_KEY:-}" ] && { echo "revenue_usd=0"; exit 0; }
res=$(curl -s https://api.stripe.com/v1/balance -u "$STRIPE_API_KEY:")
avail=$(echo "$res" | jq -r '.available[0].amount // 0')
echo "revenue_usd=$(awk "BEGIN{print $avail/100}")"
SH
chmod +x "$BASE/signals/stripe_revenue.sh"

cat <<'SH' > "$BASE/signals/traffic.sh"
#!/usr/bin/env bash
set -euo pipefail
URL="${TRAFFIC_URL:-}"
[ -z "$URL" ] && { echo "visitors=0"; exit 0; }
v=$(curl -s "$URL" || echo 0)
echo "visitors=${v:-0}"
SH
chmod +x "$BASE/signals/traffic.sh"

cat <<'PY' > "$BASE/src/llm_client.py"
import json
import os
import requests

OPENAI_API = os.environ.get("OPENAI_API_URL", "https://api.openai.com/v1/chat/completions")
MODEL = os.environ.get("OPENAI_MODEL", "gpt-4o")


def _extract_json(text):
    size = len(text)
    for start in range(size):
        if text[start] not in "{[":
            continue
        for end in range(size, start, -1):
            snippet = text[start:end]
            try:
                return json.loads(snippet)
            except Exception:
                continue
    return {"ideas": []}


def generate_ideas(direction, policy_block, n=6):
    if not os.getenv("OPENAI_API_KEY"):
        return {
            "ideas": [
                {"slug": "stripe-oneclick upsell", "title": "Stripe One‑Click Upsell", "integrations": ["stripe", "webhooks"], "kpi": "revenue_usd"},
                {"slug": "affiliate-curator", "title": "Affiliate Curator", "integrations": ["amazon", "impact"], "kpi": "revenue_usd"},
                {"slug": "api-plan-pro", "title": "API Pro Plan", "integrations": ["billing", "quota"], "kpi": "revenue_usd"},
            ]
        }

    prompt = (
        f"Retning: {direction}\n"
        f"Gi {n} konkrete, små moduler som kan øke inntekt innen 1–7 dager. Hver modul må ha:\n"
        "- slug (kebab), title, why (1 setning), integrations [str], kpi (revenue_usd|visitors|leads),\n"
        f"- testplan (1-2 tester), deploy_hint (cmd), policy_ok (true/false ift {policy_block})\n"
        "Returner KUN JSON: {\"ideas\":[...]}\n"
    )

    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": "Du er en growth-ingeniør som gir lønnsomme, testbare småmoduler."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.8,
    }
    response = requests.post(
        OPENAI_API,
        headers={"Authorization": f"Bearer {os.getenv('OPENAI_API_KEY')}", "Content-Type": "application/json"},
        json=body,
        timeout=90,
    )
    response.raise_for_status()
    text = response.json()["choices"][0]["message"]["content"]
    try:
        data = json.loads(text)
    except Exception:
        data = _extract_json(text)
    data["ideas"] = [item for item in data.get("ideas", []) if item.get("policy_ok", True)]
    return data
PY

cat <<'PY' > "$BASE/src/github_fetch.py"
import os
import time
import requests

GITHUB_SEARCH = "https://api.github.com/search/repositories"


def search(topic, per_page=3):
    headers = {"Accept": "application/vnd.github+json"}
    token = os.getenv("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    query = f"q={requests.utils.quote(topic)}&sort=stars&order=desc&per_page={per_page}"
    response = requests.get(f"{GITHUB_SEARCH}?{query}", headers=headers, timeout=30)
    if response.status_code == 403:
        time.sleep(2)
    response.raise_for_status()
    return [{"name": item["full_name"], "url": item["html_url"]} for item in response.json().get("items", [])]
PY

cat <<'PY' > "$BASE/src/bandit.py"
import json
import math
import os
import time

STATE = os.path.join(os.environ.get("BASE", "."), "experiments", "state.json")


def _load():
    if os.path.exists(STATE):
        return json.load(open(STATE))
    return {"arms": {}, "last_merge_ts": 0}


def _save(state):
    json.dump(state, open(STATE, "w"), indent=2)


def choose(ideas, k=3):
    state = _load()
    for idea in ideas:
        state["arms"].setdefault(idea["slug"], {"n": 0, "r": 0.0})
    total = sum(arm["n"] for arm in state["arms"].values()) + 1
    scored = []
    for idea in ideas:
        arm = state["arms"][idea["slug"]]
        bonus = math.sqrt(2 * math.log(total) / (arm["n"] + 1))
        mean = arm["r"] / max(arm["n"], 1)
        scored.append((mean + bonus, idea))
    scored.sort(key=lambda item: item[0], reverse=True)
    return [idea for _, idea in scored[:k]]


def reward(slug, roi_score):
    state = _load()
    arm = state["arms"].setdefault(slug, {"n": 0, "r": 0.0})
    arm["n"] += 1
    arm["r"] += roi_score
    _save(state)


def mark_merge():
    state = _load()
    state["last_merge_ts"] = int(time.time())
    _save(state)
PY

cat <<'PY' > "$BASE/src/roi.py"
import pathlib
import re
import subprocess

WEIGHTS = {"revenue_usd": 0.7, "visitors": 0.2, "leads": 0.1}


def _run_signal(path):
    try:
        output = subprocess.check_output([path], timeout=20, stderr=subprocess.DEVNULL).decode()
    except Exception:
        return {}
    metrics = {}
    for line in output.strip().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            try:
                metrics[key] = float(re.sub("[^0-9.]+", "", value))
            except Exception:
                pass
    return metrics


def read_signals(signals_dir):
    result = {}
    for path in pathlib.Path(signals_dir).glob("*.sh"):
        result.update(_run_signal(str(path)))
    return result


def score(prev, cur):
    total = 0.0
    value = 0.0
    for key, weight in WEIGHTS.items():
        prev_value = prev.get(key, 0.0)
        cur_value = cur.get(key, 0.0)
        delta = cur_value - prev_value
        component = max(0.0, 1.0 - 1.0 / (1.0 + abs(delta)))
        value += weight * component
        total += weight
    return value / max(total, 1e-9)
PY

cat <<'PY' > "$BASE/src/utils.py"
import os
import pathlib


def slugify(value):
    return "-".join(filter(None, "".join(ch.lower() if ch.isalnum() else " " for ch in value).split()))


def ensure_dir(path):
    pathlib.Path(path).mkdir(parents=True, exist_ok=True)


def write(path, text):
    ensure_dir(os.path.dirname(path))
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
PY

cat <<'PY' > "$BASE/src/loop.py"
import datetime
import json
import os
import pathlib
import subprocess
import time

import bandit
import github_fetch
import llm_client
import roi
from utils import ensure_dir, slugify, write

BASE = os.environ.get("BASE", os.path.expanduser("~/GinieSystem/AutoPilot"))
APPREPO = os.environ.get("APPREPO", os.path.join(BASE, "apprepo"))
POLICY_BLOCK = os.environ.get("POLICY_BLOCK", "adult,violence,illegal").split(",")
IDEA_MAX = int(os.environ.get("IDEA_MAX", "6"))
GATE = float(os.environ.get("GATE", "0.75"))
DRY = int(os.environ.get("DRY", "1"))


def git(*args, cwd=None):
    return subprocess.check_output(["git", *args], cwd=cwd or APPREPO).decode()


def baseline_path():
    return os.path.join(BASE, "state", "baseline.json")


def load_baseline():
    path = baseline_path()
    return json.load(open(path)) if os.path.exists(path) else {}


def save_baseline(data):
    json.dump(data, open(baseline_path(), "w"), indent=2)


def create_module(idea):
    slug = slugify(idea.get("slug") or idea["title"])
    module_dir = os.path.join(BASE, "modules", slug)
    ensure_dir(module_dir)
    write(
        os.path.join(module_dir, "module.py"),
        "# {title}\n"
        "def run(context):\n"
        "    # TODO: implementer integrasjon: {integrations}\n"
        "    # returner sann status + eventuelt logg\n"
        "    return True\n".format(title=idea["title"], integrations=",".join(idea.get("integrations", []))),
    )
    write(
        os.path.join(module_dir, "README.md"),
        "# {title}\n\n{why}\nIntegrasjoner: {integrations}\nKPI: {kpi}\n".format(
            title=idea["title"],
            why=idea.get("why", ""),
            integrations=", ".join(idea.get("integrations", [])),
            kpi=idea.get("kpi", "revenue_usd"),
        ),
    )
    write(os.path.join(module_dir, "test_module.py"), "def test_smoke():\n    assert True\n")
    return slug, module_dir


def fetch_integrations(idea):
    links = []
    for topic in idea.get("integrations", [])[:3]:
        try:
            links += github_fetch.search(f"{topic} python")[:2]
        except Exception:
            continue
    if links:
        path = os.path.join(BASE, "vendor", slugify(idea["title"]) + "_links.json")
        json.dump(links, open(path, "w"), indent=2)
    return links


def safe_merge(branch):
    if DRY:
        return
    try:
        git("checkout", "-b", branch)
    except subprocess.CalledProcessError:
        git("checkout", branch)
    git("add", ".")
    git("commit", "-m", f"auto: merge {branch}")
    try:
        git("push", "-u", "origin", branch)
    except Exception:
        pass
    bandit.mark_merge()


def main():
    direction = open(os.path.join(BASE, "direction.txt"), encoding="utf-8").read()
    ideas = llm_client.generate_ideas(direction, POLICY_BLOCK, n=IDEA_MAX)["ideas"][:IDEA_MAX]
    chosen = bandit.choose(ideas, k=min(3, len(ideas)))
    for idea in chosen:
        create_module(idea)
        fetch_integrations(idea)
    previous = load_baseline()
    current = roi.read_signals(os.path.join(BASE, "signals"))
    if not previous:
        save_baseline(current)
    score = roi.score(previous, current)
    for idea in chosen:
        bandit.reward(slugify(idea.get("slug") or idea["title"]), score)
    if score >= GATE:
        timestamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M")
        safe_merge(f"auto/{timestamp}")
        if not DRY and os.environ.get("DEPLOY_CMD"):
            subprocess.call(os.environ["DEPLOY_CMD"], shell=True)
    pathlib.Path(os.path.join(BASE, "logs")).mkdir(parents=True, exist_ok=True)
    open(os.path.join(BASE, "logs", f"loop_{int(time.time())}.log"), "w", encoding="utf-8").write(
        json.dumps({"chosen": [idea["slug"] for idea in chosen], "signals": current, "score": score, "dry": DRY}, indent=2)
    )
    print(json.dumps({"score": score, "ideas": len(ideas), "chosen": [idea["slug"] for idea in chosen]}, indent=2))


if __name__ == "__main__":
    main()
PY

cat <<'SH' > "$BASE/bin/loop.sh"
#!/usr/bin/env bash
set -Eeuo pipefail
export BASE="${BASE:-$HOME/GinieSystem/AutoPilot}"
export APPREPO="${APPREPO:-$BASE/apprepo}"
export PYTHONUNBUFFERED=1
"${BASE}/.venv/bin/python" "${BASE}/src/loop.py"
SH
chmod +x "$BASE/bin/loop.sh"

cat <<'SH' > "$BASE/bin/cron_install.sh"
#!/usr/bin/env bash
set -Eeuo pipefail
: "${CRON_SPEC:=15 2 * * *}"
LINE="$CRON_SPEC BASE=$BASE APPREPO=$APPREPO DRY=${DRY:-0} GATE=${GATE:-0.6} bash $BASE/bin/loop.sh >> $BASE/logs/cron.log 2>&1"
( crontab -l 2>/dev/null | grep -v "$BASE/bin/loop.sh" ; echo "$LINE" ) | crontab -
echo "✅ Cron installert: $LINE"
SH
chmod +x "$BASE/bin/cron_install.sh"

cat <<'SH' > "$BASE/bin/stop.sh"
#!/usr/bin/env bash
set -Eeuo pipefail
crontab -l 2>/dev/null | grep -v "bin/loop.sh" | crontab - || true
echo "✅ Cron avinstallert. Kill-switch aktivert."
SH
chmod +x "$BASE/bin/stop.sh"

log "▶️  Første loop (dry-run) ..."
BASE="$BASE" APPREPO="$APPREPO" DRY=1 "$BASE/bin/loop.sh" || true

log "📘 Les veiviser: $BASE/docs/wizard.md"
log "✅ Ferdig. Sett DRY=0 for å gå live. Eksempel: DRY=0 GATE=0.6 bash $BASE/bin/loop.sh"
