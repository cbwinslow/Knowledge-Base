#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-superset.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-15
# Summary     : Bare-metal install of Apache Superset (Python venv) with port
#               auto-reservation and Postgres backend.
#===============================================================================

set -euo pipefail
trap 'echo "[ERROR] Failed at line $LINENO" >&2' ERR

PORT_SUPERSET_DEFAULT=8088
PORT_SUPERSET="$(/usr/local/sbin/cbw-port-guard.sh reserve SUPERSET "$PORT_SUPERSET_DEFAULT" | tail -n1)"

# DB settings (change if you customized)
PG_USER="${PG_USER:-superset}"
PG_PASS="${PG_PASS:-superset_strong_pw_change}"
PG_DB="${PG_DB:-superset}"
PG_HOST="${PG_HOST:-127.0.0.1}"
PG_PORT="${PG_PORT:-5432}"
SQLA="postgresql+psycopg2://${PG_USER}:${PG_PASS}@${PG_HOST}:${PG_PORT}/${PG_DB}"

# Ensure role/db exist (idempotent)
apt update && apt install -y postgresql-client python3-venv python3-dev libpq-dev build-essential
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '${PG_USER}';" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASS}';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '${PG_DB}';" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};"

# Create user/venv
id -u superset &>/dev/null || useradd -m -s /bin/bash superset
sudo -u superset bash -lc '
  python3 -m venv ~/superset_venv
  source ~/superset_venv/bin/activate
  pip install --upgrade pip wheel
  pip install apache-superset psycopg2-binary
  echo "SQLALCHEMY_DATABASE_URI = \"'"$SQLA"'\"" > ~/superset_config.py
  echo "ENABLE_PROXY_FIX = True" >> ~/superset_config.py
  superset fab create-admin --username cbw --firstname Blaine --lastname Winslow --email blaine.winslow@gmail.com --password change_me_now || true
  superset db upgrade
  superset init
'

# systemd unit
cat >/etc/systemd/system/superset.service <<EOF
[Unit]
Description=Apache Superset
After=network.target
[Service]
User=superset
Environment=SUPERSET_CONFIG_PATH=/home/superset/superset_config.py
ExecStart=/home/superset/superset_venv/bin/superset run -p ${PORT_SUPERSET} --with-threads
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now superset

echo
echo "[+] Superset running: http://<host>:${PORT_SUPERSET}"
echo "    (Bind behind Cloudflare Tunnel + Access before exposing)"