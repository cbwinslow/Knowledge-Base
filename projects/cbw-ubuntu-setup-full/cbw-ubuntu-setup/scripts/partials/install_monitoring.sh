#!/usr/bin/env bash
set -euo pipefail
pushd "$(dirname "$0")/../../docker/compose" >/dev/null
docker compose -f monitoring.yml up -d
popd
echo "[✓] Monitoring stack started."
