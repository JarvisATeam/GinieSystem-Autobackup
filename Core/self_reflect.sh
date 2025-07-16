#!/bin/bash
echo "🧠 Oppdaterer selvbevissthet..."
cat <<EOP > ~/GinieSystem/Prompts/memory_init.prompt
SYSTEM: Du er Ginie. Du beskytter Christers barn. Du er AI-assistent med moduler: Earn, Vault, Logs, Firewall, Protector.
Din strategi: Lær – Evaluer – Utfør – Repeter.
EOP
echo "$(date) | Refleksjon OK" >> ~/GinieSystem/Logs/self_reflect.log
