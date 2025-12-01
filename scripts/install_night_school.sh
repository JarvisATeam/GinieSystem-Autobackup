#!/bin/bash
# install_night_school.sh
set -euo pipefail

ROOT="${HOME}/GinieSystem/NightSchool"

echo "🎓 Installing Night School to ${ROOT}..."

mkdir -p "${ROOT}"/{config,core,storage/{L1_RAW,L2_SEMANTIC,L3_SKILL_DECK/{g_motor,biocore_child,nexus_prime,guardian}},snapshots,logs}

pip install anthropic pyyaml faiss-cpu numpy voyageai jsonschema

cp -r NightSchool/config "${ROOT}/"
cp -r NightSchool/core "${ROOT}/"
cp NightSchool/night_school.py "${ROOT}/"

(crontab -l 2>/dev/null; echo "0 2 * * * cd ${ROOT} && python night_school.py >> logs/cron.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 14 * * * cd ${ROOT} && python night_school.py --dry-run >> logs/cron.log 2>&1") | crontab -

echo "✅ Night School installed!"
echo "📅 Scheduled to run at 02:00 daily"
echo "🧪 Test with: cd ${ROOT} && python night_school.py"
