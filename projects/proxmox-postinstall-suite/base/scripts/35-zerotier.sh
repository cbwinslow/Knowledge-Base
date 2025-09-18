#!/usr/bin/env bash
set -euo pipefail
[[ "${INSTALL_ZEROTIER:-false}" == "true" ]] || { echo "skip zerotier"; exit 0; }
command -v zerotier-cli >/dev/null || curl -s https://install.zerotier.com | bash
systemctl enable --now zerotier-one || true
[[ -n "${ZT_NETWORK_ID:-}" ]] && zerotier-cli join "$ZT_NETWORK_ID" || true
