# OpenDiscourse — MCP Servers Scaffold

This bundle provides two **Python/FastAPI** MCP-style servers plus infra:

- `mcp_govdocs`: Autonomous GovDocs collector (domain learning, crawler memory stubs, schema, health checks)
- `mcp_tokenbroker`: Token flow recorder/executor stubs (for future Playwright integration)
- `docker-compose.yml`: Postgres + Redis + MinIO + Grafana + both servers
- `shared/schema/postgres`: Canonical SQL schema auto-applied on first Postgres start

## Quick Start

```bash
cp .env.example .env
docker compose up -d --build
docker compose logs -f mcp_govdocs mcp_tokenbroker
```

Services:
- GovDocs MCP: http://localhost:8001/healthz
- TokenBroker MCP: http://localhost:8002/healthz
- Postgres: localhost:5432 (`opendiscourse`/`opendiscourse`)
- MinIO: http://localhost:9001 (console) — default: minioadmin/minioadmin
- Grafana: http://localhost:3000 (admin/admin by default per .env)

## JSON-RPC (MCP-like) Endpoints

Each server exposes a JSON-RPC 2.0 endpoint at `POST /mcp` with a small toolset.

### GovDocs MCP tools (stubs wired to DB)
- `evaluate_domain(domain)` → score + site row (insert if new)
- `approve_domain(domain)` → sets approval to approved
- `learn_patterns(domain)` → stores a dummy SiteProfile (for demo)
- `run_crawl(domain, limit)` → fake ingest a sample document row
- `search_docs(query)` → simple LIKE search

### TokenBroker MCP tools (stubs)
- `record_flow(provider_url)` → returns flow_id placeholder
- `replay_flow(flow_id, placeholders)` → returns token_ref placeholder
- `store_secret(ref, value)` → **no-op stub** (replace with Vault/Bitwarden later)

## Dev Tips

- Migrations: SQL files in `shared/schema/postgres` are mapped into Postgres’ init folder.
- Add real crawler/adapters under `servers/mcp_govdocs` and extend `mcp_tools.py`.
- Replace TokenBroker stubs with Playwright-driven recorder/executor and Vault integration.

## Security

- This is a starter. Do **not** use default credentials in production.
- Add network policies, TLS, secret stores, and SBOM/signing in a real deployment.


---
## Robustness Additions
- JSON-RPC error codes (-32601, -32602, -32603)
- DB connection **pooling** with `psycopg_pool`
- **Retries** with exponential backoff (`tenacity`)
- **Settings validation** (Pydantic) and startup DB check
- **Structured logging** and improved health checks
- **CI**: Ruff, Black, Mypy, Pytest with Postgres service
- **Makefile** targets and **pre-commit** hooks


---
## New: Minimal Crawler + Config System

**GovDocs MCP** now includes:
- `learn_robots_sitemaps` → discovers sitemaps and stores samples in `site_profiles`.
- `crawl_sample(domain, max_docs)` → fetches one or more URLs from samples (HTML/PDF), normalizes text, stores raw/text in MinIO, inserts rows into Postgres.
- `get_site_settings(domain)` / `set_site_settings(domain, settings)` → merge YAML defaults with DB overrides.

**Configuration**
- Server defaults: `servers/mcp_govdocs/config/default.yml`
- Per-site overrides: `servers/mcp_govdocs/config/sites/<domain>.yml`
- Environment variables can be used within YAML via `${VAR:-default}`.
- TokenBroker server settings at `servers/mcp_tokenbroker/config/default.yml`.

**Examples**
```bash
# Learn and crawl a sample
curl -X POST http://localhost:8001/mcp -H 'Content-Type: application/json'       -d '{"jsonrpc":"2.0","id":1,"method":"learn_robots_sitemaps","params":{"domain":"www.federalregister.gov"}}'
curl -X POST http://localhost:8001/mcp -H 'Content-Type: application/json'       -d '{"jsonrpc":"2.0","id":2,"method":"crawl_sample","params":{"domain":"www.federalregister.gov","max_docs":1}}'

# Get and set site settings
curl -X POST http://localhost:8001/mcp -H 'Content-Type: application/json'       -d '{"jsonrpc":"2.0","id":3,"method":"get_site_settings","params":{"domain":"www.federalregister.gov"}}'

curl -X POST http://localhost:8001/mcp -H 'Content-Type: application/json'       -d '{"jsonrpc":"2.0","id":4,"method":"set_site_settings","params":{"domain":"www.federalregister.gov","settings":{"crawl":{"max_docs_per_run":10}}}}'
```
