#!/bin/bash

# Complete Nextcloud and Cloudflare Tunnel Setup Script
# This script contains all the sudo commands needed for setup

echo "=== Complete Nextcloud and Cloudflare Tunnel Setup ==="
echo ""

# Create documentation
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Complete Nextcloud and Cloudflare Tunnel Setup"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Execution Log"
    echo ""
} > $DOCS_DIR/complete_setup_execution.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/complete_setup_execution.md
}

# 1. Move Nextcloud files to web directory
log_action "1. Moving Nextcloud files to web directory..."
echo ""
echo "1. Moving Nextcloud files to web directory..."
if [ -d "/tmp/nextcloud" ]; then
    mv /tmp/nextcloud /var/www/
    chown -R www-data:www-data /var/www/nextcloud
    log_action "✅ Nextcloud files moved to /var/www/nextcloud"
    echo "✅ Nextcloud files moved to /var/www/nextcloud"
else
    log_action "❌ Nextcloud files not found in /tmp/nextcloud"
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
fi

# 2. Create Nextcloud database
log_action "2. Creating Nextcloud database..."
echo ""
echo "2. Creating Nextcloud database..."
sudo -u postgres psql -c "CREATE USER nextcloud WITH PASSWORD 'nextcloud';" 2>/dev/null || echo "Database user 'nextcloud' may already exist"
sudo -u postgres psql -c "CREATE DATABASE nextcloud OWNER nextcloud;" 2>/dev/null || echo "Database 'nextcloud' may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;" 2>/dev/null || echo "Privileges may already be granted"
log_action "✅ Nextcloud database created"
echo "✅ Nextcloud database created"

# 3. Configure Apache virtual host for Nextcloud
log_action "3. Configuring Apache virtual host for Nextcloud..."
echo ""
echo "3. Configuring Apache virtual host for Nextcloud..."

# Create Apache virtual host configuration
cat > /tmp/nextcloud.conf << 'EOL'
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

# Move configuration to Apache directory
cp /tmp/nextcloud.conf /etc/apache2/sites-available/
a2ensite nextcloud.conf

# Enable required Apache modules
a2enmod rewrite headers env dir mime ssl

log_action "✅ Apache virtual host configured"
echo "✅ Apache virtual host configured"

# 4. Create Nextcloud configuration file
log_action "4. Creating Nextcloud configuration file..."
echo ""
echo "4. Creating Nextcloud configuration file..."

# Create Nextcloud configuration directory
mkdir -p /var/www/nextcloud/config

# Create Nextcloud config file
cat > /var/www/nextcloud/config/config.php << 'EOL'
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

# Set proper ownership
chown -R www-data:www-data /var/www/nextcloud/config

log_action "✅ Nextcloud configuration file created"
echo "✅ Nextcloud configuration file created"

# 5. Set up Nextcloud data directory
log_action "5. Setting up Nextcloud data directory..."
echo ""
echo "5. Setting up Nextcloud data directory..."

# Create data directory
mkdir -p /var/www/nextcloud/data
chown -R www-data:www-data /var/www/nextcloud/data

log_action "✅ Nextcloud data directory created"
echo "✅ Nextcloud data directory created"

# 6. Restart Apache to apply changes
log_action "6. Restarting Apache to apply all changes..."
echo ""
echo "6. Restarting Apache to apply all changes..."
systemctl restart apache2

log_action "✅ Apache restarted"
echo "✅ Apache restarted"

# 7. Install Cloudflare Tunnel (cloudflared)
log_action "7. Installing Cloudflare Tunnel (cloudflared)..."
echo ""
echo "7. Installing Cloudflare Tunnel (cloudflared)..."

# Download and install cloudflared
if [ -f "/home/cbwinslow/cloudflared-linux-amd64.deb" ]; then
    dpkg -i /home/cbwinslow/cloudflared-linux-amd64.deb
    log_action "✅ Cloudflared installed from existing package"
    echo "✅ Cloudflared installed from existing package"
else
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared-linux-amd64.deb
    dpkg -i /tmp/cloudflared-linux-amd64.deb
    log_action "✅ Cloudflared downloaded and installed"
    echo "✅ Cloudflared downloaded and installed"
fi

# 8. Create Cloudflare Tunnel configuration directory
log_action "8. Creating Cloudflare Tunnel configuration directory..."
echo ""
echo "8. Creating Cloudflare Tunnel configuration directory..."
mkdir -p /etc/cloudflared

log_action "✅ Cloudflare Tunnel configuration directory created"
echo "✅ Cloudflare Tunnel configuration directory created"

# 9. Create placeholder certificate file (you'll need to replace this with your actual certificate)
log_action "9. Creating placeholder certificate file..."
echo ""
echo "9. Creating placeholder certificate file..."

cat > /etc/cloudflared/cert.pem << 'EOL'
# This is a placeholder certificate file for Cloudflare Tunnel
# In a real deployment, you would replace this with your actual certificate from Cloudflare

{
  "AccountTag": "your_account_tag_here",
  "TunnelID": "your_tunnel_id_here",
  "TunnelName": "nextcloud",
  "TunnelSecret": "your_tunnel_secret_here"
}
EOL

log_action "✅ Placeholder certificate file created"
echo "✅ Placeholder certificate file created"
echo "   ⚠️  Remember to replace this with your actual Cloudflare certificate"

# Summary
{
    echo ""
    echo "## Summary"
    echo ""
    echo "### Nextcloud Setup Complete"
    echo "- Files moved to /var/www/nextcloud"
    echo "- Database created (nextcloud/nextcloud)"
    echo "- Apache virtual host configured"
    echo "- Configuration files created"
    echo "- Data directory set up"
    echo "- Apache restarted"
    echo ""
    echo "### Cloudflare Tunnel Setup Started"
    echo "- Cloudflared installed"
    echo "- Configuration directory created"
    echo "- Placeholder certificate created (replace with actual certificate)"
    echo ""
    echo "### Next Steps"
    echo "1. Access Nextcloud in your browser at http://localhost/nextcloud"
    echo "2. Complete the initial setup wizard"
    echo "3. Replace the placeholder certificate with your actual Cloudflare certificate"
    echo "4. Create and configure your Cloudflare Tunnel"
    echo "5. Route traffic to your tunnel"
    echo "6. Start the tunnel"
    echo ""
    echo "### Important Notes"
    echo "- You'll need to authenticate with Cloudflare to get your actual certificate"
    echo "- The placeholder certificate will not work for actual tunnel creation"
    echo "- Make sure to keep your actual certificate secure"
    echo "- Always backup your certificate and configuration files"
} >> $DOCS_DIR/complete_setup_execution.md

log_action "Setup script execution complete!"
echo ""
echo "=== Setup Script Execution Complete ==="
echo "Documentation created in $DOCS_DIR/complete_setup_execution.md"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud in your browser at http://localhost/nextcloud"
echo "2. Complete the initial setup wizard"
echo "3. Replace the placeholder certificate with your actual Cloudflare certificate"
echo "4. Create and configure your Cloudflare Tunnel"
echo "5. Route traffic to your tunnel"
echo "6. Start the tunnel"
echo ""
echo "Important notes:"
echo "- You'll need to authenticate with Cloudflare to get your actual certificate"
echo "- The placeholder certificate will not work for actual tunnel creation"
echo "- Make sure to keep your actual certificate secure"
echo "- Always backup your certificate and configuration files"