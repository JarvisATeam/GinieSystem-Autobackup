# Ginie Autopilot

Dette skriptet (`Scripts/ginie_autopilot.sh`) setter opp en komplett autonom løkke for GinieSystem.

## Hovedfunksjoner
- Oppretter katalogstruktur, git-repo og Python virtualenv.
- Installerer signal-scripts for Stripe-inntekt og trafikkmåling.
- Materialiserer kjerne-Pythonmoduler (LLM-ideen generator, GitHub-integrasjon, banditt, ROI, loop).
- Tilbyr kjørende shell-verktøy (`bin/loop.sh`, `bin/cron_install.sh`, `bin/stop.sh`).
- Kjør alltid en første dry-run, med enkel logging og guardrails.

## Bruk
1. Gjør skriptet kjørbart: `chmod +x Scripts/ginie_autopilot.sh` (allerede satt i repo).
2. Kjør i ønsket miljø (standard bruker `~/GinieSystem/AutoPilot`).
3. Rediger `direction.txt` og fyll ut nødvendige API-nøkler.
4. Når DRY=0 settes, skjer auto-merge og valgfri deploy hvis `DEPLOY_CMD` er definert.

Skriptet kan kjøres flere ganger og er idempotent – eksisterende filer beholdes, men kritiske filer oppdateres for å sikre nyeste logikk.
