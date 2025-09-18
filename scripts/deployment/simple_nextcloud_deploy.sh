#!/bin/bash

# Simple Nextcloud Deployment Script
# This script moves Nextcloud files to the correct directory with sudo

echo "=== Simple Nextcloud Deployment ==="
echo ""

# Move Nextcloud files to web directory
echo "Moving Nextcloud files to /var/www/nextcloud..."
sudo mv /tmp/nextcloud /var/www/

# Set proper ownership
echo "Setting proper ownership for Nextcloud files..."
sudo chown -R www-data:www-data /var/www/nextcloud

# Create Nextcloud configuration directory
echo "Creating Nextcloud configuration directory..."
sudo mkdir -p /var/www/nextcloud/config

# Set proper ownership for config directory
sudo chown -R www-data:www-data /var/www/nextcloud/config

# Create Nextcloud data directory
echo "Creating Nextcloud data directory..."
sudo mkdir -p /var/www/nextcloud/data

# Set proper ownership for data directory
sudo chown -R www-data:www-data /var/www/nextcloud/data

# Restart Apache to apply changes
echo "Restarting Apache to apply all changes..."
sudo systemctl restart apache2

echo ""
echo "=== Nextcloud Deployment Complete ==="
echo "Nextcloud files moved to /var/www/nextcloud"
echo "Configuration directory created"
echo "Data directory created"
echo "Apache restarted"
echo ""
echo "Access Nextcloud in your browser at http://localhost/nextcloud"