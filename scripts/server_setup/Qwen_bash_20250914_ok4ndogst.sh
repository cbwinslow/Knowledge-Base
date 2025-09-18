#!/bin/bash

# Setup utility services like VPN, AdGuard, etc.
echo "Setting up utility services stack..."

mkdir -p /opt/utility/{adguard,openvpn,portainer,watchtower}

# Create docker-compose.yml for utility services
cat > /opt/utility/docker-compose.yml << EOF
version: "3.8"

services:
  adguard:
    image: adguard/adguardhome
    container_name: adguard
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
    ports:
      - 53:53/tcp
      - 53:53/udp
      - 67:67/udp
      - 80:80/tcp
      - 443:443/tcp
      - 853:853/tcp
      - 3000:3000/tcp
    restart: unless-stopped

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 3600 --cleanup
    restart: unless-stopped

  traefik:
    image: traefik:v2.9
    container_name: traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - 80:80
      - 443:443
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik:/etc/traefik
    restart: unless-stopped

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    volumes:
      - ./uptime-kuma:/app/data
    ports:
      - 3001:3001
    restart: unless-stopped
EOF

# Create Traefik config
mkdir -p /opt/utility/traefik
cat > /opt/utility/traefik/traefik.yml << EOF
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
EOF

# Start utility services
cd /opt/utility
docker-compose up -d

echo "Utility services stack setup completed."