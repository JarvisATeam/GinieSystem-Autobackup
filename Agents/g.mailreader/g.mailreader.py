import imaplib, email from email.header 
import decode_header import os from datetime 
import datetime user = os.popen("gpg 
--decrypt ~/.mailuser.gpg").read().strip() 
password = os.popen("gpg --decrypt 
~/.mailpass.gpg").read().strip() imap_server 
= "imap.gmail.com" logfile = 
os.path.expanduser("~/GinieSystem/Logs/g.mailreader.log") 
def log(msg):
    with open(logfile, "a") as f:
        
f.write(f"[{datetime.now().isoformat()}] 
{msg}\n") try:
    mail = imaplib.IMAP4_SSL(imap_server) 
    mail.login(user, password) 
    mail.select("inbox") status, messages = 
    mail.search(None, "UNSEEN") messages = 
    messages[0].split() if not messages:
        log("Ingen nye e-poster.") exit()
    for num in messages:
        status, data = mail.fetch(num, 
"(RFC822)")
        raw = 
email.message_from_bytes(data[0][1])
        subject, encoding = 
decode_header(raw["Subject"])[0]
        if isinstance(subject, bytes):
            subject = 
subject.decode(encoding or "utf-8", 
errors="ignore")
        subject_l = subject.lower() if 
        "casino" in subject_l:
            folder = "casino"
        elif "workflow" in subject_l:
            folder = "workflow"
        elif "api" in subject_l or "token" 
in subject_l:
            folder = "api_tokens"
        elif "regning" in subject_l or 
"invoice" in subject_l:
            folder = "regninger"
        elif "abonnement" in subject_l or 
"subscription" in subject_l:
            folder = "abonnement"
        else:
            folder = "ukjent"
        log(f" {subject} {folder}") 
        mail.copy(num, folder) 
        mail.store(num, '+FLAGS', 
        '\\Deleted')
    mail.expunge() mail.logout() except 
Exception as e:
    log(f" Feil: {e}")
