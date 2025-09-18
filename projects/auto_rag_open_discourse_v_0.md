# AutoRAG OpenDiscourse v0.2-full — Repository in Canvas

Below are all project files with their paths and full contents. Copy/edit inline as needed.

---

## .gitignore
```gitignore
# env & secrets
.env
selfhost/env.*
# node
node_modules
apps/web/.next
# python
__pycache__/
# docker
selfhost/supabase/
# OS
.DS_Store
```

---

## README.md
```md
# AutoRAG OpenDiscourse — v0.2-full

Cloudflare-first **agentic RAG** stack for political document analysis with optional **OCI** VM.
Includes: Worker + Pages UI, Supabase schema (**pgvector + RLS**), **LocalAI**, **Qdrant**, **n8n**, **Analyzer** (spaCy + sentence-transformers), **Terraform**, **GitHub Actions**, and **Postman** collections (MCP-ready).

## Quick Start

1) **Secrets**
```bash
python3 scripts/gen_secrets.py
cp .env.example .env    # fill API_DATA_GOV_KEY, PG_DSN, etc.
```

2) **Start services** (VM or local)
```bash
cd selfhost
./bootstrap_supabase.sh
docker compose up -d
```

3) **Deploy Worker (Cloudflare)**
```bash
cd apps/worker
npx wrangler secret put OPENROUTER_API_KEY   # optional
npx wrangler publish
```

4) **Deploy Pages** (`apps/web`) via Cloudflare Pages (connect repo) or `npm run build && npx wrangler pages deploy`.

5) **Ingestion**
```bash
uv pip install -r scripts/requirements.txt
python3 scripts/ingest_govinfo.py --since 2024-01-01
python3 scripts/ingest_congress.py --congress 118 --sponsor "Warren"
```

> Swap the repo URL inside `infra/oci/userdata-cloudinit.yaml` before `terraform apply`.

## Components
- **apps/worker/** — Cloudflare Worker (RAG API): `/embed`, `/search`, `/ask`, `/config`, `/report`.
- **apps/web/** — Next.js Pages admin: `/graph`, `/ingest`, `/reports`, `/profile/[id]`.
- **services/analyzer/** — FastAPI NLP microservice.
- **selfhost/** — Docker Compose for LocalAI, Qdrant, n8n + Supabase bootstrap.
- **db/** — Full Postgres schema + helper functions (pgvector, RLS).
- **infra/** — Terraform (Cloudflare + OCI).
- **scripts/** — Secrets, ingestion, error helper, DB/embed helpers.
- **postman/** — GovInfo + Congress collections + environment.
- **.github/workflows/** — Nightly ingest + Worker deploy.

## Security
- Non-root containers, `no-new-privileges`, `cap_drop: [ALL]`, healthchecks.
- Supabase **RLS** and least-privileged service calls.
- Cloudflare Access recommended for admin routes.
- Never commit secrets; `.gitignore` included.
```

---

## .env.example
```env
API_DATA_GOV_KEY=your_api_data_gov_key_here
OPENROUTER_API_KEY=optional_openrouter_key

WORKER_BASE=https://your-worker.example.com
LOCALAI_URL=http://localhost:8080

PG_DSN=postgresql://postgres:password@127.0.0.1:5432/postgres

QDRANT_URL=http://127.0.0.1:6333
QDRANT_COLLECTION=autorag

NEO4J_URI=bolt://neo4j-host:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
```

---

## apps/worker/worker.mts
```ts
/**
 * File: apps/worker/worker.mts (v0.2-full)
 * Summary: Cloudflare Worker RAG API with Vectorize + LocalAI/OpenRouter.
 */
export interface Env {
  VECTORIZE_INDEX?: VectorizeIndex;
  OPENROUTER_API_KEY?: string;
  LOCALAI_URL?: string;
  HYPERDRIVE?: any;
  R2_BUCKET?: R2Bucket;
  CORS_ORIGIN?: string;
}

const JSON_HEADERS = { 'content-type': 'application/json; charset=utf-8' };
function cors(origin?: string) {
  const o = origin || '*';
  return {
    'Access-Control-Allow-Origin': o,
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, content-type',
  };
}
function ok(data: unknown, init: ResponseInit = {}): Response {
  return new Response(JSON.stringify(data), { ...init, headers: { ...JSON_HEADERS, ...(init.headers||{}), ...cors() } });
}

async function embedWithLocalAI(url: string, input: string) {
  const resp = await fetch(`${url}/v1/embeddings`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ input, model: 'text-embedding-bge-small' })
  });
  if (!resp.ok) throw new Error(`LocalAI embedding failed: ${resp.status}`);
  const j = await resp.json();
  return j.data?.[0]?.embedding as number[];
}
async function embedWithOpenRouter(key: string, input: string) {
  const resp = await fetch('https://openrouter.ai/api/v1/embeddings', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'authorization': `Bearer ${key}`,
      'x-title': 'autorag-opendiscourse'
    },
    body: JSON.stringify({ input, model: 'text-embedding-bge-small' })
  });
  if (!resp.ok) throw new Error(`OpenRouter embedding failed: ${resp.status}`);
  const j = await resp.json();
  return j.data?.[0]?.embedding as number[];
}
async function chooseEmbedding(env: Env, text: string) {
  if (env.LOCALAI_URL) {
    try { return await embedWithLocalAI(env.LOCALAI_URL, text); } catch {}
  }
  if (env.OPENROUTER_API_KEY) {
    return await embedWithOpenRouter(env.OPENROUTER_API_KEY, text);
  }
  throw new Error('No embedding backend configured');
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors(env.CORS_ORIGIN) });
    const url = new URL(req.url);

    try {
      if (url.pathname === '/health') return new Response('ok', { headers: cors(env.CORS_ORIGIN) });
      if (url.pathname === '/config') return ok({ embedModel: 'bge-small', topK: 8 });

      if (url.pathname === '/embed' && req.method === 'POST') {
        const { text, metadata } = await req.json();
        if (!text || typeof text !== 'string') return ok({ error: 'text required' }, { status: 400 });
        const vec = await chooseEmbedding(env, text);
        if (env.VECTORIZE_INDEX) {
          await env.VECTORIZE_INDEX.upsert([{ id: crypto.randomUUID(), values: vec, metadata }]);
        }
        return ok({ dim: vec.length, ok: true });
      }

      if (url.pathname === '/search' && req.method === 'POST') {
        const { text, k = 8, filter } = await req.json();
        if (!text || typeof text !== 'string') return ok({ error: 'text required' }, { status: 400 });
        const vec = await chooseEmbedding(env, text);
        if (!env.VECTORIZE_INDEX) return ok({ results: [] });
        const results = await env.VECTORIZE_INDEX.query(vec, { topK: Math.min(Math.max(Number(k||8),1),20), filter });
        return ok({ results });
      }

      if (url.pathname === '/ask' && req.method === 'POST') {
        const { question, contextK = 6 } = await req.json();
        if (!question || typeof question !== 'string') return ok({ error: 'question required' }, { status: 400 });

        let context: string[] = [];
        if (env.VECTORIZE_INDEX) {
          const vec = await chooseEmbedding(env, question);
          const r = await env.VECTORIZE_INDEX.query(vec, { topK: Math.min(Math.max(Number(contextK||6),1),20) });
          context = (r.matches||[]).map(m => (m?.metadata?.text as string)||'').filter(Boolean);
        }
        const prompt = `You are an analyst. Use CONTEXT to answer.\nCONTEXT:\n${context.join('\n---\n')}\n\nQ: ${question}\nA:`;

        let answer = 'No LLM configured.';
        if (env.LOCALAI_URL) {
          try {
            const r = await fetch(`${env.LOCALAI_URL}/v1/chat/completions`, {
              method: 'POST', headers: { 'content-type': 'application/json' },
              body: JSON.stringify({ model: 'llama3.1:8b-instruct-q4_k_m', messages: [{ role:'user', content: prompt }] })
            });
            if (r.ok) { const j = await r.json(); answer = j.choices?.[0]?.message?.content||answer; }
          } catch {}
        }
        if ((!answer || answer.startsWith('No LLM')) && env.OPENROUTER_API_KEY) {
          const r = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: { 'content-type':'application/json', 'authorization':`Bearer ${env.OPENROUTER_API_KEY}` },
            body: JSON.stringify({ model: 'deepseek/deepseek-chat', messages: [{ role:'user', content: prompt }] })
          });
          if (r.ok) { const j = await r.json(); answer = j.choices?.[0]?.message?.content||answer; }
        }
        return ok({ answer, ctx: context.length });
      }

      if (url.pathname === '/report' && req.method === 'POST') {
        const body = await req.json().catch(()=> ({}));
        if (!env.R2_BUCKET) return ok({ error: 'R2 not configured' }, { status: 400 });
        const key = `reports/${Date.now()}-${crypto.randomUUID()}.json`;
        await env.R2_BUCKET.put(key, JSON.stringify(body, null, 2), { httpMetadata: { contentType: 'application/json' }});
        return ok({ stored: key });
      }

      return new Response('Not found', { status: 404, headers: cors(env.CORS_ORIGIN) });
    } catch (e: any) {
      return ok({ error: e?.message||'unknown' }, { status: 500 });
    }
  }
};
```

---

## apps/worker/wrangler.toml
```toml
name = "autorag-api"
main = "worker.mts"
compatibility_date = "2024-11-10"

[vars]
CORS_ORIGIN = "*"

[[vectorize]]
binding = "VECTORIZE_INDEX"
index_name = "autorag-index"

# Optional R2 binding example
# [[r2_buckets]]
# binding = "R2_BUCKET"
# bucket_name = "autorag-blobs"

[observability]
enabled = true
```

---

## apps/web/package.json
```json
{
  "name": "autorag-web",
  "version": "0.2.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "axios": "1.7.2",
    "neovis.js": "2.0.2",
    "next": "14.2.5",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "recharts": "2.12.7"
  }
}
```

---

## apps/web/next.config.js
```js
/** @type {import('next').NextConfig} */
const nextConfig = { reactStrictMode: true };
module.exports = nextConfig;
```

---

## apps/web/tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["dom", "dom.iterable", "es2020"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": false,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve"
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
```

---

## apps/web/.env.example
```env
NEXT_PUBLIC_NEO4J_URI=bolt://your-neo4j-host:7687
NEXT_PUBLIC_NEO4J_USER=neo4j
NEXT_PUBLIC_NEO4J_PASSWORD=neo4j_password
NEXT_PUBLIC_API_BASE=https://your-worker.example.com
```

---

## apps/web/pages/index.tsx
```tsx
import Link from 'next/link';

export default function Home() {
  return (
    <main className="min-h-screen p-8 font-sans">
      <h1 className="text-3xl font-bold">AutoRAG OpenDiscourse Admin</h1>
      <p className="mt-2 opacity-80">Configure sources, run analysis, and explore the graph.</p>
      <ul className="mt-6 list-disc pl-6">
        <li><Link href="/graph">Graph Explorer</Link></li>
        <li><Link href="/ingest">Ingest</Link></li>
        <li><Link href="/reports">Reports</Link></li>
      </ul>
    </main>
  );
}
```

---

## apps/web/pages/graph.tsx
```tsx
import { useEffect, useRef } from 'react';

export default function Graph() {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    (async () => {
      const NeoVisLib: any = (await import('neovis.js')) as any;
      const config = {
        containerId: ref.current?.id || "graph",
        serverUrl: process.env.NEXT_PUBLIC_NEO4J_URI,
        serverUser: process.env.NEXT_PUBLIC_NEO4J_USER,
        serverPassword: process.env.NEXT_PUBLIC_NEO4J_PASSWORD,
        labels: { Person: { caption: 'name' }, Org: { caption: 'name' } },
        relationships: { MENTIONS: { caption: true }, AFFILIATED_WITH: { caption: true } },
        initialCypher: 'MATCH (p:Person)-[r]->(x) RETURN p,r,x LIMIT 200'
      };
      const viz = new NeoVisLib.default(config);
      viz.render();
    })();
  }, []);

  return <div id="graph" ref={ref} style={{ height: '80vh', border: '1px solid #ddd' }} />;
}
```

---

## apps/web/pages/ingest.tsx
```tsx
import { useState } from 'react';

export default function Ingest() {
  const [since, setSince] = useState('2024-01-01');
  const [log, setLog] = useState<string>('');

  const run = () => {
    setLog('Triggering ingest via n8n or scripts...\nUse n8n webhook or GitHub Actions to run scripts/ingest_*.py');
  };

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">Ingest</h1>
      <div className="mt-4">
        <label className="mr-2">Since:</label>
        <input value={since} onChange={(e)=>setSince(e.target.value)} className="border px-2 py-1" />
        <button onClick={run} className="ml-3 border px-3 py-1">Run</button>
      </div>
      <pre className="mt-6 p-3 bg-gray-100 whitespace-pre-wrap">{log}</pre>
    </main>
  );
}
```

---

## apps/web/pages/reports.tsx
```tsx
import Link from 'next/link';
import { useState } from 'react';
import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer } from 'recharts';

export default function Reports() {
  const [data] = useState<any[]>([
    { date: '2024-01', sentiment: 0.2 },
    { date: '2024-02', sentiment: 0.1 },
    { date: '2024-03', sentiment: 0.35 },
  ]);

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">Reports</h1>
      <p className="opacity-80">Trends and profiles generated from analyses.</p>

      <div className="mt-6" style={{ height: 320 }}>
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="sentiment" dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="mt-8">
        <h2 className="text-xl font-semibold">People</h2>
        <ul className="list-disc pl-6 mt-2">
          <li><Link href="/profile/sample-uuid">Sample Politician Profile</Link></li>
        </ul>
      </div>
    </main>
  );
}
```

---

## apps/web/pages/profile/[id].tsx
```tsx
import { useRouter } from 'next/router';
export default function Profile() {
  const { query } = useRouter();
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">Profile: {query.id}</h1>
      <p className="opacity-80">This view will render stance summaries, co-mention networks, and citations.</p>
      <ul className="mt-4 list-disc pl-6">
        <li>Recent stances (auto-extracted)</li>
        <li>Top co-mentions (graph neighbors)</li>
        <li>Key documents (GovInfo/Congress links)</li>
      </ul>
    </main>
  );
}
```

---

## services/analyzer/Dockerfile
```dockerfile
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt && python -m spacy download de_core_news_md
COPY app ./app
EXPOSE 8081
USER 10001:10001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081"]
```

---

## services/analyzer/requirements.txt
```txt
fastapi==0.115.0
uvicorn[standard]==0.30.6
spacy==3.7.6
transformers==4.44.2
torch==2.4.1 --extra-index-url https://download.pytorch.org/whl/cpu
sentence-transformers==3.0.1
pydantic==2.8.2
```

---

## services/analyzer/app/main.py
```py
from fastapi import FastAPI
from pydantic import BaseModel
import spacy
from sentence_transformers import SentenceTransformer

app = FastAPI(title="Analyzer", version="0.1.0")

class AnalyzeIn(BaseModel):
    text: str
    lang: str | None = 'de'

class AnalyzeOut(BaseModel):
    entities: list[dict]
    sentences: list[str]
    embedding: list[float]

nlp = spacy.load("de_core_news_md")
emb = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

@app.get('/health')
async def health():
    return {"ok": True}

@app.post('/analyze', response_model=AnalyzeOut)
async def analyze(inp: AnalyzeIn):
    doc = nlp(inp.text)
    ents = [{"text": e.text, "label": e.label_, "start": e.start_char, "end": e.end_char} for e in doc.ents]
    sentences = [s.text for s in doc.sents]
    vec = emb.encode([inp.text])[0].tolist()
    return {"entities": ents, "sentences": sentences, "embedding": vec}
```

---

## selfhost/docker-compose.yml
```yaml
version: "3.9"

services:
  localai:
    image: localai/localai:latest-aio-cpu
    command: ["-conf", "/models", "-models-path", "/models"]
    ports: ["8080:8080"]
    environment: [ "GIN_MODE=release" ]
    volumes: [ "localai-models:/models" ]
    healthcheck:
      test: ["CMD", "bash", "-lc", "curl -s http://localhost:8080/healthz || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 5
    security_opt: [ "no-new-privileges:true" ]
    read_only: true
    user: "10001:10001"
    cap_drop: [ "ALL" ]

  qdrant:
    image: qdrant/qdrant:latest
    ports: ["6333:6333", "6334:6334"]
    volumes: [ "qdrant-storage:/qdrant/storage" ]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/healthz"]
      interval: 30s
      timeout: 10s
      retries: 5
    security_opt: [ "no-new-privileges:true" ]
    read_only: false
    user: "10001:10001"
    cap_drop: [ "ALL" ]

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    ports: ["5678:5678"]
    environment:
      - N8N_PORT=5678
      - N8N_HOST=localhost
      - N8N_USER_FOLDER=/home/node/.n8n
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
    volumes: [ "n8n-data:/home/node/.n8n" ]
    healthcheck:
      test: ["CMD", "bash", "-lc", "node -e 'fetch(`http://localhost:5678/rest/ping`).then(r=>{if(r.ok)process.exit(0);else process.exit(1)})'"]
      interval: 30s
      timeout: 10s
      retries: 5
    security_opt: [ "no-new-privileges:true" ]
    read_only: false
    user: "10000:10000"
    cap_drop: [ "ALL" ]

  analyzer:
    build: ../services/analyzer
    environment: [ "SPACY_MODEL=de_core_news_md" ]
    ports: ["8081:8081"]
    healthcheck:
      test: ["CMD", "bash", "-lc", "curl -fsS http://localhost:8081/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
    security_opt: [ "no-new-privileges:true" ]
    read_only: true
    user: "10001:10001"
    cap_drop: [ "ALL" ]

volumes:
  localai-models:
  qdrant-storage:
  n8n-data:
```

---

## selfhost/bootstrap_supabase.sh
```bash
#!/usr/bin/env bash
set -euo pipefail
TAG="v0.25.0"
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$WORKDIR/supabase"

if [[ ! -f "$WORKDIR/env.supabase" ]]; then
  echo "Missing $WORKDIR/env.supabase. Run: python3 scripts/gen_secrets.py" >&2
  exit 1
fi

if [[ ! -d "$DEST" ]]; then
  git clone --depth 1 --branch "$TAG" https://github.com/supabase/supabase.git "$DEST"
fi

cp "$WORKDIR/env.supabase" "$DEST/.env"
cd "$DEST/docker"
docker compose pull
docker compose up -d
```

---

## selfhost/env.example
```env
# Supabase
JWT_SECRET=CHANGEME
ANON_KEY=CHANGEME
SERVICE_ROLE_KEY=CHANGEME
POSTGRES_PASSWORD=CHANGEME
# n8n
N8N_ENCRYPTION_KEY=CHANGEME
# LocalAI
GIN_MODE=release
```

---

## db/schema.sql
```sql
-- Extensions
create extension if not exists pgcrypto;
create extension if not exists vector;

-- Profiles
create table if not exists project_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  display_name text,
  created_at timestamptz default now()
);
alter table project_profiles enable row level security;
create policy "owner_can_see_profile" on project_profiles
  for select using (auth.uid() = user_id);

-- Documents
create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null,
  source_url text,
  title text,
  lang text default 'en',
  sha256 char(64),
  meta jsonb,
  ingested_at timestamptz default now()
);

-- Chunks
create table if not exists doc_chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references documents(id) on delete cascade,
  chunk_idx int not null,
  text text not null,
  embedding vector(384),
  meta jsonb,
  created_at timestamptz default now()
);

-- Entities / Relations
create table if not exists entities (
  id uuid primary key default gen_random_uuid(),
  kind text not null, -- Person, Org, Policy, Event
  name text not null,
  aliases text[],
  external_ids jsonb,
  created_at timestamptz default now()
);

create table if not exists relations (
  id uuid primary key default gen_random_uuid(),
  src uuid references entities(id) on delete cascade,
  dst uuid references entities(id) on delete cascade,
  type text not null,
  weight float default 1.0,
  evidence_docs uuid[]
);

-- Analyses
create table if not exists analyses (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references documents(id) on delete cascade,
  run_id uuid,
  summary text,
  sentiment real,
  stance text,
  topics text[],
  entities jsonb, -- cached IE
  facts jsonb,
  created_by uuid,
  created_at timestamptz default now()
);

-- Profiles
create table if not exists profiles (
  entity_id uuid primary key references entities(id) on delete cascade,
  metrics jsonb,
  last_updated timestamptz default now()
);

-- RLS
alter table documents enable row level security;
alter table doc_chunks enable row level security;

create policy "owner_read_docs" on documents for select
  using (auth.uid() = owner);
create policy "owner_rw_docs" on documents for all
  using (auth.uid() = owner) with check (auth.uid() = owner);

create policy "owner_read_chunks" on doc_chunks for select
  using (exists (select 1 from documents d where d.id = doc_chunks.document_id and d.owner = auth.uid()));
create policy "owner_rw_chunks" on doc_chunks for all
  using (exists (select 1 from documents d where d.id = doc_chunks.document_id and d.owner = auth.uid()))
  with check (exists (select 1 from documents d where d.id = doc_chunks.document_id and d.owner = auth.uid()));

-- Indexes
create index if not exists idx_chunks_doc on doc_chunks(document_id);
create index if not exists idx_chunks_vec on doc_chunks using ivfflat (embedding vector_cosine_ops) with (lists = 100);
```

---

## db/functions.sql
```sql
-- vector search helper
create or replace function public.match_documents(query_embedding vector(384), match_count int, owner_id uuid)
returns table(id uuid, document_id uuid, chunk_idx int, similarity float)
language plpgsql as
$$
begin
  return query
  select c.id, c.document_id, c.chunk_idx,
         1 - (c.embedding <=> query_embedding) as similarity
  from doc_chunks c
  join documents d on d.id = c.document_id
  where d.owner = owner_id and c.embedding is not null
  order by c.embedding <=> query_embedding
  limit match_count;
end;
$$;
```

---

## scripts/requirements.txt
```txt
requests>=2.32.3
psycopg[binary]>=3.2.1
python-dotenv>=1.0.1
tqdm>=4.66.5
```

---

## scripts/gen_secrets.py
```py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate env files for Supabase, LocalAI, n8n.
"""
from __future__ import annotations
import argparse, base64, os, sys, secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELFHOST = ROOT / 'selfhost'

def rand(n: int = 32) -> str:
    return base64.urlsafe_b64encode(os.urandom(n)).decode().rstrip('=')

def write_env(path: Path, lines: list[str], force: bool = False) -> None:
    if path.exists() and not force:
        print(f"[skip] {path} exists. Use --force to overwrite.")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[ok] wrote {path}")

def gen_supabase_env(force: bool) -> None:
    lines = [
        f"JWT_SECRET={secrets.token_urlsafe(64)}",
        f"ANON_KEY={secrets.token_urlsafe(48)}",
        f"SERVICE_ROLE_KEY={secrets.token_urlsafe(48)}",
        f"POSTGRES_PASSWORD={secrets.token_urlsafe(24)}",
        "POSTGRES_PORT=5432",
        "API_EXTERNAL_URL=http://localhost:8000",
        "STUDIO_DEFAULT_ORGANIZATION=CBW",
        "STUDIO_DEFAULT_PROJECT=autorag",
        "ENABLE_TELEMETRY=false",
    ]
    write_env(SELFHOST / 'env.supabase', lines, force)

def gen_localai_env(force: bool) -> None:
    write_env(SELFHOST / 'env.localai', ["GIN_MODE=release","THREADS=4","MODELS_PATH=/models"], force)

def gen_n8n_env(force: bool) -> None:
    write_env(SELFHOST / 'env.n8n', [f"N8N_ENCRYPTION_KEY={rand(32)}"], force)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--force', action='store_true')
    args = ap.parse_args()
    gen_supabase_env(args.force)
    gen_localai_env(args.force)
    gen_n8n_env(args.force)

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)
```

---

## scripts/common_db.py
```py
import os
import psycopg
from psycopg.rows import dict_row

def get_conn():
    dsn = os.getenv("PG_DSN", "postgresql://postgres:postgres@127.0.0.1:5432/postgres")
    return psycopg.connect(dsn, row_factory=dict_row)

def upsert_document(conn, owner, source_url, title, lang, sha256, meta):
    with conn.cursor() as cur:
        cur.execute(
            """insert into documents(owner, source_url, title, lang, sha256, meta)
            values (%s,%s,%s,%s,%s,%s) returning id""", (owner, source_url, title, lang, sha256, meta)
        )
        return cur.fetchone()["id"]

def upsert_chunk(conn, document_id, idx, text, embedding=None, meta=None):
    with conn.cursor() as cur:
        cur.execute(
            """insert into doc_chunks(document_id, chunk_idx, text, embedding, meta)
            values (%s,%s,%s,%s,%s) returning id""", (document_id, idx, text, embedding, meta)
        )
        return cur.fetchone()["id"]
```

---

## scripts/common_embed.py
```py
import os, requests
WORKER_BASE = os.getenv("WORKER_BASE")

def embed_text(text: str, metadata=None):
    if not WORKER_BASE:
        raise RuntimeError("WORKER_BASE not set")
    r = requests.post(f"{WORKER_BASE}/embed", json={"text": text, "metadata": metadata or {}})
    r.raise_for_status()
    return r.json()
```

---

## scripts/ingest_govinfo.py
```py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, time, hashlib, json, argparse, requests
from common_db import get_conn, upsert_document, upsert_chunk

API_KEY = os.getenv("API_DATA_GOV_KEY")
BASE = "https://api.govinfo.gov"

def search(query: str, page_size=100, offset_mark="*"):
  url = f"{BASE}/search"
  headers = {"X-Api-Key": API_KEY} if API_KEY else {}
  body = {"query": query, "pageSize": page_size, "offsetMark": offset_mark, "sorts":[{"field":"publishdate","sortOrder":"DESC"}]}
  r = requests.post(url, headers=headers, json=body, timeout=60)
  r.raise_for_status()
  return r.json()

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument("--query", default="collection:BILLSTATUS congress:118")
  ap.add_argument("--since", default="2024-01-01")
  args = ap.parse_args()

  if not API_KEY:
    print("WARNING: API_DATA_GOV_KEY not set; some endpoints may be limited.", file=sys.stderr)

  conn = get_conn()
  owner = "00000000-0000-0000-0000-000000000000"
  offset = "*"
  total = 0
  while True:
    data = search(f"{args.query} lastModified:range({args.since}T00:00:00Z,)", 100, offset)
    for pkg in data.get("packages", []):
      pid = pkg.get("packageId")
      title = pkg.get("title","")
      url_pdf = pkg.get("download",{}).get("pdfLink")
      meta = {"pid": pid, "summary": pkg.get("summary")}
      sha = hashlib.sha256((pid or title).encode()).hexdigest()
      doc_id = upsert_document(conn, owner, url_pdf or pid, title, "en", sha, json.dumps(meta))
      upsert_chunk(conn, doc_id, 0, (title or "") + "\n" + (pkg.get("summary") or ""), None, json.dumps({"pid":pid}))
      total += 1
    offset = data.get("nextOffsetMark")
    if not offset: break
    time.sleep(0.3)
  conn.commit()
  print(f"[ok] ingested {total} govinfo items")

if __name__ == "__main__":
  main()
```

---

## scripts/ingest_congress.py
```py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, argparse, time, requests, json, hashlib
from urllib.parse import urlencode
from common_db import get_conn, upsert_document, upsert_chunk

API_KEY = os.getenv("API_DATA_GOV_KEY")
BASE = "https://api.congress.gov/v3"

def list_bills(congress: int, q: str = "", limit=250, offset=0):
  params = {"api_key": API_KEY, "limit": limit, "offset": offset}
  if q: params["q"] = q
  url = f"{BASE}/bill/{congress}?{urlencode(params)}"
  r = requests.get(url, timeout=60)
  r.raise_for_status()
  return r.json()

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument("--congress", type=int, required=True)
  ap.add_argument("--sponsor", default="")
  args = ap.parse_args()

  if not API_KEY:
    print("ERROR: API_DATA_GOV_KEY required for Congress.gov", file=sys.stderr); sys.exit(1)

  q = args.sponsor and f'sponsorName:"{args.sponsor}"' or ""
  conn = get_conn()
  owner = "00000000-0000-0000-0000-000000000000"
  offset=0; total=0
  while True:
    data = list_bills(args.congress, q=q, offset=offset)
    items = data.get("bills", [])
    if not items: break
    for b in items:
      ident = b.get("number","")
      title = b.get("title","")
      url = b.get("url","")
      sha = hashlib.sha256((ident+title).encode()).hexdigest()
      doc_id = upsert_document(conn, owner, url, title, "en", sha, json.dumps({"ident":ident}))
      upsert_chunk(conn, doc_id, 0, title or ident, None, json.dumps({"source":"congress"}))
      total += 1
    offset += len(items)
    time.sleep(0.2)
  conn.commit()
  print(f"[ok] ingested {total} congress.gov bills")

if __name__ == "__main__":
  main()
```

---

## scripts/cbw_helper.py
```py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, json, argparse

def local_rules(msg: str) -> list[str]:
  tips = []
  if "EACCES" in msg or "Permission denied" in msg: tips.append("Check file/dir permissions or use sudo.")
  if "connection refused" in msg.lower(): tips.append("Target service may be down; check ports/firewall.")
  if "module not found" in msg.lower(): tips.append("Install missing dependency and re-run.")
  if "address already in use" in msg.lower(): tips.append("Port conflict; stop other process or change port.")
  if "cannot connect to the docker daemon" in msg.lower(): tips.append("Is Docker running? Add user to docker group.")
  return tips

def ask_openrouter(prompt: str) -> str:
  key = os.getenv("OPENROUTER_API_KEY")
  if not key: return ""
  try:
    import urllib.request
    req = urllib.request.Request("https://openrouter.ai/api/v1/chat/completions",
      data=json.dumps({"model":"deepseek/deepseek-chat","messages":[{"role":"user","content": prompt}]}).encode("utf-8"),
      headers={"Content-Type":"application/json","Authorization":f"Bearer {key}","X-Title":"autorag-helper"})
    with urllib.request.urlopen(req, timeout=30) as resp:
      j = json.loads(resp.read().decode("utf-8"))
      return j.get("choices", [{}])[0].get("message",{}).get("content","")
  except Exception as e:
    return f"(OpenRouter error: {e})"

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument("--file", help="Path to a log/error file", default="")
  args = ap.parse_args()

  msg = open(args.file,"r",encoding="utf-8",errors="ignore").read() if args.file and os.path.exists(args.file) else sys.stdin.read()
  base_tips = local_rules(msg)
  print("=== Heuristics ===")
  for t in base_tips or ["(no obvious heuristic suggestions)"]:
    print(f"- {t}")
  or_tip = ask_openrouter(f"Explain and fix the following error log concisely:\n\n{msg[:8000]}")
  if or_tip:
    print("\n=== LLM Suggestion (OpenRouter) ===")
    print(or_tip)

if __name__ == "__main__":
  main()
```

---

## crews/ops_crew.yaml
```yaml
version: "1"
name: "ops_crew"
description: "Crew for deployment, ingestion, troubleshooting, and reporting"
agents:
  - id: deployer
    role: "DevOps Deployer"
    goal: "Provision Cloudflare + OCI, bring services up"
  - id: ingestor
    role: "Data Ingestor"
    goal: "Fetch docs, normalize, chunk, store, and trigger embeddings"
  - id: analyst
    role: "Doc Analyst"
    goal: "Run NLP/IE, produce facts/entities, and summarize stance"
  - id: troubleshooter
    role: "SRE Troubleshooter"
    goal: "Detect incidents and propose fixes"
tasks:
  - id: t1
    agent: deployer
    description: "Apply infra/cloudflare and infra/oci terraform"
  - id: t2
    agent: ingestor
    description: "Pull OpenDiscourse docs, write to Postgres, store embeddings"
  - id: t3
    agent: analyst
    description: "Run analyzer service and update Neo4j graph via GraphRAG"
  - id: t4
    agent: troubleshooter
    description: "Watch logs and run cbw_helper on failures"
```

---

## scripts/run_crew.py
```py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import yaml, pathlib

def main():
  path = pathlib.Path(__file__).resolve().parents[1] / "crews" / "ops_crew.yaml"
  y = yaml.safe_load(path.read_text("utf-8"))
  print("Crew:", y["name"])
  for t in y.get("tasks", []):
    print(f"- [{t['agent']}] {t['description']}")
if __name__ == "__main__":
  main()
```

---

## scripts/pyproject.toml
```toml
[project]
name = "autorag-ops-scripts"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = ["pyyaml>=6.0.1"]
```

---

## infra/cloudflare/main.tf
```hcl
terraform {
  required_providers {
    cloudflare = { source  = "cloudflare/cloudflare", version = ">= 5.8.0" }
  }
}
provider "cloudflare" { api_token = var.cloudflare_api_token }

variable "account_id" { type = string }
variable "zone_id"    { type = string }
variable "cloudflare_api_token" { type = string }

resource "cloudflare_r2_bucket" "blobs" {
  account_id = var.account_id
  name       = "autorag-blobs"
}

resource "cloudflare_pages_project" "web" {
  account_id        = var.account_id
  name              = "autorag-web"
  production_branch = "main"
}

output "r2_bucket_name" { value = cloudflare_r2_bucket.blobs.name }
```

---

## infra/cloudflare/variables.tf
```hcl
variable "pg_user"     { type = string, default = "postgres" }
variable "pg_password" { type = string, sensitive = true }
variable "pg_host"     { type = string }
variable "pg_db"       { type = string, default = "postgres" }
```

---

## infra/oci/main.tf
```hcl
terraform {
  required_providers { oci = { source = "oracle/oci" } }
}
provider "oci" {}

variable "compartment_ocid" {}
variable "availability_domain" {}
variable "ssh_public_key" {}
variable "instance_display_name" { default = "autorag-a1" }
variable "shape_ocpus" { default = 2 }
variable "shape_mem_gb" { default = 12 }

resource "oci_core_virtual_network" "vcn" {
  cidr_block     = "10.20.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "autorag-vcn"
}
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "autorag-igw"
  vcn_id         = oci_core_virtual_network.vcn.id
}
resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}
resource "oci_core_subnet" "subnet" {
  cidr_block = "10.20.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_virtual_network.vcn.id
  display_name = "autorag-subnet"
  route_table_id = oci_core_route_table.rt.id
  dns_label = "autorag"
  prohibit_public_ip_on_vnic = false
}
resource "oci_core_instance" "vm" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_display_name
  shape               = "VM.Standard.A1.Flex"
  shape_config { ocpus = var.shape_ocpus, memory_in_gbs = var.shape_mem_gb }
  create_vnic_details { subnet_id = oci_core_subnet.subnet.id, assign_public_ip = true }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(file("${path.module}/userdata-cloudinit.yaml"))
  }
}
output "public_ip" { value = oci_core_instance.vm.public_ip }
```

---

## infra/oci/userdata-cloudinit.yaml
```yaml
#cloud-config
package_update: true
packages:
  - git
  - curl
  - docker.io
  - python3

runcmd:
  - usermod -aG docker ubuntu || true
  - systemctl enable --now docker

  - curl -LsSf https://astral.sh/uv/install.sh | sh

  - mkdir -p /opt && cd /opt
  - if [ ! -d autorag-opendiscourse ]; then git clone https://example.com/autorag-opendiscourse.git; fi
  - cd autorag-opendiscourse

  - python3 scripts/gen_secrets.py || true
  - cd selfhost && ./bootstrap_supabase.sh || true
  - docker compose up -d || true

  - cd /opt/autorag-opendiscourse
  - /root/.local/bin/uv pip install -r scripts/requirements.txt
  - API_DATA_GOV_KEY=DEMO_KEY PG_DSN="postgresql://postgres:postgres@127.0.0.1:5432/postgres" python3 scripts/ingest_govinfo.py --since 2024-01-01 || true

  - echo "Boot complete at $(date)" >> /var/log/autorag-boot.log
```

---

## postman/Env.postman_environment.json
```json
{
  "id": "env-autorag",
  "name": "AutoRAG",
  "values": [
    {"key":"API_DATA_GOV_KEY","value":"your_key","enabled":true},
    {"key":"GOVINFO_BASE","value":"https://api.govinfo.gov","enabled":true},
    {"key":"CONGRESS_BASE","value":"https://api.congress.gov/v3","enabled":true}
  ],
  "_postman_variable_scope":"environment",
  "_postman_exported_using":"ChatGPT"
}
```

---

## postman/GovInfo Search.postman_collection.json
```json
{
  "info": {"name":"GovInfo Search Service","schema":"https://schema.getpostman.com/json/collection/v2.1.0/collection.json"},
  "item": [{
    "name":"Search",
    "request":{
      "method":"POST",
      "header":[{"key":"X-Api-Key","value":"{{API_DATA_GOV_KEY}}"}],
      "url":{"raw":"{{GOVINFO_BASE}}/search","host":["{{GOVINFO_BASE}}"],"path":["search"]},
      "body":{"mode":"raw","raw":"{\n  \"query\": \"collection:BILLSTATUS congress:118\",\n  \"pageSize\": 25,\n  \"offsetMark\": \"*\",\n  \"sorts\": [{\n    \"field\": \"publishdate\",\n    \"sortOrder\": \"DESC\"\n  }]\n}"}
    }
  }]
}
```

---

## postman/Congress.gov.postman_collection.json
```json
{
  "info": {"name":"Congress.gov API v3","schema":"https://schema.getpostman.com/json/collection/v2.1.0/collection.json"},
  "item": [{
    "name":"List Bills",
    "request":{
      "method":"GET",
      "url":{"raw":"{{CONGRESS_BASE}}/bill/118?api_key={{API_DATA_GOV_KEY}}&limit=20","host":["{{CONGRESS_BASE}}"],"path":["bill","118"],"query":[{"key":"api_key","value":"{{API_DATA_GOV_KEY}}"},{"key":"limit","value":"20"}]}
    }
  }]
}
```

---

## workflows/n8n example — workflows/ingest_opendiscourse.json
```json
{
  "name":"Ingest OpenDiscourse -> Analyze -> Persist",
  "nodes":[
    {"parameters":{}, "id":"cron", "name":"Cron","type":"n8n-nodes-base.cron","typeVersion":1,"position":[240,300]},
    {"parameters":{"method":"POST","url":"http://analyzer:8081/analyze","jsonParameters":true,"options":{},"bodyParametersJson":"={\"text\":$json[\"text\"]}"}, "id":"analyze","name":"Analyzer","type":"n8n-nodes-base.httpRequest","typeVersion":4,"position":[760,300]}
  ],
  "connections":{}
}
```

---

## .github/workflows/ingest.yml
```yaml
name: Nightly Ingest
on:
  schedule:
    - cron: '17 3 * * *'
  workflow_dispatch: {}

jobs:
  run-ingest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh
      - name: Install deps
        run: ~/.local/bin/uv pip install -r scripts/requirements.txt
      - name: GovInfo ingest
        env:
          API_DATA_GOV_KEY: ${{ secrets.API_DATA_GOV_KEY }}
          PG_DSN: ${{ secrets.PG_DSN }}
          WORKER_BASE: ${{ secrets.WORKER_BASE }}
        run: python3 scripts/ingest_govinfo.py --since 2024-01-01
      - name: Congress ingest
        env:
          API_DATA_GOV_KEY: ${{ secrets.API_DATA_GOV_KEY }}
          PG_DSN: ${{ secrets.PG_DSN }}
        run: python3 scripts/ingest_congress.py --congress 118 --sponsor "Warren"
```

---

## .github/workflows/deploy_worker.yml
```yaml
name: Deploy Worker
on:
  push:
    paths:
      - 'apps/worker/**'
  workflow_dispatch: {}

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cloudflare/wrangler-action@v3
        with:
          workingDirectory: apps/worker
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: publish
```

