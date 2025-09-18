# Proxmox Post-Install **PLUS** — Stacks, MCP, Propagation, Observability

Generated: 2025-09-14T14:35:55.205778

- Docker stacks: Supabase, Postgres+pgvector, Qdrant, OpenWebUI, AnythingLLM, MCP (hub+agent), Observability (Grafana/Prom/Loki/Promtail/Node Exporter/cAdvisor/Postgres Exporter).
- Env/secret generation and propagation.
- Repo batch cloning.
- Pigsty bootstrap helper.
- Orchestrator to manage all stacks.

## Quick Start
cp plus/.env.example plus/.env
plus/scripts/gen-secrets.sh
cd plus/stacks/postgres-pgvector && sudo ./up.sh
cd plus/orchestrators && sudo ./run-stacks.sh up
