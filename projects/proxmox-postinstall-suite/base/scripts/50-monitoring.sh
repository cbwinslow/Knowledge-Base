#!/usr/bin/env bash
set -euo pipefail
[[ "${INSTALL_NETDATA:-false}" == "true" ]] && bash <(curl -Ss https://my-netdata.io/kickstart.sh) --stable-channel --disable-telemetry || true
[[ "${INSTALL_ZABBIX_AGENT:-false}" == "true" ]] && { apt-get update -y; apt-get install -y zabbix-agent; systemctl enable --now zabbix-agent || true; }
