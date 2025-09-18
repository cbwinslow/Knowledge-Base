# KBGen Suite (crawl4ai + TUI + API + Search + Topics + Jobs + S3)

## Quickstart (dev)

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# One-time crawl4ai setup (Playwright)
crawl4ai-setup

# Infra: Qdrant + Redis
docker compose -f docker-compose.qdrant.yml up -d
docker compose -f docker-compose.redis.yml up -d

# API server
uvicorn server:app --host 0.0.0.0 --port 5055

# Worker (separate terminal)
export REDIS_URL=redis://localhost:6379/0
rq worker -u $REDIS_URL kbq

# TUI (optional)
python tui_app.py
```

## Security & Ops
- Respect robots.txt (default true). Set `allowed_domains`.
- Secrets via env vars: `OPENAI_API_KEY`, `QDRANT_URL`, `QDRANT_API_KEY`, `AWS_*`, `POSTGRES_*`, `POSTGRES_DSN`.
- Use reverse proxy + auth if exposing `server.py`.

## S3/MinIO Export
Enable in config:
```yaml
export:
  enable: true
  endpoint_url: http://localhost:9000  # MinIO
  bucket: my-kb
  prefix: kbgen/
```

## Topic Discovery
Set `topic_discovery: true` in config; outputs `topics.md`.

## Search
`POST /search {"query":"your text", "top_k":10}`

## Jobs
- `POST /jobs` to enqueue
- `GET /jobs/{id}` status
- `GET /events/{id}` SSE log stream
