#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
command -v pveversion >/dev/null || { echo "Not a Proxmox host"; exit 1; }
apt-get update -y || true
apt-get install -y curl ca-certificates gnupg lsb-release jq || true
