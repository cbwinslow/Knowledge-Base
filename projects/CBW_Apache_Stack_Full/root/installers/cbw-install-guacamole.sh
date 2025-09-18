#!/usr/bin/env bash
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PG=/usr/local/sbin/cbw-port-guard.sh
HTTP=$($PG reserve TOMCAT_HTTP 8082 | tail -n1)
apt update && apt install -y tomcat10 guacamole guacd
sed -i "s/\(<Connector port=\)\"[0-9]\+\"/\1\"${HTTP}\"/" /etc/tomcat10/server.xml
sed -i 's/address="[^"]*"/address="127.0.0.1"/' /etc/tomcat10/server.xml || true
systemctl enable --now guacd tomcat10
echo "[+] Guacamole at http://127.0.0.1:${HTTP}/guacamole/ (tunnel via Cloudflare)"
