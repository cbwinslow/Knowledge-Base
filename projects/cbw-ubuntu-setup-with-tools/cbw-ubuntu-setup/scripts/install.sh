#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release git ufw docker.io docker-compose-plugin python3-yaml lsof
bash ./partials/install_network_security.sh
bash ./partials/install_portguard.sh
echo "[✓] Minimal tools installed. See README to start UIs."
