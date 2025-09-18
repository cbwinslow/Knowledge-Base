# Proxmox Post-Install Kit (Dell R720)

Generated: 2025-09-14T14:35:55.205778

This kit bootstraps a fresh Proxmox VE install on a Dell R720. It’s safe to re-run and fully logged.
See `README-PLUS.md` for the expanded stacks and orchestration pack.

## Quick Start
1) Copy this folder to the host (e.g., `/root/proxmox-postinstall-suite`).
2) `cp base/.env.example base/.env && nano base/.env`
3) Run: `sudo ./base/run-all.sh`

Logs: `/var/log/CBW-proxmox-setup/`
