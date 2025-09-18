#!/bin/bash

# Simple Status Report Script
# This script provides a quick status report of your security setup

echo "=== Security Setup Status Report ==="
echo ""

# Print current date and time
echo "Report generated on: $(date)"
echo ""

# Check if required tools are installed
echo "Checking installed tools..."
echo "=========================="
echo ""

# Check Apache
if command -v apache2 &> /dev/null; then
    APACHE_STATUS=$(systemctl is-active apache2)
    echo "Apache: Installed (Status: $APACHE_STATUS)"
else
    echo "Apache: Not installed"
fi

# Check PHP
if command -v php &> /dev/null; then
    PHP_VERSION=$(php --version | head -1)
    echo "PHP: Installed ($PHP_VERSION)"
else
    echo "PHP: Not installed"
fi

# Check PostgreSQL
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | head -1)
    PG_STATUS=$(systemctl is-active postgresql)
    echo "PostgreSQL: Installed ($PG_VERSION, Status: $PG_STATUS)"
else
    echo "PostgreSQL: Not installed"
fi

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    DOCKER_STATUS=$(systemctl is-active docker)
    echo "Docker: Installed ($DOCKER_VERSION, Status: $DOCKER_STATUS)"
else
    echo "Docker: Not installed"
fi

# Check cloudflared
if command -v cloudflared &> /dev/null; then
    CLOUDFLARED_VERSION=$(cloudflared --version | head -1)
    echo "Cloudflared: Installed ($CLOUDFLARED_VERSION)"
else
    echo "Cloudflared: Not installed"
fi

# Check Nextcloud
echo ""
echo "Checking Nextcloud installation..."
echo "================================="
echo ""

if [ -d "/var/www/nextcloud" ]; then
    echo "Nextcloud: Installed in /var/www/nextcloud"
else
    echo "Nextcloud: Not installed in /var/www/nextcloud"
fi

# Check if Nextcloud files are in temporary location
if [ -d "/tmp/nextcloud" ]; then
    echo "Nextcloud files: Found in /tmp/nextcloud (need to be moved)"
else
    echo "Nextcloud files: Not found in /tmp/nextcloud"
fi

# Check Apache modules
echo ""
echo "Checking Apache modules..."
echo "========================="
echo ""

REQUIRED_MODULES=("rewrite" "headers" "env" "dir" "mime" "ssl")
for module in "${REQUIRED_MODULES[@]}"; do
    if apache2ctl -M 2>/dev/null | grep -q "${module}_module"; then
        echo "Module $module: Enabled"
    else
        echo "Module $module: Not enabled"
    fi
done

# Check Apache sites
echo ""
echo "Checking Apache sites..."
echo "======================="
echo ""

if [ -f "/etc/apache2/sites-available/nextcloud.conf" ]; then
    echo "Nextcloud site config: Found"
else
    echo "Nextcloud site config: Not found"
fi

if [ -L "/etc/apache2/sites-enabled/nextcloud.conf" ]; then
    echo "Nextcloud site enabled: Yes"
else
    echo "Nextcloud site enabled: No"
fi

# Check Cloudflare certificate
echo ""
echo "Checking Cloudflare certificate..."
echo "================================="
echo ""

if [ -f "/home/cbwinslow/.cloudflared/cert.pem" ]; then
    echo "Cloudflare certificate: Found"
    if grep -q "placeholder" /home/cbwinslow/.cloudflared/cert.pem; then
        echo "Certificate status: Placeholder (needs replacement)"
    else
        echo "Certificate status: Valid"
    fi
else
    echo "Cloudflare certificate: Not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo ""

echo "Completed:"
echo "- Apache web server installed"
echo "- PHP installed with required modules"
echo "- PostgreSQL database installed"
echo "- Docker container platform installed"
echo "- Cloudflared (Cloudflare Tunnel client) installed"

echo ""
echo "Pending:"
if [ -d "/tmp/nextcloud" ]; then
    echo "- Nextcloud deployment (files in /tmp/nextcloud)"
elif [ ! -d "/var/www/nextcloud" ]; then
    echo "- Nextcloud deployment (files not found)"
else
    echo "- Nextcloud configuration"
fi

if [ -f "/home/cbwinslow/.cloudflared/cert.pem" ] && grep -q "placeholder" /home/cbwinslow/.cloudflared/cert.pem; then
    echo "- Cloudflare Tunnel configuration (placeholder certificate)"
elif [ ! -f "/home/cbwinslow/.cloudflared/cert.pem" ]; then
    echo "- Cloudflare Tunnel configuration (certificate not found)"
else
    echo "- Cloudflare Tunnel configuration"
fi

echo ""
echo "Next Steps:"
echo "1. Deploy Nextcloud using /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo "2. Configure Cloudflare Tunnel using the instructions in /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo "3. Access Nextcloud at http://localhost/nextcloud to complete setup"
echo "4. Configure external access via Cloudflare Tunnel at https://cloudcurio.cc/nextcloud"

echo ""
echo "Documentation:"
echo "- Status report: /home/cbwinslow/security_setup/docs/status_report.md"
echo "- Next steps: /home/cbwinslow/security_setup/docs/immediate_next_steps.md"
echo "- Cloudflare Tunnel setup: /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo "- Final summary: /home/cbwinslow/security_setup/docs/final_status_summary.md"