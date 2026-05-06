export type PrefillLineItem = { name: string; hours: number };

export function buildCalculatorPrefill(deliverables: string[] | undefined) {
  const map = [
    { re: /scada/i, name: "SCADA-integrasjon", hours: 120 },
    { re: /dashboard/i, name: "Dashboard-utvikling", hours: 80 },
    { re: /alarm/i, name: "Alarm-konfigurasjon", hours: 40 },
    { re: /plc/i, name: "PLC-arbeid", hours: 60 },
  ];

  const items: PrefillLineItem[] = [];
  for (const deliverable of deliverables || []) {
    const hit = map.find((entry) => entry.re.test(deliverable));
    if (hit) items.push({ name: hit.name, hours: hit.hours });
  }
  if (items.length === 0) items.push({ name: "Prosjektering", hours: 40 });

  return {
    assumptions: {
      hourly_rate: 1200,
      margin_target: 0.35,
      risk_buffer_hours: 0.15,
    },
    line_items: items,
  };
}
