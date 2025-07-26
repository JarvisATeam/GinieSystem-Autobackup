#!/bin/bash

echo "🔐 GINIE VAULT STATUS – FULL OVERSIKT"
echo "------------------------------------"
echo "📂 Vault Keys (kryptert):"
ls -l ~/GinieSystem/Vault/FoundKeys/*.gpg 2>/dev/null

echo "📜 Innhold i Vault:"
gpg -d ~/GinieSystem/Vault/FoundKeys/github_pat.key.gpg 2>/dev/null

echo "🧠 Hva du har av meg:"
echo "- Full tilgang til alle prosjekter"
echo "- GPT-agentkontroll, integrasjoner, backup og deploy"
echo "- Du kan når som helst si:"
echo '   > gini, gi meg alle tokens'
echo '   > gini, push alt'
echo '   > gini, aktiver nanotech i [prosjektnavn]'

echo "🚨 Triggere aktivert:"
echo "- g.version_save.sh"
echo "- vault_notify_push.sh"
echo "- g.git_autopush.sh"
