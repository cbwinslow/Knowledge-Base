#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-traefik.log"
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

echo "Preparing Traefik docker stack..."
echo "Use: (cd compose/reverse-proxy/traefik && docker compose up -d)"
