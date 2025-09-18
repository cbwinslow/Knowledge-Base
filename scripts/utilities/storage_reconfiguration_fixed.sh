#!/bin/bash

# Storage Reconfiguration Script
# This script removes ZFS and reconfigures all disks with LVM

set -e  # Exit on any error

echo "=== Storage Reconfiguration Script ==="
echo "This script will:"
echo "1. Remove ZFS signatures from disks"
echo "2. Configure all disks with LVM"
echo "3. Create logical volumes for data and backup"
echo "4. Expand root filesystem"
echo ""

read -p "Do you want to continue? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted by user."
    exit 1
fi

echo "Starting storage reconfiguration..."

# Phase 1: Destroy ZFS Signatures
echo "=== Phase 1: Removing ZFS Signatures ==="

# Attempt to clear ZFS labels
echo "Attempting to clear ZFS labels..."
for disk in sdb sdc sdd sdf; do
    echo "Clearing ZFS signatures from /dev/$disk..."
    if command -v zpool >/dev/null 2>&1; then
        zpool labelclear -f /dev/$disk 2>/dev/null || echo "No ZFS label found on /dev/$disk"
    fi
done

# Use wipefs as backup method
echo "Using wipefs to ensure clean disks..."
for disk in sdb sdc sdd sdf; do
    echo "Wiping filesystem signatures from /dev/$disk..."
    wipefs -a /dev/$disk 2>/dev/null || echo "No filesystem signatures found on /dev/$disk"
done

# Clear first sectors as final fallback
echo "Clearing first sectors of disks..."
for disk in sdb sdc sdd sdf; do
    echo "Clearing first 100MB of /dev/$disk..."
    dd if=/dev/zero of=/dev/$disk bs=1M count=100 2>/dev/null || echo "Warning: Could not clear /dev/$disk"
done

# Phase 2: Configure LVM
echo "=== Phase 2: Configuring LVM ==="

# Create physical volumes
echo "Creating physical volumes..."
for disk in sdb sdc sdd sdf; do
    echo "Creating PV on /dev/$disk..."
    pvcreate /dev/$disk
done

# Extend existing volume group
echo "Extending volume group..."
vgextend ubuntu-vg /dev/sdb /dev/sdc /dev/sdd /dev/sdf

# Display available space
echo "Available space in volume group:"
vgdisplay ubuntu-vg

# Phase 3: Create logical volumes
echo "=== Phase 3: Creating Logical Volumes ==="

# Get available free space in extents
FREE_EXTENTS=$(vgdisplay ubuntu-vg | grep "Free  PE" | awk '{print $5}')
echo "Free extents available: $FREE_EXTENTS"

if [ -z "$FREE_EXTENTS" ] || [ "$FREE_EXTENTS" -eq 0 ]; then
    echo "Error: No free extents available in volume group"
    exit 1
fi

# Calculate sizes (using approximately 60% for data, 30% for backup, 10% reserved)
DATA_EXTENTS=$((FREE_EXTENTS * 60 / 100))
BACKUP_EXTENTS=$((FREE_EXTENTS * 30 / 100))
RESERVED_EXTENTS=$((FREE_EXTENTS - DATA_EXTENTS - BACKUP_EXTENTS))

echo "Creating logical volumes..."
echo "Data LV: $DATA_EXTENTS extents"
echo "Backup LV: $BACKUP_EXTENTS extents"
echo "Reserved: $RESERVED_EXTENTS extents"

# Create logical volumes
echo "Creating data logical volume..."
lvcreate -l $DATA_EXTENTS -n data-lv ubuntu-vg

# Check if we have enough space for backup volume
if [ $BACKUP_EXTENTS -gt 0 ]; then
    echo "Creating backup logical volume..."
    lvcreate -l $BACKUP_EXTENTS -n backup-lv ubuntu-vg
else
    echo "Not enough space for backup volume, skipping..."
fi

# Format logical volumes
echo "Formatting logical volumes..."
if [ -e /dev/ubuntu-vg/data-lv ]; then
    mkfs.ext4 /dev/ubuntu-vg/data-lv
fi

if [ -e /dev/ubuntu-vg/backup-lv ]; then
    mkfs.ext4 /dev/ubuntu-vg/backup-lv
fi

# Create mount points
echo "Creating mount points..."
mkdir -p /data
if [ -e /dev/ubuntu-vg/backup-lv ]; then
    mkdir -p /backup
fi

# Mount volumes
echo "Mounting volumes..."
if [ -e /dev/ubuntu-vg/data-lv ]; then
    mount /dev/ubuntu-vg/data-lv /data
fi

if [ -e /dev/ubuntu-vg/backup-lv ]; then
    mount /dev/ubuntu-vg/backup-lv /backup
fi

# Add to fstab
echo "Adding to fstab..."
if [ -e /dev/ubuntu-vg/data-lv ]; then
    echo "/dev/ubuntu-vg/data-lv /data ext4 defaults 0 0" >> /etc/fstab
fi

if [ -e /dev/ubuntu-vg/backup-lv ]; then
    echo "/dev/ubuntu-vg/backup-lv /backup ext4 defaults 0 0" >> /etc/fstab
fi

# Phase 4: Expand root filesystem
echo "=== Phase 4: Expanding Root Filesystem ==="

# Allocate remaining space to root LV
echo "Expanding root logical volume..."
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# Resize the filesystem
echo "Resizing root filesystem..."
resize2fs /dev/ubuntu-vg/ubuntu-lv

# Final status
echo "=== Final Status ==="
df -h
vgdisplay ubuntu-vg

echo "=== Storage reconfiguration complete! ==="
echo "Created volumes:"
if [ -e /dev/ubuntu-vg/data-lv ]; then
    echo "- Data volume: /data (mounted from /dev/ubuntu-vg/data-lv)"
fi
if [ -e /dev/ubuntu-vg/backup-lv ]; then
    echo "- Backup volume: /backup (mounted from /dev/ubuntu-vg/backup-lv)"
fi
echo "- Root filesystem has been expanded"
echo ""
echo "Please reboot to ensure all changes are properly applied."