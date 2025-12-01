#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '%s %s\n' "[$(date '+%Y-%m-%d %H:%M:%S')]" "$*"
}

print_header() {
  echo "🧠 Nanotech aktivert!"
  date
}

check_storage_kb() {
  local path="$1"
  local min_kb="$2"
  local available

  if ! df -Pk "$path" >/dev/null 2>&1; then
    log "Oppretter sti for lagringssjekk: $path"
    mkdir -p "$path"
  fi

  available=$(df -Pk "$path" | awk 'NR==2 {print $4}')
  if [[ -z "$available" ]]; then
    log "Kunne ikke lese tilgjengelig lagringsplass for $path"
    return 1
  fi

  if (( available < min_kb )); then
    return 1
  fi

  return 0
}

require_storage() {
  local path="$1"
  local min_mb="$2"
  local min_kb=$(( min_mb * 1024 ))

  if check_storage_kb "$path" "$min_kb"; then
    return 0
  fi

  log "❌ Ikke nok lagringsplass på $path (krever minst ${min_mb}MB)."
  return 1
}

run_with_storage_check() {
  local path="$1"
  local min_mb="$2"
  shift 2
  local cmd=("$@")

  if require_storage "$path" "$min_mb"; then
    log "Kjører: ${cmd[*]}"
    "${cmd[@]}"
  else
    log "Hopper over installasjon pga. lav lagringsplass: ${cmd[*]}"
    return 1
  fi
}

ensure_command() {
  local binary="$1"
  local installer_desc="$2"
  local path="$3"
  local min_mb="$4"
  shift 4
  local install_cmd=("$@")

  if command -v "$binary" >/dev/null 2>&1; then
    log "✅ $binary finnes allerede"
    return 0
  fi

  log "⚠️ $binary mangler"

  if [[ "${AUTO_INSTALL:-0}" == "1" && ${#install_cmd[@]} -gt 0 ]]; then
    run_with_storage_check "$path" "$min_mb" "${install_cmd[@]}"
  else
    log "Installer manuelt (${installer_desc}). Set AUTO_INSTALL=1 for automatisk installasjon."
    return 1
  fi
}

main() {
  print_header

  local date_stamp="${DATE:-2025-10-30}"
  local repo="${REPO:-giniesystem-reinstall}"
  local base="${BASE:-$HOME/GinieSystem}"
  local docs="$base/Docs"
  local status_dir="$base/Status"
  local logs_dir="$base/Logs"
  local scripts_dir="$base/Scripts"
  local repos_dir="$base/Repos"
  local archive_dir="$base/Archive"
  local md_dir="$docs/Reinstall"
  local md_file="GinieSystem-Reinstall-${date_stamp}.md"
  local md_path="$md_dir/$md_file"
  local repo_dir="$repos_dir/$repo"
  local prompts_dir="$repo_dir/prompts"
  local status_json="$status_dir/reinstall_${date_stamp}.json"
  local desktop_nanotech="$HOME/Desktop/nanotech.sh"

  mkdir -p "$docs" "$status_dir" "$logs_dir" "$scripts_dir" "$repos_dir" "$archive_dir" "$md_dir" "$prompts_dir"

  mkdir -p "$(dirname "$desktop_nanotech")"

  if [[ ! -f "$desktop_nanotech" ]]; then
    cat > "$desktop_nanotech" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "🧠 Nanotech aktivert!"
date
SH
    chmod +x "$desktop_nanotech"
    log "Opprettet $desktop_nanotech"
  else
    log "Fant eksisterende $desktop_nanotech"
  fi

  if [[ ! -f "$md_path" ]]; then
    cat > "$md_path" <<'MD'
# GinieSystem — Reinstall (frosset layout)

**Dato:** 2025-10-30

Denne filen utgjør frosset spesifikasjon før reinstall av hele systemet.

```yaml
version: "2025-10-30"
name: "GinieSystem — Autonomous Cloud/CLI Layout (frosset før reinstall)"
goal: "Første selvgående Ginie som kan orkestrere research → gjennomføring → lagring → inntekt (1M USD) uten browser."
assumptions:
  physical_only: true
  local_ui: terminal
  cloud_llm_ok: true
  browser: false
  reuse_rule: "Ingen nye skript uten å gjenbruke ≥2 eksisterende og fjerne dem etterpå."
  nodes: ["thor", "heimdal", "loki"]
  primary_docs_target: "Google Drive + GitHub recipe + Heimdal-arkiv"
  language: "nb-NO"
  diary: "Den Selvforbedrende Fortellingen"

policies:
  resirkulering:
    description: "All ny automasjon må resirkulere minst to eksisterende skript under ~/GinieSystem/Scripts/ og slette dem etter bruk."
    location: "$HOME/GinieSystem/Scripts"
  logging:
    master: "$HOME/GinieSystem/Logs"
    status: "$HOME/GinieSystem/Status"
    loki_sink: true
  doc_storage:
    primary: "Google Drive (CLI/API/n8n)"
    secondary: "Heimdal (Linux) som kaldt arkiv"
    tertiary: "GitHub (recipe + infra)"
  ethics_gate:
    enabled: true
    action_on_block: "behold rapport og stopp loop"
  user_pref:
    output_box: true
    package_first: true

nodes:
  thor:
    os: "macOS 15.6.1 (24G90)"
    role: ["kontroll", "kø", "terminal-codex", "sky-LLM-cli"]
    services:
      - "GINIE-CODEX terminalmeny"
      - "nanotech.sh bootstrap"
      - "research→exec→storage orkestrering"
      - "Notion (når token virker) – men ikke krittisk"
    ports:
      nta: 8098
    constraints:
      - "Oppdatering: permanent av"
      - "SystemData må tømmes periodisk til Heimdal"
      - "Ingen uendelige 30s-loops"
  heimdal:
    os: "Linux (target) / tidligere macOS 10.15.7"
    role: ["arkiv", "rsync-endepunkt", "GitHub self-hosted runner", "systemdata-kaldlager"]
    storage:
      - "/data/systemdata"
      - "/data/logs"
      - "/data/docs"
    should_host:
      - "n8n"
      - "Drive-sync-jobb"
      - "GitHub-runner for reinstall"
  loki:
    os: "macOS 10.7.5 (Lion) / eldre maskin"
    role: ["logg-mottaker", "batch", "append-only"]
    notes: "Ikke kjør tunge AI-modeller her. Kun logg + lette cron."

agents:
  - id: "deep_research"
    purpose: "Hente, strukturere og normalisere info til YAML/JSON uten menneskelig pynt."
    input: ["tema", "prosjekt", "juridisk sak", "kurs", "northern punching"]
    output: "dataspråk (yaml|json)"
    integrations: ["github", "google_drive", "notion-when-available", "web", "local-doc-dump"]
  - id: "exec_agent"
    purpose: "Gjennomføre det research fant: kjøre skript, rsync, ssh, lage mapper, trigge n8n."
    allowed_targets: ["thor", "heimdal", "loki"]
    tools: ["ssh", "rsync", "curl", "launchctl", "tar", "cron/launchd"]
  - id: "storage_agent"
    purpose: "Sende alle ferdige artefakter til minst to lagre."
    targets: ["google_drive", "heimdal:/data/docs", "github:giniesystem-reinstall"]
    rules:
      - "slett lokal kopi når 2/2 er bekreftet"
  - id: "revenue_writer"
    purpose: "Produsere salgbare utgående pakker (leads.csv, kurs, onboarding, meldingsmaler)."
    outputs: ["csv", "md", "html", "txt"]
    integrations: ["vipps", "ifttt", "shopify", "n8n"]
  - id: "outbound_engine"
    purpose: "Automatisert distribusjon i kanaler (e-post, DM, sms via webhook)."
    depends_on: ["storage_agent"]
  - id: "ops_guardian"
    purpose: "Se etter uendelige loops, for stor SystemData, døde noder."
    triggers:
      - "thor_watch"
      - "systemdata_over_limit"
  - id: "legal_assist"
    purpose: "Samle/formatter dokumentasjon rundt familie/juridisk sak."
    inputs: ["brev", "sms-maler", "tidslinjer", "vitnefortellinger"]
    storage: ["google_drive/legal", "heimdal:/data/legal"]
  - id: "mormor_assist"
    purpose: "Eget prosjekt for mormor via deg – timeføring og oppgaver."
    storage: ["google_drive/mormor", "heimdal:/data/mormor"]
  - id: "northern_punching"
    purpose: "Eget prosjekt for Joachim – pris/ledger/content."
    storage: ["github:northern-punching", "heimdal:/data/northern-punching"]

tools_and_clis:
  ai_cli:
    - name: "GINIE-CODEX terminal"
      type: "menu"
      source: "lokal bash"
      notes: "Den du kjørte som gikk i 30s-restart-loop pga placeholder."
    - name: "curl + sky-LLM"
      type: "cli"
      notes: "Bytt modell ved å endre endpoint – ingen browser."
    - name: "n8n-cli / webhook"
      type: "agent-trigger"
  data_ingest:
    - name: "Apache Tika / pandoc / poppler"
      local: true
      role: "gjøre PDF/MD/HTML lesbart for agenter"
    - name: "nextcloudcmd"
      local: true
      role: "synce kurs/AIL"
    - name: "mail→mbox/eml"
      role: "input til legal_assist + kurs"
  automation:
    - name: "n8n (self-host)"
      role: "Drive, GitHub, Vipps, Notion (når det virker)"
    - name: "IFTTT/Maker"
      role: "rask utgående"
    - name: "Vipps eCom/ePayment"
      role: "penger inn"
    - name: "Shopify CLI (FocusGum)"
      role: "produkt/ordre"
  system:
    - name: "ssh"
    - name: "rsync"
    - name: "launchctl"
    - name: "GitHub self-hosted runner"
    - name: "fluent-bit/osquery"
  creative_media:
    - name: "PsyFactory"
      role: "8D / psytrance pipeline"
    - name: "DALL·E/Midjourney-style prompt"
      role: "branding Venom / THIS!"

pipelines:
  - name: "research→exec→storage"
    description: "standardløypa – brukes av nesten alle prosjekter"
    steps:
      - "deep_research: henter kilder og gir yaml"
      - "exec_agent: gjør faktiske kall/rsync/n8n"
      - "storage_agent: lagerfører til Drive+Heimdal+GitHub"
      - "ops_guardian: sjekker at det ikke henger"
  - name: "revenue→vipps→ledger"
    description: "for 1M USD-målet"
    steps:
      - "revenue_writer produserer pakke (csv/md)"
      - "outbound_engine distribuerer"
      - "vipps/n8n mottar betaling"
      - "storage_agent skriver ledger til Heimdal"
  - name: "legal→collect→format"
    description: "for saker rundt Pernille m.fl."
    steps:
      - "deep_research henter alt om saken"
      - "legal_assist formatterer"
      - "storage_agent lagrer sikkert"
  - name: "mormor→tasks"
    steps:
      - "deep_research (finn alle steder hun er nevnt)"
      - "storage_agent (mormor-mappe)"
      - "exec_agent (opprett oppgave)"

datasets_and_docs:
  - name: "Den Selvforbedrende Fortellingen"
    type: "diary"
    store: ["google_drive/diary", "heimdal:/data/diary"]
  - name: "GinieSystem — Prosjektdokumentasjon"
    type: "notion-export"
    status: "hadde token-trøbbel 2025-10-29"
  - name: "Reinstall-planer"
    location: ["google_drive/GinieSystem/Reinstall/", "github:giniesystem-reinstall/docs/"]
  - name: "Kurs i KI (40+ målgruppe)"
    location: ["google_drive/kurs/ai/", "heimdal:/data/kurs/"]
  - name: "Northern Punching"
    location: ["github:northern-punching", "heimdal:/data/northern-punching"]

constraints_and_painpoints:
  - "Notion token feilet via keychain → må ha egen sky-agent for Notion"
  - "macOS System Data blir for full → må dumps til Heimdal (Linux)"
  - "Terminal ble rotete → må ha ops_guardian som lukker døde vinduer"
  - "Placeholder-restart på Thor ga uendelig loop → må alltid ha MAX_RETRIES"
  - "Bruker vil ikke browse → alle browsede data må via agent"
  - "Bruker vil ha kopi-boks output"

ready_prompts:
  orchestrator_prompt: |
    Du er GINIE CLOUD ORCHESTRATOR for Thor/Heimdal/Loki.
    Du skal ikke bruke nettleser. Du skal kun bruke CLI-kall mot sky-LLM.
    All output: først YAML, så kort norsk sammendrag.
    Bruk agentrekkefølge: deep_research → exec_agent → storage_agent → ops_guardian.
    Ikke lag nye skript uten å resirkulere to.
  research_prompt: |
    Du er DEEP_RESEARCH_AGENT.
    Svar kun i YAML.
    Felter: name, source, type, oss, commercial, requires_cloud, integration, node_support, notes.
    Prioritet: CLI-baserte verktøy uten browser som kan snakke med Google Drive, GitHub og Linux-node.
    Ingen forklaringstekst kun på forespørsel
```
MD
    log "Skrev dokumentasjon til $md_path"
  else
    log "Dokumentasjon finnes allerede: $md_path"
  fi

  if [[ ! -f "$status_json" ]]; then
    cat > "$status_json" <<'JSON'
{
  "date": "2025-10-30",
  "status": "pending",
  "notes": []
}
JSON
    log "Opprettet statusfil: $status_json"
  else
    log "Statusfil finnes allerede: $status_json"
  fi

  local install_root="$base"
  local min_space_mb="${MIN_INSTALL_SPACE_MB:-1024}"

  if command -v brew >/dev/null 2>&1; then
    ensure_command "sqlite3" "brew install sqlite3" "$install_root" "$min_space_mb" brew install sqlite3
  elif command -v apt-get >/dev/null 2>&1; then
    ensure_command "sqlite3" "sudo apt-get install sqlite3" "$install_root" "$min_space_mb" bash -lc "sudo apt-get install -y sqlite3"
  else
    log "⚠️ Fant ingen kjent pakkehåndterer for å installere sqlite3 automatisk."
  fi

  log "Ferdig. Basekatalog: $base"
}

main "$@"
