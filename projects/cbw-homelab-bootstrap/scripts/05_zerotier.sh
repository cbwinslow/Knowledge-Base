#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-zerotier.log"
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

ZTC_JOIN=$(grep '^ZTC_JOIN=' .env | cut -d= -f2- || echo "false")
NET_ID=$(grep '^ZTC_NETWORK_ID=' .env | cut -d= -f2- || true)
echo "Installing ZeroTier One..."
if ! command -v zerotier-cli >/dev/null 2>&1; then
  do "curl -s https://install.zerotier.com | bash"
fi
do "systemctl enable --now zerotier-one"

if [ "${ZTC_JOIN}" = "true" ] && [ -n "${NET_ID:-}" ]; then
  echo "Joining ZeroTier network ${NET_ID}"
  do "zerotier-cli join ${NET_ID} || true"
  do "zerotier-cli listnetworks || true"
else
  echo "Skipping network join; set ZTC_JOIN=true and ZTC_NETWORK_ID in .env to enable."
fi
