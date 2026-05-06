export function buildProjectName(customer: string, deliverables: string[] | undefined, category: string, docType: string): string {
  const top = (deliverables && deliverables[0]) ? deliverables[0] : (category || docType || "Prosjekt");
  return `${customer} – ${top}`.slice(0, 140);
}
