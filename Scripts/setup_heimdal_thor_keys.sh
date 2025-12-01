#!/usr/bin/env bash
set -euo pipefail

# Script to generate and share SSH keys between Thor and Heimdal hosts.
# It also ensures the Heimdal USB helper command is available via PATH
# using the repo Scripts directory, enabling consistent usage across
# both macOS hosts where iCloud Drive is available.

usage() {
  cat <<'USAGE'
Usage: setup_heimdal_thor_keys.sh --thor-host <host> --heimdal-host <host> [options]

Options:
  --thor-user <user>       SSH username for the Thor host (defaults to current user).
  --heimdal-user <user>    SSH username for the Heimdal host (defaults to current user).
  --icloud-dir <path>      Override detected iCloud Drive directory used for storing keys.
  --key-name <name>        Custom key name (defaults to ginie_thor_heimdal_ed25519).
  --heimdal-usb-script <path>
                           Path to heimdal usb scan script (defaults to
                           ~/GinieSystem/Scripts/heimdal_usb_scan.sh).
  -n, --dry-run            Only print actions without executing them.
  -h, --help               Show this help.
USAGE
}

require_cmd() {
  local cmd="$1"; shift
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: $cmd" >&2
    exit 1
  fi
}

# Default values
thor_user="${USER:-}"
heimdal_user="${USER:-}"
dice_dry_run=0
key_name="ginie_thor_heimdal_ed25519"
heimdal_usb_script="${HOME}/GinieSystem/Scripts/heimdal_usb_scan.sh"
declared_icloud_dir=""

thor_host=""
heimdal_host=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --thor-host)
      thor_host="$2"; shift 2;;
    --heimdal-host)
      heimdal_host="$2"; shift 2;;
    --thor-user)
      thor_user="$2"; shift 2;;
    --heimdal-user)
      heimdal_user="$2"; shift 2;;
    --icloud-dir)
      declared_icloud_dir="$2"; shift 2;;
    --key-name)
      key_name="$2"; shift 2;;
    --heimdal-usb-script)
      heimdal_usb_script="$2"; shift 2;;
    -n|--dry-run)
      dice_dry_run=1; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      exit 1;;
  esac
done

if [[ -z "$thor_host" || -z "$heimdal_host" ]]; then
  echo "[ERROR] Both --thor-host and --heimdal-host must be provided." >&2
  usage
  exit 1
fi

run() {
  if [[ $dice_dry_run -eq 1 ]]; then
    echo "[DRY-RUN] $*"
  else
    echo "[RUN] $*"
    eval "$@"
  fi
}

resolve_icloud_dir() {
  if [[ -n "$declared_icloud_dir" ]]; then
    printf '%s' "$declared_icloud_dir"
    return
  fi

  local candidates=(
    "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    "$HOME/Library/Mobile\ Documents/com~apple~CloudDocs"
    "$HOME/iCloudDrive"
    "$HOME/iCloud Drive"
  )
  for path in "${candidates[@]}"; do
    # shellcheck disable=SC2088
    local expanded_path
    expanded_path=$(eval "printf '%s' $path")
    if [[ -d "$expanded_path" ]]; then
      printf '%s' "$expanded_path"
      return
    fi
  done

  echo ""  # Nothing found
}

icloud_dir=$(resolve_icloud_dir)
if [[ -z "$icloud_dir" ]]; then
  echo "[ERROR] Unable to locate iCloud Drive directory. Use --icloud-dir." >&2
  exit 1
fi

keys_dir="$icloud_dir/GinieSystem/Keys"
key_path="$keys_dir/$key_name"

mkdir_cmd="mkdir -p \"$keys_dir\""
run "$mkdir_cmd"

if [[ ! -f "$key_path" ]]; then
  require_cmd ssh-keygen
  run "ssh-keygen -t ed25519 -f \"$key_path\" -N '' -C '${USER:-unknown}@$(hostname)'"
else
  echo "[INFO] Reusing existing key at $key_path"
fi

require_cmd ssh

install_key() {
  local target_user="$1"
  local target_host="$2"
  local pub_key="${key_path}.pub"
  require_cmd ssh

  if command -v ssh-copy-id >/dev/null 2>&1; then
    run "ssh-copy-id -i \"$pub_key\" \"${target_user}@${target_host}\""
  else
    run "cat \"$pub_key\" | ssh \"${target_user}@${target_host}\" 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'"
  fi
}

install_key "$thor_user" "$thor_host"
install_key "$heimdal_user" "$heimdal_host"

# Ensure heimdal-usb command is wired up for convenience.
setup_heimdal_usb() {
  local target_bin="$HOME/.local/bin"
  local script_path="$1"
  if [[ ! -f "$script_path" ]]; then
    echo "[WARN] heimdal USB script not found at $script_path" >&2
    return
  fi
  mkdir -p "$target_bin"
  run "ln -sf \"$script_path\" \"$target_bin/heimdal-usb\""
  local shell_files=("$HOME/.zprofile" "$HOME/.bash_profile")
  for file in "${shell_files[@]}"; do
    if [[ ! -f "$file" ]] || ! grep -Fq "$target_bin" "$file"; then
      run "printf '%s\n' 'export PATH=\"$target_bin:\$PATH\"' >> \"$file\""
    fi
  done
  echo "[INFO] heimdal-usb will be available after you start a new shell session."
}

setup_heimdal_usb "$heimdal_usb_script"

echo "[DONE] SSH keys deployed to Thor ($thor_host) and Heimdal ($heimdal_host)."
echo "[DONE] heimdal-usb helper linked under ~/.local/bin."

if [[ $dice_dry_run -eq 1 ]]; then
  echo "[NOTE] Dry run mode - no remote changes were made."
fi
