import fs from "node:fs";
import path from "node:path";

export type ProjectStatus = "NEW" | "ONGOING" | "WON" | "LOST";

export type Project = {
  id: string;
  name: string;
  customer_name: string;
  contact_person?: string;
  phone?: string;
  email?: string;
  job_summary: string;
  source_import_id: string;
  status: ProjectStatus;
  created_at: string;
  updated_at: string;
  accepted_prefill?: unknown;
};

export type ProjectIntake = {
  project_id: string;
  extracted_fields: Record<string, unknown>;
  confidence_map: Record<string, unknown>;
  doc_text_preview: string;
  deliverables: string[];
  requirements: string[];
};

export type CalculatorPrefill = {
  project_id: string;
  assumptions: Record<string, unknown>;
  line_items: Array<{ name: string; hours: number }>;
  confidence: number;
};

function rootDir(): string {
  const root = process.env.ANVIL_DATA_ROOT || path.join(process.cwd(), "03_Workspace", "anvil_data");
  fs.mkdirSync(path.join(root, "projects"), { recursive: true });
  return root;
}

function projPath(id: string) {
  return path.join(rootDir(), "projects", `${id}.json`);
}

export function listProjects(): Project[] {
  const dir = path.join(rootDir(), "projects");
  const files = fs.readdirSync(dir).filter((file) => file.endsWith(".json"));
  const rows: Project[] = [];
  for (const file of files) {
    const raw = fs.readFileSync(path.join(dir, file), "utf8");
    const obj = JSON.parse(raw);
    if (obj?.project) rows.push(obj.project);
  }
  rows.sort((a, b) => (b.updated_at || "").localeCompare(a.updated_at || ""));
  return rows;
}

export function readProjectBundle(
  id: string,
): { project: Project; intake: ProjectIntake; prefill: CalculatorPrefill } {
  const raw = fs.readFileSync(projPath(id), "utf8");
  return JSON.parse(raw);
}

export function writeProjectBundle(bundle: {
  project: Project;
  intake: ProjectIntake;
  prefill: CalculatorPrefill;
}) {
  fs.writeFileSync(projPath(bundle.project.id), JSON.stringify(bundle, null, 2), "utf8");
}

export function patchProject(id: string, patch: Partial<Project>) {
  const bundle = readProjectBundle(id);
  bundle.project = { ...bundle.project, ...patch, updated_at: new Date().toISOString() };
  writeProjectBundle(bundle);
  return bundle.project;
}

export function acceptPrefill(id: string, accepted: unknown) {
  const bundle = readProjectBundle(id);
  bundle.project.accepted_prefill = accepted;
  bundle.project.updated_at = new Date().toISOString();
  writeProjectBundle(bundle);
  return bundle.project;
}
