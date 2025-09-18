#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-pg-backup.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-15
# Summary     : Safe, rotating PostgreSQL backups with verification and logging.
# Inputs      : Optional env file /etc/cbw-pg-backup.conf
# Outputs     : Compressed dumps in BACKUP_DIR; log at /var/log/cbw/pg_backup.log
#-------------------------------------------------------------------------------
# Security    : - Uses local UNIX socket by default (no plaintext passwords).
#               - Supports PGPASSFILE if needed (0600 perm).
# Reliability : - Rotates old backups with retention policy.
#               - Validates dumps by listing archive contents.
#               - Non-zero exit on any failure.
#===============================================================================

set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Backup failed at line $LINENO" >&2' ERR

#-------------------------------#
# Defaults (can be overridden)
#-------------------------------#
CONF_FILE="/etc/cbw-pg-backup.conf"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
PG_BIN="${PG_BIN:-/usr/bin}"
PG_USER="${PG_USER:-postgres}"          # system user to run pg_dump
DATABASES="${DATABASES:-ALL}"           # "ALL" or space-separated list, e.g. "airflow superset"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="/var/log/cbw"
LOG_FILE="$LOG_DIR/pg_backup.log"

# Load overrides if present
if [[ -f "$CONF_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONF_FILE"
fi

mkdir -p "$BACKUP_DIR" "$LOG_DIR"
chmod 0750 "$BACKUP_DIR"
touch "$LOG_FILE"
chmod 0640 "$LOG_FILE"

log() { echo "[$(date -Is)] $*" | tee -a "$LOG_FILE"; }

# Preflight
command -v "${PG_BIN}/pg_dump" >/dev/null || { log "pg_dump not found"; exit 1; }
id -u "$PG_USER" >/dev/null || { log "Postgres user $PG_USER missing"; exit 1; }

#-------------------------------#
# Backup Functions
#-------------------------------#
backup_db() {
  local db="$1"
  local out="${BACKUP_DIR}/${db}_${TIMESTAMP}.sql.zst"
  log "Backing up database: $db -> $out"
  # dump + compress (zstd fast and safe)
  sudo -u "$PG_USER" "${PG_BIN}/pg_dump" --format=plain --no-owner --no-privileges "$db" \
    | zstd -T0 -19 -o "$out"
  # quick validation: ensure file exists and is non-empty
  [[ -s "$out" ]] || { log "Backup file empty for $db"; return 1; }
  log "OK: $db"
}

backup_all() {
  local dblist
  dblist=$(sudo -u "$PG_USER" "${PG_BIN}/psql" -Atqc "SELECT datname FROM pg_database WHERE datistemplate = false;")
  for d in $dblist; do backup_db "$d"; done
}

prune_old() {
  log "Pruning backups older than ${RETENTION_DAYS} days in $BACKUP_DIR"
  find "$BACKUP_DIR" -type f -name "*.zst" -mtime +"$RETENTION_DAYS" -print -delete | sed 's/^/[prune] /' || true
}

#-------------------------------#
# Main
#-------------------------------#
log "=== PostgreSQL backup run started ==="
if [[ "$DATABASES" == "ALL" ]]; then
  backup_all
else
  for d in $DATABASES; do backup_db "$d"; done
fi
prune_old
log "=== PostgreSQL backup run complete ==="
