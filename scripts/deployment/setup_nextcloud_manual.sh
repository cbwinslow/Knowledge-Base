#!/bin/bash

# Nextcloud Setup Script
# This script moves Nextcloud files to the correct location and sets up Apache

echo "=== Nextcloud Setup Script ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud Setup Script"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Setup Log"
    echo ""
} > $DOCS_DIR/nextcloud_setup.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_setup.md
}

echo "Setting up Nextcloud..."
log_action "Setting up Nextcloud"

# Check if Apache is installed
if ! command -v apache2 &> /dev/null; then
    echo "❌ Apache is not installed"
    log_action "❌ Apache is not installed"
    echo "Please install Apache first:"
    echo "sudo apt install apache2"
    exit 1
else
    echo "✅ Apache is installed"
    log_action "✅ Apache is installed"
fi

# Check if PHP is installed
if ! command -v php &> /dev/null; then
    echo "❌ PHP is not installed"
    log_action "❌ PHP is not installed"
    echo "Please install PHP first:"
    echo "sudo apt install php"
    exit 1
else
    echo "✅ PHP is installed"
    log_action "✅ PHP is installed"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed"
    log_action "❌ PostgreSQL is not installed"
    echo "Please install PostgreSQL first:"
    echo "sudo apt install postgresql"
    exit 1
else
    echo "✅ PostgreSQL is installed"
    log_action "✅ PostgreSQL is installed"
fi

# 1. Move Nextcloud files to web directory
echo ""
echo "1. Moving Nextcloud files to web directory..."
log_action "1. Moving Nextcloud files to web directory..."

if [ -d "/tmp/nextcloud" ]; then
    # Move Nextcloud files to web directory (requires sudo)
    echo "Moving Nextcloud files to /var/www/nextcloud..."
    echo "Please run the following command manually with sudo:"
    echo "sudo mv /tmp/nextcloud /var/www/"
    echo "sudo chown -R www-data:www-data /var/www/nextcloud"
    
    log_action "Move Nextcloud files to /var/www/nextcloud (requires sudo):"
    log_action "sudo mv /tmp/nextcloud /var/www/"
    log_action "sudo chown -R www-data:www-data /var/www/nextcloud"
else
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
    log_action "❌ Nextcloud files not found in /tmp/nextcloud"
    exit 1
fi

# 2. Create Nextcloud database
echo ""
echo "2. Creating Nextcloud database..."
log_action "2. Creating Nextcloud database..."

echo "Creating database user and database for Nextcloud..."
echo "Please run the following commands manually with sudo:"
echo "sudo -u postgres psql -c \"CREATE USER nextcloud WITH PASSWORD 'nextcloud';\""
echo "sudo -u postgres psql -c \"CREATE DATABASE nextcloud OWNER nextcloud;\""
echo "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;\""

log_action "Create database user and database for Nextcloud (requires sudo):"
log_action "sudo -u postgres psql -c \"CREATE USER nextcloud WITH PASSWORD 'nextcloud';\""
log_action "sudo -u postgres psql -c \"CREATE DATABASE nextcloud OWNER nextcloud;\""
log_action "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;\""

# 3. Configure Apache virtual host for Nextcloud
echo ""
echo "3. Configuring Apache virtual host for Nextcloud..."
log_action "3. Configuring Apache virtual host for Nextcloud..."

echo "Creating Apache virtual host configuration..."
echo "Please run the following commands manually with sudo:"

# Create the Apache virtual host configuration
cat > /tmp/nextcloud_apache.conf << 'EOL'
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud/
    ServerName localhost

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

echo "sudo cp /tmp/nextcloud_apache.conf /etc/apache2/sites-available/nextcloud.conf"
echo "sudo a2ensite nextcloud.conf"
echo "sudo a2enmod rewrite headers env dir mime ssl"
echo "sudo systemctl restart apache2"

log_action "Create Apache virtual host configuration (requires sudo):"
log_action "sudo cp /tmp/nextcloud_apache.conf /etc/apache2/sites-available/nextcloud.conf"
log_action "sudo a2ensite nextcloud.conf"
log_action "sudo a2enmod rewrite headers env dir mime ssl"
log_action "sudo systemctl restart apache2"

# 4. Create Nextcloud configuration file
echo ""
echo "4. Creating Nextcloud configuration file..."
log_action "4. Creating Nextcloud configuration file..."

echo "Creating Nextcloud configuration file..."
echo "Please run the following commands manually with sudo:"

# Create the Nextcloud configuration file
cat > /tmp/nextcloud_config.php << 'EOL'
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

echo "sudo mkdir -p /var/www/nextcloud/config"
echo "sudo cp /tmp/nextcloud_config.php /var/www/nextcloud/config/config.php"
echo "sudo chown -R www-data:www-data /var/www/nextcloud/config"

log_action "Create Nextcloud configuration file (requires sudo):"
log_action "sudo mkdir -p /var/www/nextcloud/config"
log_action "sudo cp /tmp/nextcloud_config.php /var/www/nextcloud/config/config.php"
log_action "sudo chown -R www-data:www-data /var/www/nextcloud/config"

# 5. Set up Nextcloud data directory
echo ""
echo "5. Setting up Nextcloud data directory..."
log_action "5. Setting up Nextcloud data directory..."

echo "Setting up Nextcloud data directory..."
echo "Please run the following commands manually with sudo:"
echo "sudo mkdir -p /var/www/nextcloud/data"
echo "sudo chown -R www-data:www-data /var/www/nextcloud/data"

log_action "Set up Nextcloud data directory (requires sudo):"
log_action "sudo mkdir -p /var/www/nextcloud/data"
log_action "sudo chown -R www-data:www-data /var/www/nextcloud/data"

# 6. Final instructions
echo ""
echo "=== Nextcloud Setup Complete ==="
log_action "=== Nextcloud Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Run all the sudo commands listed above"
echo "2. Access Nextcloud in your browser at http://localhost/nextcloud"
echo "3. Complete the initial setup wizard"
echo "4. Create an admin user account"
echo "5. Configure your storage and settings"
echo "6. Set up SSL for secure access (recommended)"
echo "7. Configure Cloudflare Tunnel using the instructions in cloudflare_tunnel_helper.sh"
echo ""
echo "Documentation created in $DOCS_DIR/nextcloud_setup.md"

{
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Run all the sudo commands listed above"
    echo "2. Access Nextcloud in your browser at http://localhost/nextcloud"
    echo "3. Complete the initial setup wizard"
    echo "4. Create an admin user account"
    echo "5. Configure your storage and settings"
    echo "6. Set up SSL for secure access (recommended)"
    echo "7. Configure Cloudflare Tunnel using the instructions in cloudflare_tunnel_helper.sh"
    echo ""
    echo "## Useful Commands"
    echo ""
    echo "- Check Apache status: sudo systemctl status apache2"
    echo "- Restart Apache: sudo systemctl restart apache2"
    echo "- Check Nextcloud logs: tail -f /var/log/apache2/nextcloud_*.log"
    echo "- Access PostgreSQL: sudo -u postgres psql nextcloud"
    echo "- Run Nextcloud CLI commands: sudo -u www-data php /var/www/nextcloud/occ"
    echo ""
    echo "## Troubleshooting"
    echo ""
    echo "- If you can't access Nextcloud, check Apache configuration:"
    echo "  sudo apache2ctl configtest"
    echo "- Check Apache error logs: sudo tail -f /var/log/apache2/error.log"
    echo "- Verify PHP modules: php -m | grep -E '(pdo|gd|curl|intl|zip)'"
    echo "- Check database connection: sudo -u postgres psql -c '\\conninfo'"
    echo "- Verify file permissions: ls -la /var/www/nextcloud/"
    echo ""
    echo "## Security Recommendations"
    echo ""
    echo "- Use strong, unique passwords for all accounts"
    echo "- Enable two-factor authentication after setup"
    echo "- Keep Nextcloud updated regularly"
    echo "- Monitor logs for suspicious activity"
    echo "- Use SSL/TLS for secure connections"
    echo "- Restrict access to trusted IP addresses when possible"
    echo "- Regularly backup your data"
    echo "- Review and update security settings periodically"
} >> $DOCS_DIR/nextcloud_setup.md

echo "Setup instructions complete!"