# Best Hermes Version

Use **Hermes 4.3 36B** as the default "best Hermes" model for local/private inference.

## Recommendation

| Use case | Pick | Why |
| --- | --- | --- |
| Best balanced local Hermes model | `NousResearch/Hermes-4.3-36B-GGUF` with `hermes-4_3_36b-Q4_K_M.gguf` | Current flagship Hermes 4.3 model; Q4_K_M is the practical quality/size balance at ~21.8 GB. |
| Higher quality if you have more VRAM/disk | `hermes-4_3_36b-Q5_K_M.gguf` or `Q6_K` | Better quantization quality, but larger downloads and memory use. |
| Smallest practical 4.3 option | `hermes-4_3_36b-Q3_K_M.gguf` | Lower memory/disk use at the cost of output quality. |
| Hermes Agent app/runtime | Latest official release `v2026.4.30` | Latest GitHub release at the time this repository note was updated. |

## Source notes

- Nous Research describes Hermes 4.3 as an update to its flagship Hermes series, based on Seed-OSS-36B-Base, with up to 512K context and near Hermes 4 70B performance at roughly half the parameter count.
- The Hugging Face Hermes 4 collection lists `NousResearch/Hermes-4.3-36B` and `NousResearch/Hermes-4.3-36B-GGUF` ahead of the earlier Hermes 4 variants.
- The official GGUF repository provides `Q3_K_M`, `Q4_K_M`, `Q5_K_M`, `Q6_K`, `Q8_0`, and full GGUF files; `Q4_K_M` is the recommended default for this repo because it is the smallest quantization that still preserves strong model behavior for everyday agent use.
- The Hermes Agent GitHub latest release resolves to `v2026.4.30` / Hermes Agent `v0.12.0`.

## Quick command

From the repository root, use:

```bash
Scripts/get_best_hermes.sh info
```

To download the recommended official GGUF and create an Ollama model when the required tools are installed:

```bash
Scripts/get_best_hermes.sh download
Scripts/get_best_hermes.sh ollama
```

The script defaults to storing the GGUF under `${HOME}/.cache/ginie/hermes` and names the local Ollama model `hermes-4.3-36b:q4_k_m`.
