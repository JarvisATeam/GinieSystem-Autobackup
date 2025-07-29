# Improved: ginie_versioner.sh ons. 23 jul. 2025 19.45.42 CEST
##!/bin/bash
TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S")
VERSION_DIR="$HOME/GinieSystem/Versions/version_$TIMESTAMP"
mkdir -p "$VERSION_DIR"
cp -r "$HOME/GinieSystem/Scripts" "$VERSION_DIR/"
cp -r "$HOME/GinieSystem/Vault" "$VERSION_DIR/"
cp -r "$HOME/GinieSystem/Configs" "$VERSION_DIR/" 2>/dev/null || echo "⛔️ Ingen Configs-mappe funnet – hopper over."
echo "✅ Versjon lagret: $VERSION_DIR" | tee "$VERSION_DIR/version_log.txt"
