export function buildJobSummary(rawText: string): string {
  const lines = (rawText || "")
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line && !/generated|placeholder|draft/i.test(line));

  let summary = lines.slice(0, 10).join(" ");
  if (summary.length < 120) summary = `${summary} Dokument analysert automatisk – manuell gjennomgang anbefalt.`.trim();
  return summary.slice(0, 600);
}
