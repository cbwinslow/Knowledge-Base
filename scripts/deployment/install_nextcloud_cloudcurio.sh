#!/bin/bash

# Nextcloud Installation and Configuration Script for cloudcurio.cc/nextcloud
# This script installs and configures Nextcloud with Cloudflare integration

echo "=== Nextcloud Installation and Configuration for cloudcurio.cc/nextcloud ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud Installation and Configuration for cloudcurio.cc/nextcloud"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/nextcloud_installation_cloudcurio.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_installation_cloudcurio.md
}

echo "Starting Nextcloud installation and configuration for cloudcurio.cc/nextcloud..."
log_action "Starting Nextcloud installation and configuration for cloudcurio.cc/nextcloud"

# 1. Check prerequisites
echo ""
echo "1. Checking prerequisites..."
log_action "1. Checking prerequisites..."

# Check if Apache is installed
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | head -1)
    echo "✅ Apache installed ($APACHE_VERSION)"
    log_action "✅ Apache installed ($APACHE_VERSION)"
else
    echo "❌ Apache not installed"
    log_action "❌ Apache not installed"
    exit 1
fi

# Check if PHP is installed
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -1)
    echo "✅ PHP installed ($PHP_VERSION)"
    log_action "✅ PHP installed ($PHP_VERSION)"
else
    echo "❌ PHP not installed"
    log_action "❌ PHP not installed"
    exit 1
fi

# Check if PostgreSQL is installed
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | head -1)
    echo "✅ PostgreSQL installed ($PG_VERSION)"
    log_action "✅ PostgreSQL installed ($PG_VERSION)"
else
    echo "❌ PostgreSQL not installed"
    log_action "❌ PostgreSQL not installed"
    exit 1
fi

# Check required PHP modules
REQUIRED_PHP_MODULES=("curl" "gd" "imagick" "intl" "mbstring" "pgsql" "zip" "xml" "openssl")
MISSING_MODULES=()

for module in "${REQUIRED_PHP_MODULES[@]}"; do
    if php -m | grep -qi "$module"; then
        echo "✅ PHP module '$module' installed"
        log_action "✅ PHP module '$module' installed"
    else
        echo "❌ PHP module '$module' not installed"
        log_action "❌ PHP module '$module' not installed"
        MISSING_MODULES+=("$module")
    fi
done

# If there are missing modules, exit
if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    echo "❌ Missing PHP modules: ${MISSING_MODULES[*]}"
    log_action "❌ Missing PHP modules: ${MISSING_MODULES[*]}"
    exit 1
fi

# Check if Composer is installed
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | head -1)
    echo "✅ Composer installed ($COMPOSER_VERSION)"
    log_action "✅ Composer installed ($COMPOSER_VERSION)"
else
    echo "ℹ️ Composer not installed (optional)"
    log_action "ℹ️ Composer not installed (optional)"
fi

# 2. Start required services
echo ""
echo "2. Starting required services..."
log_action "2. Starting required services..."

# Start PostgreSQL
echo "Starting PostgreSQL..."
sudo systemctl start postgresql
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL started"
    log_action "✅ PostgreSQL started"
else
    echo "❌ Failed to start PostgreSQL"
    log_action "❌ Failed to start PostgreSQL"
    exit 1
fi

# Start Apache
echo "Starting Apache..."
sudo systemctl start apache2
if systemctl is-active --quiet apache2; then
    echo "✅ Apache started"
    log_action "✅ Apache started"
else
    echo "❌ Failed to start Apache"
    log_action "❌ Failed to start Apache"
    exit 1
fi

# 3. Create Nextcloud database
echo ""
echo "3. Creating Nextcloud database..."
log_action "3. Creating Nextcloud database..."

# Create database user and database for Nextcloud
sudo -u postgres psql -c "CREATE USER nextcloud WITH PASSWORD 'nextcloud';" 2>/dev/null || echo "Database user 'nextcloud' may already exist"
sudo -u postgres psql -c "CREATE DATABASE nextcloud OWNER nextcloud;" 2>/dev/null || echo "Database 'nextcloud' may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;" 2>/dev/null || echo "Privileges may already be granted"

echo "✅ Nextcloud database created"
log_action "✅ Nextcloud database created"

# 4. Deploy Nextcloud files
echo ""
echo "4. Deploying Nextcloud files..."
log_action "4. Deploying Nextcloud files..."

# Check if Nextcloud files exist in /tmp
if [ ! -d "/tmp/nextcloud" ]; then
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
    log_action "❌ Nextcloud files not found in /tmp/nextcloud"
    exit 1
fi

# Move Nextcloud files to web directory
echo "Moving Nextcloud files to /var/www/nextcloud..."
sudo mv /tmp/nextcloud /var/www/
sudo chown -R www-data:www-data /var/www/nextcloud

echo "✅ Nextcloud files deployed to /var/www/nextcloud"
log_action "✅ Nextcloud files deployed to /var/www/nextcloud"

# 5. Configure Apache virtual host for Nextcloud
echo ""
echo "5. Configuring Apache virtual host for Nextcloud..."
log_action "5. Configuring Apache virtual host for Nextcloud..."

sudo tee /etc/apache2/sites-available/nextcloud.conf > /dev/null << 'EOL'
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud/
    ServerName cloudcurio.cc
    ServerAlias www.cloudcurio.cc

    <Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    <IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteRule ^\.well-known/host-meta /public.php?service=host-meta [QSA,L]
        RewriteRule ^\.well-known/host-meta\.json /public.php?service=host-meta-json [QSA,L]
        RewriteRule ^\.well-known/carddav /remote.php/dav/ [R=301,L]
        RewriteRule ^\.well-known/caldav /remote.php/dav/ [R=301,L]
        RewriteRule ^remote/(.*) remote.php [QSA,L]
        RewriteRule ^(build|tests|config|lib|3rdparty|templates)/.* - [R=404,L]
        RewriteRule ^(\.|autotest|occ|issue|indie|db_|console).* - [R=404,L]
    </IfModule>

    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOL

# Enable the Nextcloud site
sudo a2ensite nextcloud.conf

# Enable required Apache modules
sudo a2enmod rewrite headers env dir mime ssl

echo "✅ Nextcloud Apache virtual host configured"
log_action "✅ Nextcloud Apache virtual host configured"

# 6. Configure Nextcloud
echo ""
echo "6. Configuring Nextcloud..."
log_action "6. Configuring Nextcloud..."

# Create Nextcloud configuration directory
sudo mkdir -p /var/www/nextcloud/config

# Create basic Nextcloud config
sudo tee /var/www/nextcloud/config/config.php > /dev/null << 'EOL'
<?php
$CONFIG = array (
  'instanceid' => '',
  'passwordsalt' => '',
  'secret' => '',
  'trusted_domains' =>
  array (
    0 => 'cloudcurio.cc',
    1 => 'www.cloudcurio.cc',
    2 => 'localhost',
    3 => '127.0.0.1',
  ),
  'datadirectory' => '/var/www/nextcloud/data',
  'dbtype' => 'pgsql',
  'version' => '',
  'overwrite.cli.url' => 'http://cloudcurio.cc/nextcloud',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'nextcloud',
  'dbpassword' => 'nextcloud',
  'installed' => false,
  'log_type' => 'file',
  'logfile' => '/var/log/apache2/nextcloud.log',
  'loglevel' => 2,
  'logdateformat' => 'F d, Y H:i:s',
);
EOL

sudo chown -R www-data:www-data /var/www/nextcloud/config
echo "✅ Nextcloud configuration file created"
log_action "✅ Nextcloud configuration file created"

# 7. Set up Nextcloud data directory
echo ""
echo "7. Setting up Nextcloud data directory..."
log_action "7. Setting up Nextcloud data directory..."

sudo mkdir -p /var/www/nextcloud/data
sudo chown -R www-data:www-data /var/www/nextcloud/data
echo "✅ Nextcloud data directory created"
log_action "✅ Nextcloud data directory created"

# 8. Restart Apache
echo ""
echo "8. Restarting Apache to apply all changes..."
log_action "8. Restarting Apache to apply all changes..."
sudo systemctl restart apache2

# 9. Create documentation for Nextcloud
{
    echo ""
    echo "## Nextcloud Installation Complete"
    echo ""
    echo "### Access Information"
    echo "- URL: http://cloudcurio.cc/nextcloud"
    echo "- Database: PostgreSQL (nextcloud/nextcloud)"
    echo "- Admin User: Will be created during first access"
    echo ""
    echo "### Configuration Files"
    echo "- Main config: /var/www/nextcloud/config/config.php"
    echo "- Apache site: /etc/apache2/sites-available/nextcloud.conf"
    echo "- Data directory: /var/www/nextcloud/data"
    echo "- Log files: /var/log/apache2/nextcloud_*.log"
    echo ""
    echo "### Next Steps"
    echo "1. Access Nextcloud in your browser at http://cloudcurio.cc/nextcloud"
    echo "2. Create an admin user account"
    echo "3. Configure your storage and settings"
    echo "4. Set up SSL for secure access (optional but recommended)"
    echo ""
    echo "### Useful Commands"
    echo "- Check Apache status: sudo systemctl status apache2"
    echo "- Restart Apache: sudo systemctl restart apache2"
    echo "- Check Nextcloud logs: tail -f /var/log/apache2/nextcloud_*.log"
    echo "- Access PostgreSQL: sudo -u postgres psql nextcloud"
    echo ""
    echo "### Troubleshooting"
    echo "- If you can't access Nextcloud, check Apache configuration:"
    echo "  sudo apache2ctl configtest"
    echo "- Check Apache error logs: sudo tail -f /var/log/apache2/error.log"
    echo "- Verify PHP modules: php -m | grep -E '(pdo|gd|curl|intl|zip)'"
    echo "- Check database connection: sudo -u postgres psql -c '\\conninfo'"
} >> $DOCS_DIR/nextcloud_installation_cloudcurio.md

log_action "Nextcloud installation and configuration complete!"
echo ""
echo "=== Nextcloud Installation and Configuration Complete ==="
echo "Documentation created in $DOCS_DIR/nextcloud_installation_cloudcurio.md"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud in your browser at http://cloudcurio.cc/nextcloud"
echo "2. Create an admin user account"
echo "3. Configure your storage and settings"
echo "4. Set up Cloudflare for SSL and access controls"
echo ""
echo "Cloudflare Setup Instructions:"
echo "============================="
echo "1. Log in to your Cloudflare dashboard"
echo "2. Add cloudcurio.cc to Cloudflare if not already added"
echo "3. Set up DNS records for cloudcurio.cc pointing to your server"
echo "4. Enable SSL/TLS encryption (Full or Full (strict))"
echo "5. Enable 'Always Use HTTPS' in SSL/TLS > Edge Certificates"
echo "6. Configure Cloudflare Access for authentication"
echo "7. Set up Cloudflare Tunnel for secure access (optional)"
echo "8. Enable Cloudflare Analytics for monitoring"
echo "9. Configure Firewall Rules (WAF) for additional protection"
echo "10. Set up Rate Limiting to prevent abuse"