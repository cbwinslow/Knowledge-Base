#!/usr/bin/env bash
set -euo pipefail

if [[ "${INSTALL_CLOUDFLARED:-false}" == "true" ]]; then
  if ! command -v cloudflared >/dev/null; then
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb
    apt-get install -y /tmp/cloudflared.deb
  fi

  if [[ -n "${CLOUDFLARED_TOKEN:-}" ]]; then
    # login & service creation
    cloudflared service install "${CLOUDFLARED_TOKEN}" || true
    systemctl enable --now cloudflared || true

    # Optional: route Proxmox UI
    if [[ "${CF_TUNNEL_PVE_HTTPS:-false}" == "true" ]]; then
      # Create a config if absent, with a route for :8006
      mkdir -p /etc/cloudflared
      cat >/etc/cloudflared/config.yml <<'EOF'
tunnel: default
credentials-file: /etc/cloudflared/default.json
ingress:
  - hostname: pve.example.com
    service: https://127.0.0.1:8006
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
      echo "NOTE: Update /etc/cloudflared/config.yml 'hostname:' to your domain, then: systemctl restart cloudflared"
    fi

    # Extra routes
    if [[ -n "${CF_TUNNEL_EXTRA_ROUTES:-}" ]]; then
      IFS=',' read -ra ROUTES <<< "${CF_TUNNEL_EXTRA_ROUTES}"
      echo "Define extra ingress in /etc/cloudflared/config.yml for: ${ROUTES[*]}"
    fi
  else
    echo "CLOUDFLARED_TOKEN not set; skipping service install."
  fi
else
  echo "Cloudflared install skipped."
fi
