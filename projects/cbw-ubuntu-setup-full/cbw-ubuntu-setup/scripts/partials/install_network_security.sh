#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
apt-get install -y openssh-server net-tools iproute2 iptables-persistent \
  nload iftop iptraf-ng htop glances lsof \
  fail2ban suricata goaccess

ufw default deny incoming || true
ufw default allow outgoing || true
for p in 22 80 443 3000 9090 3100 8000 8001 5601 5432 5433 6333 6334 27017 9200 9600 15672 19999 8080 9400 7474 7687 5050 8081 7475; do ufw allow ${p}/tcp || true; done
ufw --force enable || true

# Fail2ban
install -d -m 0755 /etc/fail2ban
cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
EOF
systemctl enable --now fail2ban

# Suricata (AF-PACKET)
systemctl stop suricata || true
cat >/etc/suricata/suricata.yaml <<'EOF'
vars:
  address-groups:
    HOME_NET: "[192.168.4.0/24]"
af-packet:
  - interface: any
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: /var/log/suricata/eve.json
      types: [alert, http, dns, tls, ssh, stats]
EOF
systemctl enable --now suricata

# GoAccess config
install -d -m 0755 /etc/goaccess
cat >/etc/goaccess/goaccess.conf <<'EOF'
time-format %T
date-format %d/%b/%Y
log-format COMBINED
real-time-html true
ws-url 127.0.0.1
port 7890
EOF
echo "[✓] Network tools & security ready."
