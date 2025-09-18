#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-airflow-diagnose-fix.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-15
# Summary     : Diagnoses and fixes common Apache Airflow service failures on
#               Ubuntu 24.04 (bare metal install with venv + systemd units).
#
# Inputs      : None (auto-discovers). You may export PG vars to override:
#               PG_USER, PG_PASS, PG_HOST, PG_PORT, PG_DB
#
# Outputs     : Human-readable report to stdout; repairs applied in place.
#
# Safe Ops    : - Backs up airflow.cfg before edits.
#               - Does not drop/alter DB schema except 'airflow db migrate'.
#
# Exit codes  : 0 on healthy, non-zero on unrecoverable errors.
#===============================================================================

set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Failed at line $LINENO" >&2' ERR

#-------------------------------#
# Constants / Defaults
#-------------------------------#
AF_USER="airflow"
AF_HOME="/home/${AF_USER}/airflow"
AF_VENV="/home/${AF_USER}/airflow_venv"
AF_CFG="${AF_HOME}/airflow.cfg"
AF_WS_UNIT="/etc/systemd/system/airflow-webserver.service"
AF_SC_UNIT="/etc/systemd/system/airflow-scheduler.service"
AF_PORT="${AF_PORT:-8081}"  # keep consistent with earlier setup
PG_USER="${PG_USER:-airflow}"
PG_PASS="${PG_PASS:-airflow_strong_pw_change}"
PG_HOST="${PG_HOST:-127.0.0.1}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-airflow}"
SQLA="postgresql+psycopg2://${PG_USER}:${PG_PASS}@${PG_HOST}:${PG_PORT}/${PG_DB}"

LOG="/tmp/CBW-airflow-fix-$(date +%s).log"
exec > >(tee -a "$LOG") 2>&1

say() { echo -e "[*] $*"; }
ok()  { echo -e "[+] $*"; }
warn(){ echo -e "[-] $*" >&2; }

require_root() { [[ $EUID -eq 0 ]] || { warn "Run with sudo/root."; exit 1; }; }

svc_status() {
  local unit="$1"
  systemctl status "$unit" --no-pager || true
  echo "----- journal (last 100 lines) for $unit -----"
  journalctl -xeu "$unit" -n 100 --no-pager || true
  echo "----------------------------------------------"
}

file_backup() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  cp -a "$f" "${f}.bak.$(date +%Y%m%d-%H%M%S)"
}

replace_cfg_kv() {
  local file="$1" key="$2" value="$3"
  grep -qE "^${key} = " "$file" && \
    sed -i "s|^${key} = .*|${key} = ${value}|" "$file" || \
    echo "${key} = ${value}" >>"$file"
}

port_free() {
  local p="$1"
  ss -lnt "( sport = :$p )" | awk 'NR>1{print $4}' | grep -q ":$p$" && return 1 || return 0
}

#-------------------------------#
# Diagnostics
#-------------------------------#
require_root

say "Checking Airflow user/home/venv..."
id "$AF_USER" &>/dev/null || { warn "User '$AF_USER' missing. Run cbw-add-airflow-user.sh first."; exit 1; }
[[ -d "$AF_HOME" ]] || { warn "AIRFLOW_HOME missing at $AF_HOME"; exit 1; }
[[ -d "$AF_VENV" ]] || { warn "Airflow venv missing at $AF_VENV"; exit 1; }
[[ -x "$AF_VENV/bin/airflow" ]] || { warn "airflow binary not found in $AF_VENV/bin"; exit 1; }
ok "Airflow user/home/venv found."

say "Checking DAGs/logs/plugins dirs ownership..."
mkdir -p "${AF_HOME}/"{dags,logs,plugins}
chown -R "${AF_USER}:${AF_USER}" "/home/${AF_USER}"
ok "Ownership normalized under /home/${AF_USER}"

say "Looking at systemd unit files..."
[[ -f "$AF_WS_UNIT" ]] || warn "Missing $AF_WS_UNIT"
[[ -f "$AF_SC_UNIT" ]] || warn "Missing $AF_SC_UNIT"
systemctl daemon-reload

say "Checking airflow.cfg and SQL Alchemy connection..."
if [[ ! -f "$AF_CFG" ]]; then
  warn "No airflow.cfg; initializing DB to generate one..."
  sudo -u "$AF_USER" bash -lc "source '$AF_VENV/bin/activate' && AIRFLOW_HOME='$AF_HOME' airflow db init"
fi

file_backup "$AF_CFG"
replace_cfg_kv "$AF_CFG" "sql_alchemy_conn" "$SQLA"
replace_cfg_kv "$AF_CFG" "web_server_port" "$AF_PORT"
replace_cfg_kv "$AF_CFG" "load_examples" "False"
ok "Configured airflow.cfg (sql_alchemy_conn, web_server_port). Backup saved."

say "Checking Postgres connectivity..."
if ! sudo -u "$AF_USER" bash -lc "python3 - <<'PY'
import sys, psycopg2
import os
from urllib.parse import urlparse
url = os.environ.get('SQLA')
if not url:
    print('No SQLA in env', file=sys.stderr); sys.exit(2)
u = urlparse(url.replace('+psycopg2',''))
conn = psycopg2.connect(dbname=u.path.lstrip('/'), user=u.username, password=u.password, host=u.hostname, port=u.port)
cur = conn.cursor(); cur.execute('SELECT 1'); print(cur.fetchone()); conn.close()
PY
"; then
  warn "Failed to connect to Postgres with $SQLA"
  warn "Ensure DB/user exist (create with psql). Trying to create user/DB now..."

  # Try to create DB and user if possible (assumes local admin)
  if command -v psql >/dev/null; then
    sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '${PG_USER}';" | grep -q 1 || \
      sudo -u postgres psql -c "CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASS}';"
    sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '${PG_DB}';" | grep -q 1 || \
      sudo -u postgres psql -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};"
    ok "Created/verified DB and user. Re-testing connection..."
    export SQLA
    sudo -u "$AF_USER" bash -lc "export SQLA='$SQLA'; python3 - <<'PY'
import sys, psycopg2, os
from urllib.parse import urlparse
u = urlparse(os.environ['SQLA'].replace('+psycopg2',''))
conn = psycopg2.connect(dbname=u.path.lstrip('/'), user=u.username, password=u.password, host=u.hostname, port=u.port)
cur = conn.cursor(); cur.execute('SELECT 1'); print(cur.fetchone()); conn.close()
PY"
  else
    warn "psql not installed or not reachable as postgres; skipping auto-create."
  fi
fi
ok "Postgres connectivity OK."

say "Running 'airflow db migrate' just in case..."
sudo -u "$AF_USER" bash -lc "source '$AF_VENV/bin/activate' && AIRFLOW_HOME='$AF_HOME' airflow db migrate"

say "Ensuring admin user exists (idempotent)..."
sudo -u "$AF_USER" bash -lc "source '$AF_VENV/bin/activate' && \
  airflow users create --role Admin --username cbw --password change_me_now \
  --firstname Blaine --lastname Winslow --email blaine.winslow@gmail.com || true"

say "Checking port availability..."
if ! port_free "$AF_PORT"; then
  warn "Port $AF_PORT is already in use. Printing listeners:"
  ss -lnt | sed -n '1p;/:'"$AF_PORT"' /p'
  warn "Adjust 'web_server_port' in $AF_CFG or free the port."
fi

say "Restarting Airflow services..."
systemctl daemon-reload
systemctl restart airflow-scheduler || true
systemctl restart airflow-webserver || true
sleep 2

say "Collecting status after restart..."
svc_status airflow-scheduler.service
svc_status airflow-webserver.service

# Health probe: try CLI ping
say "CLI health check (airflow version, db check)..."
sudo -u "$AF_USER" bash -lc "source '$AF_VENV/bin/activate' && airflow version && airflow db check"

echo
ok "Diagnosis & remediation complete. Review statuses above."
echo "Log saved to: $LOG"
