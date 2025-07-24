#!/bin/bash
SCRIPT="$1"; LINE="$2"
cp "$SCRIPT" "$SCRIPT.bak"
[ -n "$LINE" ] && nano +$LINE "$SCRIPT" || nano "$SCRIPT"
echo "🔁 Diff:"
diff "$SCRIPT.bak" "$SCRIPT" || echo "✅ Ingen endringer"
