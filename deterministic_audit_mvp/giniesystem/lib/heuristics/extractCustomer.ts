export function extractCustomer(rawText: string): { name: string; confidence: number } {
  const text = rawText || "";

  const m = text.match(/([A-ZÆØÅ][A-Za-zÆØÅ0-9& ]+)\s+(AS|ASA|AB|OY|GMBH)\b/);
  if (m) return { name: `${m[1].trim()} ${m[2].trim()}`, confidence: 0.9 };

  if (/eramet/i.test(text)) return { name: "Eramet", confidence: 0.9 };
  if (/northern punching/i.test(text)) return { name: "Northern Punching", confidence: 0.9 };
  if (/weldone/i.test(text)) return { name: "WELDONE", confidence: 0.9 };

  const m2 = text.match(/(kunde|client|customer)\s*:\s*(.+)/i);
  if (m2 && m2[2]) return { name: m2[2].trim().slice(0, 120), confidence: 0.7 };

  return { name: "Ukjent kunde", confidence: 0.2 };
}
