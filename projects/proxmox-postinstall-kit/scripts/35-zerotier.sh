#!/usr/bin/env bash
set -euo pipefail

if [[ "${INSTALL_ZEROTIER:-false}" == "true" ]]; then
  if ! command -v zerotier-cli >/dev/null; then
    curl -s https://install.zerotier.com | bash || true
  fi
  systemctl enable --now zerotier-one || true
  if [[ -n "${ZT_NETWORK_ID:-}" ]]; then
    zerotier-cli join "$ZT_NETWORK_ID" || true
    echo "Joined ZeroTier network $ZT_NETWORK_ID"
  else
    echo "ZeroTier installed. Set ZT_NETWORK_ID in .env to join a network."
  fi
else
  echo "ZeroTier install skipped."
fi
