#!/bin/bash

# Cloudflare Tunnel and Nextcloud Verification Script
# This script verifies that Cloudflare Tunnel and Nextcloud are properly configured

echo "=== Cloudflare Tunnel and Nextcloud Verification ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Cloudflare Tunnel and Nextcloud Verification"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Verification Results"
    echo ""
} > $DOCS_DIR/verification_results.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/verification_results.md
}

echo "Verifying Cloudflare Tunnel and Nextcloud setup..."
log_action "Verifying Cloudflare Tunnel and Nextcloud setup"

# 1. Check if cloudflared is installed
echo ""
echo "1. Checking if cloudflared is installed..."
log_action "1. Checking if cloudflared is installed..."
if command -v cloudflared &> /dev/null; then
    CLOUDFLARED_VERSION=$(cloudflared --version | head -1)
    echo "✅ cloudflared is installed ($CLOUDFLARED_VERSION)"
    log_action "✅ cloudflared is installed ($CLOUDFLARED_VERSION)"
else
    echo "❌ cloudflared is not installed"
    log_action "❌ cloudflared is not installed"
fi

# 2. Check if certificate exists and is valid
echo ""
echo "2. Checking Cloudflare certificate..."
log_action "2. Checking Cloudflare certificate..."
if [ -f "/home/cbwinslow/.cloudflared/cert.pem" ]; then
    echo "✅ Cloudflare certificate found"
    log_action "✅ Cloudflare certificate found"
    
    # Check if it's a placeholder
    if grep -q "placeholder" /home/cbwinslow/.cloudflared/cert.pem; then
        echo "⚠️  Certificate is a placeholder - needs replacement with actual certificate"
        log_action "⚠️  Certificate is a placeholder - needs replacement with actual certificate"
    else
        echo "✅ Certificate appears to be valid"
        log_action "✅ Certificate appears to be valid"
    fi
else
    echo "❌ Cloudflare certificate not found"
    log_action "❌ Cloudflare certificate not found"
fi

# 3. Check if Nextcloud is installed
echo ""
echo "3. Checking Nextcloud installation..."
log_action "3. Checking Nextcloud installation..."
if [ -d "/var/www/nextcloud" ]; then
    echo "✅ Nextcloud is installed in /var/www/nextcloud"
    log_action "✅ Nextcloud is installed in /var/www/nextcloud"
    
    # Check if config.php exists
    if [ -f "/var/www/nextcloud/config/config.php" ]; then
        echo "✅ Nextcloud configuration file exists"
        log_action "✅ Nextcloud configuration file exists"
    else
        echo "⚠️  Nextcloud configuration file not found"
        log_action "⚠️  Nextcloud configuration file not found"
    fi
else
    echo "❌ Nextcloud is not installed in /var/www/nextcloud"
    log_action "❌ Nextcloud is not installed in /var/www/nextcloud"
fi

# 4. Check Apache status
echo ""
echo "4. Checking Apache status..."
log_action "4. Checking Apache status..."
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
    log_action "✅ Apache is running"
else
    echo "❌ Apache is not running"
    log_action "❌ Apache is not running"
fi

# 5. Check if Nextcloud is accessible locally
echo ""
echo "5. Checking if Nextcloud is accessible locally..."
log_action "5. Checking if Nextcloud is accessible locally..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/nextcloud | grep -q "200\|301\|302"; then
    echo "✅ Nextcloud is accessible locally at http://localhost/nextcloud"
    log_action "✅ Nextcloud is accessible locally at http://localhost/nextcloud"
else
    echo "❌ Nextcloud is not accessible locally"
    log_action "❌ Nextcloud is not accessible locally"
fi

# 6. Check if required directories exist
echo ""
echo "6. Checking required directories..."
log_action "6. Checking required directories..."
if [ -d "/var/www/nextcloud/data" ]; then
    echo "✅ Nextcloud data directory exists"
    log_action "✅ Nextcloud data directory exists"
else
    echo "⚠️  Nextcloud data directory does not exist"
    log_action "⚠️  Nextcloud data directory does not exist"
fi

if [ -d "/var/www/nextcloud/config" ]; then
    echo "✅ Nextcloud config directory exists"
    log_action "✅ Nextcloud config directory exists"
else
    echo "⚠️  Nextcloud config directory does not exist"
    log_action "⚠️  Nextcloud config directory does not exist"
fi

# 7. Check Apache virtual host configuration
echo ""
echo "7. Checking Apache virtual host configuration..."
log_action "7. Checking Apache virtual host configuration..."
if [ -f "/etc/apache2/sites-available/nextcloud.conf" ]; then
    echo "✅ Nextcloud Apache virtual host configuration exists"
    log_action "✅ Nextcloud Apache virtual host configuration exists"
else
    echo "⚠️  Nextcloud Apache virtual host configuration not found"
    log_action "⚠️  Nextcloud Apache virtual host configuration not found"
fi

# 8. Check if required Apache modules are enabled
echo ""
echo "8. Checking required Apache modules..."
log_action "8. Checking required Apache modules..."
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

# 9. Check if Nextcloud site is enabled
echo ""
echo "9. Checking if Nextcloud site is enabled..."
log_action "9. Checking if Nextcloud site is enabled..."
if [ -L "/etc/apache2/sites-enabled/nextcloud.conf" ]; then
    echo "✅ Nextcloud site is enabled"
    log_action "✅ Nextcloud site is enabled"
else
    echo "❌ Nextcloud site is not enabled"
    log_action "❌ Nextcloud site is not enabled"
fi

# 10. Check Cloudflare Tunnel status (if running)
echo ""
echo "10. Checking Cloudflare Tunnel status..."
log_action "10. Checking Cloudflare Tunnel status..."
if cloudflared tunnel list &> /dev/null; then
    echo "✅ Cloudflare Tunnel is accessible"
    log_action "✅ Cloudflare Tunnel is accessible"
    
    # List tunnels
    TUNNEL_LIST=$(cloudflared tunnel list 2>/dev/null)
    if [ -n "$TUNNEL_LIST" ]; then
        echo "Tunnel list:"
        echo "$TUNNEL_LIST"
        echo "$TUNNEL_LIST" >> $DOCS_DIR/verification_results.md
        log_action "Tunnel list displayed above"
    else
        echo "No tunnels found"
        log_action "No tunnels found"
    fi
else
    echo "⚠️  Cloudflare Tunnel is not accessible or not configured"
    log_action "⚠️  Cloudflare Tunnel is not accessible or not configured"
fi

# Summary
{
    echo ""
    echo "## Verification Summary"
    echo ""
    echo "### Component Status"
    echo ""
} >> $DOCS_DIR/verification_results.md

echo ""
echo "=== Verification Summary ==="
echo ""

if command -v cloudflared &> /dev/null && [ -d "/var/www/nextcloud" ] && systemctl is-active --quiet apache2; then
    echo "✅ Core components are installed"
    log_action "✅ Core components are installed"
else
    echo "❌ Some core components are missing"
    log_action "❌ Some core components are missing"
fi

if [ -f "/etc/apache2/sites-available/nextcloud.conf" ] && [ -L "/etc/apache2/sites-enabled/nextcloud.conf" ]; then
    echo "✅ Nextcloud Apache configuration is complete"
    log_action "✅ Nextcloud Apache configuration is complete"
else
    echo "❌ Nextcloud Apache configuration is incomplete"
    log_action "❌ Nextcloud Apache configuration is incomplete"
fi

if [ ${#MISSING_MODULES[@]} -eq 0 ]; then
    echo "✅ All required Apache modules are enabled"
    log_action "✅ All required Apache modules are enabled"
else
    echo "❌ Some required Apache modules are missing: ${MISSING_MODULES[*]}"
    log_action "❌ Some required Apache modules are missing: ${MISSING_MODULES[*]}"
fi

echo ""
echo "=== Next Steps ==="
echo ""
log_action "=== Next Steps ==="
echo "1. If the certificate is a placeholder, replace it with your actual Cloudflare certificate"
echo "2. If Apache modules are missing, enable them with 'sudo a2enmod MODULE_NAME'"
echo "3. If the Nextcloud site is not enabled, enable it with 'sudo a2ensite nextcloud'"
echo "4. If Apache is not running, start it with 'sudo systemctl start apache2'"
echo "5. If Nextcloud is not accessible locally, check the configuration"
echo "6. Once everything is working locally, set up Cloudflare Tunnel"
echo "7. Access your Nextcloud at https://cloudcurio.cc/nextcloud after Cloudflare Tunnel is configured"
log_action "1. If the certificate is a placeholder, replace it with your actual Cloudflare certificate"
log_action "2. If Apache modules are missing, enable them with 'sudo a2enmod MODULE_NAME'"
log_action "3. If the Nextcloud site is not enabled, enable it with 'sudo a2ensite nextcloud'"
log_action "4. If Apache is not running, start it with 'sudo systemctl start apache2'"
log_action "5. If Nextcloud is not accessible locally, check the configuration"
log_action "6. Once everything is working locally, set up Cloudflare Tunnel"
log_action "7. Access your Nextcloud at https://cloudcurio.cc/nextcloud after Cloudflare Tunnel is configured"

{
    echo ""
    echo "### Documentation"
    echo ""
    echo "Verification results are documented in:"
    echo "$DOCS_DIR/verification_results.md"
    echo ""
    echo "### Useful Commands"
    echo ""
    echo "- Check Apache status: sudo systemctl status apache2"
    echo "- Restart Apache: sudo systemctl restart apache2"
    echo "- Enable Apache modules: sudo a2enmod MODULE_NAME"
    echo "- Enable Nextcloud site: sudo a2ensite nextcloud"
    echo "- Check Cloudflare Tunnel status: cloudflared tunnel list"
    echo "- View Apache error logs: sudo tail -f /var/log/apache2/error.log"
    echo "- View Nextcloud logs: sudo tail -f /var/log/apache2/nextcloud_*.log"
    echo ""
    echo "### Troubleshooting Tips"
    echo ""
    echo "- If Apache won't start, check configuration with 'sudo apache2ctl configtest'"
    echo "- If Nextcloud is not accessible, check file permissions in /var/www/nextcloud"
    echo "- If Cloudflare Tunnel won't connect, check certificate validity"
    echo "- Ensure all services are running with proper privileges"
} >> $DOCS_DIR/verification_results.md

log_action "Verification complete!"
echo ""
echo "=== Verification Complete ==="
echo "Documentation created in $DOCS_DIR/verification_results.md"
echo ""
echo "Next steps:"
echo "1. Review the verification results above"
echo "2. Address any issues identified"
echo "3. Complete the Cloudflare Tunnel setup if needed"
echo "4. Access your Nextcloud at https://cloudcurio.cc/nextcloud"