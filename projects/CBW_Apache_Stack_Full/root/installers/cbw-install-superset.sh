#!/usr/bin/env bash
set -euo pipefail; IFS=$'\n\t'; trap 'echo "[ERROR] $LINENO" >&2' ERR
PG=/usr/local/sbin/cbw-port-guard.sh
[[ -x $PG ]] || { echo "cbw-port-guard.sh not found"; exit 1; }
PORT=$($PG reserve SUPERSET 8088 | tail -n1)
DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=superset DB_USER=superset DB_PASS=${SUPERSET_DB_PASS:-superset_strong_pw_change}
apt update
apt install -y python3-venv python3-dev build-essential libpq-dev postgresql-client
id -u superset &>/dev/null || useradd -m -s /bin/bash superset
install -d -o superset -g superset /opt/superset
sudo -u superset python3 -m venv /opt/superset/venv
sudo -u superset /opt/superset/venv/bin/pip install --upgrade pip wheel setuptools
sudo -u superset /opt/superset/venv/bin/pip install "apache-superset==4.0.2" psycopg2-binary
cat >/etc/systemd/system/superset.service <<EOF
[Unit]
Description=Apache Superset
After=network-online.target
[Service]
User=superset
Group=superset
WorkingDirectory=/opt/superset
Environment=SUPERSET_PORT=${PORT}
Environment=SUPERSET_ENV=production
Environment=PYTHONPATH=/opt/superset
Environment=SQLALCHEMY_DATABASE_URI=postgresql+psycopg2://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}
ExecStart=/opt/superset/venv/bin/superset run -h 127.0.0.1 -p ${PORT} --with-threads --reload --debugger
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO $$BEGIN IF NOT EXISTS (SELECT FROM pg_database WHERE datname='${DB_NAME}') THEN
  CREATE DATABASE ${DB_NAME};
END IF; END$$;
DO $$BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='${DB_USER}') THEN
  CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
END IF; END$$;
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL
sudo -u superset /opt/superset/venv/bin/superset db upgrade
sudo -u superset /opt/superset/venv/bin/superset fab create-admin --username cbw --firstname CB --lastname Winslow --email cbw@example.com --password ${SUPERSET_ADMIN_PASS:-ChangeMeNow!}
sudo -u superset /opt/superset/venv/bin/superset load_examples || true
sudo -u superset /opt/superset/venv/bin/superset init
systemctl daemon-reload && systemctl enable --now superset
echo "[+] Superset running on 127.0.0.1:${PORT}"
