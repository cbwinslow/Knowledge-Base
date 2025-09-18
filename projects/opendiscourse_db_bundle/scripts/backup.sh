
#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_USER:?set in .env}"
: "${POSTGRES_PASSWORD:?set in .env}"
: "${POSTGRES_DB:?set in .env}"
: "${POSTGRES_PORT:=5432}"
: "${QDRANT_PORT_HTTP:=6333}"

TS=$(date +%Y%m%d-%H%M%S)
OUTDIR=${OUTDIR:-backups}
mkdir -p "$OUTDIR"

PGCONN="host=localhost port=${POSTGRES_PORT} user=${POSTGRES_USER} dbname=${POSTGRES_DB}"
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump --format=custom --file="$OUTDIR/postgres-${TS}.dump" "$PGCONN"

echo "Postgres backup written to $OUTDIR/postgres-${TS}.dump"

curl -fsS -X POST "http://localhost:${QDRANT_PORT_HTTP}/snapshots" -H 'Content-Type: application/json' -d '{}' > "$OUTDIR/qdrant-snapshot-${TS}.json"
echo "Qdrant snapshot metadata saved to $OUTDIR/qdrant-snapshot-${TS}.json"
