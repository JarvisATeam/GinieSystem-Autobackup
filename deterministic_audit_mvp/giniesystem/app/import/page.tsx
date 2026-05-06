"use client";

import React, { useState } from "react";

export default function ImportPage() {
  const [file, setFile] = useState<File | null>(null);
  const [resp, setResp] = useState<Record<string, unknown> | null>(null);
  const [busy, setBusy] = useState(false);

  async function run() {
    if (!file) return;
    setBusy(true);
    setResp(null);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await fetch("/api/import", { method: "POST", body: fd });
      const data = await res.json().catch(() => ({}));
      setResp({ status: res.status, ...data });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ maxWidth: 820, margin: "0 auto", padding: 18 }}>
      <h1 style={{ fontSize: 22, fontWeight: 800 }}>Import</h1>

      <div style={{ marginTop: 10, display: "flex", gap: 10, alignItems: "center" }}>
        <input type="file" accept=".pdf,.txt" onChange={(event) => setFile(event.target.files?.[0] || null)} />
        <button onClick={run} disabled={!file || busy} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #bbb" }}>
          {busy ? "Jobber..." : "Analyser fil"}
        </button>
        <a
          href="/projects"
          style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ccc", textDecoration: "none" }}
        >
          Pågående prosjekter
        </a>
      </div>

      {resp && (
        <div style={{ marginTop: 14, padding: 12, borderRadius: 12, border: "1px solid #ddd" }}>
          <div style={{ fontWeight: 700 }}>
            {resp.ok ? "✅ Import OK" : "❌ Analyse feilet"} (HTTP {resp.status as number})
          </div>

          {resp.project_id && (
            <div style={{ marginTop: 10 }}>
              <a
                href={`/projects/${resp.project_id}`}
                style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #bbb", textDecoration: "none", display: "inline-block" }}
              >
                Åpne prosjekt
              </a>
            </div>
          )}

          <pre style={{ whiteSpace: "pre-wrap", fontSize: 12, marginTop: 10 }}>{JSON.stringify(resp, null, 2)}</pre>

          <div style={{ marginTop: 10 }}>
            <button
              onClick={() => navigator.clipboard.writeText(JSON.stringify(resp, null, 2))}
              style={{ padding: "8px 12px", borderRadius: 8, border: "1px solid #bbb" }}
            >
              Kopier JSON
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
