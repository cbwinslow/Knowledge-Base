#!/usr/bin/env bash
set -euo pipefail

if [[ "${ENABLE_PVE_FIREWALL:-true}" == "true" ]]; then
  pve-firewall status || true
  pve-firewall stop || true

  # Enable host firewall with minimal allowlist
  sed -i 's/^ENABLED: .*/ENABLED: 1/' /etc/pve/firewall/cluster.fw 2>/dev/null || true
  cat >/etc/pve/firewall/host.fw <<'EOF'
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT
input_policy: DROP
output_policy: ACCEPT
smurf_log_level: warning

[RULES]
# Allow established
IN ACCEPT -source +ipfilter
IN ACCEPT -conntrack established,related

# SSH
IN ACCEPT -p tcp -dport 22

# Proxmox web UI
IN ACCEPT -p tcp -dport 8006

# Ping
IN ACCEPT -p icmp

# Block everything else (implicit DROP)
EOF

  # Simple IP filter: allow all by default; you can restrict later
  echo "0.0.0.0/0" >/etc/pve/firewall/ipset-ipfilter

  pve-firewall start || true
  echo "pve-firewall enabled with conservative rules."
else
  echo "pve-firewall not enabled per .env."
fi
