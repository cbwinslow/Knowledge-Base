#!/usr/bin/env bash
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PORT_NIFI=$( /usr/local/sbin/cbw-port-guard.sh reserve NIFI_HTTP 8089 | tail -n1 )
NV="1.27.0"; id -u nifi &>/dev/null || useradd -m -s /bin/bash nifi
cd /opt; wget -q "https://dlcdn.apache.org/nifi/${NV}/nifi-${NV}-bin.tar.gz" -O /tmp/nifi.tgz
tar -xzf /tmp/nifi.tgz -C /opt
ln -sfn /opt/nifi-${NV} /opt/nifi
chown -R nifi:nifi /opt/nifi /opt/nifi-${NV}
sed -i "s|^nifi.web.http.port=.*|nifi.web.http.port=${PORT_NIFI}|" /opt/nifi/conf/nifi.properties
sed -i 's|^nifi.web.http.host=.*|nifi.web.http.host=127.0.0.1|' /opt/nifi/conf/nifi.properties
cat >/etc/systemd/system/nifi.service <<'UNIT'
[Unit]
Description=Apache NiFi
After=network-online.target
[Service]
User=nifi
Type=forking
ExecStart=/opt/nifi/bin/nifi.sh start
ExecStop=/opt/nifi/bin/nifi.sh stop
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload; systemctl enable --now nifi
echo "[+] NiFi on http://127.0.0.1:${PORT_NIFI}/"
