import { NextResponse } from "next/server";
import { engine } from "@/lib/engine";
import { createProjectFromImport } from "@/lib/project/createProjectFromImport";
import { writeProjectBundle } from "@/lib/storage/projectsStore";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function json400(error: string, extra?: Record<string, unknown>) {
  return NextResponse.json({ ok: false, error, ...(extra || {}) }, { status: 400 });
}

function looksLikePdfStructureText(text: string): boolean {
  const sample = (text || "").slice(0, 3000);
  return /%PDF-|\/XRef|xref|obj|endobj|stream|endstream/i.test(sample);
}

export async function POST(req: Request) {
  try {
    const contentType = (req.headers.get("content-type") || "").toLowerCase();
    if (!contentType.includes("multipart/form-data")) {
      return json400("Invalid upload: expected multipart/form-data");
    }

    const form = await req.formData().catch(() => null);
    if (!form) return json400("Invalid upload: unreadable form-data payload");

    const fileEntry = form.get("file");
    if (!(fileEntry instanceof File)) {
      return json400("Invalid upload: missing form-data field 'file'");
    }
    if (fileEntry.size === 0) return json400("Invalid upload: file is empty");

    const file = fileEntry;
    const filename = file.name || "upload.bin";
    const buffer = Buffer.from(await file.arrayBuffer());

    const record = await engine.process(buffer, filename);

    const raw = String((record as { raw_text?: unknown })?.raw_text || "");
    const structural = looksLikePdfStructureText(raw);
    const tooShort = raw.trim().length < 40;
    const lowConf = Number((record as { confidence?: unknown })?.confidence || 0) < 0.15;

    if (structural || (tooShort && lowConf)) {
      return json400("PDF_PARSE_FAILED", {
        hint: "Dokumentet ser ut som korrupt/skannet/beskyttet PDF. Prøv Print→Save as PDF eller OCR før import.",
        meta: {
          structural,
          tooShort,
          lowConf,
          raw_len: raw.length,
          confidence: (record as { confidence?: unknown })?.confidence ?? null,
        },
      });
    }

    const import_id = String((record as { id?: unknown })?.id || `${Date.now()}_${Math.random().toString(16).slice(2)}`);
    const bundle = createProjectFromImport({ import_id, record });
    writeProjectBundle(bundle);

    return NextResponse.json({
      ok: true,
      id: import_id,
      record,
      project_id: bundle.project.id,
    });
  } catch (error: unknown) {
    console.error("[ANVIL:API] Import error:", error);
    return NextResponse.json(
      { ok: false, error: "IMPORT_FAILED", detail: String((error as { message?: unknown })?.message || error) },
      { status: 500 },
    );
  }
}
