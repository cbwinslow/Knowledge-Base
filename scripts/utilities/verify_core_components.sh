#!/bin/bash

# Core Components Verification Script
# This script verifies that the core components of your security setup are working

echo "=== Core Components Verification ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Core Components Verification"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Verification Results"
    echo ""
} > $DOCS_DIR/core_components_verification.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/core_components_verification.md
}

echo "Verifying core components of your security setup..."
log_action "Verifying core components of your security setup"

# 1. Check SSH status
echo ""
echo "1. Checking SSH status..."
log_action "1. Checking SSH status..."
if systemctl is-active --quiet ssh; then
    SSH_STATUS=$(systemctl status ssh | grep "Active:" | awk '{print $2, $3}')
    echo "✅ SSH: Active ($SSH_STATUS)"
    log_action "✅ SSH: Active ($SSH_STATUS)"
else
    echo "❌ SSH: Not active"
    log_action "❌ SSH: Not active"
fi

# 2. Check Docker status
echo ""
echo "2. Checking Docker status..."
log_action "2. Checking Docker status..."
if systemctl is-active --quiet docker; then
    DOCKER_STATUS=$(systemctl status docker | grep "Active:" | awk '{print $2, $3}')
    echo "✅ Docker: Active ($DOCKER_STATUS)"
    log_action "✅ Docker: Active ($DOCKER_STATUS)"
else
    echo "❌ Docker: Not active"
    log_action "❌ Docker: Not active"
fi

# 3. Check Apache status
echo ""
echo "3. Checking Apache status..."
log_action "3. Checking Apache status..."
if systemctl is-active --quiet apache2; then
    APACHE_STATUS=$(systemctl status apache2 | grep "Active:" | awk '{print $2, $3}')
    echo "✅ Apache: Active ($APACHE_STATUS)"
    log_action "✅ Apache: Active ($APACHE_STATUS)"
else
    echo "❌ Apache: Not active"
    log_action "❌ Apache: Not active"
fi

# 4. Check PHP status
echo ""
echo "4. Checking PHP status..."
log_action "4. Checking PHP status..."
if command -v php &> /dev/null; then
    PHP_VERSION=$(php --version | head -1)
    echo "✅ PHP: Installed ($PHP_VERSION)"
    log_action "✅ PHP: Installed ($PHP_VERSION)"
else
    echo "❌ PHP: Not installed"
    log_action "❌ PHP: Not installed"
fi

# 5. Check PostgreSQL status
echo ""
echo "5. Checking PostgreSQL status..."
log_action "5. Checking PostgreSQL status..."
if systemctl is-active --quiet postgresql; then
    PG_STATUS=$(systemctl status postgresql | grep "Active:" | awk '{print $2, $3}')
    echo "✅ PostgreSQL: Active ($PG_STATUS)"
    log_action "✅ PostgreSQL: Active ($PG_STATUS)"
else
    echo "❌ PostgreSQL: Not active"
    log_action "❌ PostgreSQL: Not active"
fi

# 6. Check Fail2ban status
echo ""
echo "6. Checking Fail2ban status..."
log_action "6. Checking Fail2ban status..."
if systemctl is-active --quiet fail2ban; then
    FAIL2BAN_STATUS=$(systemctl status fail2ban | grep "Active:" | awk '{print $2, $3}')
    echo "✅ Fail2ban: Active ($FAIL2BAN_STATUS)"
    log_action "✅ Fail2ban: Active ($FAIL2BAN_STATUS)"
else
    echo "❌ Fail2ban: Not active"
    log_action "❌ Fail2ban: Not active"
fi

# 7. Check Cloudflared status
echo ""
echo "7. Checking Cloudflared status..."
log_action "7. Checking Cloudflared status..."
if command -v cloudflared &> /dev/null; then
    CLOUDFLARED_VERSION=$(cloudflared --version | head -1)
    echo "✅ Cloudflared: Installed ($CLOUDFLARED_VERSION)"
    log_action "✅ Cloudflared: Installed ($CLOUDFLARED_VERSION)"
else
    echo "❌ Cloudflared: Not installed"
    log_action "❌ Cloudflared: Not installed"
fi

# 8. Check Nextcloud status
echo ""
echo "8. Checking Nextcloud status..."
log_action "8. Checking Nextcloud status..."
if [ -d "/var/www/nextcloud" ]; then
    echo "✅ Nextcloud: Installed in /var/www/nextcloud"
    log_action "✅ Nextcloud: Installed in /var/www/nextcloud"
elif [ -d "/tmp/nextcloud" ]; then
    echo "⚠️  Nextcloud: Files available in /tmp/nextcloud (not yet installed)"
    log_action "⚠️  Nextcloud: Files available in /tmp/nextcloud (not yet installed)"
else
    echo "❌ Nextcloud: Not installed"
    log_action "❌ Nextcloud: Not installed"
fi

# 9. Check if required services are running
echo ""
echo "9. Checking required services..."
log_action "9. Checking required services..."
REQUIRED_SERVICES=("ssh" "docker" "postgresql" "fail2ban")
STOPPED_SERVICES=()

for service in "${REQUIRED_SERVICES[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ Service '$service' is running"
        log_action "✅ Service '$service' is running"
    else
        echo "❌ Service '$service' is not running"
        log_action "❌ Service '$service' is not running"
        STOPPED_SERVICES+=("$service")
    fi
done

# 10. Check if Apache is installed
echo ""
echo "10. Checking Apache installation..."
log_action "10. Checking Apache installation..."
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | head -1)
    echo "✅ Apache: Installed ($APACHE_VERSION)"
    log_action "✅ Apache: Installed ($APACHE_VERSION)"
else
    echo "❌ Apache: Not installed"
    log_action "❌ Apache: Not installed"
fi

# 11. Check if required Apache modules are enabled
echo ""
echo "11. Checking required Apache modules..."
log_action "11. Checking required Apache modules..."
REQUIRED_MODULES=("rewrite" "headers" "env" "dir" "mime" "ssl")
MISSING_MODULES=()

for module in "${REQUIRED_MODULES[@]}"; do
    if apache2ctl -M 2>/dev/null | grep -q "${module}_module"; then
        echo "✅ Apache module '${module}' is enabled"
        log_action "✅ Apache module '${module}' is enabled"
    else
        echo "❌ Apache module '${module}' is not enabled"
        log_action "❌ Apache module '${module}' is not enabled"
        MISSING_MODULES+=("$module")
    fi
done

# 12. Check if Nextcloud site is configured
echo ""
echo "12. Checking Nextcloud site configuration..."
log_action "12. Checking Nextcloud site configuration..."
if [ -f "/etc/apache2/sites-available/nextcloud.conf" ]; then
    echo "✅ Nextcloud site configuration exists"
    log_action "✅ Nextcloud site configuration exists"
else
    echo "❌ Nextcloud site configuration does not exist"
    log_action "❌ Nextcloud site configuration does not exist"
fi

# 13. Check if Nextcloud site is enabled
echo ""
echo "13. Checking Nextcloud site status..."
log_action "13. Checking Nextcloud site status..."
if [ -L "/etc/apache2/sites-enabled/nextcloud.conf" ]; then
    echo "✅ Nextcloud site is enabled"
    log_action "✅ Nextcloud site is enabled"
else
    echo "❌ Nextcloud site is not enabled"
    log_action "❌ Nextcloud site is not enabled"
fi

# Summary
{
    echo ""
    echo "## Verification Summary"
    echo ""
    echo "### Component Status"
    echo ""
} >> $DOCS_DIR/core_components_verification.md

echo ""
echo "=== Verification Summary ==="
echo ""

if [ ${#STOPPED_SERVICES[@]} -eq 0 ]; then
    echo "✅ All required services are running"
    log_action "✅ All required services are running"
else
    echo "❌ Some required services are not running: ${STOPPED_SERVICES[*]}"
    log_action "❌ Some required services are not running: ${STOPPED_SERVICES[*]}"
fi

if [ ${#MISSING_MODULES[@]} -eq 0 ]; then
    echo "✅ All required Apache modules are enabled"
    log_action "✅ All required Apache modules are enabled"
else
    echo "❌ Some required Apache modules are missing: ${MISSING_MODULES[*]}"
    log_action "❌ Some required Apache modules are missing: ${MISSING_MODULES[*]}"
fi

if [ -f "/etc/apache2/sites-available/nextcloud.conf" ] && [ -L "/etc/apache2/sites-enabled/nextcloud.conf" ]; then
    echo "✅ Nextcloud site is configured and enabled"
    log_action "✅ Nextcloud site is configured and enabled"
else
    echo "❌ Nextcloud site is not properly configured"
    log_action "❌ Nextcloud site is not properly configured"
fi

if [ -d "/var/www/nextcloud" ]; then
    echo "✅ Nextcloud is installed"
    log_action "✅ Nextcloud is installed"
elif [ -d "/tmp/nextcloud" ]; then
    echo "⚠️  Nextcloud files are available but not installed"
    log_action "⚠️  Nextcloud files are available but not installed"
else
    echo "❌ Nextcloud is not installed"
    log_action "❌ Nextcloud is not installed"
fi

echo ""
echo "=== Next Steps ==="
echo ""

{
    echo ""
    echo "### Next Steps"
    echo ""
} >> $DOCS_DIR/core_components_verification.md

if [ -d "/tmp/nextcloud" ] && [ ! -d "/var/www/nextcloud" ]; then
    echo "1. Deploy Nextcloud using:"
    echo "   /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
    log_action "1. Deploy Nextcloud using /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
fi

if [ ${#STOPPED_SERVICES[@]} -gt 0 ]; then
    echo ""
    echo "2. Start stopped services:"
    for service in "${STOPPED_SERVICES[@]}"; do
        echo "   sudo systemctl start $service"
        log_action "2. Start service: sudo systemctl start $service"
    done
fi

if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    echo ""
    echo "3. Enable missing Apache modules:"
    for module in "${MISSING_MODULES[@]}"; do
        echo "   sudo a2enmod $module"
        log_action "3. Enable Apache module: sudo a2enmod $module"
    done
fi

if [ ! -f "/etc/apache2/sites-available/nextcloud.conf" ] || [ ! -L "/etc/apache2/sites-enabled/nextcloud.conf" ]; then
    echo ""
    echo "4. Configure Nextcloud site:"
    echo "   Create /etc/apache2/sites-available/nextcloud.conf"
    echo "   Enable site with: sudo a2ensite nextcloud"
    log_action "4. Configure Nextcloud site:"
    log_action "   Create /etc/apache2/sites-available/nextcloud.conf"
    log_action "   Enable site with: sudo a2ensite nextcloud"
fi

if [ ! -d "/var/www/nextcloud" ]; then
    echo ""
    echo "5. Complete Nextcloud installation after deployment"
    log_action "5. Complete Nextcloud installation after deployment"
fi

echo ""
echo "6. Configure Cloudflare Tunnel following:"
echo "   /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
log_action "6. Configure Cloudflare Tunnel following /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"

{
    echo ""
    echo "### Documentation"
    echo ""
    echo "Verification results are documented in:"
    echo "$DOCS_DIR/core_components_verification.md"
    echo ""
    echo "### Useful Commands"
    echo ""
    echo "- Check service status: systemctl status SERVICE_NAME"
    echo "- Start service: sudo systemctl start SERVICE_NAME"
    echo "- Enable Apache module: sudo a2enmod MODULE_NAME"
    echo "- Enable site: sudo a2ensite SITE_NAME"
    echo "- Restart Apache: sudo systemctl restart apache2"
    echo "- Check Apache configuration: sudo apache2ctl configtest"
    echo ""
    echo "### Troubleshooting Tips"
    echo ""
    echo "- If services won't start, check logs with: journalctl -u SERVICE_NAME -f"
    echo "- If Apache won't start, check configuration with: sudo apache2ctl configtest"
    echo "- If Nextcloud is not accessible, check file permissions in /var/www/nextcloud"
    echo "- If Cloudflare Tunnel won't connect, check certificate validity"
    echo "- Ensure all services are running with proper privileges"
} >> $DOCS_DIR/core_components_verification.md

log_action "Verification complete!"
echo ""
echo "=== Verification Complete ==="
echo "Documentation created in $DOCS_DIR/core_components_verification.md"
echo ""
echo "Next steps:"
echo "1. Review the verification results above"
echo "2. Address any issues identified"
echo "3. Complete the Nextcloud deployment if needed"
echo "4. Configure Cloudflare Tunnel following the documentation"