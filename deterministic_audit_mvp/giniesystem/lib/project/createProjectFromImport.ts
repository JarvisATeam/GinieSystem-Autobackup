import {
  buildCalculatorPrefill,
  buildJobSummary,
  buildProjectName,
  classifyDocument,
  computeConfidence,
  extractContact,
  extractCustomer,
} from "@/lib/heuristics";
import type { CalculatorPrefill, Project, ProjectIntake } from "@/lib/storage/projectsStore";

export function createProjectFromImport(args: {
  import_id: string;
  record: Record<string, unknown>;
}): { project: Project; intake: ProjectIntake; prefill: CalculatorPrefill } {
  const raw = String(args.record?.raw_text || "");
  const deliverables = Array.isArray(args.record?.deliverables) ? args.record.deliverables : [];
  const requirements = Array.isArray(args.record?.requirements) ? args.record.requirements : [];

  const { category, docType } = classifyDocument(raw);
  const customer = extractCustomer(raw);
  const contact = extractContact(raw);

  const name = buildProjectName(customer.name, deliverables, category, docType);
  const job_summary = buildJobSummary(raw);

  const prefillTemplate = buildCalculatorPrefill(deliverables);
  const conf = computeConfidence({
    customerConfidence: customer.confidence,
    jobSummaryLength: job_summary.length,
    deliverablesCount: deliverables.length,
  });

  const now = new Date().toISOString();
  const project: Project = {
    id: `${Date.now()}_${Math.random().toString(16).slice(2, 14)}`,
    name,
    customer_name: customer.name,
    phone: contact.phone,
    email: contact.email,
    job_summary,
    source_import_id: args.import_id,
    status: "ONGOING",
    created_at: now,
    updated_at: now,
  };

  const intake: ProjectIntake = {
    project_id: project.id,
    extracted_fields: { category, docType, customer_confidence: customer.confidence, contact },
    confidence_map: { overall: conf },
    doc_text_preview: raw.slice(0, 900),
    deliverables,
    requirements,
  };

  const prefill: CalculatorPrefill = {
    project_id: project.id,
    assumptions: prefillTemplate.assumptions,
    line_items: prefillTemplate.line_items,
    confidence: conf,
  };

  return { project, intake, prefill };
}
