#!/usr/bin/env bash
set -euo pipefail

LOG="/tmp/CBW-install.log"
exec > >(tee -a "$LOG") 2>&1

# Defaults (override by exporting before running)
export SERVER_IP="${SERVER_IP:-192.168.4.117}"
export HOSTNAME_NEW="${HOSTNAME_NEW:-cbwserver}"
export DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/cbwinslow/dotfiles}"
export SCRIPTS_REPO="${SCRIPTS_REPO:-https://github.com/cbwinslow/binfiles}"
export GITHUB_USER="${GITHUB_USER:-cbwinslow}"

echo "[*] Starting CBW Ubuntu setup on $(hostname) for ${SERVER_IP}"

# Require root
if [[ $EUID -ne 0 ]]; then
  echo "[!] Please run as root: sudo bash install.sh"
  exit 1
fi

apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release software-properties-common git unzip jq ufw

# Basic hostname (optional)
hostnamectl set-hostname "${HOSTNAME_NEW}" || true

# Networking tools & baseline security
bash ./partials/install_network_security.sh

# Docker & NVIDIA
bash ./partials/install_docker.sh
bash ./partials/install_nvidia.sh

# Python & uv
bash ./partials/install_python_uv.sh

# Databases (Postgres + pgvector, Qdrant, Mongo, OpenSearch, RabbitMQ)
bash ./partials/install_databases.sh

# Kong API Gateway
bash ./partials/install_kong.sh

# Monitoring stack (Prometheus/Grafana/Loki/Promtail, node_exporter, cAdvisor, DCGM exporter)
bash ./partials/install_monitoring.sh

# Netdata (optional)
bash ./partials/install_netdata.sh

# MCP servers (placeholders + repo clones you can add)
bash ./partials/install_mcp.sh

# Clone desired repos
bash ./partials/clone_repos.sh

echo "[✓] Base setup complete. Next steps:"
echo " - Compose up stacks: cd ../docker/compose && docker compose -f monitoring.yml up -d"
echo " - Access Grafana at http://$(hostname -I | awk '{print $1}'):3000 (admin / admin — change on first login)"
echo " - Kong admin at http://localhost:8001, Proxy at :8000 (see docker/compose/kong.yml)"
