#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y openssh-server net-tools iproute2 iptables-persistent \
  nload iftop iptraf-ng htop glances \
  fail2ban suricata goaccess

# Optional ntopng (commented due to community repo size)
# apt-get install -y ntopng

# UFW baseline
ufw default deny incoming || true
ufw default allow outgoing || true
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 3000/tcp || true      # Grafana
ufw allow 9090/tcp || true      # Prometheus
ufw allow 3100/tcp || true      # Loki
ufw allow 8000:8001/tcp || true # Kong
ufw --force enable || true

# Fail2ban baseline
install -d -m 0755 /etc/fail2ban
cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd
destemail = root@localhost
action = %(action_mw)s

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
EOF

systemctl enable --now fail2ban

# Suricata baseline in IDS (AF-PACKET) mode
systemctl stop suricata || true
cat >/etc/suricata/suricata.yaml <<'EOF'
# Minimal Suricata config (AF-PACKET)
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

# GoAccess sample config (for Nginx logs by default path)
install -d -m 0755 /etc/goaccess
cat >/etc/goaccess/goaccess.conf <<'EOF'
time-format %T
date-format %d/%b/%Y
log-format COMBINED
real-time-html true
ws-url 127.0.0.1
port 7890
EOF

echo "[✓] Network tools & security installed (SSH, Fail2ban, Suricata, GoAccess, UFW)."
