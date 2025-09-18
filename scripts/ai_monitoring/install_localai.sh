#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/tmp/CBW-install-localai.log"; exec > >(tee -a "$LOG") 2>&1
RED='\033[31m'; GREEN='\033[32m'; YEL='\033[33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }
require_root(){ if [[ $EUID -ne 0 ]]; then err "Run as root"; exit 1; fi; }

require_root
apt-get update -y && apt-get install -y build-essential git wget curl unzip
# Install Go if not present
if ! command -v go >/dev/null 2>&1; then
  GO_VER="1.22.5"
  ARCH="$(dpkg --print-architecture)"
  curl -L "https://go.dev/dl/go${GO_VER}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
  rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz
  echo 'export PATH=/usr/local/go/bin:$PATH' >/etc/profile.d/go.sh
  export PATH=/usr/local/go/bin:$PATH
fi
# Build LocalAI
if [ ! -d /opt/localai ]; then
  git clone https://github.com/mudler/LocalAI.git /opt/localai
fi
cd /opt/localai
make build
install -m 0755 ./local-ai /usr/local/bin/local-ai
# systemd unit
cat >/etc/systemd/system/localai.service <<'UNIT'
[Unit]
Description=LocalAI Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/local-ai run
Restart=on-failure
User=root
WorkingDirectory=/root
Environment=LOCALAI_HOME=/var/lib/localai

[Install]
WantedBy=multi-user.target
UNIT
mkdir -p /var/lib/localai
systemctl daemon-reload
systemctl enable --now localai
echo "Docs: https://localai.io/basics/getting_started/"