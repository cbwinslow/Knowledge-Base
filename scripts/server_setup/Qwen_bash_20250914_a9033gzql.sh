#!/bin/bash

# Network configuration and optimization
echo "Configuring network settings..."

# Install network tools
apt install -y speedtest-cli nmap net-tools dnsutils

# Configure static IP (example - adjust as needed)
# This would typically be done in /etc/network/interfaces or via netplan
# Example for netplan:
cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF

# Apply network configuration
netplan apply

# Setup network monitoring
cat > /etc/cron.hourly/network-monitor << EOF
#!/bin/bash
# Hourly network monitoring

# Log network usage
vnstat -i eth0 --json > /var/log/network-usage-\$(date +\%Y\%m\%d).json

# Check for unusual network activity
netstat -an | grep ESTABLISHED | wc -l > /tmp/active_connections.txt
EOF

chmod +x /etc/cron.hourly/network-monitor

echo "Network configuration completed."