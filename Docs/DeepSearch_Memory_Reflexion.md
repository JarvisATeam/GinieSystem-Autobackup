# DeepSearch — Memory + Reflexion + CBR (lokal)
**Hensikt:** Gjøre hver ny mission smartere enn forrige, uten tredjeparts avhengigheter.

## Komponenter
- **FTS5-minne (SQLite):** Lagrer plan/kritikk/lesson og artefakter for semantisk-liknende søk.
- **DeepSearch Primer:** Genererer kort referanse-ark for nye oppdrag basert på tidligere erfaring.
- **Reflexion (LESSON.md):** Etter oppdrag produseres læringsnotat via etikk-port + ollama (fallback manuelt).
- **CBR:** Nye oppdrag starter fra “nærmeste” tidligere case(r).

## Kommandoer
- `nanotech_orchestrator.sh ingest` — scanner Heimdal-prosjekter og oppdaterer minnet
- `nanotech_orchestrator.sh primer mission_<id>.yaml` — lager PRIMER_<id>.md i Thor/queue
- `nanotech_orchestrator.sh reflect <id> <project_dir>` — genererer LESSON.md og ingest
- `nanotech_orchestrator.sh install_launchd` — aktiverer time-jobb for ingest
- `nanotech_orchestrator.sh status` — teller artifacts/reflections

## Etikk
Bruk alltid `Core/ollama_gateway.sh` for modellkall. Ved nekt, revider prompt og forsøk igjen.
