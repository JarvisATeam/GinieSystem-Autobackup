#!/bin/bash
LANG="${1:-nb}"
MSG="AI reflekterer over seg selv..."

case "$LANG" in
  en) MSG="AI reflects upon itself..." ;;
  da) MSG="AI reflekterer over sig selv..." ;;
  es) MSG="La IA reflexiona sobre sí misma..." ;;
  fr) MSG="L'IA se réfléchit elle-même..." ;;
  de) MSG="KI reflektiert über sich selbst..." ;;
esac

echo "$(date '+%F %T') – $MSG" >> ~/GinieSystem/Vault/Reflections/multilang_reflection.log
