#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-monitoring.log"
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

echo "Launching monitoring stack (Prometheus + Loki + Promtail + Grafana + Node Exporter)..."
cd "$(dirname "${BASH_SOURCE[0]}")/../compose/monitoring"
do "mkdir -p data/grafana data/loki data/prometheus"
do "docker compose up -d"
