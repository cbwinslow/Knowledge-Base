#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-prereqs.log"
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

echo "Updating apt and installing base packages..."
do "apt-get update -y"
do "apt-get install -y ca-certificates curl gnupg lsb-release jq git ufw unzip software-properties-common"

# Ensure .env exists
if [ ! -f .env ] && [ -f .env.example ]; then
  echo "No .env found, copying .env.example -> .env"
  do "cp .env.example .env"
fi

# Create data root
DATA_ROOT=$(grep '^DATA_ROOT=' .env | cut -d= -f2- || echo "/opt/cbw")
DATA_ROOT=${DATA_ROOT:-/opt/cbw}
do "mkdir -p $DATA_ROOT"
echo "DATA_ROOT=$DATA_ROOT"
