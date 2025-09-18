#!/usr/bin/env bash
set -euo pipefail

if [[ "${INSTALL_NETDATA:-false}" == "true" ]]; then
  bash <(curl -Ss https://my-netdata.io/kickstart.sh) --stable-channel --disable-telemetry || true
  systemctl enable --now netdata || true
  echo "Netdata installed."
fi

if [[ "${INSTALL_ZABBIX_AGENT:-false}" == "true" ]]; then
  apt-get update -y
  apt-get install -y zabbix-agent
  systemctl enable --now zabbix-agent || true
  echo "Zabbix agent installed (edit /etc/zabbix/zabbix_agentd.conf as needed)."
fi
