#!/bin/bash

# Quick Status and Next Steps Script
# This script provides a quick overview of the current status and immediate next steps

echo "=== Quick Status and Next Steps ==="
echo ""

# Display current date and time
echo "Report generated on: $(date)"
echo ""

# Check current status
echo "Current Status:"
echo "==============="
echo ""

# Check Apache status
if systemctl is-active --quiet apache2; then
    echo "✅ Apache: Running"
else
    echo "❌ Apache: Not running"
fi

# Check Docker status
if systemctl is-active --quiet docker; then
    echo "✅ Docker: Running"
else
    echo "❌ Docker: Not running"
fi

# Check PostgreSQL status
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not running"
fi

# Check if Nextcloud is installed
if [ -d "/var/www/nextcloud" ]; then
    echo "✅ Nextcloud: Installed"
else
    echo "⚠️  Nextcloud: Not installed (files in /tmp/nextcloud)"
fi

# Check if cloudflared is installed
if command -v cloudflared &> /dev/null; then
    echo "✅ Cloudflared: Installed"
else
    echo "❌ Cloudflared: Not installed"
fi

echo ""
echo "Immediate Next Steps:"
echo "===================="
echo ""

echo "1. Deploy Nextcloud"
echo "------------------"
echo "Run: /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo ""

echo "2. Configure Cloudflare Tunnel"
echo "------------------------------"
echo "Follow: /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo ""

echo "3. Access Nextcloud"
echo "-------------------"
echo "Local: http://localhost/nextcloud"
echo "External (after Cloudflare Tunnel setup): https://cloudcurio.cc/nextcloud"
echo ""

echo "Documentation:"
echo "============="
echo "/home/cbwinslow/security_setup/docs/final_implementation_summary.md"
echo "/home/cbwinslow/security_setup/docs/immediate_next_steps.md"
echo "/home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo ""

echo "Scripts:"
echo "======="
echo "/home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo "/home/cbwinslow/security_setup/setup_cloudflare_tunnel.sh"
echo "/home/cbwinslow/security_setup/verify_security_setup.sh"
echo "/home/cbwinslow/security_setup/troubleshoot.sh"
echo ""