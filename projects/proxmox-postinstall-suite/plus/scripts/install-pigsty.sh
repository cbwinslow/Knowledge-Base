#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-}"; [[ -n "$TARGET" ]] || { echo "Usage: $0 <host>"; exit 1; }
ssh root@"$TARGET" bash -s <<'R'
set -euo pipefail
apt-get update -y || true
apt-get install -y curl sudo || true
curl -fsSL https://get.pigsty.io | bash || true
R
echo "Pigsty bootstrap invoked on $TARGET"
