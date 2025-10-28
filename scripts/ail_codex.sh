#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="$ROOT/.venv/bin/python"

log() {
  printf '%s\n' "[$(date '+%H:%M:%S')] $*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "❌ Mangler kommando: $1"
    return 1
  fi
}

activate_venv() {
  if [ ! -x "$PYTHON" ]; then
    log "Oppretter virtuell miljø (.venv)"
    python3 -m venv "$ROOT/.venv"
  fi
  # shellcheck disable=SC1091
  source "$ROOT/.venv/bin/activate"
  PYTHON="$(command -v python)"
  export PYTHON
}

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    return
  fi
  log "Installerer Node.js via nvm"
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null
  fi
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install --lts >/dev/null
  nvm use --lts >/dev/null
}

install_python_dependencies() {
  local req_file="$ROOT/requirements.txt"
  if [ ! -s "$req_file" ] || ! grep -qE "^\\s*[^#]" "$req_file"; then
    log "Ingen ekstra Python-avhengigheter å installere"
    return
  fi
  if ! "$PYTHON" -m pip install -r "$req_file"; then
    log "⚠️ Klarte ikke å installere Python-avhengigheter (fortsetter uten)"
  fi
}

run_step() {
  local description="$1"
  shift
  log "▶ ${description}"
  "$@"
  log "✅ ${description}"
}

main() {
  cd "$ROOT"
  run_step "Kontrollerer python3" require_cmd python3
  run_step "Kontrollerer curl" require_cmd curl
  activate_venv

  log "▶ Oppgraderer pip"
  if "$PYTHON" -m pip install --upgrade pip >/dev/null 2>&1; then
    log "✅ Oppgraderer pip"
  else
    log "⚠️ Klarte ikke å oppgradere pip"
  fi

  install_python_dependencies
  run_step "Sikrer struktur" "$PYTHON" scripts/ail_ops.py bootstrap
  run_step "Kjører Codex-sjekk" "$PYTHON" scripts/ail_codex_check.py --no-codespell
  ensure_node

  log "▶ Installerer Node-avhengigheter"
  if npm install --prefix courses/ail-app --no-audit --no-fund >/dev/null 2>&1; then
    log "✅ Installerer Node-avhengigheter"
  else
    log "⚠️ npm install feilet"
  fi

  run_step "Validerer glossary via npm" npm run --prefix courses/ail-app build
  run_step "Selvtest" "$PYTHON" scripts/idiotproof_selfcheck.py
  log "🎉 Alt ferdig. Kjør appen ved behov med ønsket webserver."
}

main "$@"
