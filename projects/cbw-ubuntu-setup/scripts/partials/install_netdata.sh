#!/usr/bin/env bash
set -euo pipefail

pushd "$(dirname "$0")/../../docker/compose" >/dev/null
docker compose -f netdata.yml up -d
popd

echo "[✓] Netdata started on port 19999."
