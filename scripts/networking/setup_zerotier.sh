#!/bin/bash

# ZeroTier Setup Script
# This script helps configure ZeroTier networking

echo "=== ZeroTier Setup ==="
echo ""

# Create documentation
DOCS_DIR="/home/cbwinslow/server_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# ZeroTier Setup Guide"
    echo ""
    echo "Date: $(date)"
    echo ""
} > $DOCS_DIR/zerotier_setup.md

# Check if ZeroTier is installed
if ! command -v zerotier-cli &> /dev/null; then
    echo "ZeroTier is not installed. Please run the networking setup script first."
    echo "- Command to install: /home/cbwinslow/server_setup/setup_networking_services.sh"
    exit 1
fi

echo "ZeroTier is installed."
echo "- Command line tool: zerotier-cli"
echo "- Service: zerotier-one"
echo ""

# Show current status
echo "Current ZeroTier status:"
sudo zerotier-cli info
echo ""

# Show available networks
echo "Currently joined networks:"
sudo zerotier-cli listnetworks
echo ""

# Create documentation
cat >> $DOCS_DIR/zerotier_setup.md << 'EOL'
## ZeroTier Commands

### Basic Commands
```bash
# Check ZeroTier status
sudo zerotier-cli info

# List joined networks
sudo zerotier-cli listnetworks

# Join a network
sudo zerotier-cli join <network_id>

# Leave a network
sudo zerotier-cli leave <network_id>

# List peers
sudo zerotier-cli listpeers
```

### Network Configuration
1. Go to https://my.zerotier.com/ to create an account and network
2. Note your Network ID
3. Run: `sudo zerotier-cli join <network_id>`
4. Approve the node in the ZeroTier web interface

### Service Management
```bash
# Start ZeroTier
sudo systemctl start zerotier-one

# Stop ZeroTier
sudo systemctl stop zerotier-one

# Restart ZeroTier
sudo systemctl restart zerotier-one

# Check status
sudo systemctl status zerotier-one

# Enable at boot
sudo systemctl enable zerotier-one
```

## Firewall Configuration
ZeroTier uses UDP port 9993. This should already be open if you ran the networking setup script.

## Troubleshooting
- If you can't join a network, check firewall settings
- If you can't communicate with other nodes, ensure the network is configured correctly in the web interface
- Check service status with `systemctl status zerotier-one`

## Next Steps
1. Create an account at https://my.zerotier.com/
2. Create a network
3. Join the network using the command above
4. Approve this node in the web interface
EOL

echo "Documentation created in $DOCS_DIR/zerotier_setup.md"
echo ""
echo "To use ZeroTier:"
echo "1. Create an account at https://my.zerotier.com/"
echo "2. Create a network and note the Network ID"
echo "3. Run: sudo zerotier-cli join <network_id>"
echo "4. Approve this node in the ZeroTier web interface"
echo ""
echo "Documentation is available in $DOCS_DIR/zerotier_setup.md"