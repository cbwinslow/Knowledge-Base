#!/usr/bin/env bash
# pigsty/install_pigsty.sh
set -Eeuo pipefail
LOG="/tmp/CBW-pigsty-install.log"; exec > >(tee -a "$LOG") 2>&1

# This follows the official docs at https://pigsty.io/docs/setup/install/
apt-get update -y
apt-get install -y curl wget gnupg lsb-release

# Quickstart: fetch installer
curl -fsSL https://raw.githubusercontent.com/Vonng/pigsty/master/bootstrap | bash -s -- mini

echo "Pigsty bootstrap launched. Consult docs for cluster layout & inventory customization."
echo "Docs: https://pigsty.io/docs/  | Install: https://pigsty.io/docs/setup/install/"
