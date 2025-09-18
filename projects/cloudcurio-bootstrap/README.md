# CloudCurio Bootstrap (Ubuntu Server)

This bundle gives you a clean, reproducible starting point to self‑host on your own hardware and wire everything to **cloudcurio.cc** via **Cloudflare Tunnel**.

## What you get

- Hardened base + essentials
- Docker Engine + Compose (native plugin)
- Optional **NVIDIA Container Toolkit** (GPU)
- **Cloudflare Tunnel** (cloudflared) systemd service
- **Pigsty** (bare‑metal PostgreSQL distribution) installer helper
- **Supabase** (official self‑host, via Docker Compose)
- App stacks (each is a self‑contained `docker compose` project):
  - **Qdrant** (vector DB)
  - **Neo4j** (graph DB)
  - **OpenSearch** + Dashboards
  - **Prometheus + Grafana + Loki + Promtail** (observability)
  - **Netdata** (node health)
  - **Portainer** (container GUI)
  - **Open WebUI** (LLM UI; can pair with Ollama)
  - **Dify** (AI app builder) – compose skeleton
- Port registry + simple port‑conflict checker
- Cloudflare subdomain mapping examples

> All scripts follow CBW conventions: correct shebangs, logging to `/tmp/CBW-<script>.log`, preflight checks, and `--dry-run/--verbose` flags where sensible.
>
> **Run order (minimal):**
> 1) `sudo ./cloudcurio-bootstrap.sh` (base + Docker + optional GPU + cloudflared)
> 2) `sudo ./pigsty/install_pigsty.sh` (bare‑metal Postgres) *or* `./supabase/up.sh` (self‑host Supabase)
> 3) Bring up any stacks under `stacks/*/` with `docker compose up -d`.

## Domains & TLS

We expose services privately/publicly through Cloudflare Tunnel. Edit `cloudflare/tunnel.yaml` and map subdomains under `cloudcurio.cc` to local services (examples included), then run `./cloudflare/setup_cloudflared.sh`.

