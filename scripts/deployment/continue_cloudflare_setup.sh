#!/bin/bash

# Continue Cloudflare Tunnel Setup for Nextcloud
# This script continues the setup process after cloudflared is installed

echo "=== Continuing Cloudflare Tunnel Setup for Nextcloud ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Continued Cloudflare Tunnel Setup for Nextcloud"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Setup Continuation Log"
    echo ""
} > $DOCS_DIR/continued_cloudflare_setup.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/continued_cloudflare_setup.md
}

# Verify cloudflared installation
if command -v cloudflared &> /dev/null; then
    VERSION=$(cloudflared --version)
    log_action "✅ Cloudflared verified: $VERSION"
    echo "✅ Cloudflared verified: $VERSION"
else
    log_action "❌ Cloudflared not found"
    echo "❌ Cloudflared not found"
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Authenticate with Cloudflare by running:"
echo "   cloudflared tunnel login"
echo ""
echo "2. This will open a browser window for authentication"
echo "3. After authenticating, run this script again to continue setup"
echo ""
echo "Press Enter after you've authenticated..."

read -p "Press Enter to continue setup..."

# Create a tunnel for Nextcloud
echo ""
echo "Creating Cloudflare Tunnel for Nextcloud..."
log_action "Creating Cloudflare Tunnel for Nextcloud..."

TUNNEL_OUTPUT=$(cloudflared tunnel create nextcloud 2>&1)
echo "$TUNNEL_OUTPUT"
log_action "Tunnel creation output: $TUNNEL_OUTPUT"

# Extract tunnel ID
TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
if [ -n "$TUNNEL_ID" ]; then
    echo "✅ Tunnel created with ID: $TUNNEL_ID"
    log_action "✅ Tunnel created with ID: $TUNNEL_ID"
    
    # Create configuration directory
    echo ""
    echo "Creating configuration directory..."
    log_action "Creating configuration directory..."
    mkdir -p /etc/cloudflared 2>/dev/null || echo "Configuration directory may already exist"
    
    # Prompt for domain name
    echo ""
    echo "Please enter your domain name for Nextcloud:"
    read -p "Domain name (e.g., nextcloud.yourdomain.com): " DOMAIN_NAME
    
    # Create the configuration file
    echo ""
    echo "Creating tunnel configuration..."
    log_action "Creating tunnel configuration..."
    
    cat > /tmp/nextcloud_tunnel_config.json <<EOF
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
    
    echo "✅ Configuration file created at /tmp/nextcloud_tunnel_config.json"
    log_action "✅ Configuration file created at /tmp/nextcloud_tunnel_config.json"
    
    echo ""
    echo "To complete the setup, you'll need to run the following commands manually with sudo:"
    echo ""
    echo "1. Move the configuration file:"
    echo "   sudo mv /tmp/nextcloud_tunnel_config.json /etc/cloudflared/$TUNNEL_ID.json"
    echo ""
    echo "2. Route DNS traffic to the tunnel:"
    echo "   cloudflared tunnel route dns nextcloud $DOMAIN_NAME"
    echo ""
    echo "3. Start the tunnel:"
    echo "   cloudflared tunnel --config /etc/cloudflared/$TUNNEL_ID.json run"
    echo ""
    echo "For production use, install as a service:"
    echo "   sudo cloudflared service install --config /etc/cloudflared/$TUNNEL_ID.json"
    echo "   sudo systemctl enable cloudflared"
    echo "   sudo systemctl start cloudflared"
    
    {
        echo ""
        echo "## Manual Steps Required"
        echo ""
        echo "To complete the setup, run the following commands manually with sudo:"
        echo ""
        echo "1. Move the configuration file:"
        echo "   sudo mv /tmp/nextcloud_tunnel_config.json /etc/cloudflared/$TUNNEL_ID.json"
        echo ""
        echo "2. Route DNS traffic to the tunnel:"
        echo "   cloudflared tunnel route dns nextcloud $DOMAIN_NAME"
        echo ""
        echo "3. Start the tunnel:"
        echo "   cloudflared tunnel --config /etc/cloudflared/$TUNNEL_ID.json run"
        echo ""
        echo "For production use, install as a service:"
        echo "   sudo cloudflared service install --config /etc/cloudflared/$TUNNEL_ID.json"
        echo "   sudo systemctl enable cloudflared"
        echo "   sudo systemctl start cloudflared"
        echo ""
        echo "## Access Information"
        echo ""
        echo "After the tunnel is running, access your Nextcloud at:"
        echo "https://$DOMAIN_NAME"
        echo ""
        echo "## Security Recommendations"
        echo ""
        echo "1. Configure Cloudflare Access for authentication in the Cloudflare dashboard"
        echo "2. Enable two-factor authentication in Nextcloud"
        echo "3. Use strong, unique passwords"
        echo "4. Keep cloudflared updated regularly"
        echo "5. Monitor access logs regularly"
    } >> $DOCS_DIR/continued_cloudflare_setup.md
    
    echo ""
    echo "=== Setup Instructions Saved ==="
    echo "Documentation created in $DOCS_DIR/continued_cloudflare_setup.md"
    echo ""
    echo "Next steps:"
    echo "1. Run the manual commands above with sudo privileges"
    echo "2. Access your Nextcloud at https://$DOMAIN_NAME"
    echo "3. Configure Cloudflare Access for authentication"
else
    echo "❌ Failed to extract tunnel ID"
    echo "Please check the output above and ensure the tunnel was created successfully"
    log_action "❌ Failed to extract tunnel ID"
fi