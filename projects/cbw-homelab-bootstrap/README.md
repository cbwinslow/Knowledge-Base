# CBW Homelab Bootstrap (Proxmox/Ubuntu/Debian)

Turn‑key scripts and Docker stacks to set up:
- SSH hardening, UFW, Fail2ban, Suricata, port watchdog
- Reverse proxies: Nginx, Traefik, Caddy
- Docker & Compose
- Monitoring stack: Prometheus + Node Exporter + Loki + Promtail + Grafana
- Database stack: PostgreSQL (+pgvector) + Adminer
- Vector DB: Qdrant
- AI/LLM stack: Ollama + Open WebUI
- Storage: MinIO (+ mc)
- ZeroTier CLI provisioning
- Git defaults & dotfiles hook

## Quick start
```bash
curl -fsSL https://raw.githubusercontent.com/cbwinslow/placeholder/main/install.sh -o install.sh
bash install.sh
```
Or, run from this bundle:
```bash
chmod +x install.sh
sudo ./install.sh
```
All scripts are idempotent, logged to `/tmp/CBW-<script>.log`, and support `--dry-run` & `--verbose`.

## Folders
- `scripts/` one‑purpose installers
- `compose/` Docker Compose stacks
- `systemd/` background services (port watchdog)
- `configs/` config templates
- `.env.example` copy to `.env` and edit secrets/domains/ports

## Defaults
- Domain root: `cloudcurio.cc` (override in `.env`)
- User: `cbwinslow`
- ZeroTier: optional – set `ZTC_NETWORK_ID` in `.env`

> Review each compose file and set host paths/ports to avoid conflicts.
