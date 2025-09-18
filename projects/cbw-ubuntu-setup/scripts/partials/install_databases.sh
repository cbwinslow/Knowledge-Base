#!/usr/bin/env bash
set -euo pipefail

# Compose stacks for DBs
pushd "$(dirname "$0")/../../docker/compose" >/dev/null
docker compose -f databases.yml up -d
popd

echo "[✓] Database containers (Postgres+pgvector, Qdrant, MongoDB, OpenSearch, RabbitMQ) launched."
