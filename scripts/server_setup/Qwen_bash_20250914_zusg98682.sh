#!/bin/bash

# Setup ZeroTier network with SSH key propagation
echo "Setting up ZeroTier network..."

# Install ZeroTier
curl -s https://install.zerotier.com | sudo bash

# Join network (replace with your network ID)
read -p "Enter ZeroTier Network ID: " NETWORK_ID
sudo zerotier-cli join $NETWORK_ID

# Wait for network assignment
echo "Waiting for IP assignment from ZeroTier network..."
sleep 30

# Get ZeroTier IP
ZT_IP=$(ip addr show | grep '10\.' | grep -o '10\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)

if [ -z "$ZT_IP" ]; then
    echo "Warning: Could not detect ZeroTier IP. Please check network connection."
    exit 1
fi

echo "ZeroTier IP assigned: $ZT_IP"

# Create SSH key propagation script
cat > /opt/scripts/ssh-propagate.sh << 'EOF'
#!/bin/bash

# SSH Key Propagation Script for ZeroTier Network

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Get ZeroTier network members
NETWORK_ID=$(zerotier-cli listnetworks | grep -o '[0-9a-f]\{16\}')
MEMBERS=$(zerotier-cli listpeers | grep $NETWORK_ID | awk '{print $3}' | grep -E '10\.')

# Function to copy SSH key to remote host
copy_key() {
    local host=$1
    echo "Copying SSH key to $host..."
    sshpass -p "password" ssh-copy-id -o StrictHostKeyChecking=no root@$host 2>/dev/null || true
    sshpass -p "password" ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@$host 2>/dev/null || true
}

# Copy keys to all ZeroTier members
for member in $MEMBERS; do
    if [ "$member" != "$(hostname -I | awk '{print $1}')" ]; then
        copy_key $member
    fi
done

echo "SSH key propagation completed."
EOF

chmod +x /opt/scripts/ssh-propagate.sh

# Create ZeroTier monitoring script
cat > /opt/scripts/zt-monitor.sh << 'EOF'
#!/bin/bash

# ZeroTier Network Monitoring Script

LOG_FILE="/var/log/zerotier-monitor.log"

# Check if ZeroTier is running
if ! zerotier-cli info > /dev/null 2>&1; then
    echo "$(date): ZeroTier service not running, restarting..." >> $LOG_FILE
    systemctl restart zerotier-one
fi

# Check network connectivity
NETWORK_ID=$(zerotier-cli listnetworks | grep -o '[0-9a-f]\{16\}' | head -1)
if [ -z "$NETWORK_ID" ]; then
    echo "$(date): Not connected to any network" >> $LOG_FILE
    exit 1
fi

# Log network status
STATUS=$(zerotier-cli listnetworks)
echo "$(date): Network status - $STATUS" >> $LOG_FILE

# Check for new members and propagate SSH keys
/opt/scripts/ssh-propagate.sh
EOF

chmod +x /opt/scripts/zt-monitor.sh

# Add to cron for regular monitoring
echo "*/5 * * * * root /opt/scripts/zt-monitor.sh" > /etc/cron.d/zerotier-monitor

echo "ZeroTier setup completed."