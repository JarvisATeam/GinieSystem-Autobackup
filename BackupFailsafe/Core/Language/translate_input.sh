#!/bin/bash
INPUT="$1"
LANG="${2:-nb}" # default: norsk

case "$LANG" in
  en) echo "Translating to English: $INPUT" ;;
  da) echo "Oversætter til dansk: $INPUT" ;;
  es) echo "Traduciendo al español: $INPUT" ;;
  fr) echo "Traduction en français: $INPUT" ;;
  de) echo "Übersetze ins Deutsche: $INPUT" ;;
  nb|*) echo "Oversetter til norsk: $INPUT" ;;
esac
