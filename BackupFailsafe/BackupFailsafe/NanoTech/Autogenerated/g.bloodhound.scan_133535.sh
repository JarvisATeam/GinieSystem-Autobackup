# Improved: g.bloodhound.scan.sh ons. 23 jul. 2025 13.35.35 CEST
##!/bin/bash
SCAN_DIR="$HOME/GinieSystem/Recovery/BloodhoundScan"
mkdir -p "$SCAN_DIR"
cd "$SCAN_DIR" || exit 1
echo "🧠 Starter GINIE BLOODHOUND SCAN..."

find /Volumes/GinieUSB "/Users/$USER" ~/Library/Mobile\ Documents/com~apple~CloudDocs -type f \
  \( -iname "*.vault" -o -iname "*.bat" -o -iname "*.command" -o -iname "*.sh" \
  -o -iname "*.md" -o -iname "*.log" -o -iname "*.spec" -o -iname "*.png" \
  -o -iname "*.json" -o -iname "*.m4a" -o -iname "*.wav" -o -iname "*.txt" \) \
  2>/dev/null | tee all_ginie_files.list

echo "[" > ginie_scan_index.json
first=true
while read -r file; do
  size=$(stat -f%z "$file" 2>/dev/null)
  mod=$(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$file" 2>/dev/null)
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> ginie_scan_index.json
  fi
  printf '  {"path": "%s", "size": %s, "lastmod": "%s"}' "$file" "$size" "$mod" >> ginie_scan_index.json
done < all_ginie_files.list
echo "" >> ginie_scan_index.json
echo "]" >> ginie_scan_index.json
cp all_ginie_files.list GinieFileList.txt
echo "✅ GINIE BLOODHOUND SCAN FULLFØRT."
