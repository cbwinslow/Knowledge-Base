#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-ai.log"
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

echo "Launching Ollama + Open WebUI..."
cd "$(dirname "${BASH_SOURCE[0]}")/../compose/ai"
do "mkdir -p data/openwebui data/ollama"
do "docker compose up -d"
