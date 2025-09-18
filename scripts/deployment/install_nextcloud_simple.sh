#!/bin/bash

# Simplified Nextcloud Installation Script
# This script installs Nextcloud with all prerequisites already met

echo "=== Simplified Nextcloud Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Simplified Nextcloud Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/nextcloud_simple_install.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_simple_install.md
}

# Check prerequisites
log_action "Checking prerequisites..."

# Check if Apache is installed
if ! command -v apache2 &> /dev/null; then
    echo "❌ Apache is not installed. Please install Apache first."
    log_action "❌ Apache is not installed"
    exit 1
else
    echo "✅ Apache is installed"
    log_action "✅ Apache is installed ($(apache2 -v | head -1))"
fi

# Check if PHP is installed
if ! command -v php &> /dev/null; then
    echo "❌ PHP is not installed. Please install PHP first."
    log_action "❌ PHP is not installed"
    exit 1
else
    echo "✅ PHP is installed"
    log_action "✅ PHP is installed ($(php -v | head -1))"
fi

# Check if required PHP modules are installed
REQUIRED_PHP_MODULES=("curl" "gd" "imagick" "intl" "mbstring" "pgsql" "zip" "xml")
MISSING_MODULES=()

for module in "${REQUIRED_PHP_MODULES[@]}"; do
    if php -m | grep -qi "$module"; then
        echo "✅ PHP module '$module' is installed"
        log_action "✅ PHP module '$module' is installed"
    else
        echo "❌ PHP module '$module' is not installed"
        log_action "❌ PHP module '$module' is not installed"
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
if ! command -v composer &> /dev/null; then
    echo "❌ Composer is not installed. Please install Composer first."
    log_action "❌ Composer is not installed"
    exit 1
else
    echo "✅ Composer is installed"
    log_action "✅ Composer is installed ($(composer --version | head -1))"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL first."
    log_action "❌ PostgreSQL is not installed"
    exit 1
else
    echo "✅ PostgreSQL is installed"
    log_action "✅ PostgreSQL is installed ($(psql --version | head -1))"
fi

# 1. Create Nextcloud database
log_action "Creating Nextcloud database..."
echo ""
echo "1. Creating Nextcloud database..."

# Create database user and database for Nextcloud
sudo -u postgres psql -c "CREATE USER nextcloud WITH PASSWORD 'nextcloud';" 2>/dev/null || echo "Database user 'nextcloud' may already exist"
sudo -u postgres psql -c "CREATE DATABASE nextcloud OWNER nextcloud;" 2>/dev/null || echo "Database 'nextcloud' may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;" 2>/dev/null || echo "Privileges may already be granted"

echo "✅ Nextcloud database created"
log_action "✅ Nextcloud database created"

# 2. Download and install Nextcloud
log_action "Downloading Nextcloud..."
echo ""
echo "2. Downloading Nextcloud..."

# Create directory for Nextcloud
sudo mkdir -p /var/www/nextcloud

# Download latest Nextcloud release
cd /tmp
if [ ! -f latest.tar.bz2 ]; then
    wget https://download.nextcloud.com/server/releases/latest.tar.bz2
fi

# Extract Nextcloud
tar -xjf latest.tar.bz2
sudo mv nextcloud/* /var/www/nextcloud/
sudo chown -R www-data:www-data /var/www/nextcloud

echo "✅ Nextcloud downloaded and extracted"
log_action "✅ Nextcloud downloaded and extracted"

# 3. Configure Apache virtual host for Nextcloud
log_action "Configuring Apache virtual host for Nextcloud..."
echo ""
echo "3. Configuring Apache virtual host for Nextcloud..."

sudo bash -c "cat > /etc/apache2/sites-available/nextcloud.conf" << 'EOL'
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud/
    ServerName nextcloud.local

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

# 4. Configure Nextcloud trusted domains
log_action "Configuring Nextcloud trusted domains..."
echo ""
echo "4. Configuring Nextcloud trusted domains..."

# Create Nextcloud configuration directory
sudo mkdir -p /var/www/nextcloud/config

# Create basic Nextcloud config
sudo bash -c "cat > /var/www/nextcloud/config/config.php" << 'EOL'
<?php
$CONFIG = array (
  'instanceid' => '',
  'passwordsalt' => '',
  'secret' => '',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => '127.0.0.1',
    2 => 'nextcloud.local',
  ),
  'datadirectory' => '/var/www/nextcloud/data',
  'dbtype' => 'pgsql',
  'version' => '',
  'overwrite.cli.url' => 'http://nextcloud.local',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'nextcloud',
  'dbpassword' => 'nextcloud',
  'installed' => false,
);
EOL

sudo chown -R www-data:www-data /var/www/nextcloud/config
echo "✅ Nextcloud configuration file created"
log_action "✅ Nextcloud configuration file created"

# 5. Set up Nextcloud data directory
log_action "Setting up Nextcloud data directory..."
echo ""
echo "5. Setting up Nextcloud data directory..."

sudo mkdir -p /var/www/nextcloud/data
sudo chown -R www-data:www-data /var/www/nextcloud/data
echo "✅ Nextcloud data directory created"
log_action "✅ Nextcloud data directory created"

# 6. Restart Apache
log_action "Restarting Apache to apply all changes..."
echo ""
echo "6. Restarting Apache to apply all changes..."
sudo systemctl restart apache2

# 7. Create documentation for Nextcloud
{
    echo ""
    echo "## Nextcloud Installation Complete"
    echo ""
    echo "### Access Information"
    echo "- URL: http://nextcloud.local or http://localhost/nextcloud"
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
    echo "1. Access Nextcloud in your browser at http://nextcloud.local"
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
} >> $DOCS_DIR/nextcloud_simple_install.md

log_action "Nextcloud installation complete!"
echo ""
echo "=== Nextcloud Installation Complete ==="
echo "Documentation created in $DOCS_DIR/nextcloud_simple_install.md"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud in your browser at http://nextcloud.local"
echo "2. Create an admin user account"
echo "3. Configure your storage and settings"
echo "4. Set up SSL for secure access (optional but recommended)"