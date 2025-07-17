#!/bin/bash
export STRIPE_TOKEN=$(cat ~/.stripe_token 2>/dev/null)
export TELEGRAM_TOKEN=$(cat ~/.telegram_token 2>/dev/null)
export TELEGRAM_CHAT=$(cat ~/.telegram_chat 2>/dev/null)
export NOTION_TOKEN=$(cat ~/.notion_token 2>/dev/null)
export NOTION_DB_ID=$(cat ~/.notion_db_id 2>/dev/null)
export GMAIL_PASS=$(gpg --quiet --batch --decrypt ~/.mailpass.gpg 2>/dev/null)
export GITHUB_PAT="github_pat_..."
echo "✅ Tokens og API-nøkler lastet"
