#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-storage.log"
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

echo "Launching MinIO..."
cd "$(dirname "${BASH_SOURCE[0]}")/../compose/storage"
do "mkdir -p data/minio"
do "docker compose up -d"
