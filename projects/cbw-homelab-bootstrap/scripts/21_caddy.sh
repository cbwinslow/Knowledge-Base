#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-caddy.log"
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

echo "Preparing Caddy docker stack..."
# stack is in compose/reverse-proxy/caddy
echo "Use: (cd compose/reverse-proxy/caddy && docker compose up -d)"
