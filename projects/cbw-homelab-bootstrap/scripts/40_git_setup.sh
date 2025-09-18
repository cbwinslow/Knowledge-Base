#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-git.log"
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

echo "Configuring global Git identity..."
GIT_NAME=${GIT_NAME:-cbwinslow}
GIT_EMAIL=${GIT_EMAIL:-blaine.winslow@gmail.com}
do "git config --system user.name "$GIT_NAME""
do "git config --system user.email "$GIT_EMAIL""
echo "Git set to: $(git config --system user.name) <$(git config --system user.email)>"
