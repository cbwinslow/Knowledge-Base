#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-install.log"
exec > >(tee -a "$LOG") 2>&1

DRY_RUN=false
VERBOSE=false
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

usage() {
  cat <<EOF
CBW Homelab Bootstrap Installer
Usage: sudo ./install.sh [options]

Options:
  --dry-run      Print actions without executing
  --verbose      Extra logging
  --help         This help

This orchestrates the modular scripts under ./scripts.
EOF
}

run() {
  local script="$1"; shift || true
  if $DRY_RUN; then
    echo "[DRY-RUN] $script $*"
  else
    echo "=== Running $script $*"
    bash "$SCRIPTS_DIR/$script" "$@"
  fi
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true;;
    --verbose) VERBOSE=true;;
    --help|-h) usage; exit 0;;
    *) ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "Please run as root (sudo)."; exit 1; }

export CBW_VERBOSE=$VERBOSE

# Phase 0: prerequisites & hardening
run 00_prereqs.sh
run 01_ssh_harden.sh
run 02_firewall.sh
run 03_fail2ban.sh
run 04_suricata.sh
run 05_zerotier.sh

# Phase 1: containers runtime
run 10_docker.sh
run 11_docker_compose.sh
run 12_port_watchdog.sh

# Phase 2: reverse proxy(s)
run 20_nginx.sh
run 21_caddy.sh
run 22_traefik.sh

# Phase 3: stacks
run 30_monitoring_stack.sh
run 31_database_stack.sh
run 32_vectordb_stack.sh
run 33_ai_stack.sh
run 34_storage_stack.sh

# Phase 4: git/dotfiles
run 40_git_setup.sh

echo "✅ Bootstrap complete. See README.md for next steps."
