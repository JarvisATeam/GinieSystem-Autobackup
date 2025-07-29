#!/bin/bash

YAML=~/GinieSystem/Workflow/workflow.map.yml
OUT=~/GinieSystem/Workflow/Dashboard/flow_dashboard.html
NOW=$(date '+%Y-%m-%d %H:%M:%S')

echo "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Ginie Flow Dashboard</title></head><body style='font-family:sans-serif;background:#111;color:#0f0;padding:2em;'>" > $OUT
echo "<h1>🧠 Ginie Flow Dashboard</h1><p><b>Tid:</b> $NOW</p><hr>" >> $OUT

echo "<pre style='font-size:14px;'>" >> $OUT
cat $YAML >> $OUT
echo "</pre>" >> $OUT

echo "<p style='color:#888;'>Automatisk generert av GinieSystem</p></body></html>" >> $OUT

echo "✅ Flow dashboard generert: $OUT"
