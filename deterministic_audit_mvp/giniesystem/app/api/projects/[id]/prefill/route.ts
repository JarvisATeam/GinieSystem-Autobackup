import { NextResponse } from "next/server";
import { readProjectBundle } from "@/lib/storage/projectsStore";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(_: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const bundle = readProjectBundle(id);
  return NextResponse.json(bundle.prefill);
}
