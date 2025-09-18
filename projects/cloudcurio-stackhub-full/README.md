
# CloudCurio StackHub (Full)

Next.js app + Cloudflare Worker API (D1, Vectorize, R2, Queues), plus Terraform, Pulumi, and Ansible for IaC.

## Quickstart (local web)
```bash
cd apps/web
npm install
npm run dev
```

## Cloudflare (API)
```bash
cd infrastructure/cloudflare
npm install
npm run build
# configure wrangler.toml, then:
npx wrangler d1 create stackhub_db
npx wrangler d1 execute stackhub_db --file d1/schema.sql
npm run deploy
```

## Deploy IaC
- Terraform: `terraform -chdir=infrastructure/terraform init && terraform -chdir=infrastructure/terraform apply`
- Pulumi: `cd infrastructure/pulumi && npm install && pulumi up`
- Ansible smoke tests: `ansible-playbook -i infrastructure/ansible/inventory.ini infrastructure/ansible/site.yml`
