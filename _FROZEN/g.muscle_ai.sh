#!/bin/bash
echo "🔍 Analyserer progresjon..."
awk -F, '{print \$2,\$3,\$4}' "$APP_DIR/train_log.csv" | sort | uniq -c | sort -nr | head
