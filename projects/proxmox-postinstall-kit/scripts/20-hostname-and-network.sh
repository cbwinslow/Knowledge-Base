#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${HOSTNAME:-}"
DOMAIN="${DOMAIN:-}"

if [[ -n "${HOSTNAME}" ]]; then
  fqdn="$HOSTNAME"
  if [[ -n "${DOMAIN}" ]]; then
    fqdn="$HOSTNAME.$DOMAIN"
  fi
  hostnamectl set-hostname "$fqdn"
  echo "Hostname set to $fqdn"
fi

# Static network (optional)
if [[ -n "${STATIC_IP:-}" && -n "${GATEWAY_IP:-}" ]]; then
  # Back up current interfaces file if exists
  if [[ -f /etc/network/interfaces ]]; then
    cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%s)
  fi

  # Guess primary NIC
  NIC="$(ip -o link show | awk -F': ' '/^[0-9]+: e/{print $2; exit}')"
  [[ -z "$NIC" ]] && NIC="eno1"

  cat >/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $NIC
iface $NIC inet static
    address ${STATIC_IP}
    gateway ${GATEWAY_IP}
    dns-nameservers ${DNS_SERVERS:-1.1.1.1 9.9.9.9}
EOF

  systemctl restart networking || true
  echo "Static network configured on $NIC -> $STATIC_IP"
else
  echo "Keeping current networking (DHCP)."
fi
