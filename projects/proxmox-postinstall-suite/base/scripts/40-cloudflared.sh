#!/usr/bin/env bash
set -euo pipefail
[[ "${INSTALL_CLOUDFLARED:-false}" == "true" ]] || { echo "skip cloudflared"; exit 0; }
command -v cloudflared >/dev/null || { curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb; apt-get install -y /tmp/cloudflared.deb; }
[[ -n "${CLOUDFLARED_TOKEN:-}" ]] && cloudflared service install "${CLOUDFLARED_TOKEN}" || true
