#!/bin/bash

# Simple Nextcloud Installation Script
# This script sets up Nextcloud with Apache and PostgreSQL

echo "=== Nextcloud Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Steps"
    echo ""
} > $DOCS_DIR/nextcloud_install_simple.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_install_simple.md
}

# Check if required packages are installed
log_action "Checking for required packages..."

# For Apache
if command -v apache2 &> /dev/null; then
    log_action "Apache is installed"
else
    log_action "Apache is not installed - you'll need to install it with: sudo apt install apache2"
fi

# For PHP
if command -v php &> /dev/null; then
    log_action "PHP is installed"
else
    log_action "PHP is not installed - you'll need to install it with: sudo apt install php"
fi

# For PostgreSQL
if command -v psql &> /dev/null; then
    log_action "PostgreSQL is installed"
else
    log_action "PostgreSQL is not installed - you'll need to install it with: sudo apt install postgresql"
fi

# Move Nextcloud files to web directory (this will need sudo)
log_action "Nextcloud files are in /tmp/nextcloud"
log_action "To move them to web directory, run: sudo mv /tmp/nextcloud /var/www/"

# Set up database (this will need sudo and PostgreSQL user)
log_action "Create database with:"
log_action "sudo -u postgres psql -c \"CREATE USER nextcloud WITH PASSWORD 'nextcloud';\""
log_action "sudo -u postgres psql -c \"CREATE DATABASE nextcloud OWNER nextcloud;\""

# Set permissions (this will need sudo)
log_action "Set permissions with:"
log_action "sudo chown -R www-data:www-data /var/www/nextcloud"

# Create Apache configuration (this will need sudo)
log_action "Create Apache virtual host config at /etc/apache2/sites-available/nextcloud.conf:"
cat >> $DOCS_DIR/nextcloud_install_simple.md << 'EOL'

```
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
```

Enable the site with:
sudo a2ensite nextcloud.conf
sudo systemctl reload apache2
EOL

# Create Nextcloud configuration (this can be done after installation)
log_action "After installation, create /var/www/nextcloud/config/config.php with your database settings"

{
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Move the Nextcloud files:"
    echo "   sudo mv /tmp/nextcloud /var/www/"
    echo ""
    echo "2. Create the database:"
    echo "   sudo -u postgres psql -c \"CREATE USER nextcloud WITH PASSWORD 'nextcloud';\""
    echo "   sudo -u postgres psql -c \"CREATE DATABASE nextcloud OWNER nextcloud;\""
    echo ""
    echo "3. Set permissions:"
    echo "   sudo chown -R www-data:www-data /var/www/nextcloud"
    echo ""
    echo "4. Configure Apache virtual host (see above)"
    echo ""
    echo "5. Enable the site:"
    echo "   sudo a2ensite nextcloud.conf"
    echo "   sudo systemctl reload apache2"
    echo ""
    echo "6. Access Nextcloud at http://localhost/nextcloud to complete installation"
    echo ""
} >> $DOCS_DIR/nextcloud_install_simple.md

log_action "Installation preparation complete!"
echo ""
echo "=== Installation Preparation Complete ==="
echo "Detailed instructions are in $DOCS_DIR/nextcloud_install_simple.md"
echo ""
echo "Next steps:"
echo "1. Review the instructions in the documentation file"
echo "2. Run the sudo commands as listed in the documentation"
echo "3. Complete the web-based installation at http://localhost/nextcloud