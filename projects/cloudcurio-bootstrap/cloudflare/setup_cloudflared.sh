#!/usr/bin/env bash
# cloudflare/setup_cloudflared.sh
# Sets up a locally-managed Cloudflare Tunnel and systemd service.
set -Eeuo pipefail
LOG="/tmp/CBW-cloudflared-setup.log"; exec > >(tee -a "$LOG") 2>&1

TUNNEL_NAME="${TUNNEL_NAME:-cloudcurio-core}"
CONFIG_DIR="/etc/cloudflared"
CONF="${CONFIG_DIR}/config.yaml"

mkdir -p "$CONFIG_DIR"

echo "Login to Cloudflare in a browser and authorize this machine:"
cloudflared tunnel login

# Create tunnel if not exists
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
  cloudflared tunnel create "$TUNNEL_NAME"
fi

# Write example routing config (edit as needed)
cat > "$CONF" <<'YAML'
tunnel: REPLACE_WITH_TUNNEL_ID
credentials-file: /etc/cloudflared/REPLACE_WITH_TUNNEL_ID.json

ingress:
  # Example subdomains under cloudcurio.cc
  - hostname: qdrant.cloudcurio.cc
    service: http://localhost:6333
  - hostname: neo4j.cloudcurio.cc
    service: http://localhost:7474
  - hostname: opensearch.cloudcurio.cc
    service: http://localhost:5601
  - hostname: grafana.cloudcurio.cc
    service: http://localhost:3000
  - hostname: portainer.cloudcurio.cc
    service: http://localhost:9443
  - hostname: webui.cloudcurio.cc
    service: http://localhost:8080
  - hostname: supabase.cloudcurio.cc
    service: http://localhost:8000
  - service: http_status:404
YAML

echo "Replace REPLACE_WITH_TUNNEL_ID in $CONF with the ID from 'cloudflared tunnel list'."
echo "Then enable the service:"
echo "  sudo cloudflared --config $CONF service install"
echo "  sudo systemctl enable --now cloudflared"
