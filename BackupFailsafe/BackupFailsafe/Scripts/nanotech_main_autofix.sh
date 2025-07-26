#!/bin/bash

echo "🔧 [NanoTech] Starter systemautofiks..."

# 1. Opprett alle kritiske mapper
mkdir -p ~/GinieSystem/{Scripts,Logs,Monitor,Flags,Backup,Tailscale,Vault/keys}
mkdir -p ~/JarvisATeam/{frontend-portal,backend-api,ai-agents,docs,infra,ci-cd}

# 2. Rett alle shebangs i scripts
find ~/GinieSystem/Scripts -type f -name "*.sh" -exec sed -i '' '1s|^#.*|#!/bin/bash|' {} +

# 3. Lag vault.conf hvis mangler
VAULTCONF=~/GinieSystem/vault.conf
if [ ! -f "$VAULTCONF" ]; then
  echo "TOKEN=dummy" > "$VAULTCONF"
  echo "🔐 [vault.conf] Dummy opprettet."
fi

# 4. Lag dummy mailproof hvis mangler
MAILSCRIPT=~/GinieSystem/Scripts/ginie_mailproof.sh
if [ ! -f "$MAILSCRIPT" ]; then
  echo -e '#!/bin/bash\necho \"[Mailproof] placeholder script kjører\"' > "$MAILSCRIPT"
  chmod +x "$MAILSCRIPT"
  echo "📧 [mailproof] Dummy script generert."
fi

# 5. Krypter system_keys.txt hvis den finnes
KEYFILE=~/GinieSystem/Vault/system_keys.txt
if [ -f "$KEYFILE" ]; then
  gpgconf --kill gpg-agent
  gpgconf --launch gpg-agent
  gpg -c "$KEYFILE" && rm "$KEYFILE"
  echo "🔐 [GPG] system_keys.txt kryptert og slettet."
fi

# 6. Rydd quote> fra zsh interaktiv prompt-lås
pkill -f "quote>" 2>/dev/null

# 7. GitHub CLI auth hvis ikke satt
if ! gh auth status &>/dev/null; then
  echo "⚠️ [GH CLI] Trenger login – starter auth"
  gh auth login
fi

# 8. Markør
touch ~/GinieSystem/Flags/NanoTech_ACTIVE.flag
echo "✅ [NanoTech] Autofiks ferdig – system stabil og låst."
