#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-nginx.log"
exec > >(tee -a "$LOG") 2>&1

DRY_RUN=${DRY_RUN:-false}
VERBOSE=${CBW_VERBOSE:-false}

do() {
  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

echo "Installing Nginx..."
do "apt-get install -y nginx"
do "systemctl enable --now nginx"
