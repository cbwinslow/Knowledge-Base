#!/usr/bin/env bash
set -euo pipefail

PG_VER="${PG_VER:-16}"
APP_DB="${APP_DB:-app}"
APP_USER="${APP_USER:-appuser}"
APP_PASS="${APP_PASS:-apppass}"

echo "[*] Installing PostgreSQL ${PG_VER} (PGDG) + pgvector"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg
echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt $(. /etc/os-release && echo $VERSION_CODENAME)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

apt-get update -y
apt-get install -y "postgresql-${PG_VER}" "postgresql-${PG_VER}-pgvector" postgresql-client-common

systemctl enable --now "postgresql@${PG_VER}-main" || systemctl enable --now postgresql

# Create db, user, enable extension
sudo -u "postgres" psql -tc "SELECT 1 FROM pg_database WHERE datname='${APP_DB}'" | grep -q 1 || sudo -u postgres createdb "${APP_DB}"
sudo -u "postgres" psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${APP_USER}'" | grep -q 1 || sudo -u postgres psql -c "CREATE ROLE ${APP_USER} LOGIN PASSWORD '${APP_PASS}';"
sudo -u "postgres" psql -d "${APP_DB}" -c "CREATE EXTENSION IF NOT EXISTS vector;" || true

# Basic tuning (append if not present)
PG_CONF="/etc/postgresql/${PG_VER}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VER}/main/pg_hba.conf"
if [ -f "$PG_CONF" ]; then
  grep -q "^shared_buffers" "$PG_CONF" || echo "shared_buffers = 1GB" >> "$PG_CONF"
  grep -q "^work_mem" "$PG_CONF" || echo "work_mem = 64MB" >> "$PG_CONF"
  grep -q "^maintenance_work_mem" "$PG_CONF" || echo "maintenance_work_mem = 256MB" >> "$PG_CONF"
  grep -q "^listen_addresses" "$PG_CONF" || echo "listen_addresses = '*'" >> "$PG_CONF"
fi
if [ -f "$PG_HBA" ]; then
  if ! grep -q "0.0.0.0/0" "$PG_HBA"; then
    echo "host    all             all             0.0.0.0/0               md5" >> "$PG_HBA"
  fi
fi
systemctl restart postgresql

echo "[✓] PostgreSQL ${PG_VER} + pgvector ready."
