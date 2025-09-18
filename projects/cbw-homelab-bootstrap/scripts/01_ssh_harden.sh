#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-ssh.log"
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

echo "Hardening SSH..."
SSHD=/etc/ssh/sshd_config
do "cp $SSHD ${SSHD}.bak.$(date +%s)"
cat > /etc/ssh/sshd_config.d/99-cbw.conf <<'CFG'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
AllowTcpForwarding yes
X11Forwarding no
AllowAgentForwarding yes
LoginGraceTime 30
UseDNS no
CFG
do "systemctl reload ssh || systemctl restart ssh"
echo "SSH hardened (key-only). Ensure your key works before logout."
