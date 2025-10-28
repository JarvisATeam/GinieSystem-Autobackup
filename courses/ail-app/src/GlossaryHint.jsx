import React, { useEffect, useState } from "react";

const BADGE_STYLE = {
  display: "inline-block",
  padding: "2px 8px",
  borderRadius: "8px",
  background: "rgba(0,0,0,0.08)",
  marginRight: "6px",
  fontWeight: 600,
};

const WRAPPER_STYLE = {
  marginTop: 12,
  padding: "12px 16px",
  borderRadius: 12,
  background: "linear-gradient(135deg, rgba(255,255,255,0.85), rgba(230,239,255,0.85))",
  boxShadow: "0 4px 12px rgba(0,0,0,0.08)",
};

export default function GlossaryHint() {
  const [glossary, setGlossary] = useState({});
  const [found, setFound] = useState([]);

  useEffect(() => {
    let cancelled = false;
    fetch("/glossary.json")
      .then((response) => response.json())
      .then((data) => {
        if (!cancelled) {
          setGlossary(data);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setGlossary({});
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!Object.keys(glossary).length) {
      setFound([]);
      return;
    }
    const text = document.body?.innerText ?? "";
    const hits = new Set();
    Object.keys(glossary).forEach((key) => {
      const expression = new RegExp(`\\b${key}\\b`, "g");
      if (expression.test(text)) {
        hits.add(key);
      }
    });
    setFound(Array.from(hits));
  }, [glossary]);

  if (!found.length) {
    return null;
  }

  return (
    <div style={WRAPPER_STYLE}>
      <strong>Forkortelser på denne siden</strong>
      <ul style={{ margin: "8px 0 0 16px" }}>
        {found.sort().map((key) => (
          <li key={key} style={{ marginBottom: 4 }}>
            <span style={BADGE_STYLE}>{key}</span>
            {glossary[key]}
          </li>
        ))}
      </ul>
    </div>
  );
}
