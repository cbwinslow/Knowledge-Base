# MCP — GovDocs Collector (Autonomous) — SRS & Design

## 0) Purpose
An MCP server that autonomously discovers, evaluates, ingests, normalizes, and publishes government documents across jurisdictions. Adds **domain learning**, **crawler memory**, **site ranking**, and **member/vote extraction** with a canonical SQL schema and event hooks for downstream RAG/graph.

---

## 1) Scope & Goals
- Discover and maintain an **Approved Government Domains** list (seeded → expanded via crawling/classification).
- Learn each domain’s **layout, sitemaps, pagination, detail pages**, and persist a **crawl memory** (selectors, URL patterns, rate limits).
- Ingest all relevant artifact types: **bills, laws, motions, votes, hearings, transcripts, floor statements, press releases, executive orders, regulations/rulemaking, treaties, budgets, audits**.
- Extract **entities** (people, parties, offices, districts, committees) and **events** (votes, motions, bill stages).
- Rank sources by **data volume, freshness, reliability, structure quality**.
- Persist raw artifacts + normalized text + rich metadata into **Postgres + Object Store**; publish events to **Stream**.

Out-of-scope: private/paywalled content, CAPTCHA/blocked sites beyond polite retries.

---

## 2) Functional Requirements
FR‑A1: **Autonomous domain evaluation**
- Input: seeds (e.g., `*.gov`, curated lists), discovered domains from links.
- Steps: robots fetch → sitemap inference → sampling → heuristics/ML classify gov-doc potential → score.
- Output: `sites` rows (candidate→approved) with policy and score trail.

FR‑A2: **Crawler memory**
- Persist learned patterns: list/detail URL regex, pagination rules, date selectors, attachment selectors, rate limits, last_success markers.
- Update memory with feedback from parser successes/failures.

FR‑A3: **Site ranking**
- Compute volume (docs/week), structure score (schema richness, presence of metadata), reliability (uptime, 4xx/5xx rate), freshness (publication recency), jurisdictional coverage.

FR‑I1: **Ingestion adapters**
- Generic HTTP/HTML + specialized adapters (govinfo, federalregister, congress, state legislatures, court opinions, municipal portals).
- MIME detect → PDF/HTML/XML/JSON/CSV → parse/OCR → normalize.

FR‑E1: **Entity & event extraction**
- Named entity extraction for persons/organizations/parties/offices/districts; rule-based mappers for roll call and motion/vote records.
- Committee + membership extraction when present.

FR‑S1: **Search & retrieval tools (MCP)**
- Tools: `evaluate_domain`, `approve_domain`, `rank_sites`, `run_crawl(site_id)`, `search_docs`, `get_doc`, `reprocess`, `learn_patterns(site_id)`, `list_sites(filter)`, `export_site_map`.

FR‑O1: **Observability & policy**
- Track robots/ToS decisions; crawl politeness; structured logs; metrics dashboards.

---

## 3) Non‑Functional Requirements
- Idempotent ingestion; content-hash versioning; resumable jobs with DLQ.
- Security: sandbox parsing; signed containers; least-privilege credentials; PDF sanitization.
- Scalability: shard by site or jurisdiction; stateless workers; backpressure on stream.

---

## 4) Architecture Overview
Components: **MCP API**, **Planner (domain evaluator)**, **Crawler (per-site workers)**, **Parsers**, **Normalizer**, **Entity Extractors**, **Memory Store**, **DB/Object/Stream**, **Scheduler**, **Policy Engine**.

Sequence (autonomous expansion): seeds → planner samples → classifies/scored → operator auto/semiauto approve → crawler learns patterns → scheduled ingestion → events.

---

## 5) Data Model (Postgres — Canonical)
```sql
-- Sites discovered/evaluated
CREATE TABLE sites (
  id UUID PRIMARY KEY,
  domain TEXT UNIQUE NOT NULL,
  base_url TEXT NOT NULL,
  tld TEXT NOT NULL,
  jurisdiction TEXT,            -- federal|state|county|city|intl
  government_body TEXT,         -- House|Senate|Agency|Court|Exec|Council|...
  approval_status TEXT NOT NULL DEFAULT 'candidate', -- candidate|approved|rejected
  tos_url TEXT,
  robots_txt TEXT,
  gov_likelihood NUMERIC,       -- 0..1 classifier output
  score NUMERIC,                -- ranking score
  last_crawled_at TIMESTAMPTZ,
  notes JSONB DEFAULT '{}'
);

-- Learned crawl memory per site
CREATE TABLE site_memory (
  id UUID PRIMARY KEY,
  site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
  version INT NOT NULL DEFAULT 1,
  list_url_patterns JSONB NOT NULL,     -- [regex]
  detail_url_patterns JSONB NOT NULL,   -- [regex]
  pagination JSONB,                     -- {type:'param|path|next_link', key:'page', ...}
  selectors JSONB,                      -- {title, date, body, attachments:[{sel, type}]}
  rate_limits JSONB,                    -- {rpm, concurrency}
  last_success JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Documents
CREATE TABLE documents (
  id UUID PRIMARY KEY,
  site_id UUID REFERENCES sites(id) ON DELETE SET NULL,
  source_url TEXT NOT NULL,
  content_sha256 BYTEA NOT NULL,
  version INT NOT NULL DEFAULT 1,
  title TEXT,
  doc_type TEXT,                        -- bill|law|motion|vote|press_release|...
  jurisdiction TEXT,
  government_body TEXT,
  published_at TIMESTAMPTZ,
  retrieved_at TIMESTAMPTZ NOT NULL,
  language TEXT,
  bytes BIGINT,
  ocr_used BOOLEAN DEFAULT FALSE,
  storage_key TEXT NOT NULL,            -- text/plain canonical
  pdf_key TEXT,                         -- original artifact
  provenance JSONB NOT NULL,
  UNIQUE (site_id, content_sha256, version)
);

-- People (officials), Offices, Memberships, Districts
CREATE TABLE people (
  id UUID PRIMARY KEY,
  full_name TEXT NOT NULL,
  party TEXT,
  twitter TEXT,
  email TEXT,
  social JSONB DEFAULT '{}'
);

CREATE TABLE offices (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,             -- e.g., 'U.S. House', 'State Senate 7'
  chamber TEXT,                   -- lower|upper|exec|judicial|agency
  jurisdiction TEXT,
  government_body TEXT
);

CREATE TABLE districts (
  id UUID PRIMARY KEY,
  code TEXT,                      -- e.g., 'NY-10', 'TX-SD-7'
  state TEXT,
  geoid TEXT,
  geo JSONB                      -- optional GeoJSON
);

CREATE TABLE memberships (
  id UUID PRIMARY KEY,
  person_id UUID REFERENCES people(id),
  office_id UUID REFERENCES offices(id),
  district_id UUID REFERENCES districts(id),
  start_date DATE,
  end_date DATE,
  term_number INT,
  party TEXT,
  source_doc UUID REFERENCES documents(id)
);

-- Bills & Votes (minimal subset)
CREATE TABLE bills (
  id UUID PRIMARY KEY,
  documents_id UUID REFERENCES documents(id),
  bill_number TEXT,
  session TEXT,
  title TEXT,
  status TEXT,
  introduced_at DATE,
  updated_at TIMESTAMPTZ
);

CREATE TABLE votes (
  id UUID PRIMARY KEY,
  bill_id UUID REFERENCES bills(id),
  motion TEXT,
  result TEXT,                 -- passed|failed
  vote_date DATE,
  chamber TEXT
);

CREATE TABLE vote_records (
  id UUID PRIMARY KEY,
  vote_id UUID REFERENCES votes(id),
  person_id UUID REFERENCES people(id),
  position TEXT,               -- yea|nay|present|absent
  party TEXT,
  district_id UUID REFERENCES districts(id)
);

-- Events bus (if not using external streaming)
CREATE TABLE ingest_events (
  id BIGSERIAL PRIMARY KEY,
  kind TEXT NOT NULL,          -- site.approved|doc.ingested|entity.extracted
  ref UUID,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON documents (doc_type, jurisdiction, published_at);
CREATE INDEX ON sites (approval_status, score DESC);
```

---

## 6) ML/Heuristics for Autonomy
- **Gov classifier**: binary classifier (features: TLD, WHOIS/org, presence of `.gov`/`.mil`, content signals like "Office of", accessibility footer patterns, structured data types `Legislation`, `GovernmentOrganization`).
- **Volume estimator**: rolling count of new docs/day from sampling + sitemap density.
- **Structure score**: presence of semantic HTML, microdata/JSON-LD, downloadable PDFs, stable permalinks.
- **Freshness**: days since last `published_at`.
- **Reliability**: uptime check, HTTP error rate, crawl latency.
- **Learning loop**: update `site_memory` on successful parses; demote patterns that regress.

Vector memory (optional): store CSS/XPath/URL embeddings for pattern similarity → bootstrap on new but similar CMSes.

---

## 7) MCP Tool Contracts (JSON sketch)
- `evaluate_domain(domain)` → {site_id, gov_likelihood, score, recommended_policy}
- `approve_domain(site_id, policy)` → {status}
- `learn_patterns(site_id, sample_urls?, hints?)` → {memory_version}
- `rank_sites(limit?, filters?)` → [{site_id, score, reasons}]
- `run_crawl(site_id?, depth?, max_docs?)` → {job_id}
- `search_docs(query, filters)` → [Doc]
- `extract_entities(doc_id|storage_key)` → {people, offices, bills, votes}

---

## 8) Storage & File Layout
- **DB‑first** canonical schema with migrations bundled in the server so it can self‑start.
- Artifacts in object store:
  - `raw/<site>/<yyyy>/<mm>/<sha>.pdf`
  - `text/<site>/<yyyy>/<mm>/<sha>.txt`
  - `meta/<doc_id>.json`

Provide optional **exporters** to structured folder trees for offline use.

---

## 9) Observability & Policy
- Dashboards: site coverage, ingest lag, parse fail %, events/min.
- Per‑site policy doc: ToS URL, notes, allowed fetch windows, request headers.

---

## 10) Test Plan
- Fixture sites (mock servers) for common CMS families.
- Regression suite for parser selectors.
- Chaos: pagination loops, moved pages, 301 chains, file size spikes.

---

## 11) Deployment
- Docker image with read‑only root; env‑driven config; Vault/Bitwarden bridge.
- `docker-compose` sample: Postgres, MinIO, Redis Streams, Grafana.

---

## 12) Design Decision: Where to House the Schema?
**Recommendation: Both, with clear ownership**
- **Canonical schema & migrations** live in the project repo (source of truth, reviewed, versioned, documented).
- **MCP server** ships an embedded, pinned snapshot of the current migrations so it can **self‑bootstrap** on first run (empty DB) and remain operable in isolation.
- Publish schema as a versioned package (e.g., `opendiscourse-schema`) used by server + other services.

Pros: single truth, autonomous startup, reproducible; Cons: minor duplication (intentional, versioned).

