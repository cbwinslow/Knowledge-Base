#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/tmp/CBW-install-localrecall.log"; exec > >(tee -a "$LOG") 2>&1
RED='\033[31m'; GREEN='\033[32m'; YEL='\033[33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }
require_root(){ if [[ $EUID -ne 0 ]]; then err "Run as root"; exit 1; fi; }

require_root
apt-get update -y && apt-get install -y build-essential git curl
# Go
if ! command -v go >/dev/null 2>&1; then
  GO_VER="1.22.5"
  ARCH="$(dpkg --print-architecture)"
  curl -L "https://go.dev/dl/go${GO_VER}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
  rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz
  echo 'export PATH=/usr/local/go/bin:$PATH' >/etc/profile.d/go.sh
  export PATH=/usr/local/go/bin:$PATH
fi
# Build LocalRecall
if [ ! -d /opt/localrecall ]; then
  git clone https://github.com/mudler/LocalRecall.git /opt/localrecall
fi
cd /opt/localrecall
make build || go build -o localrecall ./cmd/localrecall || true
install -m 0755 ./localrecall /usr/local/bin/localrecall || true
# systemd
cat >/etc/systemd/system/localrecall.service <<'UNIT'
[Unit]
Description=LocalRecall API
After=network-online.target

[Service]
ExecStart=/usr/local/bin/localrecall serve --data /var/lib/localrecall
Restart=on-failure
User=root
WorkingDirectory=/var/lib/localrecall

[Install]
WantedBy=multi-user.target
UNIT
mkdir -p /var/lib/localrecall
systemctl daemon-reload
systemctl enable --now localrecall
echo "Docs: https://github.com/mudler/LocalRecall"