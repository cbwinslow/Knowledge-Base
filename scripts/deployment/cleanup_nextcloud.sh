#!/bin/bash

# Clean Up Existing Nextcloud Installation
# This script removes the existing Nextcloud snap installation

echo "=== Cleaning Up Existing Nextcloud Installation ==="
echo ""

# Check if Nextcloud snap is installed
if snap list | grep -q nextcloud; then
    echo "Nextcloud snap is installed. Removing..."
    
    # Stop Nextcloud services
    echo "Stopping Nextcloud services..."
    sudo systemctl stop snap.nextcloud.apache.service 2>/dev/null || echo "Apache service not running"
    sudo systemctl stop snap.nextcloud.mysql.service 2>/dev/null || echo "MySQL service not running"
    sudo systemctl stop snap.nextcloud.certbot.service 2>/dev/null || echo "Certbot service not running"
    
    # Remove Nextcloud snap
    echo "Removing Nextcloud snap..."
    sudo snap remove nextcloud
    
    echo "Nextcloud snap removed successfully."
else
    echo "Nextcloud snap is not installed."
fi

# Remove any leftover directories
echo "Removing leftover directories..."
sudo rm -rf /var/snap/nextcloud 2>/dev/null || echo "No /var/snap/nextcloud directory"
sudo rm -rf /snap/nextcloud 2>/dev/null || echo "No /snap/nextcloud directory"

echo ""
echo "=== Cleanup Complete ==="
echo "Existing Nextcloud installation has been removed."
echo "You can now proceed with installing the official Nextcloud release."