import React from "react";
import { createRoot } from "react-dom/client";
import GlossaryHint from "./src/GlossaryHint.jsx";
import "./src/base.css";

function App() {
  return (
    <main>
      <h1>AIL kursinnhold</h1>
      <p>
        Denne demoklienten viser hvordan forkortelser automatisk får forklaring fra ordboken.
      </p>
      <section>
        <p>
          Moderne KI-systemer kombinerer <strong>ML</strong> og <strong>NLP</strong> i en <strong>LLM</strong>.
          Når løsningen implementeres som en <strong>PWA</strong> kan brukeren oppleve både <strong>API</strong>-drevet
          automatisering og <strong>RAG</strong> som gir svar med kilder.
        </p>
      </section>
      <GlossaryHint />
    </main>
  );
}

const container = document.getElementById("root");
if (container) {
  createRoot(container).render(<App />);
}
