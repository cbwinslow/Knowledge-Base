#!/bin/bash

# Cloudflare Tunnel Setup Script for Nextcloud
# This script automates the setup of Cloudflare Tunnel for Nextcloud

echo "=== Cloudflare Tunnel Setup for Nextcloud ==="
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "Installing Cloudflare Tunnel (cloudflared)..."
    
    # Download and install cloudflared
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    
    # Verify installation
    if command -v cloudflared &> /dev/null; then
        echo "✅ Cloudflared installed successfully"
    else
        echo "❌ Failed to install cloudflared"
        exit 1
    fi
else
    echo "✅ Cloudflared is already installed"
fi

echo ""
echo "Please authenticate with Cloudflare by running:"
echo "cloudflared tunnel login"
echo ""
echo "This will open a browser window for authentication."
echo "After authenticating, press Enter to continue..."
read -p "Press Enter after authenticating..."

# Create a tunnel for Nextcloud
echo ""
echo "Creating Cloudflare Tunnel for Nextcloud..."
TUNNEL_OUTPUT=$(cloudflared tunnel create nextcloud 2>&1)
echo "$TUNNEL_OUTPUT"

# Extract tunnel ID
TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
if [ -z "$TUNNEL_ID" ]; then
    echo "❌ Failed to extract tunnel ID"
    echo "Please check the output above and ensure the tunnel was created successfully"
    exit 1
else
    echo "✅ Tunnel created with ID: $TUNNEL_ID"
fi

# Create configuration directory
sudo mkdir -p /etc/cloudflared

# Prompt for domain name
echo ""
read -p "Enter your domain name (e.g., nextcloud.yourdomain.com): " DOMAIN_NAME

# Create the configuration file
echo ""
echo "Creating tunnel configuration..."
sudo tee /etc/cloudflared/$TUNNEL_ID.json > /dev/null <<EOF
{
  "tunnel": "$TUNNEL_ID",
  "credentials-file": "/home/$USER/.cloudflared/$TUNNEL_ID.json",
  "ingress": [
    {
      "hostname": "$DOMAIN_NAME",
      "service": "http://localhost:80"
    },
    {
      "service": "http_status:404"
    }
  ]
}
EOF

echo "✅ Configuration file created at /etc/cloudflared/$TUNNEL_ID.json"

# Route traffic to the tunnel
echo ""
echo "Routing DNS traffic to tunnel..."
cloudflared tunnel route dns nextcloud $DOMAIN_NAME

echo "✅ DNS route created for $DOMAIN_NAME"

# Instructions for Nextcloud installation
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Install Nextcloud:"
echo "   sudo mv /tmp/nextcloud /var/www/"
echo "   sudo chown -R www-data:www-data /var/www/nextcloud"
echo ""
echo "2. Create Nextcloud database:"
echo "   sudo -u postgres psql -c \"CREATE USER nextcloud WITH PASSWORD 'nextcloud';\""
echo "   sudo -u postgres psql -c \"CREATE DATABASE nextcloud OWNER nextcloud;\""
echo ""
echo "3. Configure Apache virtual host (see documentation)"
echo ""
echo "4. Start the tunnel:"
echo "   cloudflared tunnel --config /etc/cloudflared/$TUNNEL_ID.json run"
echo ""
echo "5. For production use, install as a service:"
echo "   sudo cloudflared service install --config /etc/cloudflared/$TUNNEL_ID.json"
echo "   sudo systemctl enable cloudflared"
echo "   sudo systemctl start cloudflared"
echo ""
echo "6. Access your Nextcloud at https://$DOMAIN_NAME"
echo ""
echo "7. Optional: Configure Cloudflare Access for authentication"
echo "   in the Cloudflare dashboard under Access > Applications"