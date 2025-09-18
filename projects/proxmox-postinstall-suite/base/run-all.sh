#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/CBW-proxmox-setup"; mkdir -p "$LOG_DIR"; touch "$LOG_DIR/run-all.log"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "Missing .env. Copy base/.env.example to .env and edit it." >&2
  exit 1
fi
set -o allexport; source "$ROOT_DIR/.env"; set +o allexport

SCRIPTS=(
  "scripts/00-preflight.sh"
  "scripts/10-os-and-repos.sh"
  "scripts/15-iommu-and-kernel.sh"
  "scripts/20-hostname-and-network.sh"
  "scripts/25-user-and-ssh.sh"
  "scripts/30-firewall.sh"
  "scripts/35-zerotier.sh"
  "scripts/40-cloudflared.sh"
  "scripts/45-docker.sh"
  "scripts/50-monitoring.sh"
  "scripts/60-ansible.sh"
)
for s in "${SCRIPTS[@]}"; do
  echo ">>> Running $s" | tee -a "$LOG_DIR/run-all.log"
  bash "$ROOT_DIR/$s" | tee -a "$LOG_DIR/$(basename "$s").log"
done
echo "✔ All steps complete."
