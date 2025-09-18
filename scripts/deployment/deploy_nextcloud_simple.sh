#!/bin/bash

# Simple Nextcloud Deployment Script
# This script moves Nextcloud files to the correct location and sets up basic configuration

echo "=== Simple Nextcloud Deployment Script ==="
echo ""

# Check if Nextcloud files exist in temporary location
if [ ! -d "/tmp/nextcloud" ]; then
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
    echo "Please ensure Nextcloud files are in /tmp/nextcloud before running this script"
    exit 1
fi

echo "✅ Nextcloud files found in /tmp/nextcloud"
echo ""

# Move Nextcloud files to web directory
echo "Moving Nextcloud files to /var/www/nextcloud..."
sudo mv /tmp/nextcloud /var/www/

# Set proper ownership
echo "Setting proper ownership for Nextcloud files..."
sudo chown -R www-data:www-data /var/www/nextcloud

# Create Nextcloud directories
echo "Creating Nextcloud directories..."
sudo mkdir -p /var/www/nextcloud/config
sudo mkdir -p /var/www/nextcloud/data

# Set proper ownership for directories
sudo chown -R www-data:www-data /var/www/nextcloud/config
sudo chown -R www-data:www-data /var/www/nextcloud/data

# Create basic Nextcloud configuration
echo "Creating basic Nextcloud configuration..."
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
    3 => 'cloudcurio.cc',
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

# Set proper ownership for config file
sudo chown www-data:www-data /var/www/nextcloud/config/config.php

# Restart Apache to apply changes
echo "Restarting Apache to apply all changes..."
sudo systemctl restart apache2

echo ""
echo "=== Nextcloud Deployment Complete ==="
echo ""
echo "Nextcloud has been deployed to /var/www/nextcloud"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud in your browser at http://localhost/nextcloud"
echo "2. Complete the initial setup wizard"
echo "3. Configure your storage and settings"
echo "4. Set up Cloudflare Tunnel using the instructions in:"
echo "   /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo ""
echo "Important notes:"
echo "- You'll need to complete the web-based setup at http://localhost/nextcloud"
echo "- After setup, configure Cloudflare Tunnel for external access"
echo "- Ensure proper security measures are in place"
echo "- Regularly backup your Nextcloud data"