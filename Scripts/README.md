# Scripts Overview

## `nanotech_autonomous_loop_setup.sh`
Bootstraps a local demonstration of the Thor/Loki/Heimdal loop, the Core ethics
gateway, and cleanup automation inside a sandbox directory. Run it from the repo
root to create the structure under `NanotechAutonomousLoop/` or pass a custom
base directory path.

The generated scaffolding mirrors Captein's notes, including:
- `Core/CoreEthics.json`, `ethics_guard.py`, and `ollama_gateway.sh`
- Thor/Loki/Heimdal mission exchange folders with sample project data
- Cleanup agent scripts and a launchd plist template
- Documentation in `Docs/Nanotech_AutonomousLoop_README.md`

The script is idempotent, so re-running it safely refreshes the demo without
modifying files outside the chosen base directory.
