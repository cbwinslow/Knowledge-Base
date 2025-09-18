#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-fail2ban.log"
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

echo "Installing & configuring Fail2ban..."
do "apt-get install -y fail2ban"
cat > /etc/fail2ban/jail.d/sshd.local <<'JAIL'
[sshd]
enabled = true
findtime = 10m
maxretry = 5
bantime = 1h
JAIL
do "systemctl enable --now fail2ban"
do "fail2ban-client status"
