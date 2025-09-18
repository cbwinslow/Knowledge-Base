#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/tmp/CBW-install-ollama.log"; exec > >(tee -a "$LOG") 2>&1
RED='\033[31m'; GREEN='\033[32m'; YEL='\033[33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }
require_root(){ if [[ $EUID -ne 0 ]]; then err "Run as root"; exit 1; fi; }

require_root
apt-get update -y && apt-get install -y curl
info "Installing Ollama (official script)"
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable --now ollama || true
ollama --version || true
echo "Docs: https://ollama.com/download"