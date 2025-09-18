
#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_USER:?set in .env}"
: "${POSTGRES_PASSWORD:?set in .env}"
: "${POSTGRES_DB:?set in .env}"
: "${POSTGRES_PORT:=5432}"

PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f db/refresh_matviews.sql
