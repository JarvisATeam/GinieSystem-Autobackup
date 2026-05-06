"use client";

import React, { useEffect, useMemo, useState } from "react";

type Project = {
  id: string;
  name: string;
  customer_name: string;
  contact_person?: string;
  phone?: string;
  email?: string;
  job_summary: string;
  status: string;
  source_import_id: string;
  accepted_prefill?: unknown;
};

type Prefill = {
  project_id: string;
  assumptions: Record<string, unknown>;
  line_items: Array<{ name: string; hours: number }>;
  confidence: number;
};

export default function ProjectPage({ params }: { params: { id: string } }) {
  const id = params.id;
  const [project, setProject] = useState<Project | null>(null);
  const [prefill, setPrefill] = useState<Prefill | null>(null);
  const [msg, setMsg] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  async function load() {
    setErr(null);
    setMsg(null);
    const r1 = await fetch(`/api/projects/${id}`, { cache: "no-store" });
    if (!r1.ok) return setErr(`Prosjekt ikke funnet (${r1.status})`);
    const pj = await r1.json();
    setProject(pj);

    const r2 = await fetch(`/api/projects/${id}/prefill`, { cache: "no-store" });
    if (r2.ok) setPrefill(await r2.json());
  }

  useEffect(() => {
    load();
  }, [id]);

  const accepted = useMemo(() => project?.accepted_prefill || null, [project]);

  async function acceptNow() {
    if (!prefill) return;
    setErr(null);
    setMsg(null);
    const res = await fetch(`/api/projects/${id}/accept-prefill`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ assumptions: prefill.assumptions, line_items: prefill.line_items }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok || !data?.ok) return setErr(`Kunne ikke akseptere forslag (${data?.error || res.status})`);
    setMsg("✅ Prefill akseptert og lagret på prosjektet");
    await load();
  }

  return (
    <div style={{ maxWidth: 980, margin: "0 auto", padding: 18 }}>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 12, alignItems: "center" }}>
        <div>
          <div style={{ fontSize: 22, fontWeight: 800 }}>{project?.name || "Prosjekt"}</div>
          <div style={{ fontSize: 13, opacity: 0.8 }}>
            {project?.customer_name || ""} · status: {project?.status || ""} · import: {project?.source_import_id || ""}
          </div>
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <a
            href="/projects"
            style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ccc", textDecoration: "none" }}
          >
            ← Til prosjekter
          </a>
          <a
            href="/import"
            style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ccc", textDecoration: "none" }}
          >
            Importer
          </a>
        </div>
      </div>

      {msg && (
        <div style={{ marginTop: 12, padding: 12, borderRadius: 12, border: "1px solid #b7eb8f", background: "#f6ffed" }}>
          {msg}
        </div>
      )}
      {err && (
        <div style={{ marginTop: 12, padding: 12, borderRadius: 12, border: "1px solid #f2b8b5", background: "#fff1f0" }}>
          ❌ {err}
        </div>
      )}

      <div style={{ marginTop: 14, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        <div style={{ padding: 14, borderRadius: 14, border: "1px solid #ddd" }}>
          <div style={{ fontWeight: 800, marginBottom: 6 }}>Oppsummering</div>
          <div style={{ whiteSpace: "pre-wrap", fontSize: 14 }}>{project?.job_summary || ""}</div>
        </div>

        <div style={{ padding: 14, borderRadius: 14, border: "1px solid #ddd" }}>
          <div style={{ fontWeight: 800, marginBottom: 6 }}>Bestiller / kontakt</div>
          <div style={{ fontSize: 14 }}>
            <div><b>Kunde:</b> {project?.customer_name || ""}</div>
            <div><b>E-post:</b> {project?.email || "-"}</div>
            <div><b>Tlf:</b> {project?.phone || "-"}</div>
          </div>
        </div>

        <div style={{ padding: 14, borderRadius: 14, border: "1px solid #ddd" }}>
          <div style={{ fontWeight: 800, marginBottom: 6 }}>Kalkulator (prefill)</div>
          {prefill ? (
            <>
              <div style={{ fontSize: 13, opacity: 0.85, marginBottom: 10 }}>
                confidence: {(prefill.confidence ?? 0).toFixed(2)}
              </div>
              <div style={{ display: "grid", gap: 8 }}>
                {(prefill.line_items || []).map((line, idx) => (
                  <div
                    key={`${line.name}-${idx}`}
                    style={{ display: "flex", justifyContent: "space-between", border: "1px solid #eee", borderRadius: 10, padding: "8px 10px" }}
                  >
                    <span>{line.name}</span>
                    <b>{line.hours} t</b>
                  </div>
                ))}
              </div>
              <button onClick={acceptNow} style={{ marginTop: 12, padding: "9px 12px", borderRadius: 10, border: "1px solid #bbb" }}>
                Bruk forslag (lagre på prosjekt)
              </button>
            </>
          ) : (
            <div style={{ opacity: 0.8 }}>Ingen prefill funnet.</div>
          )}
        </div>

        <div style={{ padding: 14, borderRadius: 14, border: "1px solid #ddd" }}>
          <div style={{ fontWeight: 800, marginBottom: 6 }}>Akseptert prefill</div>
          {accepted ? (
            <pre style={{ whiteSpace: "pre-wrap", fontSize: 12, margin: 0 }}>{JSON.stringify(accepted, null, 2)}</pre>
          ) : (
            <div style={{ opacity: 0.8 }}>Ikke akseptert ennå.</div>
          )}
        </div>
      </div>
    </div>
  );
}
