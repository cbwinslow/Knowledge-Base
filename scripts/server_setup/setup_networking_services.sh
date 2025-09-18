#!/bin/bash

# Server Networking and Services Setup Script
# This script installs and configures essential networking tools and services

echo "=== Ubuntu Server Networking and Services Setup ==="
echo ""

# Create documentation files
DOCS_DIR="/home/cbwinslow/server_setup/docs"
mkdir -p $DOCS_DIR

echo "Creating documentation files..."
{
    echo "# Server Networking and Services Setup"
    echo ""
    echo "Date: $(date)"
    echo "User: $(whoami)"
    echo ""
    echo "## Setup Process Log"
    echo ""
} > $DOCS_DIR/setup_process.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/setup_process.md
}

# 1. Update package list
log_action "Updating package list..."
sudo apt update

# 2. Install essential networking tools
log_action "Installing essential networking tools..."
sudo apt install -y \
    curl \
    wget \
    net-tools \
    iputils-ping \
    dnsutils \
    iptables \
    ufw

# 3. Install proxy server (squid)
log_action "Installing Squid proxy server..."
sudo apt install -y squid

# 4. Install ZeroTier
log_action "Installing ZeroTier..."
curl -s https://install.zerotier.com | sudo bash

# 5. Install WireGuard
log_action "Installing WireGuard..."
sudo apt install -y wireguard

# 6. Install additional useful tools
log_action "Installing additional tools..."
sudo apt install -y \
    htop \
    vim \
    git \
    tmux \
    jq \
    rsync

# 7. Configure Squid proxy
log_action "Configuring Squid proxy..."
SQUID_CONFIG="/etc/squid/squid.conf"

# Backup original config
sudo cp $SQUID_CONFIG $SQUID_CONFIG.backup

# Create a basic squid configuration
sudo bash -c "cat > $SQUID_CONFIG" << 'EOL'
# Basic Squid Configuration
http_port 3128
visible_hostname $(hostname)

# ACL for localhost
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

# ACL for localhost
acl localhost src 127.0.0.1/32 ::1/128

# Safe ports
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http

# Block dangerous ports
acl SSL_ports port 443
acl CONNECT method CONNECT

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
http_access deny to_localhost

# Allow local network
http_access allow localnet
http_access allow localhost

# And finally deny all other access to this proxy
http_access deny all

# Squid normally listens to port 3128
http_port 3128

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

# Refresh patterns
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
EOL

# Restart squid service
log_action "Restarting Squid service..."
sudo systemctl restart squid
sudo systemctl enable squid

# 8. Configure SSH for better access
log_action "Configuring SSH..."
SSH_CONFIG="/etc/ssh/sshd_config"

# Backup original config
sudo cp $SSH_CONFIG $SSH_CONFIG.backup

# Configure SSH with additional options
sudo sed -i 's/#Port 22/Port 22/' $SSH_CONFIG
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' $SSH_CONFIG
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' $SSH_CONFIG

# Add additional security settings
sudo bash -c "cat >> $SSH_CONFIG" << 'EOL'

# Additional security settings
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
AllowTcpForwarding yes
X11Forwarding no
EOL

# Restart SSH service
log_action "Restarting SSH service..."
sudo systemctl restart ssh

# 9. Configure firewall
log_action "Configuring firewall..."
# Enable UFW
echo "y" | sudo ufw enable

# Allow SSH
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow Squid proxy
sudo ufw allow 3128/tcp

# Allow ZeroTier (UDP)
sudo ufw allow 9993/udp

# Allow WireGuard (UDP)
sudo ufw allow 51820/udp

# Allow common web ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 10. Create documentation for services
log_action "Creating service documentation..."
{
    echo ""
    echo "## Installed Services and Configurations"
    echo ""
    echo "### Proxy Server (Squid)"
    echo "- Port: 3128"
    echo "- Configuration: /etc/squid/squid.conf"
    echo "- Service management: systemctl {start|stop|restart|status} squid"
    echo ""
    echo "### ZeroTier"
    echo "- Command line tool: zerotier-cli"
    echo "- Join a network: zerotier-cli join <network_id>"
    echo "- Service management: systemctl {start|stop|restart|status} zerotier-one"
    echo ""
    echo "### WireGuard"
    echo "- Configuration directory: /etc/wireguard/"
    echo "- Command line tool: wg"
    echo "- Service management: systemctl {start|stop|restart|status} wg-quick@<interface>"
    echo ""
    echo "### SSH Configuration"
    echo "- Port: 22"
    echo "- Key-based authentication required"
    echo "- Password authentication disabled"
    echo "- Configuration: /etc/ssh/sshd_config"
    echo ""
    echo "### Firewall (UFW)"
    echo "- Status: $(sudo ufw status verbose | head -1)"
    echo "- Open ports:"
    echo "  - 22/tcp (SSH)"
    echo "  - 80/tcp (HTTP)"
    echo "  - 443/tcp (HTTPS)"
    echo "  - 3128/tcp (Squid Proxy)"
    echo "  - 9993/udp (ZeroTier)"
    echo "  - 51820/udp (WireGuard)"
} >> $DOCS_DIR/setup_process.md

# 11. Create Ansible inventory and configuration
log_action "Setting up Ansible configuration..."
mkdir -p /home/cbwinslow/ansible
cat > /home/cbwinslow/ansible/inventory << 'EOL'
[local]
localhost ansible_connection=local

[servers]
localhost ansible_host=127.0.0.1
EOL

cat > /home/cbwinslow/ansible/ansible.cfg << 'EOL'
[defaults]
inventory = ./inventory
host_key_checking = False
EOL

# 12. Create a basic Ansible playbook for testing
cat > /home/cbwinslow/ansible/test-playbook.yml << 'EOL'
---
- name: Test playbook to verify Ansible setup
  hosts: localhost
  become: yes
  tasks:
    - name: Ensure required packages are installed
      apt:
        name:
          - curl
          - wget
        state: present
        update_cache: yes

    - name: Check if services are running
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - ssh
        - squid
        - zerotier-one
EOL

# 13. Create documentation for essential services to install
{
    echo ""
    echo "## Essential Services to Install First"
    echo ""
    echo "1. Docker - Containerization platform"
    echo "2. Docker Compose - Multi-container management"
    echo "3. Nginx - Web server and reverse proxy"
    echo "4. Certbot - SSL certificate management"
    echo "5. Node.js - JavaScript runtime"
    echo "6. Python3-pip - Python package manager"
    echo "7. fail2ban - Intrusion prevention"
    echo "8. logrotate - Log file management"
    echo ""
    echo "## Installation Commands"
    echo ""
    echo "```bash"
    echo "# Docker"
    echo "sudo apt install -y docker.io"
    echo "sudo systemctl enable docker"
    echo "sudo usermod -aG docker $(whoami)"
    echo ""
    echo "# Docker Compose"
    echo "sudo apt install -y docker-compose"
    echo ""
    echo "# Nginx"
    echo "sudo apt install -y nginx"
    echo "sudo systemctl enable nginx"
    echo ""
    echo "# Certbot"
    echo "sudo apt install -y certbot python3-certbot-nginx"
    echo ""
    echo "# Node.js"
    echo "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
    echo "sudo apt install -y nodejs"
    echo ""
    echo "# Python3-pip"
    echo "sudo apt install -y python3-pip"
    echo ""
    echo "# fail2ban"
    echo "sudo apt install -y fail2ban"
    echo "sudo systemctl enable fail2ban"
    echo ""
    echo "# logrotate"
    echo "sudo apt install -y logrotate"
    echo "sudo systemctl enable logrotate"
    echo "```"
} >> $DOCS_DIR/setup_process.md

# 14. Final summary
{
    echo ""
    echo "## Setup Complete"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "### Next Steps"
    echo "1. Verify services are running properly"
    echo "2. Configure ZeroTier network (join your network)"
    echo "3. Set up WireGuard configuration if needed"
    echo "4. Test proxy server functionality"
    echo "5. Install additional essential services as needed"
    echo "6. Review security settings and adjust as necessary"
    echo ""
    echo "### Important Notes"
    echo "- SSH is now configured for key-based authentication only"
    echo "- Password authentication has been disabled"
    echo "- Firewall is enabled with essential ports open"
    echo "- Proxy server is running on port 3128"
    echo "- ZeroTier and WireGuard are installed but not configured"
    echo ""
    echo "### Verification Commands"
    echo ""
    echo "```bash"
    echo "# Check service status"
    echo "systemctl status ssh squid zerotier-one"
    echo ""
    echo "# Check firewall status"
    echo "sudo ufw status"
    echo ""
    echo "# Test proxy"
    echo "curl -x http://localhost:3128 http://google.com"
    echo ""
    echo "# Test Ansible"
    echo "cd /home/cbwinslow/ansible"
    echo "ansible-playbook test-playbook.yml"
    echo "```"
} >> $DOCS_DIR/setup_process.md

log_action "Setup complete!"
echo ""
echo "=== Setup Complete ==="
echo "Documentation has been created in $DOCS_DIR/setup_process.md"
echo "Ansible configuration is in /home/cbwinslow/ansible/"
echo ""
echo "Next steps:"
echo "1. Review the documentation"
echo "2. Configure ZeroTier and WireGuard as needed"
echo "3. Install additional essential services"
echo "4. Test all services to ensure they're working properly"