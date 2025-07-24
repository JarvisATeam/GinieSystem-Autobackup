#!/bin/bash
echo "🧹 Rydder opp cronjobber med overflødig varsling og dubletter..."

TMPFILE=$(mktemp)
crontab -l > "$TMPFILE"

# Fjern duplikater og overflødige "hver 10. minutt"-jobber
awk '!seen[$0]++' "$TMPFILE" | grep -v -E 'telegram_listen|ginie_mailproof.sh|g.auto_ramwatch.sh' > "$TMPFILE.cleaned"

# Legg inn smartere varsling ved feil
echo '*/10 * * * * bash ~/GinieSystem/Scripts/ginie_mailproof.sh || echo "Feil i mailproof" | mail -s "Feil i mailproof" you@example.com' >> "$TMPFILE.cleaned"
echo '*/10 * * * * bash ~/GinieSystem/Agents/g.mailreader/g.mailreader.sh || echo "Feil i mailreader" | mail -s "Feil i mailreader" you@example.com' >> "$TMPFILE.cleaned"

# Oppdater crontab
crontab "$TMPFILE.cleaned"
rm "$TMPFILE" "$TMPFILE.cleaned"
echo "✅ Cronjobber er nå renset og optimalisert."
