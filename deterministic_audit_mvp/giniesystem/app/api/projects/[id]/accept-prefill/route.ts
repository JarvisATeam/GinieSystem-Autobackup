import { NextResponse } from "next/server";
import { acceptPrefill, readProjectBundle } from "@/lib/storage/projectsStore";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const bundle = readProjectBundle(id);
  const accepted = {
    assumptions: (body as { assumptions?: unknown }).assumptions ?? bundle.prefill.assumptions,
    line_items: (body as { line_items?: unknown }).line_items ?? bundle.prefill.line_items,
  };
  const project = acceptPrefill(id, accepted);
  return NextResponse.json({ ok: true, project, accepted_prefill: accepted });
}
