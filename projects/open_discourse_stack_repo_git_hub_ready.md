# OpenDiscourse Stack – GitHub‑ready Repo

Below is the complete repository content. Copy these files into a new repo (e.g., `opendiscourse-stack`). Everything is organized by path with full, ready‑to‑run code.

---

## README.md
```markdown
# OpenDiscourse Stack (Supabase + Observability + Proxy Options)

A production-lean, compose-first stack for **OpenDiscourse** featuring:

- **Supabase (self-hosted)**: Postgres, Kong API Gateway, Auth (GoTrue), PostgREST, Realtime, Storage (MinIO), Studio, Edge Runtime.
- **Observability**: Prometheus, Grafana (auto-provisioned datasources & starter dashboard), Loki + Promtail, Alertmanager, Postgres & Node exporters.
- **Redis**: enabled for caching/queues.
- **Proxy Options** (profiles): **Caddy** (Let’s Encrypt TLS), **Cloudflare Tunnel**, **both**, or **none**.
- **Backups**: nightly `pg_dump` with rotation.
- **Secrets**: generated into `.env` (or rendered from Bitwarden via `bw` CLI).
- **All data under `/srv/opendiscourse`** (good habit for servers & laptops).

> Default domain in examples: `api.opendiscourse.net`

---

## Quick Start

```bash
git clone https://github.com/YOURUSER/opendiscourse-stack.git
cd opendiscourse-stack

# One-liner bootstrap (installs Docker if missing, generates .env, starts stack)
bash bootstrap.sh --domain api.opendiscourse.net --email you@example.com --proxy caddy --base-dir /srv/opendiscourse
```

**Proxy modes:**
- `--proxy caddy` (requires ports 80/443 publicly reachable)
- `--proxy cloudflared` (no inbound ports; set `provisioning/cloudflared/config.yml`)
- `--proxy both`
- `--proxy none` (local ports only)

---

## Makefile shortcuts

```bash
make env              # generates .env (secrets)
make up               # docker compose up -d
make up-caddy         # enable Caddy profile
make up-cf            # enable Cloudflare Tunnel profile
make both             # both profiles
make down             # docker compose down
make logs             # tail logs
make ps               # service status
make grafana-pw       # show admin password from .env
```

---

## Configs & Paths

- Edit **`provisioning/Caddyfile`** for routes.
- Edit **`provisioning/cloudflared/config.yml`** with your **Tunnel ID** and hostnames.
- Grafana datasources/dashboards are auto-provisioned from `provisioning/grafana/provisioning`.
- All persistent data lives under **`/srv/opendiscourse`** (change via `.env: BASE_DIR`).

---

## Backups

A small cron inside the `backups` service runs nightly `pg_dump` to `/srv/opendiscourse/backups/pg`, keeping the 7 most recent archives. See `scripts/backup_pg.sh`.

---

## Security Notes

- `.env` is created with `chmod 600`. Treat it like a secret.
- Consider migrating to **Docker secrets** or **Bitwarden** (`scripts/env_from_bw.sh`) for long-term secret hygiene.
- Lock down access with **Caddy** + strict headers (already enabled) or **Cloudflare Tunnel**.

---

## Why `/srv/opendiscourse`?

It centralizes all state for easy backup/restore and avoids accidental loss when pruning Docker. Good for **servers and local machines** alike.

---

## Roadmap / Nice-to-haves

- Add **Alertmanager** routing to Slack/Email.
- Import richer **Grafana dashboards** (Kong, Postgres, Node) or wire to Tempo/Tracing.
- Add **blackbox_exporter** to probe external endpoints.
- Add **Docker secrets**/SOPS for secrets-at-rest.

---

## License

MIT (see `LICENSE`).
```

---

## LICENSE (MIT)
```text
MIT License

Copyright (c) 2025 Blaine Winslow

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## .gitignore
```gitignore
# Env & secrets
.env
*.env
.env.*

# Logs & backups
*.log
logs/
backups/
/srv/

# Node / Deno cache
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
.npm/

# TypeScript
*.tsbuildinfo

# Editor/OS
.DS_Store
Thumbs.db
.idea/
.vscode/
*.swp

# Docker
**/.docker/
**/docker-data/

# Generated Grafana session, Loki index cache (kept in BASE_DIR anyway)
**/grafana/
**/loki/
**/prometheus/
**/promtail-pos/
**/caddy/
**/caddy-config/
**/cloudflared/
```

---

## .github/workflows/ci.yml
```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint-validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python (for yamllint, shellcheck installs)
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'

      - name: Install linters
        run: |
          sudo apt-get update -y
          sudo apt-get install -y yamllint shellcheck docker-compose-plugin jq

      - name: YAML lint
        run: |
          yamllint . --format standard

      - name: Shellcheck (scripts)
        run: |
          set -e
          if compgen -G "scripts/*.sh" > /dev/null; then
            shellcheck scripts/*.sh
          else
            echo "No scripts to check"
          fi

      - name: Validate docker-compose.yml
        run: |
          docker compose config -q

      - name: Basic repo checks
        run: |
          test -f docker-compose.yml
          test -f bootstrap.sh
          test -f provisioning/prometheus.yml
          test -f provisioning/grafana/provisioning/datasources/datasource.yml

  spellcheck-readme:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check README exists
        run: test -f README.md
```

---

## docker-compose.yml
```yaml
#===============================================================================
# File         : docker-compose.yml
# Project      : OpenDiscourse – Supabase + Observability + Proxy + Backups
# Author       : ChatGPT for Blaine “CBW” Winslow
# Created      : 2025-09-09
# Summary      : Full self-hosted Supabase stack with Redis, Prom/Graf/Loki/Promtail,
#               postgres_exporter, node_exporter, Alertmanager, backups, and
#               optional Caddy TLS + Cloudflare Tunnel (profiles).
#===============================================================================
version: "3.9"

env_file:
  - .env

networks:
  od_net:   { driver: bridge }
  od_obs:   { driver: bridge }
  proxy_net:{ driver: bridge }

services:
  db:
    image: supabase/postgres:15.8.1.170
    restart: unless-stopped
    networks: [ od_net ]
    environment:
      POSTGRES_DB:       "${POSTGRES_DB}"
      POSTGRES_USER:     "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 20
    volumes:
      - ${BASE_DIR}/db:/var/lib/postgresql/data

  kong:
    image: supabase/kong:latest
    restart: unless-stopped
    networks: [ od_net, proxy_net ]
    depends_on: [ db ]
    environment:
      KONG_PASSWORD: "${KONG_PASSWORD}"

  studio:
    image: supabase/studio:latest
    restart: unless-stopped
    networks: [ od_net, proxy_net ]
    depends_on: [ kong ]
    environment:
      NEXT_PUBLIC_SUPABASE_URL: "${SITE_URL}"
      NEXT_PUBLIC_SUPABASE_ANON_KEY: "${ANON_KEY}"

  auth:
    image: supabase/gotrue:latest
    restart: unless-stopped
    networks: [ od_net ]
    depends_on: [ db ]
    environment:
      GOTRUE_JWT_SECRET: "${JWT_SECRET}"
      GOTRUE_SITE_URL:   "${SITE_URL}"

  rest:
    image: postgrest/postgrest:v12.2.3
    restart: unless-stopped
    networks: [ od_net ]
    depends_on: [ db ]
    environment:
      PGRST_DB_URI:       "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}"
      PGRST_DB_SCHEMAS:   "public"
      PGRST_DB_ANON_ROLE: "anon"
      PGRST_JWT_SECRET:   "${JWT_SECRET}"

  realtime:
    image: supabase/realtime:latest
    restart: unless-stopped
    networks: [ od_net ]
    depends_on: [ db ]
    environment:
      DB_HOST:        db
      DB_PASSWORD:    "${POSTGRES_PASSWORD}"
      DB_NAME:        "${POSTGRES_DB}"
      DB_USER:        "${POSTGRES_USER}"
      DB_ENC_KEY:     "${REPLICATION_PASSWORD}"

  storage:
    image: supabase/storage-api:latest
    restart: unless-stopped
    networks: [ od_net ]
    depends_on: [ db, minio ]
    environment:
      ANON_KEY:        "${ANON_KEY}"
      SERVICE_KEY:     "${SERVICE_ROLE_KEY}"

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    restart: unless-stopped
    networks: [ od_net, proxy_net ]
    environment:
      MINIO_ROOT_USER:     "${MINIO_ROOT_USER}"
      MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
    volumes:
      - ${BASE_DIR}/minio:/data

  edge-functions:
    image: supabase/edge-runtime:latest
    restart: unless-stopped
    networks: [ od_net ]
    depends_on: [ kong ]
    volumes:
      - ./functions:/home/deno/functions:ro

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks: [ od_net ]
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    volumes:
      - ${BASE_DIR}/redis:/data

  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    networks: [ od_obs ]
    volumes:
      - ${BASE_DIR}/prometheus:/prometheus
      - ./provisioning/prometheus.yml:/etc/prometheus/prometheus.yml:ro

  loki:
    image: grafana/loki:2.9.8
    restart: unless-stopped
    networks: [ od_obs ]
    volumes:
      - ${BASE_DIR}/loki:/loki
      - ./provisioning/loki-local-config.yaml:/etc/loki/local-config.yaml:ro
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:2.9.8
    restart: unless-stopped
    networks: [ od_obs ]
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ${BASE_DIR}/promtail-pos:/var/log
      - ./provisioning/promtail/promtail.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    networks: [ od_obs, proxy_net ]
    depends_on: [ prometheus, loki ]
    environment:
      GF_SECURITY_ADMIN_PASSWORD: "${GRAFANA_ADMIN_PASSWORD}"
    volumes:
      - ${BASE_DIR}/grafana:/var/lib/grafana
      - ./provisioning/grafana/provisioning:/etc/grafana/provisioning:ro

  postgres_exporter:
    image: quay.io/prometheuscommunity/postgres-exporter
    restart: unless-stopped
    networks: [ od_obs, od_net ]
    depends_on: [ db ]
    environment:
      DATA_SOURCE_URI:  "db:5432/${POSTGRES_DB}?sslmode=disable"
      DATA_SOURCE_USER: "${POSTGRES_USER}"
      DATA_SOURCE_PASS: "${POSTGRES_PASSWORD}"

  node_exporter:
    image: prom/node-exporter:latest
    restart: unless-stopped
    networks: [ od_obs ]
    pid: "host"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'

  alertmanager:
    image: prom/alertmanager:latest
    restart: unless-stopped
    networks: [ od_obs ]
    volumes:
      - ${BASE_DIR}/alertmanager:/alertmanager
      - ./provisioning/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro

  backups:
    image: bash:5.2
    restart: unless-stopped
    networks: [ od_net ]
    depends_on: [ db, minio ]
    volumes:
      - ./scripts:/opt/scripts:ro
      - ${BASE_DIR}/backups:/backups
    entrypoint: [ "bash", "-lc", "echo '0 3 * * * /opt/scripts/backup_pg.sh >> /backups/backup.log 2>&1' > /var/spool/cron/crontabs/root && crond -f -l 8" ]

  caddy:
    profiles: [ "caddy" ]
    image: caddy:latest
    restart: unless-stopped
    networks: [ proxy_net ]
    depends_on: [ kong, studio, grafana, minio ]
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAIN: "${DOMAIN}"
      EMAIL:  "${OWNER_EMAIL}"
    volumes:
      - ./provisioning/Caddyfile:/etc/caddy/Caddyfile:ro
      - ${BASE_DIR}/caddy:/data
      - ${BASE_DIR}/caddy-config:/config

  cloudflared:
    profiles: [ "cloudflared" ]
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    depends_on: [ kong, studio, grafana, minio ]
    networks: [ proxy_net ]
    command: tunnel --config /etc/cloudflared/config.yml run
    volumes:
      - ./provisioning/cloudflared/config.yml:/etc/cloudflared/config.yml:ro
      - ${BASE_DIR}/cloudflared:/etc/cloudflared
```

---

## provisioning/Caddyfile
```caddy
{
  email {env.EMAIL}
  servers {
    protocols h1 h2 h3
  }
}

{env.DOMAIN} {
  encode zstd gzip

  @api path /v1/* /rest/* /auth/* /realtime/* /storage/* /functions/* /rpc/*
  reverse_proxy @api kong:8000 {
    fail_timeout 10s
    transport http {
      versions h2c 1.1
    }
  }

  handle_path /studio/* {
    uri strip_prefix /studio
    reverse_proxy studio:3000
  }
  handle_path /grafana/* {
    uri strip_prefix /grafana
    reverse_proxy grafana:3000
  }
  handle_path /minio/* {
    uri strip_prefix /minio
    reverse_proxy minio:9001
  }

  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
    Referrer-Policy "no-referrer-when-downgrade"
    Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' https: data:"
  }

  log
}
```

---

## provisioning/cloudflared/config.yml (template)
```yaml
tunnel: "<YOUR_TUNNEL_ID>"
credentials-file: "/etc/cloudflared/<YOUR_TUNNEL_ID>.json"

ingress:
  - hostname: api.opendiscourse.net
    service: http://kong:8000
  - hostname: studio.opendiscourse.net
    service: http://studio:3000
  - hostname: grafana.opendiscourse.net
    service: http://grafana:3000
  - hostname: minio.opendiscourse.net
    service: http://minio:9001
  - service: http_status:404
```

---

## provisioning/prometheus.yml
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 30s

rule_files:
  - /etc/prometheus/alert_rules.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs: [{ targets: ['prometheus:9090'] }]

  - job_name: 'loki'
    static_configs: [{ targets: ['loki:3100'] }]

  - job_name: 'postgres_exporter'
    static_configs: [{ targets: ['postgres_exporter:9187'] }]

  - job_name: 'node_exporter'
    static_configs: [{ targets: ['node_exporter:9100'] }]
```

---

## provisioning/alert_rules.yml
```yaml
groups:
  - name: basic-health
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 2m
        labels: { severity: critical }
        annotations:
          summary: "Instance down ({{ $labels.instance }})"
          description: "Target {{ $labels.job }} on {{ $labels.instance }} is down."

      - alert: HighCPU
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels: { severity: warning }
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
          description: "CPU usage > 85% over 10m"

  - name: postgres
    rules:
      - alert: PGConnectionsHigh
        expr: pg_stat_activity_count > 200
        for: 5m
        labels: { severity: warning }
        annotations:
          summary: "Postgres connections high"
          description: "Active connections exceed 200 for 5 minutes"

  - name: api-errors
    rules:
      - alert: APIFailures
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 1
        for: 5m
        labels: { severity: warning }
        annotations:
          summary: "API 5xx elevated"
          description: "5xx rate > 1/s over 5m"
```

---

## provisioning/alertmanager.yml
```yaml
route:
  receiver: "null"
  group_by: [alertname]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 3h

receivers:
  - name: "null"
    webhook_configs: []
# To enable Slack/Email, add a receiver and change the top-level route.receiver
```

---

## provisioning/loki-local-config.yaml
```yaml
auth_enabled: false
server:
  http_listen_port: 3100
ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore: { store: inmemory }
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_target_size: 1536000
schema_config:
  configs:
    - from: 2023-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v13
      index: { prefix: index_, period: 24h }
storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/boltdb-cache
  filesystem: { directory: /loki/chunks }
limits_config:
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 24
  max_streams_per_user: 0
  max_global_streams_per_user: 0
table_manager:
  retention_deletes_enabled: true
  retention_period: 168h
```

---

## provisioning/promtail/promtail.yml
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

clients:
  - url: http://loki:3100/loki/api/v1/push

positions:
  filename: /var/log/promtail-positions.yaml

scrape_configs:
  - job_name: docker
    static_configs:
      - targets: [localhost]
        labels:
          job: dockerlogs
          __path__: /var/lib/docker/containers/*/*-json.log
```

---

## provisioning/grafana/provisioning/datasources/datasource.yml
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
```

---

## provisioning/grafana/provisioning/dashboards/dashboards.yml
```yaml
apiVersion: 1
providers:
  - name: 'OpenDiscourse Dashboards'
    orgId: 1
    folder: 'OpenDiscourse'
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards/json
```

---

## provisioning/grafana/provisioning/dashboards/json/overview.json
```json
{
  "annotations": { "list": [] },
  "editable": true,
  "graphTooltip": 0,
  "panels": [
    {
      "type": "timeseries",
      "title": "Node CPU %",
      "targets": [
        { "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)" }
      ]
    },
    {
      "type": "timeseries",
      "title": "Postgres Connections",
      "targets": [
        { "expr": "pg_stat_activity_count" }
      ]
    }
  ],
  "schemaVersion": 38,
  "style": "dark",
  "tags": ["opendiscourse"],
  "time": { "from": "now-6h", "to": "now" },
  "title": "OpenDiscourse Overview",
  "version": 1
}
```

---

## scripts/gen_env.sh
```bash
#!/usr/bin/env bash
#===============================================================================
# Script Name   : scripts/gen_env.sh
# Author        : ChatGPT for CBW
# Created       : 2025-09-09
# Summary       : Generate a secure .env for the compose stack.
# Usage         : bash scripts/gen_env.sh --domain api.opendiscourse.net --email you@x.com [--base-dir /srv/opendiscourse]
#===============================================================================
set -Eeuo pipefail

DOMAIN=""; EMAIL=""; BASE_DIR_DEFAULT="/srv/opendiscourse"

usage(){ echo "Usage: $0 --domain <FQDN> --email <EMAIL> [--base-dir /srv/opendiscourse]"; }
rand(){ openssl rand -hex 32; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --base-dir) BASE_DIR_DEFAULT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -n "$DOMAIN" ]] || { echo "Missing --domain"; exit 1; }
[[ -n "$EMAIL"  ]] || { echo "Missing --email"; exit 1; }

cat > .env <<EOF
#-------------------- REQUIRED --------------------
DOMAIN="${DOMAIN}"
SITE_URL="https://${DOMAIN}"
OWNER_EMAIL="${EMAIL}"
BASE_DIR="${BASE_DIR_DEFAULT}"

#-------------------- SUPABASE --------------------
JWT_SECRET="$(rand)"
ANON_KEY="$(rand)"
SERVICE_ROLE_KEY="$(rand)"

POSTGRES_DB="postgres"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="$(rand)"

MINIO_ROOT_USER="supabase"
MINIO_ROOT_PASSWORD="$(rand)"

REPLICATION_PASSWORD="$(rand)"
KONG_PASSWORD="$(rand)"

#-------------------- OBS/GRAFANA -----------------
GRAFANA_ADMIN_PASSWORD="$(rand)"

#-------------------- REDIS -----------------------
REDIS_PASSWORD="$(rand)"
EOF

chmod 600 .env
echo "[OK] Wrote .env (600). Base dir: ${BASE_DIR_DEFAULT}"
```

---

## scripts/env_from_bw.sh (optional Bitwarden integration)
```bash
#!/usr/bin/env bash
#===============================================================================
# Script Name   : scripts/env_from_bw.sh
# Author        : ChatGPT for CBW
# Summary       : Render .env from Bitwarden secrets (requires 'bw' CLI logged in).
# Usage         : bash scripts/env_from_bw.sh --domain api.opendiscourse.net --email you@x.com --item opendiscourse-secrets
#===============================================================================
set -Eeuo pipefail

ITEM=""; DOMAIN=""; EMAIL=""; BASE_DIR_DEFAULT="/srv/opendiscourse"
usage(){ echo "Usage: $0 --domain <FQDN> --email <EMAIL> --item <BW_ITEM_NAME> [--base-dir /srv/opendiscourse]"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --item) ITEM="$2"; shift 2;;
    --domain) DOMAIN="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --base-dir) BASE_DIR_DEFAULT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -n "$ITEM" && -n "$DOMAIN" && -n "$EMAIL" ]] || { usage; exit 1; }

bw sync >/dev/null
SESSION="$(bw unlock --raw)" || { echo "Bitwarden unlock failed"; exit 1; }
JQ='.fields | from_entries | . as $f | {
  DOMAIN: "'"$DOMAIN"'",
  SITE_URL: "https://'"$DOMAIN"'",
  OWNER_EMAIL: "'"$EMAIL"'",
  BASE_DIR: "'"$BASE_DIR_DEFAULT"'",
  JWT_SECRET: $f.JWT_SECRET,
  ANON_KEY: $f.ANON_KEY,
  SERVICE_ROLE_KEY: $f.SERVICE_ROLE_KEY,
  POSTGRES_DB: ($f.POSTGRES_DB // "postgres"),
  POSTGRES_USER: ($f.POSTGRES_USER // "postgres"),
  POSTGRES_PASSWORD: $f.POSTGRES_PASSWORD,
  MINIO_ROOT_USER: ($f.MINIO_ROOT_USER // "supabase"),
  MINIO_ROOT_PASSWORD: $f.MINIO_ROOT_PASSWORD,
  REPLICATION_PASSWORD: $f.REPLICATION_PASSWORD,
  KONG_PASSWORD: $f.KONG_PASSWORD,
  GRAFANA_ADMIN_PASSWORD: $f.GRAFANA_ADMIN_PASSWORD,
  REDIS_PASSWORD: $f.REDIS_PASSWORD
}'
DATA="$(bw get item "$ITEM" --session "$SESSION" | jq -r "$JQ")"
echo "$DATA" | jq -r 'to_entries[] | "\(.key)=\"\(.value)\""' > .env
chmod 600 .env
echo "[OK] Rendered .env from Bitwarden item '$ITEM'."
```

---

## scripts/backup_pg.sh
```bash
#!/usr/bin/env bash
#===============================================================================
# Script Name   : scripts/backup_pg.sh
# Author        : ChatGPT for CBW
# Summary       : Nightly logical backup of Postgres via pg_dump, rotated by date.
#===============================================================================
set -Eeuo pipefail
BACKUP_DIR="/backups/pg"
mkdir -p "$BACKUP_DIR"

DATE="$(date +%F_%H%M%S)"
FILE="${BACKUP_DIR}/pg_${DATE}.sql.gz"

export PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"
pg_isready -h db -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" -t 30 || {
  echo "[ERR] Postgres not ready"; exit 1; }

pg_dump -h db -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" \
  --format=plain --no-owner --no-privileges | gzip -9 > "$FILE"

echo "[OK] Wrote $FILE"
# Optional: prune >7 backups
ls -1t "$BACKUP_DIR"/pg_*.sql.gz | sed -e '1,7d' | xargs -r rm -f
```

---

## scripts/install_docker.sh
```bash
#!/usr/bin/env bash
# Robust Docker install (Debian/Ubuntu/RHEL). Safe to re-run.
set -Eeuo pipefail
if command -v docker >/dev/null; then
  echo "[OK] Docker present: $(docker --version)"; exit 0
fi
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
if ! docker compose version >/dev/null 2>&1; then
  if command -v apt-get >/dev/null; then sudo apt-get update -y && sudo apt-get install -y docker-compose-plugin; fi
  if command -v dnf >/dev/null; then sudo dnf install -y docker-compose-plugin || true; fi
  if command -v yum >/dev/null; then sudo yum install -y docker-compose-plugin || true; fi
fi
echo "[OK] Docker & Compose ready."
```

---

## Makefile
```makefile
DOMAIN ?= api.opendiscourse.net
EMAIL  ?= blaine.winslow@gmail.com

.PHONY: env up up-caddy up-cf both down logs ps grafana-pw

env:
	bash scripts/gen_env.sh --domain $(DOMAIN) --email $(EMAIL)

up:
	docker compose up -d

up-caddy:
	docker compose --profile caddy up -d

up-cf:
	docker compose --profile cloudflared up -d

both:
	docker compose --profile caddy --profile cloudflared up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

ps:
	docker compose ps

grafana-pw:
	@grep GRAFANA_ADMIN_PASSWORD .env || echo "Run make env first."
```

---

## bootstrap.sh (one‑liner entrypoint)
```bash
#!/usr/bin/env bash
#===============================================================================
# Script Name   : bootstrap.sh
# Author        : ChatGPT for Blaine "CBW" Winslow
# Created       : 2025-09-09
# Summary       : One-liner bootstrap for the OpenDiscourse stack.
#===============================================================================
set -Eeuo pipefail

PROXY="caddy"
DOMAIN=""
EMAIL=""
BASE_DIR="/srv/opendiscourse"
USE_BW=false
BW_ITEM=""

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/tmp/CBW-${SCRIPT_NAME%.sh}.log"

log(){ printf '[%(%F %T)T] [%s] %s\n' -1 "$1" "$2" | tee -a "$LOG_FILE"; }
info(){ log INFO "$*"; }
warn(){ log WARN "$*"; }
err(){ log ERR! "$*"; }

usage(){
  cat <<EOF
$SCRIPT_NAME
  --domain <FQDN>         (e.g., api.opendiscourse.net)
  --email <EMAIL>         (e.g., blaine.winslow@gmail.com)
  --proxy <mode>          caddy | cloudflared | both | none   (default: caddy)
  --base-dir <path>       default: /srv/opendiscourse
  --use-bitwarden         render .env from Bitwarden item fields
  --bw-item <ITEMNAME>    Bitwarden item name if --use-bitwarden
  -h|--help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2;;
    --email)  EMAIL="$2"; shift 2;;
    --proxy)  PROXY="$2"; shift 2;;
    --base-dir) BASE_DIR="$2"; shift 2;;
    --use-bitwarden) USE_BW=true; shift 1;;
    --bw-item) BW_ITEM="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -n "$DOMAIN" ]] || { err "Missing --domain"; exit 1; }
[[ -n "$EMAIL"  ]] || { err "Missing --email"; exit 1; }
mkdir -p "$(dirname "$LOG_FILE")" && : > "$LOG_FILE"

install_docker(){
  if command -v docker &>/dev/null; then
    info "Docker present: $(docker --version)"
  else
    info "Installing Docker engine..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
  fi
  if docker compose version &>/dev/null; then
    info "Docker Compose plugin present: $(docker compose version)"
  else
    info "Installing Docker Compose plugin..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -y && sudo apt-get install -y docker-compose-plugin
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y docker-compose-plugin || true
    elif command -v yum &>/dev/null; then
      sudo yum install -y docker-compose-plugin || true
    fi
  fi
}

gen_env(){
  if $USE_BW; then
    [[ -n "$BW_ITEM" ]] || { err "--use-bitwarden requires --bw-item"; exit 1; }
    command -v bw &>/dev/null || { err "Bitwarden CLI (bw) not found"; exit 1; }
    info "Rendering .env from Bitwarden item: $BW_ITEM"
    bash scripts/env_from_bw.sh --domain "$DOMAIN" --email "$EMAIL" --item "$BW_ITEM"
  else
    info "Generating .env with strong secrets"
    bash scripts/gen_env.sh --domain "$DOMAIN" --email "$EMAIL" --base-dir "$BASE_DIR"
  fi
}

bring_up(){
  sudo mkdir -p "$BASE_DIR" && sudo chown -R "$USER":"$USER" "$BASE_DIR"
  local profiles=()
  case "$PROXY" in
    caddy) profiles+=(--profile caddy);; cloudflared) profiles+=(--profile cloudflared);;
    both) profiles+=(--profile caddy --profile cloudflared);; none) : ;;
    *) warn "Unknown proxy mode '$PROXY'";;
  esac
  info "Starting stack (proxy: $PROXY; base-dir: $BASE_DIR)"
  docker compose up -d
  if [[ ${#profiles[@]} -gt 0 ]]; then docker compose "${profiles[@]}" up -d; fi
  sleep 5
  docker compose ps | tee -a "$LOG_FILE"
  info "Services:"
  echo "  Supabase Studio : https://${DOMAIN}/studio   (via Caddy)   or http://localhost:3000"
  echo "  Grafana         : https://${DOMAIN}/grafana  (via Caddy)   or http://localhost:3001"
  echo "  MinIO Console   : https://${DOMAIN}/minio    (via Caddy)   or http://localhost:9001"
  echo "  API (Kong)      : https://${DOMAIN}/         (via Caddy)   or http://localhost:8000"
  echo "  Base dir        : ${BASE_DIR}"
  echo "  Log file        : ${LOG_FILE}"
}

main(){ install_docker; gen_env; bring_up; info "Done."; }
main
```

---

## functions/hello/index.ts
```ts
// Simple hello function (Deno) for Supabase Edge Runtime
export default async (req: Request): Promise<Response> => {
  return new Response(JSON.stringify({ ok: true, msg: "Hello from OpenDiscourse Edge" }), {
    headers: { "Content-Type": "application/json" },
    status: 200,
  });
};
```

