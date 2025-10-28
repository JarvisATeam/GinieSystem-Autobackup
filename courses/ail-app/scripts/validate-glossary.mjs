import { readFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const root = join(__dirname, "..", "public", "glossary.json");

const raw = await readFile(root, "utf8");
const glossary = JSON.parse(raw);

if (!glossary || typeof glossary !== "object") {
  throw new Error("glossary.json mangler eller er ugyldig");
}

const keys = Object.keys(glossary);
if (!keys.length) {
  throw new Error("glossary.json er tom");
}

console.log(`✅ Verifiserte ${keys.length} forkortelser`);
