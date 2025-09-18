#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-compose.log"
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

echo "Ensuring Docker Compose v2 plugin is available..."
do "docker compose version || true"
# Create default network
NET=$(grep '^DOCKER_NET=' .env | cut -d= -f2- || echo "cbw_net")
do "docker network create $NET || true"
