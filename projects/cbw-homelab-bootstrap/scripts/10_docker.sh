#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-docker.log"
exec > >(tee -a "$LOG") 2>&1

DRY_RUN=${DRY_RUN:-false}
VERBOSE=${CBW_VERBOSE:-false}

do() {
  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

echo "Installing Docker Engine..."
if ! command -v docker >/dev/null 2>&1; then
  do "install -m 0755 -d /etc/apt/keyrings"
  do "curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo $ID)/gpg -o /etc/apt/keyrings/docker.gpg"
  do "chmod a+r /etc/apt/keyrings/docker.gpg"
  echo     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo $ID)     $(. /etc/os-release; echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  do "apt-get update -y"
  do "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
fi
do "systemctl enable --now docker"
usermod -aG docker ${SUDO_USER:-$USER} || true
