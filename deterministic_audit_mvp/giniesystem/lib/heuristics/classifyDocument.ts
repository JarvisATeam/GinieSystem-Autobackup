export type DocCategory = "AUTOMATION" | "GENERIC";
export type DocType = "PROPOSAL" | "RFP" | "GENERIC";

export function classifyDocument(rawText: string): { category: DocCategory; docType: DocType } {
  const t = (rawText || "").toLowerCase();
  const category: DocCategory = /scada|plc|alarm|dashboard|hmi/.test(t) ? "AUTOMATION" : "GENERIC";
  const docType: DocType =
    /proposal|tilbud|scope|deliverables/.test(t) ? "PROPOSAL" :
    /requirement|shall|must|krav/.test(t) ? "RFP" :
    "GENERIC";
  return { category, docType };
}
