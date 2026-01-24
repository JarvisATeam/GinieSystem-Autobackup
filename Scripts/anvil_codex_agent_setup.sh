#!/usr/bin/env bash
#
# ANVIL Codex Agent - Installasjonsscript
# Kjør dette fra hvilken som helst mappe - det setter opp alt riktig.
#
set -euo pipefail

REPO="${REPO:-$HOME/GinieSystem/deterministic_audit_mvp/giniesystem}"
AGENT_DIR="$REPO/03_Workspace"
TASKS_DIR="$AGENT_DIR/claude_tasks"
OUT_DIR="$AGENT_DIR/claude_out"

echo "=============================================="
echo "🤖 ANVIL Codex Agent - Setup"
echo "=============================================="

# 1. Opprett mapper
echo "📁 Oppretter mapper..."
mkdir -p "$TASKS_DIR"
mkdir -p "$OUT_DIR"

# 2. Kopier agent-script
echo "📄 Installerer codex_agent.py..."
cat > "$AGENT_DIR/codex_agent.py" << 'AGENT_EOF'
#!/usr/bin/env python3
"""
ANVIL Codex Agent - Lokal Claude-agent for kodeoppgaver
Henter tasks fra claude_tasks/, sender til Claude API, genererer patcher.

Bruk:
  ./codex_agent.py                    # Kjør default task (001_fix_pdf_export.md)
  ./codex_agent.py --task 002_*.md    # Kjør spesifikk task
  ./codex_agent.py --list             # List tilgjengelige tasks
  ./codex_agent.py --dry-run          # Generer prompt uten API-kall
"""

import os
import sys
import re
import json
import argparse
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Optional

# ============================================================================
# KONFIGURASJON
# ============================================================================

BASE_DIR = Path.home() / "GinieSystem/deterministic_audit_mvp/giniesystem"
TASK_DIR = BASE_DIR / "03_Workspace/claude_tasks"
OUT_DIR = BASE_DIR / "03_Workspace/claude_out"
REPO_DIR = BASE_DIR

# API config
API_URL = "https://api.anthropic.com/v1/messages"
MODEL = "claude-sonnet-4-20250514"
MAX_TOKENS = 4096
MAX_INPUT_CHARS = 80000

# ============================================================================
# HJELPEFUNKSJONER
# ============================================================================

def get_api_key() -> Optional[str]:
    return os.environ.get("ANTHROPIC_API_KEY")

def estimate_tokens(text: str) -> int:
    return len(text) // 4

def truncate_file(content: str, max_chars: int = 8000) -> str:
    if len(content) <= max_chars:
        return content
    half = max_chars // 2
    return content[:half] + "\n\n[... TRUNCATED ...]\n\n" + content[-half:]

def parse_files_block(task_content: str) -> list[str]:
    files = []
    in_files_block = False
    for line in task_content.split("\n"):
        if line.strip().upper().startswith("FILES:"):
            in_files_block = True
            continue
        if in_files_block:
            if line.strip().startswith("-"):
                file_path = line.strip().lstrip("-").strip()
                files.append(file_path)
            elif line.strip() and not line.strip().startswith("-"):
                break
    return files

def load_attached_files(file_paths: list[str]) -> str:
    chunks = []
    total_chars = 0
    for rel_path in file_paths:
        full_path = REPO_DIR / rel_path
        if full_path.exists():
            content = full_path.read_text(errors="replace")
            content = truncate_file(content)
            total_chars += len(content)
            if total_chars > MAX_INPUT_CHARS * 0.6:
                chunks.append(f"\n# FILE: {rel_path}\n[SKIPPED - token budget]\n")
                continue
            chunks.append(f"\n# FILE: {rel_path}\n```\n{content}\n```\n")
        else:
            chunks.append(f"\n# FILE: {rel_path}\n[NOT FOUND]\n")
    return "\n".join(chunks)

def find_task_file(pattern: str) -> Optional[Path]:
    if "*" in pattern:
        matches = list(TASK_DIR.glob(pattern))
        return matches[0] if matches else None
    exact = TASK_DIR / pattern
    if exact.exists():
        return exact
    for f in TASK_DIR.glob("*.md"):
        if pattern in f.name:
            return f
    return None

# ============================================================================
# PROMPT-BYGGING
# ============================================================================

SYSTEM_PROMPT = """Du er Codex, en deterministisk kode-agent som kjører i Christers lokale utviklingsmiljø.

REGLER:
1. Generer KUN kode og patcher - ingen forklaringer med mindre eksplisitt bedt om
2. Output ALLTID i dette formatet:
   - PATCH-blokk med unified diff format
   - VERIFY-blokk med kommandoer for å teste
   - CHANGELOG-blokk med 3-5 bullets
3. Vær KONKRET: ekte filstier, ekte kode, kjørbare kommandoer
4. Ingen "placeholder" eller "TODO" - lever ferdig kode
5. Hold deg innenfor scopet til oppgaven

OUTPUT FORMAT:
```patch
--- a/path/to/file.ts
+++ b/path/to/file.ts
@@ -line,count +line,count @@
 context
-old line
+new line
 context
```

```verify
# Kommandoer for å verifisere at patchen fungerer
```

```changelog
- Punkt 1: Hva som ble endret
- Punkt 2: Hvorfor
- Punkt 3: Eventuelle side-effekter
```
"""

def build_prompt(task_path: Path) -> str:
    task_content = task_path.read_text()
    attached_files = parse_files_block(task_content)
    files_content = load_attached_files(attached_files) if attached_files else ""
    
    return f"""# OPPGAVE: {task_path.name}

{task_content}

# VEDLAGTE FILER
{files_content if files_content else "[Ingen filer spesifisert - bruk FILES: blokk i task]"}

# INSTRUKSJON
Analyser oppgaven og de vedlagte filene. Generer en patch som løser problemet.
Følg output-formatet eksakt (PATCH, VERIFY, CHANGELOG blokker).
"""

# ============================================================================
# API-KALL
# ============================================================================

def call_claude_api(prompt: str) -> Optional[str]:
    api_key = get_api_key()
    if not api_key:
        return None
    
    try:
        import requests
    except ImportError:
        print("⚠️  requests ikke installert. Kjør: pip install requests")
        return None
    
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    data = {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "system": SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": prompt}],
    }
    
    print(f"📡 Sender til Claude API ({MODEL})...")
    print(f"   Input: ~{estimate_tokens(prompt)} tokens")
    
    try:
        resp = requests.post(API_URL, headers=headers, json=data, timeout=120)
        resp.raise_for_status()
        result = resp.json()
        if "content" in result and result["content"]:
            usage = result.get("usage", {})
            print(f"   Output: {usage.get('output_tokens', '?')} tokens")
            return result["content"][0].get("text", "")
        return None
    except Exception as e:
        print(f"❌ API-feil: {e}")
        return None

# ============================================================================
# OUTPUT-HÅNDTERING
# ============================================================================

def extract_blocks(response: str) -> dict:
    blocks = {"patch": "", "verify": "", "changelog": "", "raw": response}
    patch_match = re.search(r"```(?:patch|diff)\n(.*?)```", response, re.DOTALL)
    verify_match = re.search(r"```verify\n(.*?)```", response, re.DOTALL)
    changelog_match = re.search(r"```changelog\n(.*?)```", response, re.DOTALL)
    if patch_match:
        blocks["patch"] = patch_match.group(1).strip()
    if verify_match:
        blocks["verify"] = verify_match.group(1).strip()
    if changelog_match:
        blocks["changelog"] = changelog_match.group(1).strip()
    return blocks

def save_output(task_name: str, blocks: dict) -> tuple[Path, Path]:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    task_id = task_name.replace(".md", "")
    
    patch_file = OUT_DIR / f"{task_id}_{ts}.patch"
    report_file = OUT_DIR / f"{task_id}_{ts}.report.md"
    
    if blocks["patch"]:
        patch_file.write_text(blocks["patch"])
    else:
        patch_file.write_text("# Ingen patch generert\n" + blocks["raw"])
    
    report = f"""# Codex Report: {task_name}
Generated: {datetime.now().isoformat()}

## Changelog
{blocks.get('changelog', 'N/A')}

## Verification Commands
```bash
{blocks.get('verify', '# Ingen verify-kommandoer')}
```

## How to Apply
```bash
cd {REPO_DIR}
git apply --check {patch_file}
git apply {patch_file}
```

## Raw Response
<details>
<summary>Full response</summary>

{blocks['raw']}

</details>
"""
    report_file.write_text(report)
    return patch_file, report_file

def copy_to_clipboard(text: str) -> bool:
    try:
        subprocess.run(["pbcopy"], input=text.encode(), check=True)
        return True
    except:
        return False

def save_fallback(prompt: str) -> Path:
    fallback = Path("/tmp/claude_prompt.txt")
    fallback.write_text(prompt)
    return fallback

# ============================================================================
# MAIN
# ============================================================================

def list_tasks():
    if not TASK_DIR.exists():
        print(f"⚠️  Task-mappe finnes ikke: {TASK_DIR}")
        return
    tasks = sorted(TASK_DIR.glob("*.md"))
    if not tasks:
        print(f"📂 Ingen tasks i {TASK_DIR}")
        return
    print(f"📂 Tasks i {TASK_DIR}:\n")
    for t in tasks:
        files = parse_files_block(t.read_text())
        print(f"  • {t.name} ({t.stat().st_size}b, {len(files)} vedlegg)")

def run_task(task_pattern: str, dry_run: bool = False):
    task_file = find_task_file(task_pattern)
    if not task_file:
        print(f"❌ Fant ikke task: {task_pattern}")
        list_tasks()
        return
    
    print(f"🔧 Task: {task_file.name}")
    prompt = build_prompt(task_file)
    tokens = estimate_tokens(prompt)
    print(f"📝 Prompt: ~{tokens} tokens ({len(prompt)} chars)")
    
    if dry_run:
        print("\n--- DRY RUN ---")
        if copy_to_clipboard(prompt):
            print("✅ Prompt kopiert til clipboard")
        print(f"📄 Lagret til: {save_fallback(prompt)}")
        return
    
    if get_api_key():
        response = call_claude_api(prompt)
        if response:
            blocks = extract_blocks(response)
            patch_file, report_file = save_output(task_file.name, blocks)
            print(f"\n✅ Output:")
            print(f"   📄 Patch:  {patch_file}")
            print(f"   📋 Report: {report_file}")
            if blocks["patch"]:
                print(f"\n🔍 Test: git apply --check {patch_file}")
            return
    
    print("\n⚠️  Ingen API-nøkkel (ANTHROPIC_API_KEY)")
    if copy_to_clipboard(prompt):
        print("✅ Prompt kopiert til clipboard")
    print(f"📄 Lagret til: {save_fallback(prompt)}")

def main():
    parser = argparse.ArgumentParser(description="ANVIL Codex Agent")
    parser.add_argument("--task", "-t", default="001_fix_pdf_export.md")
    parser.add_argument("--list", "-l", action="store_true")
    parser.add_argument("--dry-run", "-n", action="store_true")
    args = parser.parse_args()
    
    print("=" * 50)
    print("🤖 ANVIL Codex Agent")
    print("=" * 50)
    
    if args.list:
        list_tasks()
    else:
        run_task(args.task, args.dry_run)

if __name__ == "__main__":
    main()
AGENT_EOF

chmod +x "$AGENT_DIR/codex_agent.py"

# 3. Opprett P0 task
echo "📋 Oppretter P0 task (001_fix_pdf_export.md)..."
cat > "$TASKS_DIR/001_fix_pdf_export.md" << 'TASK_EOF'
# P0: Fix /api/export/pdf - Returner ekte PDF

## Problem
`/api/export/pdf` returnerer HTML i stedet for ekte PDF.
- Content-Type er feil (HTML i stedet for application/pdf)
- Body er HTML-dokument, ikke PDF-bytes

## Krav
1. Response header: `Content-Type: application/pdf`
2. Body: Ekte PDF-bytes (starter med `%PDF-`)
3. Ingen HTML fallback ved feil - returner JSON error i stedet

## Forventet løsning
- Bruk `pdf-lib` eller tilsvarende for å generere PDF
- Sett korrekte headers i Response
- Håndter errors gracefully (JSON, ikke HTML)

## Verifisering
```bash
curl -si "http://127.0.0.1:3001/api/export/pdf?id=test" | head -20
curl -s "http://127.0.0.1:3001/api/export/pdf?id=test" | head -c 8 | xxd
curl -s "http://127.0.0.1:3001/api/export/pdf?id=test" -o /tmp/test.pdf && file /tmp/test.pdf
```

FILES:
- app/api/export/pdf/route.ts
- package.json
TASK_EOF

# 4. Opprett P1 task
echo "📋 Oppretter P1 task (002_weekly_report_customerid.md)..."
cat > "$TASKS_DIR/002_weekly_report_customerid.md" << 'TASK_EOF'
# P1: Weekly Report - Robust customerId håndtering

## Problem
`POST /api/reports/weekly` feiler med "customerId is required".

## Krav
1. Støtt customerId fra flere kilder (prioritert):
   - Request body: `{ "customerId": "xxx" }`
   - Header: `x-customer-id: xxx`
   - Query param: `?customerId=xxx`
2. Gi tydelig feilmelding hvis ingen customerId finnes

## Verifisering
```bash
curl -X POST http://127.0.0.1:3001/api/reports/weekly -H "Content-Type: application/json" -d '{"customerId":"test"}'
curl -X POST http://127.0.0.1:3001/api/reports/weekly -H "x-customer-id: test"
curl -X POST "http://127.0.0.1:3001/api/reports/weekly?customerId=test"
```

FILES:
- app/api/reports/weekly/route.ts
- app/api/reports/weekly/list/route.ts
TASK_EOF

# 5. Opprett alias/wrapper
echo "🔗 Oppretter 'codex' alias..."
cat > "$AGENT_DIR/codex" << 'WRAPPER_EOF'
#!/usr/bin/env bash
cd "$(dirname "$0")"
python3 codex_agent.py "$@"
WRAPPER_EOF
chmod +x "$AGENT_DIR/codex"

# 6. Sjekk requests
echo ""
echo "🔍 Sjekker Python requests..."
if python3 -c "import requests" 2>/dev/null; then
    echo "   ✅ requests installert"
else
    echo "   ⚠️  requests mangler. Installer med:"
    echo "      pip install requests"
fi

# 7. Ferdig!
echo ""
echo "=============================================="
echo "✅ Setup ferdig!"
echo "=============================================="
echo ""
echo "📁 Struktur:"
echo "   $AGENT_DIR/"
echo "   ├── codex_agent.py    # Hovedscript"
echo "   ├── codex             # Wrapper (./codex)"
echo "   ├── claude_tasks/     # Task-filer"
echo "   │   ├── 001_fix_pdf_export.md"
echo "   │   └── 002_weekly_report_customerid.md"
echo "   └── claude_out/       # Output (patcher + rapporter)"
echo ""
echo "🚀 Bruk:"
echo "   cd $AGENT_DIR"
echo "   export ANTHROPIC_API_KEY='sk-...'"
echo "   ./codex --list              # Se tasks"
echo "   ./codex                     # Kjør P0 (default)"
echo "   ./codex --task 002_*        # Kjør P1"
echo "   ./codex --dry-run           # Bare generer prompt"
echo ""
echo "📋 Etter kjøring:"
echo "   git apply --check claude_out/*.patch"
echo "   git apply claude_out/*.patch"
echo ""
