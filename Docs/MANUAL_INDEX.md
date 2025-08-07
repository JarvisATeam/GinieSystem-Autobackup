# Ginie System Manual Index

Dette dokumentet gir en kort oversikt over de viktigste skriptene i `Scripts/`-mappen.

- `g_superloop.sh` – masterløkken som starter agentskriptet hver time.
- `g_agentloop.sh` – finner og kjører alle aktiverte agenter.
- `g_proc_killer.sh` – stopper prosesser som bruker for mye RAM.
- `g_key_checker.sh` – verifiserer at alle nødvendige nøkkelfiler finnes.
- `g_push_docs.sh` – genererer en enkel statusrapport og forsøker å sende den til Notion.

For detaljer om planlagte cron-jobber, se `CRON_OVERSIKT.md`.
