#!/bin/bash

# System hardening script for Proxmox
echo "Starting system hardening..."

# Update system
apt update && apt upgrade -y

# Install security tools
apt install -y fail2ban unattended-upgrades aide

# Configure unattended upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "Debian stable";
    "Proxmox pve-no-subscription";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Configure fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Secure SSH
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers root@192.168.1.*" >> /etc/ssh/sshd_config
systemctl restart ssh

# Enable firewall
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 8006 -j ACCEPT
iptables -A INPUT -p tcp --dport 5900:5999 -j ACCEPT
iptables-save > /etc/iptables/rules.v4

echo "Hardening completed."