# CloudCurio StackHub — Repo Tree & How to Deploy

This canvas summarizes the repo you can download, including Worker+Queues+Access+R2 improvements and the Next.js app.

## Repo tree (key paths)
```
cloudcurio-stackhub/
├─ README.md
├─ apps/
│  └─ web/
│     ├─ package.json
│     ├─ next.config.mjs
│     ├─ tailwind.config.ts
│     ├─ src/
│     │  ├─ app/
│     │  │  ├─ page.tsx
│     │  │  ├─ validator/page.tsx
│     │  │  ├─ admin/page.tsx
│     │  │  └─ api/export/route.ts
│     │  ├─ components/
│     │  │  ├─ Nav.tsx
│     │  │  └─ ItemCard.tsx
│     │  └─ lib/
│     │     ├─ types.ts
│     │     ├─ data.ts
│     │     ├─ exporters.ts
│     │     ├─ bundles.ts
│     │     └─ seed.json
│     └─ content/blog/hello.md
├─ infrastructure/
│  ├─ cloudflare/
│  │  ├─ package.json
│  │  ├─ tsconfig.json
│  │  ├─ wrangler.toml  ← Worker with D1 + Vectorize + R2 + Queues (+ Turnstile/Access)
│  │  ├─ d1/schema.sql
│  │  └─ src/index.ts   ← API + /export cache+R2 + /share + Queue consumer
│  ├─ terraform/
│  │  ├─ providers.tf
│  │  ├─ variables.tf
│  │  └─ main.tf        ← Pages, DNS, D1, R2, Turnstile, Access, Queue, WorkersScript
│  └─ pulumi/
│     ├─ Pulumi.yaml
│     ├─ package.json
│     ├─ tsconfig.json
│     └─ index.ts       ← D1, R2, Turnstile, Queue, Pages, DNS
├─ infrastructure/ansible/
│  ├─ inventory.ini
│  ├─ group_vars/all.yml
│  └─ site.yml          ← Preflight+Wrangler deploy+D1 schema+Vectorize create+Smoke tests
├─ docker/
│  ├─ flowise/docker-compose.yml
│  └─ n8n/docker-compose.yml
└─ .github/workflows/
   ├─ pages-build.yml
   ├─ terraform.yml
   └─ smoke.yml
```

## How to deploy (quick)
1. **Terraform** (create CF resources): set secrets, then `terraform -chdir=infrastructure/terraform init && terraform -chdir=infrastructure/terraform apply`.
2. **Worker**: `cd infrastructure/cloudflare && npm i && npm run build && npm run deploy` (ensure `wrangler.toml` bindings are set and D1 id replaced).
3. **Pages**: connect repo in CF Pages, set root to `apps/web/` and `NODE_VERSION=20`; env `NEXT_PUBLIC_STACKHUB_API=https://api.cloudcurio.cc`.
4. **Smoke**: `ansible-playbook -i infrastructure/ansible/inventory.ini infrastructure/ansible/site.yml`.

## Download the full repo
Use the link below to grab the complete zip with all files listed above.

