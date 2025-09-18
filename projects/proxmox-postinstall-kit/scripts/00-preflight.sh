#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root." >&2
  exit 1
fi

command -v pveversion >/dev/null || {
  echo "This host does not appear to be Proxmox VE." >&2
  exit 1
}

echo "Hostname: $(hostname)"
echo "Proxmox version: $(pveversion)"
echo "Kernel: $(uname -r)"
echo "Disk usage:"
df -h /

# ensure basic tools
apt-get update -y || true
apt-get install -y curl ca-certificates gnupg lsb-release jq || true
