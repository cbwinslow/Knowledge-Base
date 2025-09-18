#!/bin/bash

# Fix for missing libjpeg62-turbo-dev package
# This script addresses the issue with missing package during Guacamole installation

echo "=== Fixing Missing Package Issue ==="
echo ""

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install the correct JPEG development package
echo "Installing libjpeg-turbo8-dev (replacement for libjpeg62-turbo-dev)..."
sudo apt install -y libjpeg-turbo8-dev

# Also install other common dependencies that might be needed
echo "Installing additional dependencies for Guacamole..."
sudo apt install -y \
    libpng-dev \
    libgif-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libfreerdp-dev \
    libpango1.0-dev \
    libssh2-1-dev \
    libtelnet-dev \
    libvncserver-dev \
    libpulse-dev \
    libssl-dev \
    libvorbis-dev \
    libwebp-dev

# Check if we have the required packages installed
echo ""
echo "Checking installed packages..."
dpkg -l | grep -E "(jpeg|png|gif|avcodec|avformat|pango|ssh|vnc|pulse|ssl|vorbis|webp)"

echo ""
echo "=== Package Installation Complete ==="
echo "You can now continue with your Guacamole installation."
echo "The missing libjpeg62-turbo-dev package has been replaced with libjpeg-turbo8-dev."
echo "Additional dependencies have also been installed."