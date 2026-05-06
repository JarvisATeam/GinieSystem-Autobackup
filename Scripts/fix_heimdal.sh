#!/usr/bin/env bash
set -Eeuo pipefail

# [HEIMDAL] – Fix/Auto-SSH bootstrap
# Oppgave:
#   - Sikre at nanotech.sh ligger på Desktop (standard)
#   - Generere/bruk ed25519-nøkkel
#   - Finne fungerende IP av Heimdal (10.0.0.2 / 10.0.0.3)
#   - Legge inn nøkkel på Heimdal
#   - Oppdatere ~/.ssh/config med alias "heimdal"
#   - Verifisere med rsync-test
#
# Logg:
#   - ~/GinieSystem/Logs/fix_heimdal_YYYYMMDD_HHMMSS.log

# --- Nanotech-header (standard) ---
DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

F="$DESKTOP_DIR/nanotech.sh"
cat > "$F" <<'NT'
#!/usr/bin/env bash
echo "🧠 Nanotech aktivert!"
date
NT
chmod +x "$F"
"$F" >/dev/null 2>&1 || true

# --- Logging ---
LOG_DIR="$HOME/GinieSystem/Logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/fix_heimdal_$(date +%Y%m%d_%H%M%S).log"

BLUE='\033[34m'
RESET='\033[0m'

echo -e "${BLUE}[HEIMDAL] Starter fix_heimdal-prosedyre...${RESET}" | tee -a "$LOG"

# --- SSH-nøkkel og kandidater ---
USER_HINT="${USER_HINT:-allweek}"
CANDIDATES=(10.0.0.2 10.0.0.3)

SSH_DIR="$HOME/.ssh"
KEY="$SSH_DIR/id_ed25519"
PUB="$KEY.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$KEY" ]; then
  echo "[HEIMDAL] Genererer ny ed25519-nøkkel for $USER_HINT ..." | tee -a "$LOG"
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "$USER_HINT@$(hostname)" >>"$LOG" 2>&1
fi

BEST_IP=""
PUBKEY="$(cat "$PUB")"

# --- Finn fungerende IP og trykk inn nøkkel ---
for IP in "${CANDIDATES[@]}"; do
  echo "[HEIMDAL] Tester IP: $IP ..." | tee -a "$LOG"
  if ssh -o ConnectTimeout=4 -o BatchMode=yes "$USER_HINT@$IP" "echo OK" >/dev/null 2>&1; then
    BEST_IP="$IP"
    echo "[HEIMDAL] Fant fungerende nøkkel-login på $IP" | tee -a "$LOG"
    break
  else
    echo "[HEIMDAL] Forsøker å legge inn nøkkelen på $IP ..." | tee -a "$LOG"
    if ssh -o ConnectTimeout=8 "$USER_HINT@$IP" \
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && (grep -qF \"$PUBKEY\" ~/.ssh/authorized_keys || printf \"%s\\n\" \"$PUBKEY\" >> ~/.ssh/authorized_keys) && echo OK" \
      >>"$LOG" 2>&1; then

      if ssh -o ConnectTimeout=4 -o BatchMode=yes "$USER_HINT@$IP" "echo OK" >/dev/null 2>&1; then
        BEST_IP="$IP"
        echo "[HEIMDAL] Nøkkel lagt inn og verifisert på $IP" | tee -a "$LOG"
        break
      fi
    else
      echo "[HEIMDAL] Klarte ikke å nå $IP med passord/ssh for nøkkel-innlegg." | tee -a "$LOG"
    fi
  fi

done

if [ -z "$BEST_IP" ]; then
  echo "ERR: fant ingen IP som aksepterer nøkkel/passord (10.0.0.2/10.0.0.3)." | tee -a "$LOG"
  exit 1
fi

# --- Oppdater ~/.ssh/config med alias heimdal ---
CFG="$SSH_DIR/config"
touch "$CFG"

# Fjern gammel heimdal-blokk
awk 'BEGIN{skip=0}/^Host heimdal$/{skip=1} skip==1&&NF==0{skip=0;next} skip==0{print}' "$CFG" > "$CFG.tmp" || true
mv "$CFG.tmp" "$CFG"

cat >> "$CFG" <<EOF2

Host heimdal
  HostName $BEST_IP
  User $USER_HINT
  PreferredAuthentications publickey
  IdentitiesOnly yes
  IdentityFile $KEY
EOF2

chmod 600 "$CFG"

echo "[HEIMDAL] Oppdatert SSH-config med Host heimdal -> $BEST_IP" | tee -a "$LOG"

# --- Known_hosts hygiene ---
ssh-keygen -R heimdal >/dev/null 2>&1 || true
ssh-keygen -R "$BEST_IP" >/dev/null 2>&1 || true
ssh-keyscan -t ed25519 "$BEST_IP" >> "$SSH_DIR/known_hosts" 2>/dev/null || true
ssh-keyscan -t ed25519 heimdal   >> "$SSH_DIR/known_hosts" 2>/dev/null || true

# --- Verifiser alias & rsync-test ---
if ! ssh -o BatchMode=yes heimdal "echo OK" >/dev/null 2>&1; then
  echo "ERR: nøkkel-login feilet mot alias. Kjør: ssh -vv heimdal" | tee -a "$LOG"
  exit 2
fi

TMP="/tmp/ssh_testfile_fix_heimdal.txt"
echo "Hei fra Thor" > "$TMP"

echo "[HEIMDAL] Tester rsync til heimdal:/tmp ..." | tee -a "$LOG"
rsync -av "$TMP" heimdal:/tmp/ssh_testfile_fix_heimdal.txt >>"$LOG" 2>&1 || {
  echo "ERR: rsync-feil mot heimdal." | tee -a "$LOG"
  rm -f "$TMP"
  exit 3
}

ssh heimdal "ls -l /tmp/ssh_testfile_fix_heimdal.txt && cat /tmp/ssh_testfile_fix_heimdal.txt && rm -f /tmp/ssh_testfile_fix_heimdal.txt" >>"$LOG" 2>&1 || {
  echo "ERR: klarte ikke å verifisere testfil på Heimdal." | tee -a "$LOG"
  rm -f "$TMP"
  exit 4
}

rm -f "$TMP"

echo -e "${BLUE}[HEIMDAL] OK: alias heimdal -> $BEST_IP${RESET}" | tee -a "$LOG"
echo "[HEIMDAL] Logg: $LOG"
