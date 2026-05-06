import { NextResponse } from "next/server";
import { patchProject, readProjectBundle } from "@/lib/storage/projectsStore";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(_: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const bundle = readProjectBundle(id);
  return NextResponse.json(bundle.project);
}

export async function PATCH(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const allowed = ["name", "customer_name", "contact_person", "phone", "email", "job_summary", "status"] as const;

  const patch: Partial<Record<(typeof allowed)[number], unknown>> = {};
  for (const key of allowed) {
    if (key in body) patch[key] = body[key];
  }

  const project = patchProject(id, patch);
  return NextResponse.json({ ok: true, project });
}
