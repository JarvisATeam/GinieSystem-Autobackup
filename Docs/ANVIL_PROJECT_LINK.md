# Anvil prosjektkobling (ASK-007)

Denne mappen dokumenterer hvordan `deterministic_audit_mvp/giniesystem` kobles til Anvil-prosjektet og hvordan du verifiserer import → prosjekt → prefill-flyt.

## Mapping
- **App-rot:** `deterministic_audit_mvp/giniesystem`
- **Anvil data-root:** `03_Workspace/anvil_data`
- **Prosjektlager:** `03_Workspace/anvil_data/projects/*.json`

## API-endepunkter
- `POST /api/import` → oppretter import + prosjekt + prefill
- `GET /api/projects` → liste over prosjekter
- `GET /api/projects/:id` → prosjektmetadata
- `PATCH /api/projects/:id` → oppdater prosjekt
- `GET /api/projects/:id/prefill` → kalkulator-prefill
- `POST /api/projects/:id/accept-prefill` → lagrer akseptert prefill

## UI-sider
- `/import` → last opp og analyser dokument
- `/projects` → liste over prosjekter
- `/projects/:id` → detaljer + prefill-aksept

## Lokal testflyt (manuell)
1. Start appen og gå til `/import`.
2. Last opp et dokument og klikk **Analyser fil**.
3. Klikk **Åpne prosjekt** for å verifisere at prosjekt + prefill er opprettet.
4. Klikk **Bruk forslag (lagre på prosjekt)** for å teste lagring av prefill.

## Verifiser lagring
Sjekk at `03_Workspace/anvil_data/projects/<project_id>.json` har:
- `project.accepted_prefill` etter aksept.
- `prefill` satt fra heuristikk.
