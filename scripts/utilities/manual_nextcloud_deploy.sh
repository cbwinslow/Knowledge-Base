#!/bin/bash

# Manual Nextcloud Deployment Script
# This script contains the exact commands you need to run manually with sudo

echo "=== Manual Nextcloud Deployment Script ==="
echo ""
echo "Please run the following commands manually with sudo:"
echo ""

# Commands to run manually
echo "# 1. Move Nextcloud files to web directory"
echo "sudo mv /tmp/nextcloud /var/www/"
echo ""

echo "# 2. Set proper ownership for Nextcloud files"
echo "sudo chown -R www-data:www-data /var/www/nextcloud"
echo ""

echo "# 3. Create Nextcloud configuration directory"
echo "sudo mkdir -p /var/www/nextcloud/config"
echo ""

echo "# 4. Set proper ownership for config directory"
echo "sudo chown -R www-data:www-data /var/www/nextcloud/config"
echo ""

echo "# 5. Create Nextcloud data directory"
echo "sudo mkdir -p /var/www/nextcloud/data"
echo ""

echo "# 6. Set proper ownership for data directory"
echo "sudo chown -R www-data:www-data /var/www/nextcloud/data"
echo ""

echo "# 7. Restart Apache to apply changes"
echo "sudo systemctl restart apache2"
echo ""

echo "# 8. Check Apache status"
echo "sudo systemctl status apache2"
echo ""

echo "=== End of Manual Deployment Script ==="
echo ""
echo "After running these commands, you can access Nextcloud at:"
echo "http://localhost/nextcloud"