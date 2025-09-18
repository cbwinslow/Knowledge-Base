#!/bin/bash

# ================================================
# 🚀 QUICK INSTALL SCRIPT FOR ENHANCED SERVER SETUP
# ================================================

echo "🚀 Downloading Enhanced Server Setup Script..."

# Download the main script
wget -O /tmp/enhanced_server_setup.sh https://raw.githubusercontent.com/cbwinslow/system-setup/main/enhanced_server_setup_final.sh 2>/dev/null || {
    echo "⚠️  Could not download from GitHub, using local copy..."
    if [ -f "/home/cbwinslow/enhanced_server_setup_final.sh" ]; then
        cp /home/cbwinslow/enhanced_server_setup_final.sh /tmp/enhanced_server_setup.sh
    else
        echo "❌ Could not find local copy either. Please download manually."
        exit 1
    fi
}

# Make it executable
chmod +x /tmp/enhanced_server_setup.sh

echo "✅ Download complete!"

# Create a simple configuration template
cat > /tmp/server_setup.conf <<EOF
# Configuration file for enhanced_server_setup.sh

# Username for the new user account
NEW_USER="your_username"

# SSH public key for authentication
# Replace this with your actual public key
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD...your_key_here..."

# Additional configuration options
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"

# Development tools to install
INSTALL_NODEJS=true
INSTALL_DOCKER=false
INSTALL_GIT_TOOLS=true

# Security settings
ENABLE_FAIL2BAN=true
ENABLE_UFW=true
SSH_PORT=22

# Monitoring
ENABLE_MONITORING=true
EOF

echo "📝 Created configuration template at /tmp/server_setup.conf"
echo "   Edit this file with your settings before running the setup script."

echo ""
echo "📋 To complete setup:"
echo "1. Edit the configuration file:"
echo "   nano /tmp/server_setup.conf"
echo ""
echo "2. Run the setup script:"
echo "   sudo /tmp/enhanced_server_setup.sh"
echo ""
echo "3. Follow the prompts for any unset configuration values"
echo ""
echo "📄 For detailed instructions, see:"
echo "   less /home/cbwinslow/ENHANCED_SERVER_SETUP_README.md"