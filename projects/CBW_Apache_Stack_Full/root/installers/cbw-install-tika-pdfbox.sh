#!/usr/bin/env bash
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PG=/usr/local/sbin/cbw-port-guard.sh
PORT=$($PG reserve TIKA 9998 | tail -n1)
TV=2.9.2
apt update && apt install -y default-jre wget
install -d /opt/tika
wget -q "https://dlcdn.apache.org/tika/${TV}/tika-server-standard-${TV}.jar" -O /opt/tika/tika-server.jar
cat >/etc/systemd/system/tika.service <<EOF
[Unit]
Description=Apache Tika Server
After=network-online.target
[Service]
User=root
ExecStart=/usr/bin/java -jar /opt/tika/tika-server.jar -h 127.0.0.1 -p ${PORT}
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now tika
echo "[+] Tika server on 127.0.0.1:${PORT}"
