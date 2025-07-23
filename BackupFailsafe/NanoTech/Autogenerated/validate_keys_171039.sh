# Improved: validate_keys.sh ons. 23 jul. 2025 17.10.39 CEST
##!/bin/bash 
VAULT="$HOME/GinieSystem/Vault/Keys" echo " 
Validerer Vault-nkler..." for k in 
stripe_token.key notion_token.key 
notion_db_id.key telegram_token.key 
telegram_chat.key openai.key github_pat.key 
gmail_pass.gpg; do
  if [[ -f "$VAULT/$k" ]]; then
    echo " $k funnet"
  else
    echo " $k mangler"
  fi
done
