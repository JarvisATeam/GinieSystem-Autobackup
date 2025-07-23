import os, requests, sqlite3
from bs4 import BeautifulSoup
from tqdm import tqdm

DEST = os.path.expanduser("~/GinieSystem/Vault/Knowledge/raw/")
DB = os.path.expanduser("~/GinieSystem/Vault/Knowledge/db/books.db")

# Enkel bokliste fra Gutenberg
book_urls = [
    "https://www.gutenberg.org/files/1342/1342-0.txt",  # Pride and Prejudice
    "https://www.gutenberg.org/files/11/11-0.txt",      # Alice in Wonderland
    "https://www.gutenberg.org/files/1661/1661-0.txt",  # Sherlock Holmes
]

os.makedirs(DEST, exist_ok=True)
os.makedirs(os.path.dirname(DB), exist_ok=True)

# Last ned bøker
for url in tqdm(book_urls, desc="📚 Laster ned bøker"):
    filename = os.path.join(DEST, url.split('/')[-1])
    if not os.path.exists(filename):
        r = requests.get(url)
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(r.text)

# Lag database
conn = sqlite3.connect(DB)
c = conn.cursor()
c.execute('''CREATE TABLE IF NOT EXISTS books (id INTEGER PRIMARY KEY, title TEXT, path TEXT)''')

for fname in os.listdir(DEST):
    title = fname.replace(".txt", "")
    full_path = os.path.join(DEST, fname)
    c.execute("INSERT INTO books (title, path) VALUES (?, ?)", (title, full_path))

conn.commit()
conn.close()
print("✅ Ferdig! Bøker lagt inn i databasen.")
