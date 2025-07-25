#!/bin/bash

# Installer Homebrew hvis mangler
if ! command -v brew &>/dev/null; then
  echo "📦 Homebrew mangler – installerer..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Installer qrencode hvis mangler
if ! command -v qrencode &>/dev/null; then
  echo "📦 Installerer qrencode..."
  brew install qrencode
else
  echo "✅ qrencode er allerede installert"
fi

# Generer SSH kommando fra Tailscale IP
if [ ! -f ~/GinieSystem/Tailscale/ssh_shortcut_command.txt ]; then
  IP=$(tailscale ip -4 | head -n1)
  echo "ssh christerolsen@$IP 'startwatch'" > ~/GinieSystem/Tailscale/ssh_shortcut_command.txt
fi

# Lag QR-kode
mkdir -p ~/GinieSystem/Tailscale
qrencode -o ~/GinieSystem/Tailscale/watchtower_qr.png "$(cat ~/GinieSystem/Tailscale/ssh_shortcut_command.txt)"
open ~/GinieSystem/Tailscale/watchtower_qr.png

echo "✅ QR klar: ~/GinieSystem/Tailscale/watchtower_qr.png"
