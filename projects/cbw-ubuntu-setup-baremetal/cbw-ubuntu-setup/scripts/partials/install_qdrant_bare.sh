#!/usr/bin/env bash
set -euo pipefail

echo "[*] Installing Qdrant (APT)"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://qdrant.github.io/qdrant-ppa/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/qdrant.gpg
echo "deb [signed-by=/etc/apt/keyrings/qdrant.gpg] https://qdrant.github.io/qdrant-ppa/ $(. /etc/os-release && echo $VERSION_CODENAME) main" > /etc/apt/sources.list.d/qdrant.list

apt-get update -y
apt-get install -y qdrant

systemctl enable --now qdrant
echo "[✓] Qdrant running on :6333 (HTTP) and :6334 (gRPC)."
