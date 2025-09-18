#!/usr/bin/env bash
set -euo pipefail

bash "$(dirname "$0")/install_postgres_pgvector_bare.sh"
bash "$(dirname "$0")/install_qdrant_bare.sh"
bash "$(dirname "$0")/install_mongodb_bare.sh"
bash "$(dirname "$0")/install_opensearch_bare.sh"
bash "$(dirname "$0")/install_rabbitmq_bare.sh"

echo "[✓] Bare-metal databases installed and started (Postgres+pgvector, Qdrant, MongoDB, OpenSearch, RabbitMQ)."
