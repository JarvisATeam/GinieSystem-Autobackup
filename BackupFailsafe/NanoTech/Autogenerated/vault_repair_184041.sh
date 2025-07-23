# Improved: vault_repair.sh ons. 23 jul. 2025 18.40.41 CEST
##!/bin/bash echo " Prver gjenopprette Vault 
fra iCloud..." 
ICLOUD_BACKUP_DIR="$HOME/Library/Mobile 
Documents/com~apple~CloudDocs/GinieBackups" 
VAULT_DIR="$HOME/GinieSystem/Vault/Keys" 
LATEST_ZIP=$(ls -t 
"$ICLOUD_BACKUP_DIR"/vault_*.zip 2>/dev/null 
| head -n 1) LATEST_GPG=$(ls -t 
"$ICLOUD_BACKUP_DIR"/vault_*.gpg 2>/dev/null 
| head -n 1) mkdir -p "$VAULT_DIR" if [[ -f 
"$LATEST_ZIP" ]]; then
  echo " Fant zip: $LATEST_ZIP" unzip -o 
  "$LATEST_ZIP" -d "$VAULT_DIR"
elif [[ -f "$LATEST_GPG" ]]; then
  echo " Fant kryptert Vault: $LATEST_GPG" 
  gpg --output 
  "$VAULT_DIR/vault_recovered.zip" --decrypt 
  "$LATEST_GPG" unzip -o 
  "$VAULT_DIR/vault_recovered.zip" -d 
  "$VAULT_DIR"
else
  echo " Ingen backup funnet i 
$ICLOUD_BACKUP_DIR"
  exit 1 fi echo " Gjenoppretting fullfrt. 
Validerer..."
bash "$HOME/GinieSystem/Scripts/validate_keys.sh"
