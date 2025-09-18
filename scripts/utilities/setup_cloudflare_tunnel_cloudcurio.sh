#!/bin/bash

# Cloudflare Tunnel Setup Script for cloudcurio.cc/nextcloud
# This script helps set up Cloudflare Tunnel for your Nextcloud instance

echo "=== Cloudflare Tunnel Setup for cloudcurio.cc/nextcloud ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Cloudflare Tunnel Setup for cloudcurio.cc/nextcloud"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Setup Instructions"
    echo ""
} > $DOCS_DIR/cloudflare_tunnel_cloudcurio.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/cloudflare_tunnel_cloudcurio.md
}

echo "Setting up Cloudflare Tunnel for cloudcurio.cc/nextcloud..."
log_action "Setting up Cloudflare Tunnel for cloudcurio.cc/nextcloud"

# Check if cloudflared is installed
if command -v cloudflared &> /dev/null; then
    echo "✅ Cloudflared is installed"
    log_action "✅ Cloudflared is installed ($(cloudflared --version | head -1))"
else
    echo "❌ Cloudflared is not installed"
    log_action "❌ Cloudflared is not installed"
    echo "Please install cloudflared first:"
    echo "wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    echo "sudo dpkg -i cloudflared-linux-amd64.deb"
    exit 1
fi

# Check if certificate exists
if [ -f "/home/cbwinslow/.cloudflared/cert.pem" ]; then
    echo "✅ Cloudflare certificate found"
    log_action "✅ Cloudflare certificate found"
    
    # Check if it's a placeholder
    if grep -q "placeholder" /home/cbwinslow/.cloudflared/cert.pem; then
        echo "⚠️  Certificate is a placeholder - you need to replace it with your actual certificate"
        log_action "⚠️  Certificate is a placeholder - you need to replace it with your actual certificate"
        echo ""
        echo "Instructions to get your actual certificate:"
        echo "1. Visit the Cloudflare dashboard at https://dash.cloudflare.com/"
        echo "2. Navigate to Access > Tunnels"
        echo "3. Click 'Create a tunnel'"
        echo "4. Choose 'Cloudflared' as the connector type"
        echo "5. Give your tunnel a name (e.g., 'nextcloud')"
        echo "6. Follow the instructions to install the certificate on your system"
        echo "7. The certificate will be downloaded automatically to ~/.cloudflared/"
        echo ""
        echo "After getting your actual certificate, replace the placeholder:"
        echo "cp /path/to/actual/cert.pem /home/cbwinslow/.cloudflared/cert.pem"
        echo ""
        echo "Then run this script again."
        exit 1
    else
        echo "✅ Certificate appears to be valid"
        log_action "✅ Certificate appears to be valid"
    fi
else
    echo "❌ Cloudflare certificate not found"
    log_action "❌ Cloudflare certificate not found"
    echo "Please authenticate with Cloudflare to get your certificate:"
    echo "cloudflared tunnel login"
    exit 1
fi

# Create tunnel for Nextcloud
echo ""
echo "Creating Cloudflare Tunnel for Nextcloud..."
log_action "Creating Cloudflare Tunnel for Nextcloud"

echo "Please run the following command manually:"
echo "cloudflared tunnel create nextcloud"
echo ""
echo "This will create a tunnel and generate a UUID for it."

log_action "Command to run manually:"
log_action "cloudflared tunnel create nextcloud"

# Find tunnel ID
echo ""
echo "Finding tunnel ID..."
log_action "Finding tunnel ID"

echo "Please run the following command manually:"
echo "cloudflared tunnel list"
echo ""
echo "Look for the tunnel ID in the output (it will be a UUID)."

log_action "Command to run manually:"
log_action "cloudflared tunnel list"

# Create tunnel configuration
echo ""
echo "Creating tunnel configuration..."
log_action "Creating tunnel configuration"

echo "Please replace TUNNEL_ID with your actual tunnel ID from the previous command:"
echo ""
echo "sudo mkdir -p /etc/cloudflared"
echo ""
echo "sudo tee /etc/cloudflared/TUNNEL_ID.json > /dev/null <<EOF"
echo "{"
echo "  \"tunnel\": \"TUNNEL_ID\","
echo "  \"credentials-file\": \"/home/cbwinslow/.cloudflared/TUNNEL_ID.json\","
echo "  \"ingress\": ["
echo "    {"
echo "      \"hostname\": \"cloudcurio.cc\","
echo "      \"service\": \"http://localhost:80\""
echo "    },"
echo "    {"
echo "      \"service\": \"http_status:404\""
echo "    }"
echo "  ]"
echo "}"
echo "EOF"

log_action "Commands to run manually (replace TUNNEL_ID with actual ID):"
log_action "sudo mkdir -p /etc/cloudflared"
log_action "sudo tee /etc/cloudflared/TUNNEL_ID.json > /dev/null <<EOF (see above for content)"

# Route traffic to tunnel
echo ""
echo "Routing traffic to tunnel..."
log_action "Routing traffic to tunnel"

echo "Please run the following command manually (replace TUNNEL_ID with your actual tunnel ID):"
echo "cloudflared tunnel route dns TUNNEL_ID cloudcurio.cc"

log_action "Command to run manually (replace TUNNEL_ID with actual ID):"
log_action "cloudflared tunnel route dns TUNNEL_ID cloudcurio.cc"

# Start tunnel
echo ""
echo "Starting tunnel..."
log_action "Starting tunnel"

echo "To run the tunnel temporarily for testing:"
echo "cloudflared tunnel --config /etc/cloudflared/TUNNEL_ID.json run"
echo ""
echo "To install as a service for production use:"
echo "sudo cloudflared service install --config /etc/cloudflared/TUNNEL_ID.json"
echo "sudo systemctl enable cloudflared"
echo "sudo systemctl start cloudflared"

log_action "Commands to run manually (replace TUNNEL_ID with actual ID):"
log_action "For testing: cloudflared tunnel --config /etc/cloudflared/TUNNEL_ID.json run"
log_action "For production: sudo cloudflared service install --config /etc/cloudflared/TUNNEL_ID.json"
log_action "sudo systemctl enable cloudflared"
log_action "sudo systemctl start cloudflared"

# Summary
{
    echo ""
    echo "## Summary"
    echo ""
    echo "### Cloudflare Tunnel Setup for cloudcurio.cc/nextcloud"
    echo ""
    echo "1. ✅ Cloudflared is installed"
    echo "2. ⚠️  Certificate is a placeholder (needs replacement with actual certificate)"
    echo "3. 📥 Tunnel needs to be created"
    echo "4. 📥 Configuration needs to be created"
    echo "5. 📥 Traffic routing needs to be set up"
    echo "6. 📥 Tunnel needs to be started"
    echo ""
    echo "### Next Steps"
    echo ""
    echo "1. Replace the placeholder certificate with your actual Cloudflare certificate"
    echo "2. Run the commands listed above manually"
    echo "3. Access your Nextcloud at https://cloudcurio.cc/nextcloud"
    echo "4. Complete the initial Nextcloud setup through the web interface"
    echo ""
    echo "### Important Notes"
    echo ""
    echo "- You must replace the placeholder certificate with your actual Cloudflare certificate"
    echo "- All commands with 'sudo' must be run manually with sudo privileges"
    echo "- Replace 'TUNNEL_ID' with your actual tunnel ID in all commands"
    echo "- Make sure your domain 'cloudcurio.cc' is configured in your Cloudflare account"
    echo "- After setup, you can access Nextcloud at https://cloudcurio.cc/nextcloud"
} >> $DOCS_DIR/cloudflare_tunnel_cloudcurio.md

log_action "Cloudflare Tunnel setup instructions complete!"
echo ""
echo "=== Cloudflare Tunnel Setup Instructions Complete ==="
echo "Documentation created in $DOCS_DIR/cloudflare_tunnel_cloudcurio.md"
echo ""
echo "Next steps:"
echo "1. Replace the placeholder certificate with your actual Cloudflare certificate"
echo "2. Run the commands listed above manually"
echo "3. Access your Nextcloud at https://cloudcurio.cc/nextcloud"
echo "4. Complete the initial Nextcloud setup through the web interface"
echo ""
echo "Important notes:"
echo "- You must replace the placeholder certificate with your actual Cloudflare certificate"
echo "- All commands with 'sudo' must be run manually with sudo privileges"
echo "- Replace 'TUNNEL_ID' with your actual tunnel ID in all commands"
echo "- Make sure your domain 'cloudcurio.cc' is configured in your Cloudflare account"
echo "- After setup, you can access Nextcloud at https://cloudcurio.cc/nextcloud"