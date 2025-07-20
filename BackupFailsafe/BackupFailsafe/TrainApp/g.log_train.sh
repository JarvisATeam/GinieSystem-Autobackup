#!/bin/bash
echo "📈 Treningslogg:"
column -s, -t < "$APP_DIR/train_log.csv" | less
