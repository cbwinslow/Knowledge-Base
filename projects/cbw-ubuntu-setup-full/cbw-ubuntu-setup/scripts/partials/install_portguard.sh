#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
apt-get install -y python3-yaml lsof
install -d -m 0755 /usr/local/bin
install -m 0755 "$(dirname "$0")/../tools/cbw-portguard.py" /usr/local/bin/cbw-portguard
install -d -m 0755 /etc/cbw
[ -f /etc/cbw/ports.yaml ] || cp "$(dirname "$0")/../../configs/cbw/ports.yaml" /etc/cbw/ports.yaml
echo "[✓] Installed cbw-portguard. Use: sudo CBW_BASE=~/cbw-ubuntu-setup cbw-portguard"
