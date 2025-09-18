# Proxmox Post‑Install Kit (Dell R720)

Generated: 2025-09-14T13:31:08.134888

This kit bootstraps a **fresh Proxmox VE** install on a Dell R720 with sensible defaults and optional integrations (ZeroTier, Cloudflare Tunnel, Docker, monitoring, Ansible).

## Highlights
- Idempotent, logged, and safe-by-default.
- One `.env` file to drive all scripts.
- Disables enterprise repo; enables no‑subscription repo.
- Hardens SSH; creates admin user; enforces key‑only auth.
- Enables IOMMU for PCIe passthrough on Intel (R720).
- Optional: ZeroTier join, Cloudflare Tunnel, Docker CE, Netdata/Zabbix, Ansible prep.

## Quick Start
1. Copy this folder to your Proxmox host (e.g., `/root/proxmox-postinstall`).
2. Create and edit your `.env` by copying the example:
   ```bash
   cp .env.example .env
   nano .env
   ```
3. Run the orchestrator:
   ```bash
   sudo ./run-all.sh
   ```

Logs are written to `/var/log/CBW-proxmox-setup/*.log`.

> Tip: You can re-run `./run-all.sh` safely; steps are idempotent.
