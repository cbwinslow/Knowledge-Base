#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-vectordb.log"
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

echo "Launching Qdrant..."
cd "$(dirname "${BASH_SOURCE[0]}")/../compose/vectordb"
do "mkdir -p data/qdrant"
do "docker compose up -d"
