#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-tika-pdfbox.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-15
# Summary     : Bare-metal install of Apache Tika server + PDFBox with port
#               auto-reservation via cbw-port-guard.
#===============================================================================

set -euo pipefail
trap 'echo "[ERROR] Failed at line $LINENO" >&2' ERR

PORT_TIKA_DEFAULT=9998
PORT_TIKA="$(/usr/local/sbin/cbw-port-guard.sh reserve TIKA "$PORT_TIKA_DEFAULT" | tail -n1)"

apt update
apt install -y openjdk-21-jdk wget

mkdir -p /opt/tika /var/log/tika
TIKA_VER="2.9.2"
PDFBOX_VER="2.0.31"

wget -q "https://dlcdn.apache.org/tika/tika-server-${TIKA_VER}.jar" -O /opt/tika/tika-server.jar
wget -q "https://dlcdn.apache.org/pdfbox/${PDFBOX_VER}/pdfbox-app-${PDFBOX_VER}.jar" -O /opt/tika/pdfbox.jar

cat >/etc/systemd/system/tika.service <<EOF
[Unit]
Description=Apache Tika Server
After=network-online.target
[Service]
ExecStart=/usr/bin/java -jar /opt/tika/tika-server.jar -p ${PORT_TIKA}
Restart=on-failure
User=root
StandardOutput=append:/var/log/tika/tika.log
StandardError=append:/var/log/tika/tika.err
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tika

echo
echo "[+] Tika running on http://127.0.0.1:${PORT_TIKA}"
echo "    Logs: /var/log/tika/"