#!/bin/bash

# Fix for missing libjpeg62-turbo-dev package
# This script addresses the issue with missing package during Guacamole installation

echo "=== Fixing Missing Package Issue ==="
echo ""

# Update package lists
echo "Updating package lists..."
sudo apt update

# Try to install the alternative package
echo "Installing alternative JPEG development package..."
sudo apt install -y libjpeg-turbo8-dev

# If that doesn't work, try libjpeg-dev
if [ $? -ne 0 ]; then
    echo "Trying libjpeg-dev package..."
    sudo apt install -y libjpeg-dev
fi

# Check if we have any JPEG development package installed
echo "Checking installed JPEG development packages..."
dpkg -l | grep jpeg

echo ""
echo "=== Package Fix Complete ==="
echo "You can now continue with your Guacamole installation."
echo "If you're using an automated script, you may need to rerun it."