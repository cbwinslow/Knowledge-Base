#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/CBW-proxmox-setup"
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/run-all.log"

red() { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
log() { echo "[$(date -Is)] $*" | tee -a "$LOG_DIR/run-all.log" ; }

# Load .env
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  red "Missing .env. Copy .env.example to .env and edit it."
  exit 1
fi
set -o allexport
source "$ROOT_DIR/.env"
set +o allexport

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
  log ">>> Running $s"
  bash "$ROOT_DIR/$s" | tee -a "$LOG_DIR/$(basename "$s").log"
  green "✔ Completed $(basename "$s")"
done

green "All steps completed."
