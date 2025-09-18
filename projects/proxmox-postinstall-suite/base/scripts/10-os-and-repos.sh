#!/usr/bin/env bash
set -euo pipefail
ENTERPRISE_LIST="/etc/apt/sources.list.d/pve-enterprise.list"
[[ -f "$ENTERPRISE_LIST" ]] && sed -i 's/^\s*deb /# deb /' "$ENTERPRISE_LIST" || true

CODENAME="$(. /etc/os-release; echo "$VERSION_CODENAME")"
echo "deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-${CODENAME}.gpg -o /etc/apt/keyrings/proxmox-release-${CODENAME}.gpg || true

apt-get update -y
apt-get -y dist-upgrade
apt-get install -y ifupdown2
