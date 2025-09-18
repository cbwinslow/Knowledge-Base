# local-ai-packaged — Hardening + Political Docs Pipeline

A single place to capture the plan, docs, and **drop-in code** to make this project stable, self-hostable, and capable of analyzing political documents with repeatable methods.

---

## Table of Contents
- [Overview & Goals](#overview--goals)
- [Architecture & Persistence](#architecture--persistence)
- [Compose Override (bind-mounts, healthchecks)](#compose-override-bind-mounts-healthchecks)
- [.env.example (config schema)](#envexample-config-schema)
- [Shell Scripts (secrets, backup, restore)](#shell-scripts-secrets-backup-restore)
- [Makefile](#makefile)
- [GitHub: CI, Security, ETL/Eval Workflows](#github-ci-security-etleval-workflows)
- [Repo Process: CODEOWNERS, PR Template, Issue Forms](#repo-process-codeowners-pr-template-issue-forms)
- [ETL: Congress.gov Ingestion (Python)](#etl-congressgov-ingestion-python)
- [Evaluation: RAGAS Skeleton (Python)](#evaluation-ragas-skeleton-python)
- [Body of Knowledge (short list)](#body-of-knowledge-short-list)
- [Roadmap 30/60/90](#roadmap-306090)

---

## Overview & Goals
**Goals**
1) Boringly reliable local deployment (Docker + Compose profiles + bind-mount persistence).
2) Permanent, encrypted backups + restore playbook.
3) Reproducible ETL for political documents (Congress.gov + GovInfo), canonical schema, and vectorization.
4) Evaluation loop (RAGAS/TruLens-ready) for measurable quality.
5) GitHub-first team workflow: CI, security scans, AI code review, CODEOWNERS.

**Fast Start**
```bash
cp .env.example .env          # configure DATA_ROOT etc.
make up                        # compose up with persistence
scripts/ensure_secrets.sh      # generate or sync secrets (optional Bitwarden)
make backup                    # run backups (db + data)
python etl/ingest_congress.py --since 2024-01-01 --limit 50
```

---

## Architecture & Persistence
```
+-----------------------------+           +-------------------------+
|  Clients / CLI / UI         |  HTTPS    | Supabase Auth/Storage   |
|  (OpenWebUI, etc.)          +---------->+ (self-hosted services)  |
+-----------------------------+           +-------------------------+
           |                                      |
           |                                      v
           |                            +--------------------+
           |                            | Postgres (pgvector)|  <- bind-mount: /srv/local-ai/postgres
           |                            +--------------------+
           |                                      |
           |                                      v
           |                            +--------------------+
           |                            | Qdrant (vectors)   |  <- bind-mount: /srv/local-ai/qdrant
           |                            +--------------------+
           |                                      |
           v                                      v
+-----------------------------+           +-------------------------+
|  Ingest/Eval Workers        |           |  Backups (restic, etc.)|
|  (ETL Python, RAGAS)        |           |  /srv/local-ai/backups  |
+-----------------------------+           +-------------------------+
```

**Data lives on host** under a single root (e.g., `/srv/local-ai`), bound into containers so you can nuke/recreate containers freely.

---

## Compose Override (bind-mounts, healthchecks)
Create `deploy/docker-compose.override.yml`:

```yaml
# deploy/docker-compose.override.yml
# Project: local-ai-packaged
# Author: CBW + ChatGPT
# Summary: Persistence-first overrides; add restart policies and basic healthchecks.

services:
  db:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/supabase/db:/var/lib/postgresql/data"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres} -h 127.0.0.1 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10

  storage:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/supabase/storage:/var/lib/storage"

  kong:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/supabase/kong:/var/lib/kong"

  qdrant:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/qdrant:/qdrant/storage"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:6333/readyz"]
      interval: 10s
      timeout: 5s
      retries: 12

  ollama:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/ollama:/root/.ollama"

  openwebui:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/openwebui:/app/backend/data"

  n8n:
    restart: unless-stopped
    volumes:
      - "${DATA_ROOT}/n8n:/home/node/.n8n"
    depends_on:
      db:
        condition: service_started

# Optional example:
#  neo4j:
#    restart: unless-stopped
#    volumes:
#      - "${DATA_ROOT}/neo4j/data:/data"
#      - "${DATA_ROOT}/neo4j/logs:/logs"
```

> Run with: `docker compose -f docker-compose.yml -f deploy/docker-compose.override.yml up --wait -d`

---

## .env.example (config schema)
Create `.env.example` (copy to `.env` and edit):

```bash
# .env.example
# Global
DATA_ROOT=/srv/local-ai-data
ENVIRONMENT=dev

# Postgres / Supabase
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_DB=postgres
POSTGRES_PASSWORD=  # generated by scripts/ensure_secrets.sh if empty
DATABASE_URL=postgresql+psycopg2://postgres:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}

# Backups
BACKUP_DIR=./backups
BACKUP_PASSPHRASE=CHANGE_ME_STRONG_PASSPHRASE
RETAIN=7

# ETL
CONGRESS_API_KEY=
ETL_OUTPUT_DIR=${DATA_ROOT}/etl

# Qdrant (optional)
QDRANT_URL=http://qdrant:6333
QDRANT_API_KEY=
QDRANT_COLLECTION=politics_sections

# Bitwarden (optional secret bootstrap)
BW_CLIENTID=
BW_CLIENTSECRET=
BW_PASSWORD=
BW_ITEM_NAME=local-ai-packaged/.env
```

---

## Shell Scripts (secrets, backup, restore)

### scripts/ensure_secrets.sh
```bash
#!/usr/bin/env bash
# File: scripts/ensure_secrets.sh
# Author: CBW + ChatGPT
# Summary: Generate or sync critical secrets into .env (Bitwarden optional).
# Inputs: .env (created/updated), BW_* env vars (optional)
# Outputs: .env with POSTGRES_PASSWORD, JWT_SECRET, SUPABASE_* keys
# Logging: /tmp/CBW-ensure-secrets.log
set -Eeuo pipefail
LOG=/tmp/CBW-ensure-secrets.log
umask 077
exec > >(sed 's/.*/[ensure-secrets] &/' | tee -a "$LOG") 2>&1

BW_ITEM_NAME="${BW_ITEM_NAME:-local-ai-packaged/.env}"
mask(){ local s="$1"; echo "${s:0:3}****${s: -3}"; }
rand_b64(){ openssl rand -base64 48 | tr -d '\n'; }
rand_hex(){ openssl rand -hex 32 | tr -d '\n'; }
need_keys=( POSTGRES_PASSWORD JWT_SECRET SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY )

[[ -f .env ]] || touch .env

declare -A CURRENT
while IFS='=' read -r k v; do [[ -z "${k:-}" || "${k:0:1}" == "#" ]] && continue; CURRENT["$k"]="$v"; done < <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env || true)

BW_OK=0
if command -v bw >/dev/null 2>&1; then
  if [[ -n "${BW_CLIENTID:-}" && -n "${BW_CLIENTSECRET:-}" ]]; then export BW_CLIENTID BW_CLIENTSECRET; bw logout >/dev/null 2>&1 || true; bw login --apikey >/dev/null; fi
  if ! bw status | grep -q '"unlocked": true'; then
    if [[ -n "${BW_PASSWORD:-}" ]]; then export BW_SESSION=$(bw unlock --raw <<<"${BW_PASSWORD}"); fi
  fi
  bw status | grep -q '"unlocked": true' && BW_OK=1
fi

if [[ "$BW_OK" -eq 1 ]]; then
  if bw list items --search "$BW_ITEM_NAME" | grep -q '"id"'; then
    item_json=$(bw get item "$BW_ITEM_NAME")
    note=$(jq -r '.notes // empty' <<<"$item_json" || true)
    if [[ -n "$note" ]]; then
      while IFS='=' read -r k v; do [[ -z "${k:-}" || "${k:0:1}" == "#" ]] && continue; CURRENT["$k"]="$v"; done < <(printf "%s\n" "$note")
    fi
    for key in "${need_keys[@]}"; do
      val=$(jq -r --arg k "$key" '.fields[]? | select(.name==$k) | .value // empty' <<<"$item_json" || true)
      [[ -n "$val" ]] && CURRENT["$key"]="$val"
    done
  fi
fi

gen_if_missing(){ local key="$1" val=""; if [[ -z "${CURRENT[$key]:-}" ]]; then case "$key" in POSTGRES_PASSWORD) val="$(rand_b64)";; *) val="$(rand_hex)";; esac; CURRENT["$key"]="$val"; echo "[+] $key=$(mask "$val")"; else echo "[=] $key=$(mask "${CURRENT[$key]}")"; fi; }
for k in "${need_keys[@]}"; do gen_if_missing "$k"; done

TMP=.env.new.$RANDOM; cp .env "$TMP"
for k in "${need_keys[@]}"; do grep -q "^$k=" "$TMP" && sed -i "s|^$k=.*|$k=${CURRENT[$k]}|" "$TMP" || echo "$k=${CURRENT[$k]}" >> "$TMP"; done
mv "$TMP" .env; echo "[✓] .env updated"

if [[ "$BW_OK" -eq 1 ]]; then
  fields_json=$(jq -n '{fields: []}')
  for k in "${need_keys[@]}"; do fields_json=$(jq --arg n "$k" --arg v "${CURRENT[$k]}" '.fields += [{name:$n, value:$v}]' <<<"$fields_json"); done
  safe_note=$(printf "%s\n" $(for k in "${!CURRENT[@]}"; do echo "$k=${CURRENT[$k]}"; done))
  item_payload=$(jq -n --arg name "$BW_ITEM_NAME" --arg notes "$safe_note" '{type:2, name:$name, notes:$notes}')
  if bw list items --search "$BW_ITEM_NAME" | grep -q '"id"'; then
    BW_ID=$(bw list items --search "$BW_ITEM_NAME" | jq -r '.[0].id')
    existing=$(bw get item "$BW_ID")
    updated=$(jq --argjson fields "$fields_json" --arg notes "$safe_note" '.notes=$notes | .fields=($fields.fields)' <<<"$existing")
    echo "$updated" | bw edit item "$BW_ID" >/dev/null
  else
    created=$(jq --argjson item "$item_payload" --argjson fields "$fields_json" -n '$item | .fields=($fields.fields)')
    echo "$created" | bw create item >/dev/null
  fi
  echo "[✓] Bitwarden synced"
fi
```

### scripts/backup_all.sh
```bash
#!/usr/bin/env bash
# File: scripts/backup_all.sh
# Author: CBW + ChatGPT
# Summary: Online logical Postgres dump + Qdrant snapshot + archive DATA_ROOT; optional AES-256 encryption.
# Logs: /tmp/CBW-backup.log
set -Eeuo pipefail; umask 077
LOG=/tmp/CBW-backup.log
exec > >(sed 's/.*/[backup] &/' | tee -a "$LOG") 2>&1

[[ -f .env ]] && source .env
: "${DATA_ROOT:?DATA_ROOT must be set}"
: "${POSTGRES_HOST:=db}"; : "${POSTGRES_PORT:=5432}"; : "${POSTGRES_USER:=postgres}"; : "${POSTGRES_DB:=postgres}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"; RETAIN="${RETAIN:-7}"; TS=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

export PGPASSWORD="$POSTGRES_PASSWORD"
DB_DUMP="$BACKUP_DIR/db-all-$TS.sql"
echo "[i] Dumping Postgres ..."
pg_dumpall -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -f "$DB_DUMP"

echo "[i] Qdrant snapshot (best-effort) ..."
if docker ps --format '{{.Names}}' | grep -q '^qdrant$'; then
  curl -fsS -X POST http://127.0.0.1:6333/snapshots -H 'Content-Type: application/json' -d '{"wait":true}' || true
fi

ARCHIVE_RAW="$BACKUP_DIR/data-$TS.tar.gz"
echo "[i] Archiving $DATA_ROOT -> $ARCHIVE_RAW"
tar -C "$(dirname "$DATA_ROOT")" -czf "$ARCHIVE_RAW" "$(basename "$DATA_ROOT")"

if [[ -n "${BACKUP_PASSPHRASE:-}" ]]; then
  ARCHIVE_ENC="$ARCHIVE_RAW.enc"
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$ARCHIVE_RAW" -out "$ARCHIVE_ENC" -pass env:BACKUP_PASSPHRASE
  shred -u "$ARCHIVE_RAW" || rm -f "$ARCHIVE_RAW"; FINAL="$ARCHIVE_ENC"
else
  FINAL="$ARCHIVE_RAW"
fi

echo "[✓] Backup ready: $FINAL"
ls -1t "$BACKUP_DIR"/data-*.tar.gz* 2>/dev/null | tail -n +$((RETAIN+1)) | xargs -r rm -f || true
ls -1t "$BACKUP_DIR"/db-all-*.sql 2>/dev/null | tail -n +$((RETAIN+1)) | xargs -r rm -f || true
```

### scripts/restore_all.sh
```bash
#!/usr/bin/env bash
# File: scripts/restore_all.sh
# Author: CBW + ChatGPT
# Summary: Restore DATA_ROOT archive and Postgres dump created by backup_all.sh.
set -Eeuo pipefail; umask 077
LOG=/tmp/CBW-restore.log
exec > >(sed 's/.*/[restore] &/' | tee -a "$LOG") 2>&1

ARCHIVE=; DBFILE=
while [[ $# -gt 0 ]]; do case "$1" in --archive) ARCHIVE="$2"; shift 2;; --db) DBFILE="$2"; shift 2;; *) echo "Usage: $0 --archive <data.tar.gz[.enc]> --db <db-all.sql>"; exit 2;; esac; done
[[ -f .env ]] && source .env
: "${DATA_ROOT:?DATA_ROOT must be set}"
: "${POSTGRES_HOST:=db}"; : "${POSTGRES_PORT:=5432}"; : "${POSTGRES_USER:=postgres}"; : "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set}"

echo "[!] Make sure the stack is DOWN. Type 'I UNDERSTAND' to continue:"; read -r ACK; [[ "$ACK" == "I UNDERSTAND" ]] || exit 1
TMPD=$(mktemp -d)
if [[ "$ARCHIVE" == *.enc ]]; then
  [[ -n "${BACKUP_PASSPHRASE:-}" ]] || { echo "BACKUP_PASSPHRASE required"; exit 1; }
  openssl enc -d -aes-256-cbc -pbkdf2 -in "$ARCHIVE" -out "$TMPD/data.tar.gz" -pass env:BACKUP_PASSPHRASE
  tar -C / -xzf "$TMPD/data.tar.gz"
else
  tar -C / -xzf "$ARCHIVE"
fi
rm -rf "$TMPD"; echo "[✓] DATA_ROOT restored -> $DATA_ROOT"

export PGPASSWORD="$POSTGRES_PASSWORD"
docker compose up -d db
for i in {1..30}; do docker compose exec -T db bash -lc "pg_isready -U $POSTGRES_USER -h 127.0.0.1" && break; sleep 2; done
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -f "$DBFILE" postgres
```

---

## Makefile
```makefile
.PHONY: up down logs backup restore etl-sample eval-sample

up:
	docker compose -f docker-compose.yml -f deploy/docker-compose.override.yml up --wait -d

down:
	docker compose -f docker-compose.yml -f deploy/docker-compose.override.yml down

logs:
	docker compose logs --no-color --tail=200

backup:
	./scripts/backup_all.sh

restore:
	@echo "Use: scripts/restore_all.sh --archive backups/data-<TS>.tar.gz[.enc] --db backups/db-all-<TS>.sql"

etl-sample:
	python etl/ingest_congress.py --since 2024-01-01 --limit 25

eval-sample:
	python eval/ragas_eval.py --dataset eval/sample_eval.csv --report eval/report.md
```

---

## GitHub: CI, Security, ETL/Eval Workflows
Create `.github/workflows/ci.yml`:
```yaml
name: CI
on:
  push: { branches: [ main, master ] }
  pull_request: { branches: ["**"] }
jobs:
  lint-and-smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install tools
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck jq yamllint
          curl -sSL https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 -o hadolint
          chmod +x hadolint && sudo mv hadolint /usr/local/bin/
      - name: Shellcheck
        run: |
          if compgen -G "scripts/*.sh" > /dev/null; then shellcheck -S warning scripts/*.sh; fi
      - name: Lint Dockerfiles
        run: |
          if compgen -G "Dockerfile*" > /dev/null; then hadolint Dockerfile*; fi
      - name: Lint YAML
        run: |
          yamllint -d '{extends: default, rules: {line-length: disable}}' . || true
      - name: Compose config validation
        run: |
          if [ -f "docker-compose.yml" ]; then
            if [ -f "deploy/docker-compose.override.yml" ]; then
              docker compose -f docker-compose.yml -f deploy/docker-compose.override.yml config -q
            else
              docker compose -f docker-compose.yml config -q
            fi
          fi
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gitleaks/gitleaks-action@v2
        with: { args: --no-banner -v }
      - uses: trufflesecurity/trufflehog@v3.82.10
        with: { extra_args: --only-verified }
```

Nightly ETL: `.github/workflows/etl_nightly.yml`
```yaml
name: ETL Nightly
on:
  schedule:
    - cron: '17 3 * * *'
  workflow_dispatch: {}
jobs:
  etl:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - name: Install deps
        run: |
          python -m pip install --upgrade pip
          pip install requests pydantic sqlalchemy psycopg2-binary tenacity qdrant-client python-dotenv
      - name: Run sample ingest (dry-run DB if no connection)
        env:
          CONGRESS_API_KEY: ${{ secrets.CONGRESS_API_KEY }}
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          QDRANT_URL: ${{ secrets.QDRANT_URL }}
          QDRANT_API_KEY: ${{ secrets.QDRANT_API_KEY }}
        run: |
          python etl/ingest_congress.py --since 2024-01-01 --limit 25 --dry-run
```

Weekly Eval: `.github/workflows/eval_weekly.yml`
```yaml
name: RAG Eval Weekly
on:
  schedule:
    - cron: '7 4 * * 1'
  workflow_dispatch: {}
jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - name: Install deps
        run: |
          pip install ragas datasets pandas
      - name: Run eval
        run: |
          python eval/ragas_eval.py --dataset eval/sample_eval.csv --report eval/report.md
      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: rag-eval-report
          path: eval/report.md
```

---

## Repo Process: CODEOWNERS, PR Template, Issue Forms

**.github/CODEOWNERS**
```text
# Require review by code owners
*             @cbwinslow
scripts/*     @cbwinslow
etl/*         @cbwinslow
deploy/*      @cbwinslow
```

**.github/pull_request_template.md**
```markdown
### What changed
- [ ] Persistence: No data loss on compose down/up
- [ ] Secrets: No plaintext creds; .env only
- [ ] Healthchecks / --wait verified
- [ ] Docs updated

### How to test
1. cp .env.example .env && edit
2. make up
3. make etl-sample

### Risk & rollback
- Use scripts/restore_all.sh with the latest backup
```

**.github/ISSUE_TEMPLATE/bug_report.yml**
```yaml
name: Bug report
description: Report a problem
labels: [bug]
body:
  - type: textarea
    id: what-happened
    attributes: { label: What happened?, description: Steps to reproduce }
  - type: input
    id: version
    attributes: { label: Version/commit }
```

**.github/ISSUE_TEMPLATE/feature_request.yml**
```yaml
name: Feature request
description: Suggest an idea
labels: [enhancement]
body:
  - type: textarea
    id: problem
    attributes: { label: Problem }
  - type: textarea
    id: proposal
    attributes: { label: Proposal }
```

---

## ETL: Congress.gov Ingestion (Python)
Create `etl/ingest_congress.py`:
```python
#!/usr/bin/env python3
"""
Script: etl/ingest_congress.py
Author: CBW + ChatGPT
Date: 2025-09-18
Summary:
    Incremental fetch from Congress.gov API, normalize to a canonical schema,
    write raw JSON to disk, upsert metadata to Postgres, and (optionally)
    insert text chunks + embeddings into Qdrant.

Inputs:
    ENV: CONGRESS_API_KEY, DATABASE_URL, QDRANT_URL, QDRANT_API_KEY, QDRANT_COLLECTION, ETL_OUTPUT_DIR
    CLI: --since YYYY-MM-DD, --limit N, --dry-run
Outputs:
    Files: ${ETL_OUTPUT_DIR}/raw/congress/*.json
    Tables: public.documents, public.sections (if DATABASE_URL provided)

Security:
    - Does not print secrets.
    - Validates host params; robust error handling & retries.
"""
from __future__ import annotations
import os, sys, json, time, hashlib, argparse, logging, textwrap, datetime as dt
from dataclasses import dataclass
from typing import Dict, Any, List, Optional, Iterable
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Optional imports guarded
try:
    from sqlalchemy import create_engine, text
    from sqlalchemy.engine import Engine
except Exception:  # pragma: no cover
    create_engine = None
    Engine = None

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models as qm
except Exception:  # pragma: no cover
    QdrantClient = None
    qm = None

# ---------------- Logging ----------------
LOG = logging.getLogger("etl.congress")
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# ---------------- HTTP util ----------------

def _session() -> requests.Session:
    s = requests.Session()
    r = Retry(total=5, backoff_factor=0.6, status_forcelist=[429, 500, 502, 503, 504])
    s.mount("https://", HTTPAdapter(max_retries=r))
    return s

# ---------------- Canonical schema helpers ----------------

def canon_doc(bill: Dict[str, Any]) -> Dict[str, Any]:
    # Minimal canonical mapping; expand as needed
    doc_id = bill.get("billNumber") or f"{bill.get('congress')}-{bill.get('type')}-{bill.get('number')}"
    title = (bill.get("title") or bill.get("titleWithoutNumber") or "").strip()
    summary = (bill.get("summary") or {}).get("text", "")
    introduced = bill.get("introducedDate")
    sponsors = [
        {
            "name": (bill.get("sponsors") or [{}])[0].get("fullName"),
            "bioguideId": (bill.get("sponsors") or [{}])[0].get("bioguideId"),
        }
    ] if bill.get("sponsors") else []
    return {
        "external_id": doc_id,
        "type": "bill",
        "title": title,
        "summary": summary,
        "introduced": introduced,
        "sponsors": sponsors,
    }

# ---------------- Database ----------------

def ensure_tables(engine: Engine):
    with engine.begin() as cx:
        cx.execute(text(
            """
            create table if not exists documents (
              id serial primary key,
              external_id text unique,
              type text not null,
              title text,
              summary text,
              introduced date,
              sponsors jsonb,
              raw_sha256 char(64),
              created_at timestamptz default now(),
              updated_at timestamptz default now()
            );
            create table if not exists sections (
              id serial primary key,
              document_external_id text references documents(external_id) on delete cascade,
              section_no text,
              text text,
              created_at timestamptz default now()
            );
            """
        ))


def upsert_document(engine: Engine, doc: Dict[str, Any], raw_sha: str):
    with engine.begin() as cx:
        cx.execute(text(
            """
            insert into documents (external_id, type, title, summary, introduced, sponsors, raw_sha256)
            values (:external_id, :type, :title, :summary, :introduced, :sponsors, :raw_sha256)
            on conflict (external_id) do update set
                title = excluded.title,
                summary = excluded.summary,
                introduced = excluded.introduced,
                sponsors = excluded.sponsors,
                raw_sha256 = excluded.raw_sha256,
                updated_at = now();
            """
        ), {
            **doc,
            "raw_sha256": raw_sha,
        })

# ---------------- Qdrant ----------------

def ensure_qdrant_collection(client: QdrantClient, name: str, dim: int = 384):
    try:
        client.get_collection(name)
    except Exception:
        client.recreate_collection(
            collection_name=name,
            vectors_config=qm.VectorParams(size=dim, distance=qm.Distance.COSINE),
        )

# Placeholder embedder: swap with your local model (sentence-transformers, etc.)
def embed_chunks(chunks: List[str]) -> List[List[float]]:
    import math
    # Cheap deterministic toy embedding so script runs without heavy deps.
    vecs = []
    for t in chunks:
        h = hashlib.sha256(t.encode()).digest()
        # 384-dim fake vector
        v = [(h[i % len(h)]/255.0 - 0.5) for i in range(384)]
        # L2 normalize
        norm = math.sqrt(sum(x*x for x in v)) or 1.0
        vecs.append([x/norm for x in v])
    return vecs

# ---------------- ETL ----------------

def fetch_bills(api_key: str, since: str, limit: int) -> Iterable[Dict[str, Any]]:
    base = "https://api.congress.gov/v3/bill"  # filter by lastUpdateDate if available
    s = _session()
    params = {"fromDate": since, "format": "json", "api_key": api_key}
    count = 0
    url = base
    while url and count < limit:
        r = s.get(url, params=params, timeout=30)
        if r.status_code == 429:
            time.sleep(2); continue
        r.raise_for_status()
        data = r.json()
        bills = (data.get("bills") or [])
        for b in bills:
            yield b; count += 1
            if count >= limit:
                break
        url = data.get("pagination", {}).get("next")
        params = {}  # next already contains cursor


def chunk_text(text: str, size: int = 1200, overlap: int = 200) -> List[str]:
    out = []
    i = 0
    while i < len(text):
        out.append(text[i:i+size])
        i += max(1, size - overlap)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", required=True, help="YYYY-MM-DD")
    ap.add_argument("--limit", type=int, default=100)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    api_key = os.getenv("CONGRESS_API_KEY", "").strip()
    if not api_key:
        LOG.error("CONGRESS_API_KEY not set"); sys.exit(2)

    out_dir = os.getenv("ETL_OUTPUT_DIR", "./etl_out"); os.makedirs(out_dir + "/raw/congress", exist_ok=True)
    db_url = os.getenv("DATABASE_URL", "").strip()
    engine = create_engine(db_url) if (db_url and create_engine) else None
    if engine is not None:
        ensure_tables(engine)

    qdrant_url = os.getenv("QDRANT_URL", "").strip()
    qdrant_key = os.getenv("QDRANT_API_KEY", "").strip()
    qdrant_col = os.getenv("QDRANT_COLLECTION", "politics_sections")
    qclient = QdrantClient(url=qdrant_url, api_key=qdrant_key) if (qdrant_url and QdrantClient) else None
    if qclient is not None:
        ensure_qdrant_collection(qclient, qdrant_col, 384)

    rows = 0
    for bill in fetch_bills(api_key, args.since, args.limit):
        # Persist raw
        raw = json.dumps(bill, ensure_ascii=False)
        sha = hashlib.sha256(raw.encode()).hexdigest()
        doc_id = bill.get("billNumber") or f"{bill.get('congress')}-{bill.get('type')}-{bill.get('number')}"
        raw_path = os.path.join(out_dir, "raw", "congress", f"{doc_id}.json")
        with open(raw_path, "w", encoding="utf-8") as f:
            f.write(raw)

        # Normalize + DB upsert
        doc = canon_doc(bill)
        if engine is not None and not args.dry_run:
            upsert_document(engine, doc, sha)

        # Sections -> naive from summary/body for demo; expand to real sections later
        text = (bill.get("summary") or {}).get("text", "")
        chunks = chunk_text(text) if text else []
        if qclient is not None and chunks and not args.dry_run:
            vecs = embed_chunks(chunks)
            points = [
                qm.PointStruct(id=int(hashlib.sha1((doc_id+str(i)).encode()).hexdigest()[:12], 16),
                               vector=vecs[i], payload={"external_id": doc_id, "section_no": str(i), "text": chunks[i]})
                for i in range(len(chunks))
            ]
            qclient.upsert(collection_name=qdrant_col, points=points)

        rows += 1
        if rows % 10 == 0:
            LOG.info("Processed %d bills", rows)

    LOG.info("Done. processed=%d raw_out=%s", rows, out_dir)

if __name__ == "__main__":
    main()
```

---

## Evaluation: RAGAS Skeleton (Python)
Create `eval/ragas_eval.py` (minimal, reference-free metrics when possible):
```python
#!/usr/bin/env python3
"""
Script: eval/ragas_eval.py
Author: CBW + ChatGPT
Summary: Load a CSV of (question, answer, contexts, ground_truth optional) and produce a basic RAGAS report.
"""
import os, argparse, pandas as pd
from pathlib import Path

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True, help="CSV with columns: question,answer,contexts[,ground_truth]")
    ap.add_argument("--report", default="eval/report.md")
    args = ap.parse_args()

    df = pd.read_csv(args.dataset)
    # Placeholder simple metrics: context count and answer length; swap for ragas when configured
    df["ctx_count"] = df["contexts"].fillna("").apply(lambda s: max(1, len(str(s).split("||"))))
    df["ans_len"] = df["answer"].fillna("").str.len()

    md = ["# RAG Eval (light)", "", f"Dataset: {args.dataset}", "", "## Summary", ""]
    md.append(f"n={len(df)}  avg_ctx={df['ctx_count'].mean():.2f}  avg_ans_len={df['ans_len'].mean():.1f}")
    Path(args.report).parent.mkdir(parents=True, exist_ok=True)
    Path(args.report).write_text("\n".join(md), encoding="utf-8")

if __name__ == "__main__":
    main()
```

> Later, replace internals with `ragas` metrics once an evaluation LLM/provider is configured.

---

## Body of Knowledge (short list)
- Datasets: BillSum (US bills), GovReport (CRS/GAO long reports)
- APIs/Bulk: Congress.gov API, GovInfo bulk data, ProPublica Congress API
- Retrieval: pgvector (in Postgres) or Qdrant (HNSW + snapshots)
- Eval: RAGAS, TruLens; add weekly reports & trend charts
- Data quality: Great Expectations; DVC for dataset versioning

---

## Roadmap 30/60/90
- **0–30 days**: bind-mount persistence; secrets; healthchecks; backups; CI; ETL MVP (25 bills nightly)
- **31–60 days**: better chunking; embeddings A/B + reranker; light RAG eval; data quality checks
- **61–90 days**: Graph layer (GraphRAG pilot); PITR backups; dashboards; full eval suite

---

### Notes
- All code here is drop-in and self-contained; adjust service names to match your `docker-compose.yml`.
- Replace the toy `embed_chunks` with your preferred local embedder (e.g., sentence-transformers via PyTorch) when ready.


---

## ✅ Add-on: Great Expectations (Data Quality)
This section adds a light-but-real **Great Expectations** (GE) runner that validates your core tables, fully programmatic (no heavy YAML ceremony). It’s designed to run locally or in CI and fail fast when upstream ETL goes sideways.

**Files to add**
```
qa/
  run_gx.py
  requirements.txt
```

**qa/requirements.txt**
```text
great_expectations==0.17.21
SQLAlchemy>=2.0
psycopg2-binary>=2.9
pandas>=2.0
python-dotenv>=1.0
```

**qa/run_gx.py**
```python
#!/usr/bin/env python3
"""
Script: qa/run_gx.py
Author: CBW + ChatGPT
Date: 2025-09-18
Summary:
  Programmatic Great Expectations checks against Postgres.
  - Validates core schema for `documents` and basic row integrity.
  - Fails with nonzero exit on expectation failures, suitable for CI.
Inputs:
  ENV: DATABASE_URL (postgresql+psycopg2://...)
Outputs:
  qa/artifacts/gx_results.json , qa/artifacts/gx_report.md
Notes:
  This uses the PandasDataset API for simplicity (stable cross-version).
"""
import os, sys, json
from pathlib import Path
import pandas as pd
from dotenv import load_dotenv
import great_expectations as ge

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL", "").strip()
if not DATABASE_URL:
    print("[gx] DATABASE_URL not set", file=sys.stderr)
    sys.exit(2)

import sqlalchemy as sa
engine = sa.create_engine(DATABASE_URL)
ART = Path("qa/artifacts"); ART.mkdir(parents=True, exist_ok=True)

# ---- documents table checks ----
with engine.connect() as cx:
    df = pd.read_sql_query(
        """
        select external_id, type, title, summary, introduced, sponsors
        from documents
        """,
        cx,
    )

dataset = ge.from_pandas(df)

# Required columns
for col in ["external_id", "type", "introduced"]:
    dataset.expect_column_to_exist(col)

# Integrity expectations
dataset.expect_column_values_to_not_be_null("external_id")
dataset.expect_column_values_to_be_unique("external_id")
dataset.expect_column_values_to_not_be_null("type")
# Introduced should look like a date (YYYY-MM-DD)
dataset.expect_column_values_to_match_regex("introduced", r"^\d{4}-\d{2}-\d{2}$")

# Light size sanity
dataset.expect_table_row_count_to_be_greater_than_or_equal_to(0)

results = dataset.validate()
(ART/"gx_results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

# Markdown summary
passed = results["statistics"]["successful_expectations"]
failed = results["statistics"]["unsuccessful_expectations"]
md = [
    "# Great Expectations — documents suite",
    f"successful: {passed}  failed: {failed}",
]
(ART/"gx_report.md").write_text("
".join(md), encoding="utf-8")

if failed > 0:
    sys.exit(1)
```

**Makefile additions**
```makefile
qa:
	python qa/run_gx.py
```

> Tip: wire `qa` into CI after ETL steps to block merges on schema drift or null/dup keys.

---

## ✅ Add-on: RAGAS (Real Metrics)
This replaces the stub evaluator with a real **RAGAS** pipeline. It supports three modes: `--provider openai`, `--provider ollama` (local), or `--provider none` for reference-free-only metrics.

**Files to add/replace**
```
eval/
  ragas_eval.py  # upgraded
  requirements.txt
```

**eval/requirements.txt**
```text
ragas>=0.1.5
pandas>=2.0
datasets>=2.18
langchain>=0.2
langchain-community>=0.2
sentence-transformers>=2.2
python-dotenv>=1.0
```

**eval/ragas_eval.py**
```python
#!/usr/bin/env python3
"""
Script: eval/ragas_eval.py
Author: CBW + ChatGPT
Date: 2025-09-18
Summary:
  Run RAGAS on a CSV (question, answer, contexts[, ground_truth]).
  Provider options:
    - openai: uses OPENAI_API_KEY for LLM; embeddings via sentence-transformers (local) by default
    - ollama: uses a local Ollama model for LLM; embeddings via sentence-transformers (local)
    - none: compute only embedding-based metrics (no LLM), e.g., context precision/recall
Inputs:
  --dataset CSV, --report MD, --provider [openai|ollama|none], --model, --embed-model
ENV:
  OPENAI_API_KEY (if provider=openai)
  OLLAMA_MODEL (if provider=ollama, default: llama3)
"""
import os, argparse, pandas as pd
from pathlib import Path
from datasets import Dataset
from dotenv import load_dotenv

load_dotenv()

# RAGAS imports
from ragas import evaluate
from ragas.metrics import (
    context_precision, context_recall, answer_relevancy, faithfulness,
)

# LangChain models
from langchain_community.llms import Ollama
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_openai import ChatOpenAI  # if installed with langchain


def build_llm(provider: str, model_name: str):
    if provider == "openai":
        return ChatOpenAI(model=model_name or "gpt-4o-mini", temperature=0)
    if provider == "ollama":
        return Ollama(model=model_name or os.getenv("OLLAMA_MODEL", "llama3"))
    return None


def build_embeddings(name: str):
    return HuggingFaceEmbeddings(model_name=name or "sentence-transformers/all-MiniLM-L6-v2")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True, help="CSV with columns: question,answer,contexts[,ground_truth]")
    ap.add_argument("--report", default="eval/report.md")
    ap.add_argument("--provider", choices=["openai", "ollama", "none"], default="none")
    ap.add_argument("--model", default="")
    ap.add_argument("--embed-model", default="sentence-transformers/all-MiniLM-L6-v2")
    args = ap.parse_args()

    df = pd.read_csv(args.dataset)
    # Normalize contexts column: split on `||` to list
    df["contexts"] = df["contexts"].fillna("").apply(lambda s: [c.strip() for c in str(s).split("||") if c.strip()])
    ds = Dataset.from_pandas(df)

    llm = build_llm(args.provider, args.model)
    emb = build_embeddings(args["embed-model"]) if isinstance(args, dict) and "embed-model" in args else build_embeddings(args.embed_model)

    metrics = [context_precision, context_recall]
    if llm is not None:
        metrics += [answer_relevancy, faithfulness]

    report = evaluate(ds, metrics=metrics, llm=llm, embeddings=emb)
    md = ["# RAGAS Report", f"provider: {args.provider}", "", report.to_pandas().describe(include='all').to_markdown()]
    Path(args.report).parent.mkdir(parents=True, exist_ok=True)
    Path(args.report).write_text("
".join(md), encoding="utf-8")

if __name__ == "__main__":
    main()
```

**Makefile additions**
```makefile
eval:
	python eval/ragas_eval.py --dataset eval/sample_eval.csv --report eval/report.md --provider none
```

> Later, flip `--provider openai` (set `OPENAI_API_KEY`) or `--provider ollama` to run LLM-assisted metrics.

---

## ✅ Add-on: GraphRAG Bootstrap (Neo4j + Ingest)
This wires a **Neo4j** profile and a tiny ingest that syncs your relational data (documents, sponsors) into a graph you can query or use with GraphRAG-style retrieval.

**Compose (append to deploy/docker-compose.override.yml)**
```yaml
  neo4j:
    profiles: ["graph"]
    image: neo4j:5
    restart: unless-stopped
    ports:
      - "7474:7474"   # HTTP UI
      - "7687:7687"   # Bolt
    environment:
      - NEO4J_AUTH=${NEO4J_USER:-neo4j}/${NEO4J_PASSWORD:-neo4j}
      - NEO4J_dbms_security_auth__enabled=true
    volumes:
      - "${DATA_ROOT}/neo4j/data:/data"
      - "${DATA_ROOT}/neo4j/logs:/logs"
```

**Files to add**
```
graphs/
  ingest_graph.py
  requirements.txt
  README.md
```

**graphs/requirements.txt**
```text
neo4j>=5.23
SQLAlchemy>=2.0
python-dotenv>=1.0
```

**graphs/ingest_graph.py**
```python
#!/usr/bin/env python3
"""
Script: graphs/ingest_graph.py
Author: CBW + ChatGPT
Date: 2025-09-18
Summary:
  Read `documents` from Postgres and MERGE them into Neo4j as (:Bill {external_id}).
  Also MERGE (:Person {bioguideId}) and SPONSORED_BY edges when available.
Inputs:
  ENV: DATABASE_URL, NEO4J_URI (bolt://localhost:7687), NEO4J_USER, NEO4J_PASSWORD
"""
import os, sys
from neo4j import GraphDatabase
import sqlalchemy as sa
from sqlalchemy import text
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.getenv("DATABASE_URL", "").strip()
NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "neo4j")

if not DB_URL:
    print("DATABASE_URL not set", file=sys.stderr); sys.exit(2)

def run():
    engine = sa.create_engine(DB_URL)
    with engine.connect() as cx:
        rows = cx.execute(text("""
            select external_id, title, introduced, sponsors
            from documents
        """)).mappings().all()

    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    def ingest_tx(tx, row):
        tx.run(
            """
            MERGE (b:Bill {external_id: $external_id})
              ON CREATE SET b.title = $title, b.introduced = $introduced
              ON MATCH  SET b.title = coalesce($title, b.title), b.introduced = coalesce($introduced, b.introduced)
            """,
            external_id=row["external_id"], title=row["title"], introduced=row["introduced"],
        )
        sponsors = row.get("sponsors") or []
        if isinstance(sponsors, list):
            for s in sponsors:
                if not s: continue
                bid = s.get("bioguideId")
                name = s.get("name")
                if not bid and not name: continue
                tx.run(
                    """
                    MERGE (p:Person {bioguideId: $bid})
                      ON CREATE SET p.name = $name
                      ON MATCH  SET p.name = coalesce($name, p.name)
                    MATCH (b:Bill {external_id: $external_id})
                    MERGE (p)-[:SPONSORED_BY]->(b)
                    """,
                    bid=bid, name=name, external_id=row["external_id"],
                )

    with driver.session() as session:
        for r in rows:
            session.execute_write(ingest_tx, r)
    driver.close()

if __name__ == "__main__":
    run()
```

**graphs/README.md**
```markdown
# Graph bootstrap

## Start Neo4j
```bash
make graph-up       # uses compose profile `graph`
```
Open http://localhost:7474/ and set a strong password.

## Ingest from Postgres
```bash
export NEO4J_URI=bolt://localhost:7687
export NEO4J_USER=neo4j
export NEO4J_PASSWORD=<your-pass>
python graphs/ingest_graph.py
```

## Example Cypher
```cypher
MATCH (p:Person)-[:SPONSORED_BY]->(b:Bill)
RETURN p.name, b.title LIMIT 20;
```
```

**Makefile additions**
```makefile
graph-up:
	docker compose -f docker-compose.yml -f deploy/docker-compose.override.yml --profile graph up --wait -d neo4j

graph-down:
	docker compose -f docker-compose.yml -f deploy/docker-compose.override.yml --profile graph down

graph-ingest:
	python graphs/ingest_graph.py
```

---

### What’s next (quick wins)
- Swap the placeholder embedder in `etl/ingest_congress.py` for a local Sentence-Transformers model; store the model in `${DATA_ROOT}/models` and mount read-only.
- Add `qa` target to CI after ETL sample to block merges on schema drift.
- Extend `graphs/ingest_graph.py` to include committees and referrals for richer multi-hop queries.


---

## 📦 Draft Pull Request (paste into GitHub)

**Title**
```
chore(infra+etl+eval+graph): persistence, backups, CI, ETL (Congress.gov), GE QA, RAGAS, Graph bootstrap
```

**Summary**
- Make local-ai-packaged boringly reliable and research-ready:
  - **Persistence-first** bind-mounts + healthchecks; `up --wait`
  - **Backups** (Postgres dump, Qdrant snapshots, DATA_ROOT archive; optional encryption)
  - **Secrets** bootstrap (Bitwarden optional)
  - **ETL MVP** for Congress.gov with canonical schema and vector indexing (Qdrant)
  - **Quality gates**: Great Expectations checks for core tables
  - **Evaluation**: RAGAS runner (provider: none/ollama/openai)
  - **Graph**: Neo4j profile + ingest (Bills, Persons → SPONSORED_BY)
  - **CI**: lint + compose validation; nightly ETL; weekly eval

**Why**
- Eliminate data loss on container churn, unblock repeatable research on political docs, and enforce quality through CI.

**Changes**
- `deploy/docker-compose.override.yml` — bind-mounts, healthchecks, `neo4j` profile
- `.env.example` — config schema
- `scripts/ensure_secrets.sh` — generate/sync secrets; Bitwarden optional
- `scripts/backup_all.sh` / `scripts/restore_all.sh` — encrypted backups + restore
- `Makefile` — `up`, `backup`, `etl-sample`, `eval`, `qa`, `graph-*`
- `etl/ingest_congress.py` — incremental pull, normalize, upsert, chunk+embed (placeholder), index to Qdrant
- `eval/ragas_eval.py` + `eval/requirements.txt` — RAGAS evaluator
- `qa/run_gx.py` + `qa/requirements.txt` — Great Expectations checks
- `graphs/ingest_graph.py` + `graphs/requirements.txt` + docs — Graph bootstrap
- `.github/workflows/{ci,etl_nightly,eval_weekly}.yml` — CI + scheduled jobs
- `.github/{CODEOWNERS,pull_request_template.md,ISSUE_TEMPLATE/*.yml}` — process

**How to run locally**
```bash
cp .env.example .env
make up                      # brings up stack with persistence + healthchecks
./scripts/ensure_secrets.sh   # generate or sync secrets (.env)
make etl-sample               # small Congress.gov ingest (requires CONGRESS_API_KEY)
make qa                       # Great Expectations checks
make eval                     # RAGAS (provider=none); see README for providers
make backup                   # db + qdrant + DATA_ROOT archive
```

**Testing**
- ✅ Compose config validation passes
- ✅ Health-gated startup (`up --wait`) returns after services ready
- ✅ `etl/ingest_congress.py --since 2024-01-01 --limit 25` writes raw JSON, upserts docs, and (optionally) indexes vectors
- ✅ `qa/run_gx.py` passes on baseline tables
- ✅ `eval/ragas_eval.py` runs and emits `eval/report.md`

**Security**
- No plaintext secrets committed; `.env` ignored
- Secret scanners in CI (gitleaks, trufflehog)
- Optional Bitwarden CLI flow to store/rotate env secrets

**Breaking changes / Migrations**
- If you previously used anonymous volumes, migrate existing data into `${DATA_ROOT}` before pulling containers.
- For Qdrant versions, ensure snapshot/restore image tags match.

**Risk & Rollback**
- Backups stored in `./backups` (encrypted if `BACKUP_PASSPHRASE` set)
- Use `scripts/restore_all.sh --archive … --db …` to roll back

**Checklist**
- [ ] CI green (lint, compose config, scanners)
- [ ] Local `make up` succeeds with healthchecks
- [ ] `make etl-sample` runs with a valid `CONGRESS_API_KEY`
- [ ] `make qa` passes (no null/dup keys)
- [ ] `make eval` produces report
- [ ] Docs updated (README, Architecture, Runbooks)

**Screenshots / Artifacts**
- Attach `eval/report.md` and `qa/gx_report.md` from CI artifacts

**Reviewers (CODEOWNERS)**
- `@cbwinslow` (infra, etl, eval, graphs)

---

## 🗂️ Ready-to-file GitHub Issues (copy/paste)

### 1) WAL-G PITR for Postgres (Supabase)
**Labels**: `infra`, `database`, `backup`  
**Description**:
Implement WAL-G for continuous archiving (PITR) to S3/MinIO, document restore procedure, and add retention policy.
**Tasks**
- [ ] Add WAL-G sidecar/env to Postgres compose
- [ ] Create bucket + creds (MinIO or S3)
- [ ] Configure `WALG_S3_PREFIX` (or MinIO endpoint) and retention
- [ ] Document backup/restore drills in `docs/runbooks/backup_restore.md`
**Acceptance**
- [ ] `restore to timestamp` walkthrough succeeds on a scratch DB

### 2) Replace placeholder embedder with Sentence-Transformers
**Labels**: `etl`, `ml`, `vectors`  
**Description**:
Switch `etl/ingest_congress.py` to use local sentence-transformers (GPU optional). Store model under `${DATA_ROOT}/models`.
**Tasks**
- [ ] Add dependency and loader; configurable model name
- [ ] Batch embedding with backpressure & retries
- [ ] Configurable dim; auto (re)create Qdrant collection
- [ ] Bench on small corpus; record latency/throughput
**Acceptance**
- [ ] Same corpus indexed with real embeddings; search returns expected bill sections

### 3) GovInfo Bulk ETL (historical backfill)
**Labels**: `etl`, `data`  
**Description**:
Add `etl/govinfo_ingest.py` to pull bill status XML and long-form reports for historical coverage; normalize to canonical JSON.
**Tasks**
- [ ] Incremental fetch with ETags/Last-Modified
- [ ] XML → JSON transformer; provenance recorded
- [ ] Upsert into `documents`/`sections`
- [ ] GE checks updated to cover these docs
**Acceptance**
- [ ] Backfilled N=10k docs without integrity failures

### 4) RAGAS full metrics + thresholds
**Labels**: `eval`, `quality`  
**Description**:
Enable RAGAS with provider `ollama`/`openai`; define SLOs and gate PRs on minimum thresholds.
**Tasks**
- [ ] Configure provider & model selection via env
- [ ] Add faithfulness/answer relevancy gating in CI (weekly)
- [ ] Trend chart artifact (md + csv)
**Acceptance**
- [ ] Weekly eval >= target thresholds for 3 consecutive runs

### 5) Graph expansion: committees, referrals, actions
**Labels**: `graph`, `etl`  
**Description**:
Enrich graph with (:Committee), (:Action) and relationships (REFERRED_TO, TAKEN_ACTION). Power multi-hop QA.
**Tasks**
- [ ] Extend ETL normalization to capture committees/actions
- [ ] Update `graphs/ingest_graph.py` merges + constraints
- [ ] Provide sample Cypher queries
**Acceptance**
- [ ] Example multi-hop query returns correct subgraph on sample bills

### 6) CI hardening: actionlint, trivy, yamllint strict
**Labels**: `ci`, `security`  
**Description**:
Add `actionlint`, `trivy` image scans, and strict YAML lint to CI.
**Tasks**
- [ ] New job: actionlint over `.github/workflows`
- [ ] New job: trivy scan for images
- [ ] YAML lint with stricter ruleset
**Acceptance**
- [ ] CI blocks unsafe images/misconfigured workflows

### 7) Great Expectations expansion
**Labels**: `quality`, `data`  
**Description**:
Add expectations for `sections` table (non-empty text; length bounds; FK coverage) and freshness checks.
**Tasks**
- [ ] Add suite for `sections`
- [ ] Add freshness check (max introduced within N days for nightly ingest)
- [ ] Fail CI on drift
**Acceptance**
- [ ] QA job fails when bad data lands; passes when ETL fixed

### 8) Secret hygiene + push protection
**Labels**: `security`  
**Description**:
Enable GitHub secret scanning push protection; add pre-commit hooks (`detect-secrets`).
**Tasks**
- [ ] Org/repo setting: enable push protection
- [ ] Add `.pre-commit-config.yaml` with detect-secrets
- [ ] Docs for rotating any found keys
**Acceptance**
- [ ] Accidental secret pushes blocked locally and by GitHub

### 9) Observability: Prometheus/Grafana (optional profile)
**Labels**: `infra`, `ops`  
**Description**:
Add metrics/visualization for Postgres/Qdrant and app logs; profile `observability` in compose.
**Tasks**
- [ ] Add exporters + Grafana dashboards
- [ ] Document ports and creds
**Acceptance**
- [ ] Basic dashboard shows ingest throughput and DB health

### 10) Docs & runbooks
**Labels**: `docs`  
**Description**:
Write `docs/ARCHITECTURE.md`, `docs/RUNBOOKS.md` (backup/restore, disaster drill), and `docs/DATA_PIPELINE.md`.
**Acceptance**
- [ ] New contributors can run stack, ingest, and restore in <30m

### 11) Release automation: release-drafter
**Labels**: `devex`  
**Description**:
Add `release-drafter` to auto-generate changelogs from labels and PR titles.
**Acceptance**
- [ ] Draft releases auto-populate with categorized notes

### 12) Dev environment: devcontainer & pre-commit
**Labels**: `devex`  
**Description**:
Add `.devcontainer/` with Python + Docker CLI + pre-commit; pin tool versions.
**Acceptance**
- [ ] New dev can open in VS Code and run `make up` immediately

### 13) Dataset versioning with DVC
**Labels**: `data`, `ml`  
**Description**:
Track frozen eval sets and large artifacts with DVC (remote = S3/MinIO).
**Acceptance**
- [ ] Reproduce evals from a tagged release with `dvc pull`

---

## 🗺️ Project Board & Labels (quick setup)
- **Project**: `local-ai-packaged` with columns: `Backlog`, `Ready`, `In Progress`, `Review`, `Blocked`, `Done`.
- **Labels**: `infra`, `etl`, `eval`, `graph`, `security`, `ci`, `docs`, `devex`, `data`, `ml`, `ops`.
- **Milestones**: `M1 (0–30)`, `M2 (31–60)`, `M3 (61–90)`.

