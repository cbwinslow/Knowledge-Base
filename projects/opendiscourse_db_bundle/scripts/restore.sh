
#!/usr/bin/env bash
set -euo pipefail

FILE=${1:-}
if [[ -z "$FILE" ]]; then
  echo "Usage: scripts/restore.sh <postgres_dump_file>" >&2
  exit 1
fi

: "${POSTGRES_USER:?set in .env}"
: "${POSTGRES_PASSWORD:?set in .env}"
: "${POSTGRES_DB:?set in .env}"
: "${POSTGRES_PORT:=5432}"

PGCONN="host=localhost port=${POSTGRES_PORT} user=${POSTGRES_USER} dbname=${POSTGRES_DB}"
PGPASSWORD="$POSTGRES_PASSWORD" pg_restore --clean --if-exists --no-owner --dbname="$PGCONN" "$FILE"
