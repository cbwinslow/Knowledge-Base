#!/usr/bin/env bash
set -euo pipefail
if [[ "${ENABLE_PVE_FIREWALL:-true}" == "true" ]]; then
  mkdir -p /etc/pve/firewall
  cat >/etc/pve/firewall/host.fw <<'EOF'
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
IN ACCEPT -p tcp -dport 22
IN ACCEPT -p tcp -dport 8006
IN ACCEPT -p icmp
EOF
  pve-firewall restart || true
fi
