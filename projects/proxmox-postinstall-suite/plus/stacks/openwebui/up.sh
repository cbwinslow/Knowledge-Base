#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/../.env"
if [[ -f "$ENV_FILE" ]]; then export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n' --no-run-if-empty echo) || true; fi
docker compose up -d
docker compose ps
