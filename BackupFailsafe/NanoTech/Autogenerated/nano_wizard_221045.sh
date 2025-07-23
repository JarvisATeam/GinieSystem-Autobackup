# Improved: nano_wizard.sh ons. 23 jul. 2025 22.10.45 CEST
##!/bin/bash
SCRIPT="$1"; LINE="$2"
cp "$SCRIPT" "$SCRIPT.bak"
[ -n "$LINE" ] && nano +$LINE "$SCRIPT" || nano "$SCRIPT"
echo "🔁 Diff:"
diff "$SCRIPT.bak" "$SCRIPT" || echo "✅ Ingen endringer"
