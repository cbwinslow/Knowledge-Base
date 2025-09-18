#!/usr/bin/env bash
# cloudcurio-bootstrap.sh
# Purpose: Prepare Ubuntu for self-hosting: base hardening, Docker, optional NVIDIA, cloudflared.
set -Eeuo pipefail

LOG="/tmp/CBW-cloudcurio-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1

# ---------- Helpers ----------
RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m'); YEL=$(printf '\033[33m'); NC=$(printf '\033[0m')
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }
die(){ err "$*"; exit 1; }

DRY_RUN=0
VERBOSE=0
INSTALL_GPU=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ; set -x ;;
    --gpu) INSTALL_GPU=1 ;;
    *) warn "Unknown arg: $arg";;
  esac
done

run(){ if [[ $DRY_RUN -eq 1 ]]; then echo "[dry-run] $*"; else eval "$@"; fi; }

require_root(){
  if [[ $EUID -ne 0 ]]; then die "Run as root (sudo)."; fi
}

check_cmd(){ command -v "$1" >/dev/null 2>&1; }

# ---------- Preflight ----------
require_root
info "Updating APT and installing essentials"
run "apt-get update -y"
run "apt-get install -y curl wget ca-certificates gnupg lsb-release apt-transport-https jq ufw git net-tools dnsutils unzip htop tmux"

# ---------- UFW sane defaults ----------
info "Configuring basic UFW rules (allow SSH; deny inbound by default)"
if check_cmd ufw; then
  run "ufw allow OpenSSH || true"
  run "ufw --force enable || true"
fi

# ---------- Docker Engine + Compose plugin ----------
if ! check_cmd docker; then
  info "Installing Docker Engine (official repo)"
  run "install -m 0755 -d /etc/apt/keyrings"
  run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
  run "chmod a+r /etc/apt/keyrings/docker.gpg"
  UB_CODENAME=$( . /etc/os-release && echo ${VERSION_CODENAME} )
  run "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UB_CODENAME} stable\" > /etc/apt/sources.list.d/docker.list"
  run "apt-get update -y"
  run "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  run "systemctl enable --now docker"
else
  info "Docker already installed; ensuring compose plugin is present"
  run "apt-get install -y docker-compose-plugin || true"
fi

# Allow current user to use docker without sudo
if id -nG "${SUDO_USER:-$USER}" | grep -qw docker; then
  info "User already in docker group"
else
  info "Adding ${SUDO_USER:-$USER} to docker group"
  run "usermod -aG docker ${SUDO_USER:-$USER} || true"
fi

# ---------- Optional: NVIDIA Container Toolkit ----------
if [[ $INSTALL_GPU -eq 1 ]]; then
  info "Installing NVIDIA Container Toolkit"
  run "distribution=$(. /etc/os-release;echo $ID$VERSION_ID)"
  run "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
  run "curl -fsSL https://nvidia.github.io/libnvidia-container/experimental/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://' > /etc/apt/sources.list.d/nvidia-container-toolkit.list"
  run "apt-get update -y"
  run "apt-get install -y nvidia-container-toolkit"
  run "nvidia-ctk runtime configure --runtime=docker || true"
  run "systemctl restart docker || true"
fi

# ---------- Cloudflared (Cloudflare Tunnel) ----------
info "Installing cloudflared (Cloudflare Tunnel client)"
if ! check_cmd cloudflared; then
  run "curl -fsSL https://pkg.cloudflare.com/gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg"
  run "echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/ $(lsb_release -cs) main' > /etc/apt/sources.list.d/cloudflare-main.list"
  run "apt-get update -y"
  run "apt-get install -y cloudflared"
fi

info "Bootstrap complete."
echo
echo "Next:"
echo " 1) Configure Cloudflare Tunnel: sudo ./cloudflare/setup_cloudflared.sh"
echo " 2) Bare-metal Postgres with Pigsty: sudo ./pigsty/install_pigsty.sh"
echo " 3) Or self-host Supabase: ./supabase/up.sh"
echo " 4) Bring up stacks under ./stacks/<name>: docker compose up -d"
