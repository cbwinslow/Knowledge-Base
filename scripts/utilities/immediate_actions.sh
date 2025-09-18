#!/bin/bash

# Immediate Action Script
# This script helps you get started with the immediate next steps

echo "=== Immediate Action Script ==="
echo ""

echo "Let's get you started with the immediate next steps!"
echo ""

# Check if Nextcloud files are available
if [ ! -d "/tmp/nextcloud" ]; then
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
    echo "Please ensure Nextcloud files are in /tmp/nextcloud before proceeding"
    exit 1
fi

echo "✅ Nextcloud files found in /tmp/nextcloud"
echo ""

# Deploy Nextcloud
echo "Step 1: Deploying Nextcloud..."
echo "=============================="
echo ""

echo "Running Nextcloud deployment script:"
echo "/home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo ""

# Run the deployment script
/home/cbwinslow/security_setup/deploy_nextcloud_simple.sh

echo ""
echo "✅ Nextcloud deployment complete!"
echo ""

# Start required services
echo "Step 2: Starting required services..."
echo "==================================="
echo ""

echo "Starting Apache service:"
sudo systemctl start apache2
echo ""

echo "Starting PostgreSQL service:"
sudo systemctl start postgresql
echo ""

echo "✅ Required services started!"
echo ""

# Verify services are running
echo "Step 3: Verifying services..."
echo "============================"
echo ""

echo "Checking Apache status:"
if systemctl is-active --quiet apache2; then
    echo "✅ Apache: Running"
else
    echo "❌ Apache: Not running"
fi

echo ""

echo "Checking PostgreSQL status:"
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not running"
fi

echo ""

# Check Nextcloud installation
echo "Step 4: Checking Nextcloud installation..."
echo "========================================"
echo ""

if [ -d "/var/www/nextcloud" ]; then
    echo "✅ Nextcloud: Installed in /var/www/nextcloud"
    echo ""
    echo "You can now access Nextcloud at http://localhost/nextcloud"
    echo "Complete the initial web-based setup wizard to create your admin account."
else
    echo "❌ Nextcloud: Not installed in /var/www/nextcloud"
    echo "Please check the deployment script output for errors."
fi

echo ""
echo "=== Immediate Actions Complete ==="
echo ""

echo "Next steps:"
echo "1. Access Nextcloud at http://localhost/nextcloud"
echo "2. Complete the initial web-based setup wizard"
echo "3. Create your admin account"
echo "4. Configure your storage and settings"
echo "5. Set up Cloudflare Tunnel using the instructions in:"
echo "   /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo "6. Access your Nextcloud externally at https://cloudcurio.cc/nextcloud"
echo ""
echo "Documentation:"
echo "- Nextcloud deployment log: /home/cbwinslow/security_setup/docs/nextcloud_install_simple.md"
echo "- Cloudflare Tunnel setup: /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo "- Verification results: /home/cbwinslow/security_setup/docs/verification_results.md"
echo ""
echo "Scripts:"
echo "- Deploy Nextcloud: /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo "- Verify setup: /home/cbwinslow/security_setup/verify_core_components.sh"
echo "- Troubleshoot: /home/cbwinslow/security_setup/troubleshoot.sh"
echo ""
echo "Happy securing! 🛡️"