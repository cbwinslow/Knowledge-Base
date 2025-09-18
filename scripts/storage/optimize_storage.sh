#!/bin/bash

# Storage Optimization Script
# This script will convert data drives to LVM and expand available storage space
# WARNING: This script will destroy all data on the specified drives
# Make sure to backup any important data before running this script

echo "=== Storage Optimization Script ==="
echo "This script will convert data drives to LVM and expand storage space."
echo ""
echo "CURRENT STORAGE CONFIGURATION:"
echo "------------------------------"
echo "Boot Drive (sda): 1.1TB SSD"
echo "  - sda1: 1.1GB vfat (EFI boot partition)"
echo "  - sda2: 2GB ext4 (boot partition)"
echo "  - sda3: 1.1TB LVM2 physical volume (root filesystem)"
echo ""
echo "Data Drives (currently unused):"
echo "  - sdb: 1.1TB (ZFS member)"
echo "  - sdc: 1.1TB (ZFS member)"
echo "  - sdd: 1.1TB (ZFS member)"
echo "  - sde: 586GB (ext4, unmounted)"
echo "  - sdf: 1.1TB (ZFS member)"
echo ""
echo "WARNING: This will destroy all data on sdb, sdc, sdd, sde, and sdf."
echo "Please ensure you have backed up any important data."
echo ""
read -p "Do you want to continue? (yes/no): " confirmation

if [[ $confirmation != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "Checking if required tools are installed..."
if ! command -v pvcreate &> /dev/null; then
    echo "LVM tools not found. Please install lvm2 package:"
    echo "  sudo apt update && sudo apt install -y lvm2"
    echo "Then run this script again."
    exit 1
fi

echo "LVM tools are installed. Proceeding with optimization..."

# Deactivate any existing volume groups (if possible without sudo)
echo ""
echo "Note: Some operations require root privileges. You may be prompted for your password."

# Create physical volumes from the data drives
echo "Creating physical volumes..."
sudo pvcreate -ff /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf

# Create a volume group named 'data-vg' spanning all physical volumes
echo "Creating volume group 'data-vg'..."
sudo vgcreate data-vg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf

# Display volume group information
echo "Volume group information:"
sudo vgdisplay data-vg

# Create logical volumes
echo "Creating logical volumes..."
# Create a large data volume (using about 80% of total space)
sudo lvcreate -l 80%FREE -n data-lv data-vg
# Create a smaller backup volume with the remaining space
sudo lvcreate -l 100%FREE -n backup-lv data-vg

# Display logical volume information
echo "Logical volume information:"
sudo lvdisplay

# Create filesystems on the logical volumes
echo "Creating filesystems..."
sudo mkfs.ext4 /dev/data-vg/data-lv
sudo mkfs.ext4 /dev/data-vg/backup-lv

# Create mount points
echo "Creating mount points..."
sudo mkdir -p /data /backup

# Add entries to /etc/fstab for automatic mounting
echo "Adding entries to /etc/fstab..."
echo "/dev/data-vg/data-lv /data ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "/dev/data-vg/backup-lv /backup ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Mount the filesystems
echo "Mounting filesystems..."
sudo mount /data
sudo mount /backup

# Display final storage configuration
echo "Final storage configuration:"
df -h

echo ""
echo "=== Storage optimization complete ==="
echo "You now have additional storage space:"
echo "- Data volume mounted at /data"
echo "- Backup volume mounted at /backup"
echo ""
echo "To verify your new storage configuration, you can run:"
echo "  sudo pvdisplay"
echo "  sudo vgdisplay"
echo "  sudo lvdisplay"
echo ""
echo "Your additional storage is now ready to use!"