#!/bin/bash

# ZFS Recovery Script
# This script attempts to recover the existing ZFS pool configuration

echo "=== ZFS Recovery Script ==="
echo "This script will attempt to recover your existing ZFS pool."

# Check if ZFS tools are installed
if ! command -v zpool &> /dev/null; then
    echo "ZFS tools are not installed."
    echo "Would you like to install them? (yes/no)"
    read install_zfs
    
    if [[ $install_zfs == "yes" ]]; then
        echo "Installing ZFS tools..."
        sudo apt update && sudo apt install -y zfsutils-linux
    else
        echo "Cannot proceed without ZFS tools installed."
        exit 1
    fi
fi

# Check if the pool exists
echo "Checking for existing ZFS pools..."
sudo zpool import

if [[ $? -eq 0 ]]; then
    echo ""
    echo "Found ZFS pool(s). Would you like to import the 'data-pool'? (yes/no)"
    read import_pool
    
    if [[ $import_pool == "yes" ]]; then
        echo "Importing 'data-pool'..."
        sudo zpool import data-pool
        
        if [[ $? -eq 0 ]]; then
            echo "Pool imported successfully!"
            echo "Creating mount point and mounting..."
            sudo mkdir -p /data
            sudo zfs set mountpoint=/data data-pool
            echo "ZFS pool is now mounted at /data"
            
            echo "Final storage configuration:"
            df -h | grep -E 'data|backup'
        else
            echo "Failed to import pool."
        fi
    else
        echo "Pool import cancelled."
    fi
else
    echo "No ZFS pools found or unable to import."
fi

echo "=== End of ZFS Recovery Script ==="