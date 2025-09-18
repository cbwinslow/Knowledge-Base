#!/usr/bin/env bash
set -euo pipefail

pushd "$(dirname "$0")/../../docker/compose" >/dev/null
docker compose -f kong.yml up -d
popd

echo "[✓] Kong API Gateway started."
