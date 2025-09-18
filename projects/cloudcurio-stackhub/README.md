# CloudCurio StackHub

A tiny **Next.js + Tailwind** app for curating your **scripts, configs, tools, and stacks** (Bash, Ansible, Terraform, Pulumi), then **exporting** a single **monolith** file:
- **bash** (`stackhub-export.sh`) or
- **ansible** (`stackhub-export.yml`).

Includes:
- **Left-hand navigation** with categories and tags
- **Search + multi-select** to build an export
- **Cloudflare** setup: Pages + Workers (Wrangler), **D1** (SQLite), **Vectorize** (optional), **KV** (optional)
- **Terraform** and **Pulumi** IaC examples for Cloudflare
- **Flowise** and **n8n** docker-compose to help **auto-generate blog posts** and **docs** from prompts
- Starter **Blog** page with editable markdown posts

> Generated: 2025-09-15 22:29:53

## Quickstart (Local Dev)

```bash
# 1) Prereqs: Node 20+, pnpm (or npm), and wrangler (if using Cloudflare dev)
# Install deps
cd apps/web
pnpm install   # or: npm install

# Run dev server
pnpm dev       # or: npm run dev
# open http://localhost:3000
```

## Deploy to Cloudflare Pages

1. Create a new Cloudflare Pages project, connect this repo.
2. Build command: `pnpm install && pnpm build`
3. Output directory: `.next` (Pages picks it automatically for Next.js)
4. For Workers/D1/KV/Vectorize: push `infrastructure/cloudflare/wrangler.toml` to a separate Workers project or bind via Pages Functions.

## Data Storage Options

- **Static JSON** (`apps/web/src/lib/seed.json`): simplest, zero infra.
- **Cloudflare D1**: use `infrastructure/cloudflare/d1/schema.sql` then bind to the Worker.
- **Cloudflare Vectorize** (optional) + **KV/R2** for vector/RAG assets.

This starter uses static JSON at runtime by default. Flip to D1 by enabling the API adapter in `apps/web/src/lib/data.ts`.

## Export Formats

- **Bash**: app merges selected `script_bash` blocks with safety headers and logging.
- **Ansible**: app synthesizes a valid playbook containing roles/tasks derived from selected items.

Exports are built by `apps/web/src/app/api/export/route.ts`.

## Blog & Editor Flow

- Basic Markdown blog under `apps/web/content/blog/`.
- Bring up **Flowise** (`docker/flowise`) or **n8n** (`docker/n8n`) to generate drafts automatically. Wire webhooks to create `.md` files.

## Repo Layout

```
cloudcurio-stackhub/
├─ apps/web/                    # Next.js app
│  ├─ src/app/                  # App Router
│  ├─ src/components/           # UI components
│  ├─ src/lib/                  # data adapters, seed
│  ├─ content/blog/             # markdown posts
│  └─ public/                   # static assets
├─ infrastructure/
│  ├─ cloudflare/
│  │  ├─ wrangler.toml          # Workers/D1 bindings (edit IDs/names)
│  │  ├─ d1/schema.sql          # D1 table schema
│  │  └─ vectorize/README.md    # notes on Vectorize setup
│  ├─ terraform/                # Cloudflare IaC example
│  └─ pulumi/                   # Cloudflare IaC example
└─ docker/
   ├─ flowise/docker-compose.yml
   └─ n8n/docker-compose.yml
```

## Security & Best Practices

- No secrets in repo. Use **Wrangler secrets**, **Pages env vars**, or CI vault.
- Shell export includes **defensive headers**, dry-run guard, and logging to `/tmp/CBW-stackhub.log`.
- Ansible export sets `gather_facts: true`, `become: true`, and validates `ansible_python_interpreter`.

## Ideas & Next Steps
1. Add auth (Cloudflare Access) + per-user collections.
2. Switch from static seed to **D1 + Vectorize** with embeddings for semantic search.
3. Build **“Agent Configs”** UI and deploy to **Workers** directly.
4. Add **GitHub Actions** for Pages deploy, schema migrations, and seed sync.
5. Add **importers** for your existing `~/dev/dotfiles` + `~/bin` via drag/drop.
6. Generate **one-click gists** or **GitHub repo** of a selected bundle.

— Built for **cloudcurio.cc** ♥
