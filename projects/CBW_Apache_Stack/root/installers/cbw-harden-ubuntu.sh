#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-harden-ubuntu.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Baseline hardening: SSH, UFW, fail2ban, unattended, sysctl, auditd.
#===============================================================================
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
apt update && apt install -y ufw fail2ban unattended-upgrades auditd needrestart
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload ssh || systemctl restart ssh
ufw default deny incoming; ufw default allow outgoing; ufw allow OpenSSH; yes | ufw enable
cat >/etc/fail2ban/jail.d/cbw-sshd.conf <<JAIL
[sshd]
enabled = true
bantime = 30m
findtime = 10m
maxretry = 5
JAIL
systemctl restart fail2ban
cat >/etc/sysctl.d/99-cbw.conf <<SYS
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
kernel.randomize_va_space=2
SYS
sysctl --system
chmod 640 /etc/cbw-ports.conf 2>/dev/null || true
chmod 600 /etc/cbw-secrets.env 2>/dev/null || true
echo "[+] Hardening applied."
