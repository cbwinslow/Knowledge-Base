#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-install.log"
exec > >(tee -a "$LOG") 2>&1

export SERVER_IP="${SERVER_IP:-192.168.4.117}"
export HOSTNAME_NEW="${HOSTNAME_NEW:-cbwserver}"
export DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/cbwinslow/dotfiles}"
export SCRIPTS_REPO="${SCRIPTS_REPO:-https://github.com/cbwinslow/binfiles}"
export GITHUB_USER="${GITHUB_USER:-cbwinslow}"

if [[ $EUID -ne 0 ]]; then
  echo "[!] Run as root: sudo bash install.sh"; exit 1; fi

apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release software-properties-common git unzip jq ufw

hostnamectl set-hostname "${HOSTNAME_NEW}" || true

bash ./partials/install_network_security.sh
bash ./partials/install_docker.sh
bash ./partials/install_nvidia.sh
bash ./partials/install_python_uv.sh

# Bare-metal databases
bash ./partials/install_postgres_pgvector_bare.sh
bash ./partials/install_qdrant_bare.sh
bash ./partials/install_mongodb_bare.sh
bash ./partials/install_opensearch_bare.sh
bash ./partials/install_rabbitmq_bare.sh
bash ./partials/install_neo4j_bare.sh

# Dashboards / Monitoring
bash ./partials/install_opensearch_dashboards_bare.sh
bash ./partials/install_monitoring.sh
bash ./partials/install_netdata.sh

# Kong
bash ./partials/install_kong.sh

# Port conflict manager
bash ./partials/install_portguard.sh

# MCP + repos
bash ./partials/install_mcp.sh
bash ./partials/clone_repos.sh

echo "[✓] Base setup complete."
echo "Start Supabase and tools when ready — see README."
