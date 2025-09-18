#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-ufw.log"
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

echo "Configuring UFW..."
do "ufw default deny incoming"
do "ufw default allow outgoing"
# Common services
for p in 22 80 443; do do "ufw allow $p"; done
# Monitoring console (Grafana) default
do "ufw allow 3000"
# Postgres (restrict later if needed)
do "ufw allow 5432"
# MinIO console default
do "ufw allow 9001"
do "ufw --force enable"
do "ufw status verbose"
