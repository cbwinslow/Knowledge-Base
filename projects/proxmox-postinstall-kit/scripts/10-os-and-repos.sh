#!/usr/bin/env bash
set -euo pipefail

# Disable enterprise repo; enable no-subscription repo
ENTERPRISE_LIST="/etc/apt/sources.list.d/pve-enterprise.list"
NO_SUBS_LIST="/etc/apt/sources.list.d/pve-no-subscription.list"

if [[ -f "$ENTERPRISE_LIST" ]]; then
  sed -i 's/^\s*deb /# deb /' "$ENTERPRISE_LIST" || true
  echo "Commented out enterprise repo."
fi

CODENAME="$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 || true)"
if [[ -z "${CODENAME:-}" ]]; then CODENAME="$(. /etc/os-release; echo "$VERSION_CODENAME")"; fi
if [[ -z "${CODENAME:-}" ]]; then CODENAME="bookworm"; fi

cat > "$NO_SUBS_LIST" <<EOF
deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription
EOF

# Clean up possible broken keys (sqv errors) by switching to signed-by keyring best practice
install -d -m 0755 /etc/apt/keyrings

# Proxmox key (should already be present but ensure)
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-${CODENAME}.gpg -o /etc/apt/keyrings/proxmox-release-${CODENAME}.gpg || true

# Grafana OSS repo (optional example hardened; not installed by default here)
# echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
# curl -fsSL https://packages.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

apt-get update -y
apt-get -y dist-upgrade
apt-get install -y ifupdown2
echo "Repos configured and system upgraded."
