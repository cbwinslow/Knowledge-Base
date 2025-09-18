#!/bin/bash

# Enhanced SSH Hardening Script
echo "Hardening SSH configuration..."

# Install fail2ban if not present
apt install -y fail2ban

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Create enhanced SSH configuration
cat > /etc/ssh/sshd_config << EOF
# SSH Hardening Configuration

# Basic Settings
Port 22
Protocol 2
AddressFamily inet
ListenAddress 0.0.0.0

# Security Settings
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Authentication Settings
LoginGraceTime 60
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility AUTH
LogLevel INFO

# Ciphers and Algorithms
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa

# Additional Security
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
UseLogin no
UsePrivilegeSeparation yes
PermitUserEnvironment no
Compression delayed
GatewayPorts no

# Allow specific users (customize as needed)
AllowUsers $(logname) root@192.168.1.* root@10.*

# Banner
Banner /etc/ssh/banner
EOF

# Create SSH banner
cat > /etc/ssh/banner << EOF

***************************************************************************
*                                                                         *
*                   UNAUTHORIZED ACCESS IS PROHIBITED                     *
*                                                                         *
*  This system is for authorized users only. All activities are logged    *
*  and monitored. Unauthorized access will be prosecuted to the fullest   *
*  extent of the law.                                                     *
*                                                                         *
***************************************************************************

EOF

# Generate new SSH host keys with stronger encryption
rm -f /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Configure fail2ban for SSH
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
ignoreip = 127.0.0.1/8 192.168.1.0/24

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2
bantime = 3600
findtime = 600
EOF

# Create SSH key for current user if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
fi

# Set proper permissions
chmod 600 /etc/ssh/sshd_config
chmod 644 /etc/ssh/banner

# Restart SSH service
systemctl restart ssh

# Restart fail2ban
systemctl restart fail2ban

echo "SSH hardening completed."