#!/bin/bash
SOURCE_DIR="$HOME/GinieSystem/Vault/Learning"
DEST_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieVaultBackup/Learning"
LOG_FILE="$HOME/GinieSystem/Vault/Logs/sync_learning_to_icloud.log"

mkdir -p "$DEST_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date)] Starter iCloud sync..." >> "$LOG_FILE"
rsync -avh --delete "$SOURCE_DIR/" "$DEST_DIR/" >> "$LOG_FILE" 2>&1
echo "[$(date)] Sync fullført." >> "$LOG_FILE"
