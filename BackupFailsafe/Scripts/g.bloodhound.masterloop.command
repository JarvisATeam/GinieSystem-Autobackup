#!/bin/bash
echo "🚀 Starter GINIE BLOODHOUND SYSTEMLOOP..."
LOOPDIR="$HOME/GinieSystem/Recovery/BloodhoundScan"
SCRIPTDIR="$HOME/GinieSystem/Scripts"
mkdir -p "$LOOPDIR"
echo "[START] $(date)" > "$LOOPDIR/loop_log.txt"

bash "$SCRIPTDIR/g.bloodhound.scan.sh"

# Her kan du legge til flere kall til:
# g.docify.iterate.sh, g.loop.evolve.sh, g.master.specgen.sh

echo "[DONE] $(date)" >> "$LOOPDIR/loop_log.txt"
open "$LOOPDIR"
