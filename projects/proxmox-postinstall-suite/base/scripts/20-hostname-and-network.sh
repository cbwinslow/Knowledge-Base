#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOSTNAME:-}" ]] && { hn="$HOSTNAME"; [[ -n "${DOMAIN:-}" ]] && hn="$HOSTNAME.$DOMAIN"; hostnamectl set-hostname "$hn"; echo "Hostname -> $hn"; }
if [[ -n "${STATIC_IP:-}" && -n "${GATEWAY_IP:-}" ]]; then
  [[ -f /etc/network/interfaces ]] && cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%s)
  NIC="$(ip -o link show | awk -F': ' '/^[0-9]+: e/{print $2; exit}')"; [[ -z "$NIC" ]] && NIC="eno1"
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
fi
