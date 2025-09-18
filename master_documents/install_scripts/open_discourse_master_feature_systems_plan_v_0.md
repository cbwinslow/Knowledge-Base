# OpenDiscourse — Master Feature & Systems Plan (v0.2)

> A consolidated blueprint for building a real‑time, objective political intelligence and news analytics platform. Optimized for local or server deployment, with clear inter‑app contracts and an extensible, Next.js‑first developer experience.

---

## 0) At‑a‑Glance Scope

**Goals**
- Ingest: government data (govinfo.gov, congress.gov, data.gov bulkdata), news sites, RSS, social media (X/Twitter), TV/radio audio & transcripts.
- Analyze: NLP (spaCy, transformers/BERT‑class), embeddings, stance & sentiment, claim extraction/verification, coref + relationship extraction, clustering/bucketing via embeddings.
- Attribute: Entity resolution to politicians, agencies, journalists, outlets; build longitudinal profiles.
- Persist: SQL ground truth, vector store for semantic ops, graph DB for relationships.
- Expose: APIs, dashboards, entity “wiki” pages, bias & truthfulness scoring, downloadable datasets.

**High‑Level Stack**
- **Frontend**: Next.js (App Router), Tailwind + shadcn/ui
- **Backend**: FastAPI (Py) + Node/Express service where convenient (agent/workers ok)
- **DBs**: Postgres (ground truth), **Weaviate or Qdrant** (vectors), **Neo4j** (graph)
- **Pipelines/Orch**: n8n, Celery (Python) / BullMQ (Node), Redis
- **LLM/RAG**: Local AI (Ollama/local‑ai‑packaged), OpenAI‑compatible, agentic‑knowledge‑graph‑rag
- **Observability**: Langfuse (LLM tracing), OpenTelemetry → Prometheus + Grafana (or Graphite/StatsD optional), Sentry
- **Auth**: OAuth2/OIDC (Auth.js), RBAC/ABAC
- **Packaging**: pnpm workspaces (mono‑repo), Docker Compose, optional Helm/K8s

---

## 1) Feature Matrix (What + With What)

| Capability | User Value | Primary App/Service | Secondary/Libs |
|---|---|---|---|
| Bulk gov docs ingestion | Crawl & fetch laws, bills, budgets, treaties, committee data | **Ingestion Worker (Py)** via n8n | Scrapy/Playwright, pdfminer.six, pytesseract/ocrmypdf, robots/sitemaps
| Social media ingest (X) | Pull tweets/threads from politicians & outlets for NLP | **Ingestion Worker (Py)** | X API/Firehose (or third‑party), SNS→SQS adapter
| News/RSS ingestion | Monitor outlets/press releases | **n8n** flows → **Ingestion Worker** | feedparser, trafilatura/Readability
| A/V transcription | TV/radio appearances → text | **ASR Worker (Py)** | Whisper/WhisperX, diarization (pyannote), VAD
| Document analysis | NER, coref, RE, claims, quotes | **NLP Worker (Py)** | spaCy, Hugging Face (BERT/DeBERTa), spacy‑transformers, LexNLP for legalese
| Embeddings + clustering | Similarity, binning, dedupe | **Vector Service** | Weaviate/Qdrant, bge‑large/e5‑mistral via Ollama
| Knowledge graph | People↔bills↔votes↔statements | **Neo4j** (+ **agentic‑knowledge‑graph‑rag**) | APOC, GDS, KG‑RAG agents
| RAG & Q/A | Contextual answers with citations | **RAG Gateway** | local‑ai‑packaged, OpenAI‑compat, re‑rankers (bge‑rerank, Cohere‑rerank)
| Profiles & scoring | Bias, truthfulness, aggressiveness timelines | **Next.js UI** + **Analytics Worker** | calibration datasets, stance detection, claim‑veracity
| Reporting & exports | PDF/CSV/JSON reports per entity | **Report Service** | WeasyPrint/PrinceXML, pandas/duckdb
| Admin & ops | OAuth, users, roles, secrets, queues | **Admin UI (Next.js)** | Auth.js, Postgres, Redis, n8n admin
| Observability | Tracing, metrics, logs, evals | **Langfuse**, **Grafana** | OpenTelemetry, Prometheus, ELK/Vector

---

## 2) Monorepo Layout (pnpm workspaces)

```
openDiscourse/
├─ apps/
│  ├─ web/                 # Next.js app (SSR/ISR, App Router)
│  ├─ api/                 # FastAPI gateway (REST/GraphQL, OpenAPI)
│  ├─ rag-gateway/         # RAG API + re-rankers + citation normalizer
│  ├─ admin/               # Next.js admin (feature flags, settings, queues)
│  └─ n8n/                 # n8n container config + flows
├─ services/
│  ├─ ingestion/           # Scrapy/playwright pipelines, RSS, X, gov bulkdata
│  ├─ asr/                 # WhisperX, diarization, alignment
│  ├─ nlp/                 # spaCy pipelines, transformers, coref/RE/claims
│  ├─ vector/              # Weaviate/Qdrant client + schema mgmt
│  ├─ graph/               # Neo4j, schema, Cypher, GDS jobs
│  ├─ scoring/             # bias/truthfulness/stance models & calibration
│  ├─ report/              # report builders (PDF/CSV) + scheduled jobs
│  └─ workers/             # Celery/BullMQ consumers (queue names per domain)
├─ packages/
│  ├─ ui/                  # shared React components (shadcn/ui, charts)
│  ├─ config/              # eslint, prettier, tsconfig, tailwind preset
│  ├─ sdk/                 # typed client for API/RAG/Graph endpoints
│  ├─ schemas/             # zod/pydantic schemas; OpenAPI types
│  └─ prompts/             # prompt templates, evaluation harness
├─ infra/
│  ├─ docker/              # per‑service Dockerfiles, docker‑compose.*
│  ├─ k8s/                 # Helm charts/manifests (optional)
│  └─ otel/                # OpenTelemetry collector config
├─ scripts/                # bootstrap, db migrate/seed, smoke‑tests
└─ .env.example            # single source of config truth
```

---

## 3) Configuration & Settings

**Environment keys (.env)**
- CORE: `NODE_ENV`, `PYTHONPATH`, `TZ`, `LOG_LEVEL`
- DB: `POSTGRES_URL`, `REDIS_URL`, `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASS`
- VECTORS: `WEAVIATE_URL`/`QDRANT_URL`, `EMBEDDING_MODEL`, `RERANK_MODEL`
- AUTH: `AUTH_SECRET`, `AUTH_URL`, `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`
- PROVIDERS: `OPENAI_API_KEY` (compat), `OLLAMA_HOST`, `X_BEARER_TOKEN`
- STORAGE: `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`
- OBS: `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `OTEL_EXPORTER_OTLP_ENDPOINT`
- JOBS: `QUEUE_URL`, `MAX_CONCURRENCY`, `RATE_LIMITS_JSON`

**Runtime flags (Feature toggles)**
- `ENABLE_RAG`, `ENABLE_GRAPH`, `ENABLE_RE_RANK`, `ENABLE_SPEAKER_DIARIZATION`, `ENABLE_PRESS_RELEASE_FEEDS`, `ENABLE_TV_OCR`, `ENABLE_BIAS_SCORING`, `ENABLE_PUBLIC_EXPORTS`

**Tenant & RBAC**
- Roles: `owner`, `admin`, `analyst`, `viewer`, `api_client`
- Policy: ABAC (attribute based) for dataset sensitivity & PII redaction controls.

---

## 4) Data Architecture

**Relational (Postgres)**
- `entities` (person/org/outlet/committee) → resolution keys (name, aliases, handles, office terms)
- `documents` (source, url, mime, hash, ingest_ts, transcript_id)
- `statements` (entity_id, doc_id, span_offsets, quoted_text, context)
- `claims` (statement_id, normalized_claim, claim_tsv, topic_tags[], claim_hash)
- `verifications` (claim_id, status{true,false,partially,unverified}, evidence, method, updated_at)
- `sentiments` (statement_id, target_entity_id?, polarity, score, model)
- `relationships` (head_entity_id, rel_type, tail_entity_id, doc_id, confidence)
- `bills` (bill_id, congress, title, sponsors[], cosponsors[], committees[])
- `votes` (bill_id, member_id, rollcall_id, vote{Yea/Nay/Present/NotVoting})
- `appearances` (entity_id, media_type{tv,radio,podcast}, aired_at, show, network, clip_url)
- `scores` (entity_id, date, bias_score, truthfulness_score, aggressiveness_score, stance_vector)
- `users`, `oauth_accounts`, `api_tokens`, `audit_logs`

**Vector Store (Weaviate/Qdrant)**
- Classes: `DocChunk`, `StatementChunk`, `ClaimChunk` with metadata (entity_ids[], bill_ids[], time_range)
- Index params: cosine/dot, HNSW; filters by entity/topic/date/source

**Graph (Neo4j)**
- Nodes: `Person`, `Org`, `Outlet`, `Bill`, `Committee`, `Claim`, `Statement`, `Source`
- Rels: `SPONSORED`, `MEMBER_OF`, `APPEARED_ON`, `QUOTED_IN`, `SUPPORTS`, `OPPOSES`, `CITED_BY`, `CONTRADICTS`, `ALIGNED_WITH`
- Periodic ETL from Postgres; enforce idempotent MERGE keys

---

## 5) Pipelines & Workers

**Ingestion**
1) **Gov Bulkdata**: scheduler → fetch index → dedupe by hash → persist raw → extract (pdf/html/xml) → normalize to `documents`
2) **Press/RSS**: n8n watch → fetch & extract main content → link to `entities` by outlet/journalist
3) **Social/X**: cron → API search/lists for known handles → hydrate threads → store
4) **A/V**: download clips → WhisperX (ASR + alignment) → diarize → speaker map to entities → transcript segments to `statements`

**NLP**
- spaCy pipeline: tok/pos/ner; coref (pipelines like coreferee/spacy‑llm); dependency parse
- RE (relation extraction): transformers fine‑tuned or zero‑shot templates;
- Quote & claim extraction: rule‑augmented LLM; normalize claims (canonical forms)
- Embeddings: bge‑large/e5‑mistral via Ollama; store → vector DB; nightly cluster (HDBSCAN/k‑means) to bin similar statements
- Sentiment/stance: domain‑adapted models; per‑target sentiment where available

**Verification & Scoring**
- Claim→evidence matching: semantic search across docs, bills, official releases
- Truthfulness: rubric = evidence support, contradiction count, source credibility
- Bias: outlet balance, sentiment skew, issue framing diversity; calibrated with baselines
- Aggressiveness: toxicity/insult classifiers + intensity heuristics

**RAG Gateway**
- Hybrid retrieval: BM25 + vectors (+ re‑rank) → cite spans/URLs → guardrails (answer only from context) → audit to Langfuse

**Graph Build**
- Nightly: batch Cypher to upsert nodes/edges; GDS to compute centrality, communities, influence paths

---

## 6) Frontend (Next.js)

**Apps/Pages**
- **Entity Profiles**: biography, offices/terms, timelines (bias/truth/trend), latest statements, media appearances, vote record, connections (graph viz)
- **Documents Explorer**: filters (source, time, topic, entity), OCR flag, transcript viewer w/ speaker highlights
- **Claims & Fact‑Checks**: browse claims, statuses, evidence packs, diffs across time
- **Knowledge Graph**: Neo4j viz (react‑force‑graph or neo4j‑graphs), path finders ("How Senator A connects to Bill B")
- **Dashboards**: ingestion health, queue depth, model latencies, eval metrics
- **Admin**: user/role mgmt, API tokens, features, providers, rate limits, secrets vault proxy

**UI Toolkit**
- Tailwind + shadcn/ui, Radix; charts with Recharts/ECharts; code/JSON viewers; diff viewers

**Perf/SEO**
- ISR for entity pages; Edge runtime for lightweight APIs; sitemaps & structured data (JSON‑LD) on entity/report pages

---

## 7) Inter‑App Contracts

**APIs**
- REST/GraphQL via FastAPI (OpenAPI spec versioned)
- Auth: OAuth2/OIDC bearer, API keys for service accounts
- Webhooks: `ingest.completed`, `nlp.completed`, `asr.completed`, `claim.verified`, `score.updated`

**Queues (Redis/RabbitMQ)**
- Topics: `ingest.raw`, `ingest.parsed`, `nlp.tasks`, `verify.tasks`, `score.tasks`, `report.tasks`
- Retry: exponential backoff; DLQs with n8n triage flows

**Schemas**
- Shared zod/pydantic package; strict semantic versions; JSON‑Schema snapshots for CI breaking‑change checks

---

## 8) Security, Privacy, Compliance

- OAuth2/OIDC + MFA; session/device policies; IP allowlists for admin
- RBAC/ABAC on datasets; field‑level PII masking; SAR/erasure support
- Secrets via Doppler/Vault/1Password‑SC; never in env files committed
- Network: Zero‑Trust (Tailscale), mTLS between services (optional)
- Supply chain: lockfiles, SLSA‑inspired provenance, image signing (cosign)
- Logging: structured JSON; PII redaction; audit trails for all reads/writes

---

## 9) Observability & QA

- **Langfuse** for all LLM/RAG prompts, costs, latencies, eval traces
- **OpenTelemetry** instrumentation (HTTP, DB, queues) → Prometheus
- **Grafana/Graphite** dashboards (ingestion lag, ASR WER, NER F1, verify throughput)
- **Sentry** for error tracking; alert policies (pager/Slack)
- **Model Eval Harness**: offline test sets for NER/RE/stance/verify; regression gates in CI

---

## 10) DevEx & CI/CD

- pnpm workspaces; conventional commits; changesets versioning
- Pre‑commit: ruff/black (Py), eslint/prettier/tsc (TS), mypy
- CI: build, test, type‑check, docker bake; contract tests (OpenAPI diff)
- Preview envs (docker‑compose.override) per branch; seed datasets
- Makefile/justfile for common tasks (`make up`, `make seed`, `make eval`)

---

## 11) Deployment

**Local (fast start)**
- `docker compose -f docker-compose.core.yml up` → Postgres, Redis, Weaviate/Qdrant, Neo4j, n8n, Langfuse, API, web

**Server/K8s**
- Helm values per env; HPA on workers; RWX storage for models; object storage (MinIO/S3)
- Backups: `pgbackrest`, Neo4j dump, vector snapshots; disaster‑recovery playbook

---

## 12) Repos to Vendor/Integrate

- **agentic‑knowledge‑graph‑rag**: KG‑RAG agents for relationship inference
- **local‑ai‑packaged**: local model hosting (Ollama/llama.cpp compatible endpoints)
- **n8n**: orchestration for connectors & human‑in‑the‑loop
- **Neo4j** ecosystem: APOC, GDS; bloom (optional)
- **Weaviate/Qdrant**: embeddings, HNSW; re‑ranker sidecar

---

## 13) Scoring Frameworks (first pass)

**Truthfulness** (0–1)
- Weighted evidence: (#support − #contradict) normalized; source credibility priors; recency bonus

**Bias** (−1..+1)
- Sentiment skew by topic; outlet balance over window; language framing (lexicon + LLM rubric)

**Aggressiveness** (0–1)
- Toxicity & insult scores; imperative intensity; interruption/overlap rate (A/V)

Calibrate with held‑out labeled sets; report confidence intervals.

---

## 14) Initial Backlog / Microgoals

- Ingestion: gov bulkdata MVP; RSS watcher; X handle seeding list
- ASR: WhisperX pipeline with diarization; speaker resolution heuristic → entity map
- NLP: spaCy baseline NER; claim extractor v0; embeddings + Qdrant schema
- Graph: Neo4j schema & nightly ETL
- RAG: Hybrid retrieval + rerank; citation normalizer; Langfuse wiring
- UI: Entity profile page MVP; document explorer; admin auth
- Ops: OAuth provider; roles & API tokens; dashboards

---

## 15) Risks & Mitigations

- **API rate limits** → batch scheduling, backoff, caching, mirrored archives
- **Model drift/bias** → periodic evals, ensemble checks, transparency UI
- **Speaker attribution errors** → diarization thresholds, manual override tool
- **Legal/compliance** → transparent sourcing, opt‑out handling, clear disclosures

---

## 16) Ready‑to‑Run: Bootstrap Commands

```bash
# 1) clone + env
cp .env.example .env  # fill in keys

# 2) start core services
docker compose -f infra/docker/docker-compose.core.yml up -d

# 3) run migrations & seed
pnpm -w run db:migrate && pnpm -w run db:seed

# 4) start apps
pnpm -w --filter @opendiscourse/web dev
pnpm -w --filter @opendiscourse/api dev

# 5) launch n8n & open admin
open http://localhost:5678  # n8n
open http://localhost:3000  # Next.js UI
```

---

## 17) Extension Ideas

- Live debate rooms (WebRTC) with real‑time transcription & attribution
- Cross‑lingual ingestion (opus‑mt) + multilingual embeddings
- Active learning loop (analyst corrections improve models)
- Public API & datasets portal with API metering/quotas

---

**This plan is designed to be immediately actionable, auditable, and extensible.**

