#!/bin/bash

# Nextcloud Official Installation Script
# This script installs the official Nextcloud release with Apache and PostgreSQL

echo "=== Nextcloud Official Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud Official Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/nextcloud_install.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_install.md
}

# 1. Check prerequisites
log_action "Checking prerequisites..."

# Check if Apache is installed
if ! command -v apache2 &> /dev/null; then
    echo "Apache is not installed. Installing Apache..."
    log_action "Installing Apache web server..."
    sudo apt install -y apache2
else
    echo "Apache is already installed."
    log_action "Apache web server already installed"
fi

# Check if PHP is installed
if ! command -v php &> /dev/null; then
    echo "PHP is not installed. Installing PHP 8.3 and required modules..."
    log_action "Installing PHP 8.3 and required modules..."
    sudo apt install -y \
        php8.3 \
        php8.3-cli \
        php8.3-common \
        php8.3-curl \
        php8.3-gd \
        php8.3-imagick \
        php8.3-intl \
        php8.3-mbstring \
        php8.3-mysql \
        php8.3-opcache \
        php8.3-pgsql \
        php8.3-readline \
        php8.3-xml \
        php8.3-zip \
        php8.3-bz2 \
        php8.3-fpm \
        libapache2-mod-php8.3
else
    echo "PHP is already installed."
    log_action "PHP already installed"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL is not installed. Installing PostgreSQL..."
    log_action "Installing PostgreSQL database..."
    sudo apt install -y postgresql postgresql-contrib
else
    echo "PostgreSQL is already installed."
    log_action "PostgreSQL database already installed"
fi

# 2. Configure Apache for Nextcloud
log_action "Configuring Apache for Nextcloud..."

# Enable required Apache modules
sudo a2enmod rewrite headers env dir mime ssl
sudo a2enmod php8.3

# Restart Apache to apply changes
sudo systemctl restart apache2
log_action "Restarted Apache with Nextcloud modules enabled"

# 3. Create Nextcloud database
log_action "Creating Nextcloud database..."

# Create database user and database for Nextcloud
sudo -u postgres psql -c "CREATE USER nextcloud WITH PASSWORD 'nextcloud';"
sudo -u postgres psql -c "CREATE DATABASE nextcloud OWNER nextcloud;"
log_action "Created Nextcloud database and user"

# 4. Download and install Nextcloud
log_action "Downloading Nextcloud..."

# Create directory for Nextcloud
sudo mkdir -p /var/www/nextcloud

# Download latest Nextcloud release
cd /tmp
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjf latest.tar.bz2
sudo mv nextcloud/* /var/www/nextcloud/
sudo chown -R www-data:www-data /var/www/nextcloud
log_action "Downloaded and extracted Nextcloud"

# 5. Configure Apache virtual host for Nextcloud
log_action "Configuring Apache virtual host for Nextcloud..."

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
log_action "Created and enabled Nextcloud Apache virtual host"

# 6. Configure Nextcloud trusted domains
log_action "Configuring Nextcloud trusted domains..."

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
log_action "Created Nextcloud configuration file"

# 7. Set up Nextcloud data directory
log_action "Setting up Nextcloud data directory..."

sudo mkdir -p /var/www/nextcloud/data
sudo chown -R www-data:www-data /var/www/nextcloud/data
log_action "Created Nextcloud data directory"

# 8. Restart Apache
log_action "Restarting Apache to apply all changes..."
sudo systemctl restart apache2

# 9. Create documentation for Nextcloud
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
} >> $DOCS_DIR/nextcloud_install.md

log_action "Nextcloud installation complete!"
echo ""
echo "=== Nextcloud Installation Complete ==="
echo "Documentation created in $DOCS_DIR/nextcloud_install.md"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud in your browser at http://nextcloud.local"
echo "2. Create an admin user account"
echo "3. Configure your storage and settings"
echo "4. Set up SSL for secure access (optional but recommended)"