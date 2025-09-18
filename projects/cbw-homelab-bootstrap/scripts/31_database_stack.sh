#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-database.log"
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

echo "Launching PostgreSQL (+pgvector) + Adminer..."
cd "$(dirname "${BASH_SOURCE[0]}")/../compose/database"
do "mkdir -p data/postgres"
do "docker compose up -d"
