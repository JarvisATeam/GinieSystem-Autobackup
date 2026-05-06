import { NextResponse } from "next/server";
import { listProjects } from "@/lib/storage/projectsStore";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  const rows = listProjects();
  return NextResponse.json(rows);
}
