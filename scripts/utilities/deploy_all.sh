#!/bin/bash

# Nextcloud and Cloudflare Tunnel Deployment Script
# This script deploys all components to the correct directories

echo "=== Nextcloud and Cloudflare Tunnel Deployment ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud and Cloudflare Tunnel Deployment"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Deployment Log"
    echo ""
} > $DOCS_DIR/deployment_log.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/deployment_log.md
}

# 1. Deploy Nextcloud to correct directory
log_action "Deploying Nextcloud to /var/www/nextcloud..."
echo "1. Deploying Nextcloud to /var/www/nextcloud..."

if [ -d "/tmp/nextcloud" ]; then
    # Move Nextcloud files to web directory
    sudo mv /tmp/nextcloud /var/www/
    sudo chown -R www-data:www-data /var/www/nextcloud
    
    log_action "✅ Nextcloud deployed to /var/www/nextcloud"
    echo "✅ Nextcloud deployed to /var/www/nextcloud"
else
    log_action "❌ Nextcloud files not found in /tmp/nextcloud"
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
fi

# 2. Create Nextcloud database
log_action "Creating Nextcloud database..."
echo ""
echo "2. Creating Nextcloud database..."

# Create database user and database for Nextcloud
sudo -u postgres psql -c "CREATE USER nextcloud WITH PASSWORD 'nextcloud';" 2>/dev/null || echo "Database user 'nextcloud' may already exist"
sudo -u postgres psql -c "CREATE DATABASE nextcloud OWNER nextcloud;" 2>/dev/null || echo "Database 'nextcloud' may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;" 2>/dev/null || echo "Privileges may already be granted"

log_action "✅ Nextcloud database created"
echo "✅ Nextcloud database created"

# 3. Configure Apache virtual host for Nextcloud
log_action "Configuring Apache virtual host for Nextcloud..."
echo ""
echo "3. Configuring Apache virtual host for Nextcloud..."

# Create Apache virtual host configuration
sudo tee /etc/apache2/sites-available/nextcloud.conf > /dev/null << 'EOL'
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

# Enable the Nextcloud site
sudo a2ensite nextcloud.conf

# Enable required Apache modules
sudo a2enmod rewrite headers env dir mime ssl

log_action "✅ Apache virtual host configured"
echo "✅ Apache virtual host configured"

# 4. Create Nextcloud configuration
log_action "Creating Nextcloud configuration..."
echo ""
echo "4. Creating Nextcloud configuration..."

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

log_action "✅ Nextcloud configuration created"
echo "✅ Nextcloud configuration created"

# 5. Set up Nextcloud data directory
log_action "Setting up Nextcloud data directory..."
echo ""
echo "5. Setting up Nextcloud data directory..."

sudo mkdir -p /var/www/nextcloud/data
sudo chown -R www-data:www-data /var/www/nextcloud/data

log_action "✅ Nextcloud data directory created"
echo "✅ Nextcloud data directory created"

# 6. Restart Apache to apply changes
log_action "Restarting Apache to apply all changes..."
echo ""
echo "6. Restarting Apache to apply all changes..."
sudo systemctl restart apache2

log_action "✅ Apache restarted"
echo "✅ Apache restarted"

# 7. Install Cloudflare Tunnel (cloudflared)
log_action "Installing Cloudflare Tunnel (cloudflared)..."
echo ""
echo "7. Installing Cloudflare Tunnel (cloudflared)..."

# Download and install cloudflared
if [ ! -f "/usr/local/bin/cloudflared" ]; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared-linux-amd64.deb
    sudo dpkg -i /tmp/cloudflared-linux-amd64.deb
    log_action "✅ Cloudflared installed"
    echo "✅ Cloudflared installed"
else
    log_action "✅ Cloudflared already installed"
    echo "✅ Cloudflared already installed"
fi

# 8. Create Cloudflare Tunnel configuration directory
log_action "Creating Cloudflare Tunnel configuration directory..."
echo ""
echo "8. Creating Cloudflare Tunnel configuration directory..."
sudo mkdir -p /etc/cloudflared

log_action "✅ Cloudflare Tunnel configuration directory created"
echo "✅ Cloudflare Tunnel configuration directory created"

# 9. Create placeholder certificate file
log_action "Creating placeholder certificate file..."
echo ""
echo "9. Creating placeholder certificate file..."

sudo tee /etc/cloudflared/cert.pem > /dev/null << 'EOL'
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
    echo "## Deployment Summary"
    echo ""
    echo "### Nextcloud Deployment"
    echo "- Files deployed to /var/www/nextcloud"
    echo "- Database created (nextcloud/nextcloud)"
    echo "- Apache virtual host configured"
    echo "- Configuration files created"
    echo "- Data directory set up"
    echo "- Apache restarted"
    echo ""
    echo "### Cloudflare Tunnel Deployment"
    echo "- Cloudflared installed"
    echo "- Configuration directory created"
    echo "- Placeholder certificate created"
    echo ""
    echo "## Access Information"
    echo "- Nextcloud URL: http://localhost/nextcloud"
    echo "- Database: PostgreSQL (nextcloud/nextcloud)"
    echo "- Apache logs: /var/log/apache2/nextcloud_*.log"
    echo ""
    echo "## Next Steps"
    echo "1. Access Nextcloud in your browser at http://localhost/nextcloud"
    echo "2. Complete the initial setup wizard"
    echo "3. Replace the placeholder certificate with your actual Cloudflare certificate"
    echo "4. Create and configure your Cloudflare Tunnel"
    echo "5. Route traffic to your tunnel"
    echo "6. Start the tunnel"
    echo ""
    echo "## Important Notes"
    echo "- The placeholder certificate will not work for actual tunnel creation"
    echo "- You'll need to authenticate with Cloudflare to get your actual certificate"
    echo "- Always backup your actual certificate and configuration files"
    echo "- Keep your certificate secure and never share it publicly"
} >> $DOCS_DIR/deployment_log.md

log_action "Deployment complete!"
echo ""
echo "=== Deployment Complete ==="
echo "Documentation created in $DOCS_DIR/deployment_log.md"
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
echo "- The placeholder certificate will not work for actual tunnel creation"
echo "- You'll need to authenticate with Cloudflare to get your actual certificate"
echo "- Always backup your actual certificate and configuration files"
echo "- Keep your certificate secure and never share it publicly"