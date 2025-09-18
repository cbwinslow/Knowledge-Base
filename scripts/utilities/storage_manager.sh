#!/bin/bash

# Storage Management Suite
# This script provides a menu-driven interface for managing your storage

echo "=== Storage Management Suite ==="
echo "Select an option:"
echo "1. Check current storage configuration"
echo "2. Get help deciding on storage approach"
echo "3. Optimize storage with LVM (WARNING: Destroys data on sdb,sdc,sdd,sde,sdf)"
echo "4. Optimize storage with LVM (Better LV sizes)"
echo "5. Recover existing ZFS pool"
echo "6. Exit"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo "Running storage check..."
        ./check_storage.sh
        ;;
    2)
        echo "Running decision helper..."
        ./storage_decision_helper.sh
        ;;
    3)
        echo "Running LVM optimization (Original)..."
        ./optimize_storage.sh
        ;;
    4)
        echo "Running LVM optimization (Better LV sizes)..."
        ./optimize_storage_better_sizes.sh
        ;;
    5)
        echo "Running ZFS recovery..."
        ./recover_zfs.sh
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please run the script again and select a valid option."
        exit 1
        ;;
esac