# Small / mini / lite models for MDLP — placement map + model picks

**Date:** 2026-07-28 · **Method:** 110-agent deep-research harness (27 sources fetched, 131 claims extracted, 74 adversarial refute-votes — 1 claim killed) + the MDLP/TA placement analysis from the 2026-07-28 session. *Note: the harness's final synthesis step misfired (returned a placeholder); this report was reconstructed directly from the verified journal — claim provenance is per-source model cards/repos (HF, GitHub) with blog aggregators as secondary.*
**Status:** study document — ungated. Library changes it implies (optional extras) are IMPLEMENTATION-v2-level advisories; anything touching gated artifacts flows L-010.

## 1. Where small models plug into MDLP (the placement map)

Structural fact first: **MDLP already has a pluggable embedding interface with no provider behind it.** TA's `growth.py` states "this module never assumes a specific embedding model"; the corpus is "embedding-free"; `LocalVectorStore` is dim-agnostic. So this is *plug a provider in*, not redesign — and the `weight = [torch, transformers, peft, trl]` optional extra already exists.

One embedding model lights up six currently-dark consumers: **VectorStore population** (skills/lessons/failures), **B1 misconception clustering** (τ_coh cosine), **B3 skill transfer** (sim_bar), **§16/R1 `sim` feature**, **§5.1 growth merge** (τ_merge, currently fail-closed), **§15 "new connection" trigger**. A reranker is an optional quality upgrade inside R1's semantic path (R1's fusion reranker itself is a learned linear over 5 features — no neural model required). A small generative LLM has three roles: the **fine-tunable open-weights student** for the M2 weight axis (the profile's own resolution: "Claude-as-student ⇒ no general fine-tuning ⇒ open-weights student or skip"), a **cheap Teacher/judge** (§13, schema-validated verdicts — proposes, never arbitrates; the statistical gate stays the judge), and **§17/G2 proposal generation** (frontier).

**Where small models do NOT belong:** the M0/M1 student stays Claude (a weak student is a different experiment); A5 warm-start's learner similarity needs **anchor-set response vectors, not a text embedder** (its RC-7 rule — and note the TA audit found A5's RC-7 guards buggy independently); and nothing model-based may enter the pure-stdlib core — extras only.

## 2. Category A — sentence embeddings

| Model | Params / dim | License | Quality (MTEB) | CPU story |
|---|---|---|---|---|
| **all-MiniLM-L6-v2** ⭐ default | 22M / 384 | Apache-2.0 | 55.93 avg (the reference point) | sentence-transformers, ONNX; the canonical CPU baseline |
| **Model2Vec potion-base-32M** ⭐ zero-infra tier | 32.3M static / — (~30MB) | MIT | 52.13 avg = **93.2% of MiniLM** | **No inference at all** — numpy-only lookup, up to 500× faster on CPU |
| potion-retrieval-32M | 32.3M static | MIT | 35.06 retrieval (≈82% of MiniLM's 42.92) | same; retrieval-tuned |
| potion-multilingual-128M | 128M static | MIT | (distilled from bge-m3) | same |
| WordLlama WL256 | 16MB / 64–1024 dims | MIT | below MiniLM on most tasks (STS 67.9, clustering 33.3) | numpy-only; the absolute-minimum footprint |
| **Qwen3-Embedding-0.6B** ⭐ quality upgrade | 0.6B / 32–1024 (MRL) | Apache-2.0 | **64.33 MTEB multilingual** (8B sibling ranks #1 at 70.58) | 32k context, 100+ languages incl. code; verified 3-0 against the official card |
| snowflake-arctic-embed-l-v2.0 | large / — | Apache-2.0 | strong multilingual (74 langs) | sentence-transformers + **ONNX** + TEI — best packaged CPU/edge path |
| EmbeddingGemma-300M | ~300M / 768 (MRL→128) | **Gemma Terms** ⚠ | #1 sub-500M on MTEB (61.15 multi / 69.67 en) | <200MB quantized, <22ms EdgeTPU. ⚠ One spec claim (512-token context) was **refuted 0-3** in verification — context is 2048; treat secondhand specs cautiously, and the license is not Apache/MIT |

**Picks:** default `mdlp[embed]` = **all-MiniLM-L6-v2** (the interface's canonical citizen; every τ threshold in the specs was informally calibrated against this class). Zero-infra `mdlp[embed-lite]` = **potion-base-32M** — MIT, numpy-only, no torch, 93% of MiniLM: this is the one that preserves MDLP's `pip install and run` identity while still filling all six consumers. Quality upgrade = **Qwen3-Embedding-0.6B** (Apache, MRL dims mean the 384-dim stores don't need migration — truncate to 384).

## 3. Category B — cross-encoder rerankers (optional, R1 semantic path)

| Model | Params | License | Quality | CPU story |
|---|---|---|---|---|
| **ms-marco-MiniLM-L6-v2** ⭐ default | ~23M | Apache-2.0 | NDCG@10 74.30 (TREC DL19) | ~1800 docs/s; L2-v2 does 4100 docs/s at 71.01 |
| **Ettin rerankers (17.6M–1B)** ⭐ modern alternative | 17.6M–1B | Apache-2.0 | 150M variant is the **strongest sub-600M tested** (0.5994 NDCG@10), edging Qwen3-Reranker-0.6B | 8K context; **17M runs 267 pairs/s on pure CPU** (the 1B: 2.1/s — stay small on CPU) |
| mxbai-rerank-base-v2 | 0.5B | Apache-2.0 | BEIR 55.57 — beats bge-v2-m3 (53.94) and jina-v2 (54.35) | modest GPU or patient CPU |
| bge-reranker-v2-m3 | 568M | Apache-2.0 | 53.94 BEIR; multilingual | ~2.5GB |
| Qwen3-Reranker 0.6B/4B | 0.6B/4B | Apache-2.0 | multilingual | 0.6B ≈ 2GB |
| jina-reranker v2 / v3 | 278M / 0.6B | **CC-BY-NC-4.0** ⚠ | good | **non-commercial — exclude** |

**Picks:** default = **ms-marco-MiniLM-L6-v2** (tiny, fast, proven); if starting fresh in 2026, **Ettin-17M/150M** is the better-licensed, longer-context modern equivalent. Skip Jina (license).

## 4. Category C — small generative LLMs (student / teacher / judge)

| Model | Params / ctx | License | Headline | Local story |
|---|---|---|---|---|
| **Phi-4-mini** ⭐ best small CPU LLM | 3.8B / 128K | **MIT** | MMLU ~67, GSM8K ~88 — leads the sub-4B class | Q4 ≈ 3GB; `ollama run phi4-mini`; 15–50 tok/s CPU-only |
| **SmolLM3-3B** ⭐ most-open student | 3B / 64K (→128K YaRN) | Apache-2.0 | beats Llama-3.2-3B & Qwen2.5-3B across 12 benchmarks | **fully open training pipeline** — best for a *reproducible* M2 student |
| **Qwen3 dense 0.6B/1.7B/4B** ⭐ best sub-1B | 0.6–4B / 32K | Apache-2.0 | Qwen3-4B-class strongest under-4B on general benchmarks | llama.cpp ≥ b5092, GGUF Q4_K_M/Q8_0; the 0.6B is the best permissive sub-1B |
| Llama 3.2 1B/3B | 1–3B / 128K | Llama license ⚠ | solid | Ollama/GGUF |
| Gemma 3 1B/4B | 1–4B / 128K | **Gemma Terms** ⚠ | 4B in ~4.2GB RAM | Ollama |
| Qwen2.5-3B | 3B | **Research-only** ⚠ (0.5B/1.5B are Apache) | — | licensing gotcha — use Qwen3 instead |

All of the 3–4B tier runs CPU-only at Q4 in ≤8GB RAM at 15–50 tok/s; all are LoRA/QLoRA-tunable via peft/trl — **which TA's `weight` extra already pins.**

**Picks:** M2 **student** = **Qwen3-1.7B or SmolLM3-3B** (Apache; SmolLM3 if reproducibility-of-training matters for the paper, Qwen3 for capability-per-param; **Qwen3-0.6B** for the cheapest viable axis test). Cheap **teacher/judge** = **Phi-4-mini** (MIT, strongest reasoning per byte — but it only *proposes*; §8 stays the arbiter).

## 5. Library shape (advisories → IMPLEMENTATION-v2 §20 family)

```
mdlp[embed-lite]  # model2vec           — numpy-only static embeddings (near-zero-infra tier)
mdlp[embed]       # sentence-transformers + all-MiniLM-L6-v2 (default provider)
mdlp[rerank]      # ms-marco-MiniLM / Ettin small cross-encoder
mdlp[weight]      # (exists in TA) torch+transformers+peft+trl — student: Qwen3/SmolLM3
```
One `EmbeddingProvider` protocol behind all six consumers (`embed(texts) -> list[vec]`, dim-reported); providers selected by config like store backends. Dims: standardize the vector store on 384 (MiniLM/potion native; Qwen3-Embedding truncates via MRL). License floor for anything shipped as a default: Apache-2.0/MIT only — Gemma-Terms/CC-NC/Llama-license models stay documented alternatives, never defaults.

*Verification note: 24/25 sampled claims survived 3-vote adversarial refutation; the one kill was an EmbeddingGemma spec bundle (wrong context length). Numbers above marked "verified" were confirmed against official model cards; blog-sourced throughputs are indicative, not gospel.*
