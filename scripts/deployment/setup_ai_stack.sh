#!/usr/bin/env bash
# setup_ai_stack.sh - Comprehensive AI Stack Setup
set -Eeuo pipefail

LOG="/tmp/CBW-ai-stack-setup.log"; exec > >(tee -a "$LOG") 2>&1

RED='\033[31m'; GREEN='\033[32m'; YEL='\033[33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }
die(){ err "$*"; exit 1; }

require_root(){
  if [[ $EUID -ne 0 ]]; then 
    err "This script must be run as root or with sudo"
    exit 1
  fi
}

check_cmd(){ command -v "$1" >/dev/null 2>&1; }

# Check if we're running as root
require_root

# Check for port conflicts
info "Checking for port conflicts..."
if ! ./check_ports.sh; then
  err "Port conflicts detected. Please resolve before continuing."
  exit 1
fi

# Run the cloudcurio bootstrap
info "Setting up base system..."
./cloudcurio-bootstrap.sh

# Install core AI components
info "Installing core AI components..."
./baremetal/install_ollama.sh
./baremetal/install_localai.sh
./baremetal/install_localrecall.sh

# Install databases
info "Installing databases..."
./baremetal/install_redis.sh
./baremetal/install_falkordb.sh

# Install monitoring
info "Installing monitoring tools..."
./baremetal/install_graphite.sh

# Install identity management
info "Installing identity management..."
./baremetal/install_keycloak.sh

# Install storage
info "Installing object storage..."
./baremetal/install_minio.sh

# Install database management tools
info "Installing database management tools..."
./baremetal/install_pgadmin.sh
./baremetal/install_adminer.sh

# Install web servers
info "Installing web servers..."
./baremetal/install_nginx.sh
./baremetal/install_caddy.sh

info "AI Stack setup complete!"
echo
echo "Next steps:"
echo "1. Configure Cloudflare Tunnel: sudo ./cloudflare/setup_cloudflared.sh"
echo "2. Set up your database:"
echo "   - Bare-metal Postgres with Pigsty: sudo ./pigsty/install_pigsty.sh"
echo "   - Or self-host Supabase: ./supabase/up.sh"
echo "3. Enable pgvector extension: ./db/enable_pgvector.sh your_database_name"
echo "4. Check service status with: systemctl status servicename"