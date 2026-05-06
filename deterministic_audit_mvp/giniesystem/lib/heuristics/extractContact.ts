export function extractContact(rawText: string): { email?: string; phone?: string } {
  const text = rawText || "";
  const email = text.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i)?.[0];
  const phone = text.match(/(\+47\s?)?\d{8}/)?.[0];
  return { email, phone };
}
