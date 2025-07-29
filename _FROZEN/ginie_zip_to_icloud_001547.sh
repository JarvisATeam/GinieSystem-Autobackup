# Improved: ginie_zip_to_icloud.sh tor. 24 jul. 2025 00.15.47 CEST
##!/bin/bash

## Path til iCloud Drive (OBS! Mellomrom IKKE med \ )
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents"
ZIP_NAME="GinieSystem_Backup_$(date +'%Y-%m-%d_%H-%M-%S').zip"
ZIP_TARGET="$ICLOUD_DIR/$ZIP_NAME"
SOURCE_DIR="$HOME/GinieSystem"

echo "[GINIE-ZIP] Starter zip av $SOURCE_DIR til $ZIP_TARGET"

if [ -d "$SOURCE_DIR" ]; then
    /usr/bin/zip -r "$ZIP_TARGET" "$SOURCE_DIR" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ ZIP fullført\033[0m: $ZIP_TARGET"
        bash ~/GinieSystem/Scripts/telegram_notify.sh "✅ iCloud ZIP fullført: $ZIP_NAME"
    else
        echo -e "\033[1;31m❌ ZIP-feil under kjøring\033[0m"
    fi
else
    echo -e "\033[1;31m❌ Mappe ikke funnet:\033[0m $SOURCE_DIR"
fi

