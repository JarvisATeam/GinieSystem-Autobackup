"use client";

import React, { useEffect, useState } from "react";

type Project = {
  id: string;
  name: string;
  customer_name: string;
  status: string;
  updated_at: string;
};

export default function ProjectsPage() {
  const [rows, setRows] = useState<Project[]>([]);
  const [err, setErr] = useState<string | null>(null);

  async function load() {
    setErr(null);
    const res = await fetch("/api/projects", { cache: "no-store" });
    if (!res.ok) return setErr(`Kunne ikke hente prosjekter (${res.status})`);
    const data = await res.json();
    setRows(Array.isArray(data) ? data : []);
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <div style={{ maxWidth: 900, margin: "0 auto", padding: 18 }}>
      <h1 style={{ fontSize: 22, fontWeight: 700 }}>Pågående prosjekter</h1>
      <div style={{ marginTop: 10, display: "flex", gap: 10 }}>
        <a
          href="/import"
          style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ccc", textDecoration: "none" }}
        >
          Importer dokument
        </a>
        <button onClick={load} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ccc" }}>
          Oppdater
        </button>
      </div>

      {err && (
        <div style={{ marginTop: 14, padding: 12, borderRadius: 12, border: "1px solid #f2b8b5", background: "#fff1f0" }}>
          ❌ {err}
        </div>
      )}

      <div style={{ marginTop: 14, display: "grid", gap: 10 }}>
        {rows.map((project) => (
          <a key={project.id} href={`/projects/${project.id}`} style={{ textDecoration: "none", color: "inherit" }}>
            <div style={{ padding: 12, borderRadius: 14, border: "1px solid #ddd" }}>
              <div style={{ fontWeight: 700 }}>{project.name}</div>
              <div style={{ fontSize: 13, opacity: 0.8 }}>
                {project.customer_name} · {project.status} · {new Date(project.updated_at).toLocaleString()}
              </div>
            </div>
          </a>
        ))}
        {rows.length === 0 && (
          <div style={{ padding: 12, borderRadius: 14, border: "1px dashed #ccc", opacity: 0.85 }}>
            Ingen prosjekter ennå. Gå til Import og analyser et dokument.
          </div>
        )}
      </div>
    </div>
  );
}
