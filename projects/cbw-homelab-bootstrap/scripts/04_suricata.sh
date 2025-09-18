#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-suricata.log"
exec > >(tee -a "$LOG") 2>&1

DRY_RUN=${DRY_RUN:-false}
VERBOSE=${CBW_VERBOSE:-false}

do() {
  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

echo "Installing Suricata (IDS)..."
do "apt-get install -y suricata"
# Basic config tweak (promiscuous off by default in many installs)
sed -i 's/^ *- interface: .*/  - interface: eth0/' /etc/suricata/suricata.yaml || true
do "systemctl enable --now suricata"
do "systemctl status suricata --no-pager || true"
