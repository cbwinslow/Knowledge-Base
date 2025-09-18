#!/usr/bin/env bash
set -euo pipefail
ufw default deny incoming || true
ufw default allow outgoing || true
for p in 22 5050 8081 7475; do ufw allow ${p}/tcp || true; done
ufw --force enable || true
echo "[✓] UFW configured."
