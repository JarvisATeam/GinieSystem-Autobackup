#!/bin/bash
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
report=~/GinieSystem/Vault/InitProof/init_report_${timestamp}.txt

echo "🧠 AutoBevis kjøres: $timestamp" >> "$report"
echo "" >> "$report"
echo "📂 Earn-noder:" >> "$report"
ls -lt ~/GinieSystem/Earn/active | head -n 10 >> "$report"

# E-post
cat "$report" | msmtp -a default -t <<EOFMAIL
To: coolsen86@gmail.com
Subject: 🔥 Ginie AutoBevis
From: ginie.pro.ops@gmail.com

Logg og bevis for automatisk init:

$(cat "$report")
EOFMAIL

# WhatsApp-ping
~/GinieSystem/Scripts/whatsapp_alert.sh "🔥 AutoBevis kjørt og sendt. Tid: $timestamp"

echo "✅ Alt sendt: Mail, Vault, WhatsApp"
