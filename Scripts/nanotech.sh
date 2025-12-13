#!/usr/bin/env bash
echo "🧠 Nanotech aktivert!"
date

set -Eeuo pipefail

# ============================================================
# Nanotech Total Orchestrator v1 (Thor -> Heimdal (+Pi5 plugin))
# - One-shot: setup + verify + status
# - Future-ready: Raspberry Pi 5 as "plugin worker" for Heimdal
# - Sustainability rule: resirkulerer + fjerner minst 2 gamle scripts (hvis de finnes)
# ============================================================

# ---------- UI ----------
BLUE="\033[34m"; RED="\033[31m"; GRN="\033[32m"; YEL="\033[33m"; DIM="\033[2m"; RST="\033[0m"
say(){ echo -e "$*"; }
ok(){ say "${GRN}✅${RST} $*"; }
warn(){ say "${YEL}⚠️${RST} $*"; }
err(){ say "${RED}❌${RST} $*"; }
tag_heimdal(){ say "${BLUE}[HEIMDAL]${RST} $*"; }

need(){ command -v "$1" >/dev/null 2>&1 || { err "Mangler kommando: $1"; return 1; }; }

# ---------- Paths ----------
ROOT="$HOME/GinieSystem"
SCRIPTS="$ROOT/Scripts"
DOCS="$ROOT/Docs"
CONF="$HOME/.config/nanotech"
ENV="$CONF/total_env"
LOGS="$ROOT/Logs"
RECYCLED="$SCRIPTS/_recycled/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$SCRIPTS" "$DOCS" "$CONF" "$LOGS" "$RECYCLED"

# ---------- Dependencies (local Thor) ----------
missing=0
for c in bash ssh scp rsync curl; do need "$c" || missing=1; done
if [ "$missing" -eq 1 ]; then
  warn "Installer manglende verktøy over, og kjør scriptet på nytt."
  exit 1
fi

# ---------- Env bootstrap ----------
touch "$ENV"
chmod 600 "$ENV"

# Helper: set KEY=VALUE in env (no duplicates)
set_kv(){
  local k="$1"; local v="$2"
  if grep -qE "^${k}=" "$ENV"; then
    perl -0777 -i -pe "s/^${k}=.*\\n/${k}=${v}\\n/m" "$ENV"
  else
    echo "${k}=${v}" >> "$ENV"
  fi
}

# Load env safely (only simple KEY=VALUE lines)
load_env(){
  # shellcheck disable=SC1090
  set -a
  source "$ENV" 2>/dev/null || true
  set +a
}

load_env

# ---------- Interactive minimal config (no follow-up questions in chat; script asks in CLI) ----------
ask_if_empty(){
  local key="$1"; local prompt="$2"; local def="${3:-}"
  load_env
  local cur=""
  cur="$(grep -E "^${key}=" "$ENV" | tail -n1 | cut -d= -f2- || true)"
  if [ -z "${cur}" ]; then
    if [ -n "$def" ]; then
      read -r -p "$prompt [$def]: " val || true
      val="${val:-$def}"
    else
      read -r -p "$prompt: " val || true
    fi
    val="$(printf "%s" "$val" | sed -e "s/[[:space:]]*$//")"
    [ -n "$val" ] || { err "Tom verdi for $key"; exit 1; }
    # Quote for safe source
    set_kv "$key" "\"$val\""
  fi
}

say "${DIM}— Konfig (lagres i $ENV, chmod 600) —${RST}"
ask_if_empty HEIMDAL_SSH "Heimdal SSH (user@host)" ""
ask_if_empty HEIMDAL_PORT "Heimdal API port (NTA/LLM-core default 8088/8000?)" "8088"
ask_if_empty THOR_PORT "Thor API port (NTA default 8098?)" "8098"

# Pi5 plugin (valgfritt)
ask_if_empty PI5_ENABLE "Har du Pi5 nå? (yes/no)" "no"
load_env
PI5_ENABLE="${PI5_ENABLE//\"/}"

if [ "$PI5_ENABLE" = "yes" ]; then
  ask_if_empty PI5_SSH "Pi5 SSH (user@host)" ""
  ask_if_empty PI5_ROLE "Pi5 rolle (worker/monitor/proxy)" "worker"
  ask_if_empty PI5_PORT "Pi5 agent port (default 8099)" "8099"
fi

load_env

# ---------- Safety: show plan ----------
say ""
say "${DIM}Plan:${RST}"
say " - Thor: control plane (local)"
say " - Heimdal: backbone (docker/jobs/api)"
if [ "${PI5_ENABLE}" = "yes" ]; then
  say " - Pi5: plugin node (${PI5_ROLE})"
else
  say " - Pi5: ikke aktivert (klar for senere)"
fi
say ""

# ---------- Resirkulering rule (minst 2 scripts) ----------
# Vi forsøker å finne disse, og hvis de finnes, arkiverer vi dem og fjerner originals.
# (Dette er i tråd med din bærekraftsregel. Arkiv beholdes i _recycled.)
CANDIDATES=(
  "$SCRIPTS/nta_watch_thor.sh"
  "$SCRIPTS/nanotech_ops_status.sh"
  "$SCRIPTS/Heimdall_Enable_SSH_and_Node.sh"
)
recycled_count=0
for f in "${CANDIDATES[@]}"; do
  if [ -f "$f" ]; then
    cp -p "$f" "$RECYCLED/$(basename "$f")"
    rm -f "$f"
    ok "Resirkulert + fjernet: $f -> $RECYCLED/"
    recycled_count=$((recycled_count+1))
  fi
done

if [ "$recycled_count" -lt 2 ]; then
  warn "Fant ikke minst 2 av kjente gamle scripts å resirkulere."
  warn "For å holde regelen din 100%: legg minst 2 legacy scripts i $SCRIPTS (navnene over), så kjør på nytt."
  warn "Jeg fortsetter likevel med orkestreringen (ingen flere nye filer opprettes, kun fjernkjøring)."
fi

# ---------- Remote runner ----------
remote_bash(){
  local target="$1"; shift
  local label="$1"; shift
  local script="$1"

  if [ "$label" = "HEIMDAL" ]; then
    tag_heimdal "Kjører remote bootstrap på $target ..."
  else
    ok "Kjører remote bootstrap på $target ..."
  fi

  # Use bash -lc remotely for consistent env
  ssh -o BatchMode=no -o StrictHostKeyChecking=accept-new "$target" "bash -lc 'set -Eeuo pipefail; $script'"
}

# ---------- Heimdal bootstrap script (remote) ----------
# Minimal, safe defaults: create folders, optional docker sanity checks, health endpoints placeholders
HEIMDAL_BOOTSTRAP='
ROOT="$HOME/GinieSystem"
mkdir -p "$ROOT/Scripts" "$ROOT/Docs" "$ROOT/Logs" "$HOME/.config/nanotech" "$ROOT/MoneyFlow/Slot1"
echo "[HEIMDAL] ✅ Struktur OK: $ROOT"

# Docker check (optional)
if command -v docker >/dev/null 2>&1; then
  echo "[HEIMDAL] ✅ Docker finnes"
else
  echo "[HEIMDAL] ⚠️ Docker mangler (plan: installér når vi flytter docker-jobber hit)"
fi

# Create a simple /health responder suggestion (no service started here)
echo "[HEIMDAL] ℹ️ Neste: flytte docker-compose workloads hit + eksponere /health"
'

# ---------- Pi5 bootstrap script (remote) ----------
PI5_BOOTSTRAP='
ROOT="$HOME/GinieSystem"
mkdir -p "$ROOT/Scripts" "$ROOT/Docs" "$ROOT/Logs" "$HOME/.config/nanotech" "$ROOT/Plugin"
echo "[PI5] ✅ Struktur OK: $ROOT"

# Lightweight role hints
ROLE="${PI5_ROLE:-worker}"
echo "[PI5] Rolle: $ROLE"
echo "[PI5] ℹ️ Ideell bruk: queue-worker, monitor-agent, reverse-proxy, scraping, cron watchdogs"
'

# ---------- Execute ----------
# Heimdal always
remote_bash "$HEIMDAL_SSH" "HEIMDAL" "$HEIMDAL_BOOTSTRAP"

# Pi5 optional
if [ "${PI5_ENABLE}" = "yes" ]; then
  # export PI5_ROLE into remote script by inlining
  remote_bash "$PI5_SSH" "PI5" "PI5_ROLE=${PI5_ROLE}; ${PI5_BOOTSTRAP}"
fi

# ---------- Post-checks / status ----------
say ""
ok "Orkestrering ferdig."
say "${DIM}Neste operative steg (for å faktisk flytte Docker fra Thor -> Heimdal):${RST}"
say "1) Eksporter/identifiser hvilke docker-compose stacks som kjører på Thor"
say "2) Flytt compose + volumes plan til Heimdal (rsync) og start der"
say "3) La Pi5 ta lightweight jobs (monitor/queue/proxy) når den er på plass"

say ""
say "${DIM}Env-fil:${RST} $ENV"
say "${DIM}Resirkulert arkiv:${RST} $RECYCLED"
