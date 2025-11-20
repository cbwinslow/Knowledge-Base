# CloudCurio Monorepo Template (v1)

A batteries-included starter monorepo for Blaine’s stack on **cbwdellr720** with:

- **Apps**: Next.js web, FastAPI API, Workers/Edge functions, Supabase functions
- **Infra**: Ansible (bare metal & Docker), Terraform (Cloudflare + free-tier), Pulumi stacks
- **Observability**: Prometheus, Grafana, Loki, Tempo/Jaeger, Netdata, OpenSearch, Sentry
- **Messaging/Jobs**: RabbitMQ, Redis
- **Secrets**: Bitwarden CLI first-class, optional Vault buffer, SOPS support
- **Dev Tools**: .devcontainer, VSCode settings (Roo Code, Cline, Kilo, MCP clients), linting, Actions/CI
- **Networking**: Cloudflared, Traefik/Caddy/Nginx, SSH toolkit, ZeroTier/Tailscale/NetBird-aware
- **DB**: Postgres (central on cbwdellr720), Prisma (TS), SQLAlchemy/SQLModel (Py)
- **Agents**: MCP servers registry + client configs, CrewAI configs, OpenRouter/Ollama wiring
- **Shells**: bash/zsh/fish/nushell profiles, completions, aliases, secrets glue

> **Target OS**: Debian/Ubuntu/RHEL family. **Python**: 3.10.6 via pyenv + uv. **GPU**: optional (NVIDIA/AMD hooks provided).

---

## Repository Layout

```
cloudcurio-monorepo/
├─ apps/
│  ├─ web-next/                 # Next.js app (app router, Tailwind, shadcn/ui)
│  ├─ api-fastapi/              # FastAPI service (Pydantic v2, SQLModel)
│  ├─ workers-cloudflare/       # Cloudflare Workers (Hono/itty-router)
│  ├─ supabase/                 # Edge functions, SQL, storage rules
│  └─ worker-jobs/              # Celery (Python) and BullMQ (Node) jobs
├─ packages/
│  ├─ ui/                       # Shared React components
│  ├─ config/                   # ESLint, Prettier, tsconfig, ruff, mypy, biome
│  ├─ types/                    # Zod schemas & TS types
│  └─ python-lib/               # Shared Python utilities (logging, BW, OTEL)
├─ infra/
│  ├─ ansible/
│  │  ├─ inventories/
│  │  │  ├─ lab/
│  │  │  │  ├─ hosts            # cbwdellr720, cbwhpz, etc.
│  │  │  │  ├─ group_vars/
│  │  │  │  │  ├─ all.yml
│  │  │  │  │  └─ monitoring.yml
│  │  │  └─ prod/
│  │  ├─ roles/
│  │  │  ├─ common/             # baseline (users, ssh, packages)
│  │  │  ├─ docker/             # docker+compose setup
│  │  │  ├─ reverse_proxy/      # traefik|caddy|nginx
│  │  │  ├─ postgres/           # pg + pgvector + backups
│  │  │  ├─ monitoring/         # prom+grafana+loki+tempo+netdata
│  │  │  ├─ opensearch/         # opensearch + dashboards seed
│  │  │  ├─ sentry/             # self-host sentry
│  │  │  └─ rabbitmq/
│  │  ├─ playbooks/
│  │  │  ├─ site.yml            # master site playbook
│  │  │  ├─ bootstrap.yml       # first-run baseline
│  │  │  ├─ monitoring.yml      # monitoring stack install
│  │  │  ├─ db.yml              # postgres stack
│  │  │  └─ reverse-proxy.yml
│  │  └─ files/                 # static files, service units, configs
│  ├─ terraform/
│  │  ├─ cloudflare/            # DNS, R2, KV, Zero-Trust, Tunnels
│  │  ├─ oracle-free-tier/      # optional DB/VM free tier (safe placeholders)
│  │  └─ outputs/               # json outputs to consume in CI
│  ├─ pulumi/
│  │  ├─ stacks/
│  │  │  ├─ networking/         # tunnels, WAF, routes
│  │  │  ├─ observability/      # loki/prom buckets, alerts
│  │  │  └─ apps/               # app deploy groups
│  │  └─ Pulumi.yaml
│  └─ k8s/                      # optional k3s/helm charts
├─ ops/
│  ├─ scripts/                  # backups, migrations, log shipping
│  ├─ ssh/                      # ssh policy mgmt, key sync, bastion
│  └─ reports/                  # system profile collectors → Postgres
├─ secrets/
│  ├─ templates/                # .env.tpl files (Bitwarden lookups)
│  └─ sops/                     # optional sealed secrets
├─ ci/
│  ├─ github/                   # GitHub Actions workflows
│  └─ gitlab/                   # .gitlab-ci.yml and includes
├─ .devcontainer/               # dev containers (Docker + features)
├─ tools/
│  ├─ mcp/                      # MCP servers registry + client configs
│  ├─ agents/                   # CrewAI, prompts, tool specs
│  ├─ shell/                    # bash/zsh/fish/nushell (_functions etc.)
│  ├─ bw/                       # Bitwarden helpers
│  └─ templates/                # project & code templates
├─ docs/
│  ├─ ADRs/
│  ├─ playbooks/                # Runbooks, SOPs
│  ├─ cheatsheets/              # TL;DRs for stack terms
│  └─ reference/
├─ docker-compose.yml           # dev single-host composition
├─ Makefile                     # common tasks (make help)
├─ pyproject.toml               # uv + project metadata
├─ .tool-versions               # asdf/pyenv pin for Python 3.10.6
└─ README.md
```

---

## Quick Start

```bash
# 0) Prereqs (host): Docker, Docker Compose, Make, Git, bw CLI, pyenv, uv

# 1) Clone
git clone https://github.com/cbwinslow/cloudcurio-monorepo-template.git
cd cloudcurio-monorepo-template

# 2) Secrets login (Bitwarden)
bw login blaine.winslow@gmail.com  # or bw unlock --raw > /tmp/BW_SESSION
export BW_SESSION=$(bw unlock --raw)

# 3) Materialize env files from templates with BW lookups
./tools/bw/bw-env.sh materialize

# 4) Bring up dev stack
docker compose up -d --build

# 5) Deploy monitoring to cbwdellr720 via Ansible
ansible-playbook -i infra/ansible/inventories/lab/hosts infra/ansible/playbooks/monitoring.yml
```

> **Secrets model**: We use **Bitwarden CLI** and lightweight placeholders like `BW[item="Postgres Admin" field="password"]`. The **bw-env.sh** tool resolves them at build/run time. Optional Vault integration is provided for a two-step secrets buffer.

---

## Secrets Strategy (Bitwarden-first, Vault-optional)

**Lookup syntax in .env templates**
```
# secrets/templates/.env.api.tpl
DATABASE_URL=postgresql://postgres:${BW[item="Postgres Admin" field="password"]}@cbwdellr720:5432/cloudcurio
JWT_SECRET=${BW[item="CloudCurio JWT" field="secret"]}
OPENROUTER_API_KEY=${BW[item="OpenRouter" field="api_key"]}
```

**Materialization**
- `tools/bw/bw-env.sh materialize` reads all `secrets/templates/*.tpl` files, replaces `BW[...]` expressions using `bw get item` and writes concrete `.env` files next to consumers (never commit them).
- Optional: `tools/bw/bw-env.sh export` prints an env block you can `eval` for ephemeral shells.

**Vault buffer (optional)**
- `infra/ansible/roles/vault/` (not shown in tree) can mirror Bitwarden items into Vault for runtime fetch (envconsul or custom shim). This keeps a separation between your password manager and runtime.

---

## Networking & Remote Access Opinionated Setup

- **Primary overlay**: pick **one** (ZeroTier _or_ Tailscale _or_ NetBird). Default: **ZeroTier** per recent stability for you.
- **SSH**: Managed via `ops/ssh/` tools
  - `cbw-ssh-ensure.sh` idempotently sets up `~/.ssh`, `ssh_config`, `known_hosts`, and pushes keys to targets.
  - `cbw-ssh-audit.sh` prints a cross-host matrix (who can SSH to whom) and tests overlay IPs.
  - `cbw-ssh-recover.sh` provides emergency local-console steps + Cloudflared tunnel fallback.
- **Reverse proxy**: Traefik (default) with ACME, rate-limit, secure headers; Caddy and Nginx templates included.
- **Cloudflared**: `apps` exposed via named tunnels; Zero-Trust policies documented.

---

## Observability Stack (bare metal via Ansible; Docker alternative)

Playbook installs on **cbwdellr720**:
- **Prometheus** (scrape hosts/apps), **Alertmanager** (basic rules)
- **Grafana** (dashboards for Linux hosts, Postgres, Loki)
- **Loki** (logs) + **Promtail** agents
- **Tempo/Jaeger** (traces via OTEL)
- **Netdata** (host telemetry)
- **OpenSearch** (search + archival logs)
- **Sentry** (app errors)

> Agents send logs/metrics to cbwdellr720 via overlay IPs. Retention default 90 days, configurable.

---

## Database (Postgres on cbwdellr720)

- Enabled extensions: `pgvector`, `uuid-ossp`, `pg_stat_statements`.
- `ops/scripts/pg/` includes: backup/restore, role mgmt, index advice, vacuum/ANALYZE, WAL archiving helpers.
- **Universal Logging DB**: schema `observability` with tables for host metrics/logs (normalized) and ingest pipelines from Prom/Loki exporters.

---

## CI/CD (GitHub & GitLab)

- **GitHub Actions** in `ci/github/` (copy to `.github/workflows/`):
  - `ci.yml`: lint/type/test for TS/Py, build images, SBOM, push to GHCR
  - `deploy.yml`: Ansible playbook runner on tag; Terraform plan/apply gated
  - `secrets-check.yml`: detect secrets, SLSA provenance, dependency review
  - `issues-automation.yml`: triage Issues/Projects v2 with AI assist (OpenRouter)
- **GitLab CI** templates in `ci/gitlab/` with stages parity, container registry push, and environment reviews.

Secrets for CI are resolved by `bw-env.sh ci-export` + masked CI variables. Never store raw secrets in repo.

---

## Dev Environment

- **.devcontainer/** includes Dockerfile with:
  - Node (lts), pnpm/bun, Python 3.10.6 via pyenv + uv, Go optional, `bw` CLI, `gh`, `glab`
  - Extensions: Roo Code, Cline, Kilo Code, MCP client, Thunder Client, Prisma, Python, Ruff
- **VSCode settings** pre-wire formatters/linters, autofix, and workspace tasks for `make web`/`make api`.
- **Shell profiles** in `tools/shell/` with `_functions`, `_aliases`, `_completions`, `_secrets`, `_profiles` across bash/zsh/fish/nushell. Colorized prompts, Git & kube context, bw helpers.

---

## MCP Servers & Agents

- `tools/mcp/registry.yaml` lists MCP endpoints (Anthropic MCP): Cloudflare, GitHub, GitLab, Context7, Supabase, BW, Terraform, Pulumi, Postgres.
- `tools/agents/` houses CrewAI crew configs, tool specs, prompts, runbooks. Includes an **Orchestrator MCP** that can render downstream client configs and distribute them to target apps.

**Workflow**
1) Define endpoints & creds via Bitwarden items (names documented).
2) Run `tools/mcp/render-configs.py` to emit per-tool client configs into `apps/*/mcp.json`.
3) Apps load MCP configs at boot from mounted path.

---

## Key Files (Selected Content)

### 1) `tools/bw/bw-env.sh`
```bash
#!/usr/bin/env bash
# ============================================================================
# Script: bw-env.sh
# Author: CBW / CloudCurio
# Date: 2025-10-24
# Summary: Materialize .env files from templates with Bitwarden CLI lookups.
# Inputs: subcommand [materialize|export|ci-export], optional paths
# Outputs: Concrete .env files or an exported env block (stdout)
# Params: BW_SESSION (env), BW_VAULT (collection filter optional)
# Notes: Never commits outputs; resolves tokens like BW[item="X" field="Y"]
# Changelog:
#  - v1: initial
# ============================================================================
set -euo pipefail
shopt -s globstar nullglob

err() { echo "[bw-env] ERROR: $*" >&2; }
log() { echo "[bw-env] $*"; }
usage() { sed -n '1,40p' "$0"; }

_require() {
  command -v bw >/dev/null 2>&1 || { err "Bitwarden CLI not found"; exit 1; }
}

_resolve() {
  local token="$1" json key field
  # token format: BW[item="Name" field="key"] or BW[item="Name" notes]
  json=$(bw get item "$(sed -E 's/.*item=\"([^\"]+)\".*/\1/' <<<"$token")")
  if grep -q 'field=' <<<"$token"; then
    key=$(sed -E 's/.*field=\"([^\"]+)\".*/\1/' <<<"$token")
    field=$(jq -r --arg k "$key" '.fields[]?|select(.name==$k).value' <<<"$json")
    [[ -z "$field" || "$field" == "null" ]] && field=$(jq -r --arg k "$key" '.secureNote?.notes' <<<"$json")
    echo -n "$field"
  else
    jq -r '.notes' <<<"$json"
  fi
}

_render_file() {
  local src="$1" dst=${2:-"${src%.tpl}"}
  log "render $src -> $dst"
  awk '{print}' "$src" | \
  perl -0777 -pe 's/\$\{BW\[[^\]]+\]\}/my $t=$&; $t=~s/[\$\{\}]//g; $t=~s/^BW\[//; $t=~s/\]$//; open(FX, "-|", "bash", "-lc", "_bw_token \"$t\" ") or die $!; local $/; <FX>; /ge' > "$dst"
}

# helper exposed to perl above
export -f _resolve
_bw_token() { _resolve "$*"; }
export -f _bw_token

cmd=${1:-materialize}
paths=("secrets/templates/**/*.tpl")
shift || true
[[ $# -gt 0 ]] && paths=("$@")

_require
: "${BW_SESSION:?Run 'bw unlock --raw' and export BW_SESSION}"

case "$cmd" in
  materialize)
    for f in ${paths[@]}; do [ -f "$f" ] && _render_file "$f"; done ;;
  export|ci-export)
    # Prints KEY=VALUE pairs by scanning templates and resolving tokens
    for f in ${paths[@]}; do
      [ -f "$f" ] || continue
      while IFS= read -r line; do
        [[ "$line" =~ ^#|^\s*$ ]] && continue
        key=${line%%=*}
        val=${line#*=}
        if [[ "$val" =~ BW\[.*\] ]]; then
          token=$(sed -E 's/.*(BW\[[^\]]+\]).*/\1/' <<<"$val")
          resolved=$(_resolve "$token")
          echo "$key=$resolved"
        fi
      done < "$f"
    done ;;
  *) usage; exit 2;;
}
```

### 2) `infra/ansible/inventories/lab/hosts`
```ini
[monitoring]
cbwdellr720 ansible_host=192.168.6.69 ansible_user=cbwinslow

[databases]
cbwdellr720

[reverse_proxy]
cbwdellr720

[all:vars]
ansible_python_interpreter=/usr/bin/python3
overlay_primary=zerotier
zerotier_ip=172.28.158.179
```

### 3) `infra/ansible/playbooks/monitoring.yml`
```yaml
---
- name: Install Monitoring Stack on cbwdellr720
  hosts: monitoring
  become: true
  vars_files:
    - ../inventories/lab/group_vars/monitoring.yml
  roles:
    - role: common
    - role: docker
    - role: monitoring
```

### 4) `infra/ansible/roles/monitoring/tasks/main.yml`
```yaml
---
- name: Create monitoring directories
  file:
    path: "/opt/monitoring/{{ item }}"
    state: directory
    owner: root
    group: root
    mode: "0755"
  loop:
    - prometheus
    - grafana
    - loki
    - promtail
    - tempo
    - alertmanager

- name: Deploy docker-compose for monitoring
  copy:
    dest: /opt/monitoring/docker-compose.yml
    content: |
      version: "3.9"
      services:
        prometheus:
          image: prom/prometheus:latest
          volumes:
            - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
          ports: ["9090:9090"]
          restart: unless-stopped
        grafana:
          image: grafana/grafana:latest
          environment:
            - GF_SECURITY_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD}
          ports: ["3000:3000"]
          restart: unless-stopped
        loki:
          image: grafana/loki:latest
          command: ["-config.file=/etc/loki/local-config.yaml"]
          ports: ["3100:3100"]
          restart: unless-stopped
        promtail:
          image: grafana/promtail:latest
          command: ["-config.file=/etc/promtail/config.yml"]
          volumes:
            - /var/log:/var/log:ro
          restart: unless-stopped
        tempo:
          image: grafana/tempo:latest
          ports: ["3200:3200"]
          restart: unless-stopped
      networks:
        default:
          name: monitoring
          driver: bridge

- name: .env for monitoring
  copy:
    dest: /opt/monitoring/.env
    content: |
      GF_ADMIN_PASSWORD={{ lookup('env', 'GF_ADMIN_PASSWORD') | default('changeme') }}
  no_log: true

- name: Start monitoring stack
  community.docker.docker_compose:
    project_src: /opt/monitoring
    state: present
```

### 5) `ops/ssh/cbw-ssh-ensure.sh`
```bash
#!/usr/bin/env bash
# ============================================================================
# Script: cbw-ssh-ensure.sh
# Author: CBW / CloudCurio
# Date: 2025-10-24
# Summary: Idempotently ensure SSH client config, keys, known_hosts, and test
# Inputs: --push <hostfile> (scp authorized_keys), --test <host>
# Outputs: Validated SSH access across overlays
# ============================================================================
set -euo pipefail

me=${USER:-cbwinslow}
ssh_dir="$HOME/.ssh"
mkdir -p "$ssh_dir"; chmod 700 "$ssh_dir"
: "${BW_SESSION:?export BW_SESSION=$(bw unlock --raw)}"

# Pull key from Bitwarden item "CBW SSH Ed25519"
if [ ! -f "$ssh_dir/id_ed25519" ]; then
  bw get attachment id_ed25519 --itemid "$(bw list items --search "CBW SSH Ed25519" | jq -r '.[0].id')" \
    --output "$ssh_dir/id_ed25519"
  chmod 600 "$ssh_dir/id_ed25519"
fi
if [ ! -f "$ssh_dir/id_ed25519.pub" ]; then
  bw get attachment id_ed25519.pub --itemid "$(bw list items --search "CBW SSH Ed25519" | jq -r '.[0].id')" \
    --output "$ssh_dir/id_ed25519.pub"
  chmod 644 "$ssh_dir/id_ed25519.pub"
fi

# Basic ssh_config
cat > "$ssh_dir/config" <<'CFG'
Host *
  AddKeysToAgent yes
  ForwardAgent no
  IdentityAgent ~/.ssh/agent.sock
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 4
  StrictHostKeyChecking accept-new

Host cbwdellr720
  HostName 192.168.6.69
  User cbwinslow

Host cbwdellr720-zt
  HostName 172.28.158.179
  User cbwinslow
CFG
chmod 600 "$ssh_dir/config"

if [[ ${1:-} == "--push" ]]; then
  hostfile=${2:?provide hostfile}
  while read -r host; do
    echo "[ssh] pushing key to $host";
    ssh -o StrictHostKeyChecking=accept-new "$host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$(cat "$ssh_dir/id_ed25519.pub")' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  done < "$hostfile"
fi

if [[ ${1:-} == "--test" ]]; then
  target=${2:?target}
  echo "[ssh] testing to $target"; ssh -o BatchMode=yes -o ConnectTimeout=5 "$target" 'echo ok'
fi
```

### 6) `docker-compose.yml` (dev convenience)
```yaml
version: "3.9"
services:
  web:
    build: ./apps/web-next
    env_file:
      - ./apps/web-next/.env
    ports: ["3000:3000"]
    depends_on: [api]
  api:
    build: ./apps/api-fastapi
    env_file:
      - ./apps/api-fastapi/.env
    ports: ["8000:8000"]
    depends_on: [db, redis]
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: cloudcurio
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports: ["5432:5432"]
  redis:
    image: redis:7
    ports: ["6379:6379"]
  traefik:
    image: traefik:v3.1
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
    ports: ["80:80","443:443","8080:8080"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
volumes:
  pgdata:
```

### 7) GitHub Actions `ci/github/ci.yml`
```yaml
name: CI
on: [push, pull_request]
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with: { node-version: lts }
      - name: Setup Python
        uses: actions/setup-python@v5
        with: { python-version: '3.10' }
      - name: Install pnpm
        run: npm i -g pnpm
      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh
      - name: Resolve secrets via Bitwarden
        env:
          BW_CLIENTID: ${{ secrets.BW_CLIENTID }}
          BW_CLIENTSECRET: ${{ secrets.BW_CLIENTSECRET }}
          BW_PASSWORD: ${{ secrets.BW_PASSWORD }}
        run: |
          bw login --apikey
          export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
          ./tools/bw/bw-env.sh ci-export > /tmp/ci.env
      - name: Typecheck & Lint
        run: |
          pnpm i --frozen-lockfile
          pnpm -C apps/web-next lint
          uv sync && uv run ruff check
      - name: Build Containers
        run: |
          docker build -t ghcr.io/${{ github.repository }}/web:sha-${{ github.sha }} apps/web-next
          docker build -t ghcr.io/${{ github.repository }}/api:sha-${{ github.sha }} apps/api-fastapi
      - name: SBOM
        uses: anchore/syft-action@v0.16.0
        with:
          image: ghcr.io/${{ github.repository }}/web:sha-${{ github.sha }}
      - name: Push Images
        if: github.ref == 'refs/heads/main'
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - run: |
          docker push ghcr.io/${{ github.repository }}/web:sha-${{ github.sha }}
          docker push ghcr.io/${{ github.repository }}/api:sha-${{ github.sha }}
```

### 8) GitLab CI `ci/gitlab/.gitlab-ci.yml`
```yaml
stages: [lint, test, build, deploy]
variables:
  DOCKER_DRIVER: overlay2
lint:
  stage: lint
  image: node:lts
  script:
    - npm i -g pnpm
    - pnpm i
    - pnpm -C apps/web-next lint
build:
  stage: build
  image: docker:24
  services: [docker:24-dind]
  script:
    - docker build -t $CI_REGISTRY_IMAGE/web:$CI_COMMIT_SHA apps/web-next
    - docker push $CI_REGISTRY_IMAGE/web:$CI_COMMIT_SHA
```

### 9) `apps/api-fastapi/app/main.py`
```python
#!/usr/bin/env python3
"""
Script: main.py (FastAPI service)
Author: CBW / CloudCurio
Date: 2025-10-24
Summary: Typed API with health, Postgres, Redis, and OTEL ready.
Inputs: ENV via .env (pydantic-settings)
Outputs: JSON API
ChangeLog: v1 initial
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from pydantic_settings import BaseSettings
import asyncpg

class Settings(BaseSettings):
    DATABASE_URL: str
    REDIS_URL: str | None = None

settings = Settings()  # type: ignore

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.db = await asyncpg.connect(settings.DATABASE_URL)
    yield
    await app.state.db.close()

app = FastAPI(lifespan=lifespan)

@app.get("/health")
async def health():
    return {"ok": True}
```

### 10) Docs: `docs/cheatsheets/stack-terms.md`
```md
# TL;DR Stack Terms
- **Prisma**: TS ORM & schema tool. One schema file → migrations + typed client.
- **SQLAlchemy/SQLModel**: Python ORM; SQLModel adds Pydantic-like models.
- **Zod**: TS schema validation; generate types & OpenAPI.
- **Celery**: Python task queue using Redis/RabbitMQ.
- **Pydantic**: Python data validation; used by FastAPI.
- **TanStack Query**: Frontend server-state cache (fetching, caching, retries).
- **tRPC**: End-to-end typesafe RPC between TS client & server.
- **mTLS**: Mutual TLS—both client/server present certs. Use for service-to-service.
- **Alembic**: DB migration tool for SQLAlchemy/SQLModel.
- **SSR/ISR**: Server-Side Rendering / Incremental Static Regeneration in Next.js.
- **ACME**: Protocol for auto TLS certificates (Let’s Encrypt).
- **Middleware**: Request/response interceptors (auth, logging, rate limits).
- **JWT**: Signed token for auth; keep short-lived.
- **REST**: HTTP resource API; pair with OpenAPI.
- **Tailwind**: Utility-first CSS framework.
- **KMS**: Key Management Service (e.g., Cloud KMS) for encryption keys.
- **Ingress**: Entry to cluster/services (Traefik/Caddy/Nginx).
- **Drizzle**: Lightweight TS ORM; alt to Prisma.
- **WebSockets**: Bi-directional realtime; fallbacks SSE.
```

---

## Deployment Notes

- Prefer **Ansible** for host bootstraps and long-running stacks on **cbwdellr720**.
- Use **Docker Compose** locally and for quick previews; move heavy services to Ansible-managed bare metal.
- Maintain **single source of truth** for secrets in **Bitwarden**; CI loads them ephemerally.
- Centralize logs/metrics/traces on **cbwdellr720**; default retention 90 days (tune in Ansible vars).

---

## Make Targets

```makefile
help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## First-run host bootstrap
	ansible-playbook -i infra/ansible/inventories/lab/hosts infra/ansible/playbooks/bootstrap.yml

monitoring: ## Install/update monitoring stack
	ansible-playbook -i infra/ansible/inventories/lab/hosts infra/ansible/playbooks/monitoring.yml

env: ## Materialize env files from BW
	./tools/bw/bw-env.sh materialize
```

---

## What To Customize First
1) `infra/ansible/inventories/lab/hosts` – your hostnames & overlay IPs
2) `secrets/templates/*.tpl` – Bitwarden item names (no raw secrets!)
3) `apps/web-next` & `apps/api-fastapi` – project names, routes, DB urls
4) `infra/terraform/cloudflare` – DNS zones, tunnels, KV/R2 buckets
5) `tools/mcp/registry.yaml` – add/edit MCP endpoints & auth

---

## Roadmap / Tasks Backlog
- 🔐 Add Vault role to mirror select BW items → Vault paths w/ leases
- 🧠 Add LiteLLM proxy service + central config and per-app adapters
- ☸️ k3s variant with Helm charts for monitoring & apps
- 📈 Supabase functions scaffold + DDL & policies; seed scripts
- 🧪 Add end-to-end tests (Playwright for web, pytest for API)
- ♻️ GitHub/GitLab automation: Issues ↔ Projects v2 sync; AI code review jobs using OpenRouter free-tier
- 🗂 Knowledge base: evaluate **ClickUp** vs **Outline** (self-host) vs **AppFlowy Cloud** with RAG

---

## Security Notes
- Use **short-lived tokens** and **principle of least privilege** for CI variables.
- Restrict overlay access: only one primary overlay active for production paths.
- Rotate SSH keys quarterly; `cbw-ssh-ensure.sh` helps sync and push.
- Backups: Postgres base + WAL, Grafana dashboards, Prometheus TSDB snapshots.

---

## License
MIT (template). Replace with your preferred license.

