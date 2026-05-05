#!/usr/bin/env bash
set -Eeuo pipefail

# Best Hermes defaults, verified 2026-05-05 from official Nous/Hugging Face/GitHub pages.
HERMES_MODEL_REPO="${HERMES_MODEL_REPO:-NousResearch/Hermes-4.3-36B-GGUF}"
HERMES_MODEL_FILE="${HERMES_MODEL_FILE:-hermes-4_3_36b-Q4_K_M.gguf}"
HERMES_MODEL_ALIAS="${HERMES_MODEL_ALIAS:-hermes-4.3-36b:q4_k_m}"
HERMES_AGENT_RELEASE="${HERMES_AGENT_RELEASE:-v2026.4.30}"
HERMES_CACHE_DIR="${HERMES_CACHE_DIR:-$HOME/.cache/ginie/hermes}"
HERMES_MODEL_PATH="$HERMES_CACHE_DIR/$HERMES_MODEL_FILE"
HERMES_MODEL_URL="https://huggingface.co/$HERMES_MODEL_REPO/resolve/main/$HERMES_MODEL_FILE"

say() { printf '%s\n' "$*"; }
fail() { say "❌ $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"; }

usage() {
  cat <<USAGE
Usage: ${0##*/} <info|download|ollama|agent-command>

Commands:
  info           Print the recommended Hermes versions and local paths.
  download       Download the official Hermes 4.3 36B Q4_K_M GGUF.
  ollama         Create/pull the local Ollama model alias from the downloaded GGUF.
  agent-command  Print the official Hermes Agent install command pinned to $HERMES_AGENT_RELEASE.

Environment overrides:
  HERMES_CACHE_DIR=$HERMES_CACHE_DIR
  HERMES_MODEL_REPO=$HERMES_MODEL_REPO
  HERMES_MODEL_FILE=$HERMES_MODEL_FILE
  HERMES_MODEL_ALIAS=$HERMES_MODEL_ALIAS
  HERMES_AGENT_RELEASE=$HERMES_AGENT_RELEASE
USAGE
}

print_info() {
  cat <<INFO
Best Hermes model:      $HERMES_MODEL_REPO
Recommended GGUF:       $HERMES_MODEL_FILE
Local model path:       $HERMES_MODEL_PATH
Ollama model alias:     $HERMES_MODEL_ALIAS
Hermes Agent release:   $HERMES_AGENT_RELEASE

Why this pick:
- Hermes 4.3 36B is the current best balanced Hermes model for local/private inference.
- Q4_K_M is the default quality/size balance; use Q5_K_M or Q6_K if you have more memory.
- See Docs/Hermes_Best_Version.md for source notes and alternatives.
INFO
}

download_model() {
  mkdir -p "$HERMES_CACHE_DIR"
  if [ -s "$HERMES_MODEL_PATH" ]; then
    say "✅ Already downloaded: $HERMES_MODEL_PATH"
    return 0
  fi

  if command -v huggingface-cli >/dev/null 2>&1; then
    say "⬇️  Downloading with huggingface-cli: $HERMES_MODEL_REPO/$HERMES_MODEL_FILE"
    huggingface-cli download "$HERMES_MODEL_REPO" "$HERMES_MODEL_FILE" \
      --local-dir "$HERMES_CACHE_DIR" \
      --local-dir-use-symlinks False
  else
    need curl
    say "⬇️  Downloading with curl: $HERMES_MODEL_URL"
    curl -L --fail --continue-at - --output "$HERMES_MODEL_PATH" "$HERMES_MODEL_URL"
  fi

  [ -s "$HERMES_MODEL_PATH" ] || fail "Download did not create $HERMES_MODEL_PATH"
  say "✅ Downloaded: $HERMES_MODEL_PATH"
}

create_ollama_model() {
  need ollama
  [ -s "$HERMES_MODEL_PATH" ] || fail "Model file not found. Run: ${0##*/} download"

  local modelfile
  modelfile="$(mktemp)"
  cat > "$modelfile" <<MODELFILE
FROM $HERMES_MODEL_PATH
PARAMETER num_ctx 32768
MODELFILE

  say "🧠 Creating Ollama model: $HERMES_MODEL_ALIAS"
  ollama create "$HERMES_MODEL_ALIAS" -f "$modelfile"
  rm -f "$modelfile"
  say "✅ Ready: ollama run $HERMES_MODEL_ALIAS"
}

print_agent_command() {
  cat <<COMMAND
# Official installer pinned to the recommended Hermes Agent release tag.
# Review remote scripts before running in sensitive environments.
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/$HERMES_AGENT_RELEASE/scripts/install.sh | bash
COMMAND
}

cmd="${1:-info}"
case "$cmd" in
  info) print_info ;;
  download) download_model ;;
  ollama) create_ollama_model ;;
  agent-command) print_agent_command ;;
  -h|--help|help) usage ;;
  *) usage >&2; fail "Unknown command: $cmd" ;;
esac
