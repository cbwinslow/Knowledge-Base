#!/bin/bash

# Manual completion script for storage reconfiguration
# This script should be run manually with sudo privileges

echo "=== Manual Storage Setup Completion ==="
echo "Please run these commands manually with sudo:"

echo "
# 1. Format the data logical volume
sudo mkfs.ext4 /dev/mapper/ubuntu--vg-data--lv

# 2. Create mount point and mount
sudo mkdir -p /data
sudo mount /dev/mapper/ubuntu--vg-data--lv /data

# 3. Add to fstab for persistent mounting
echo '/dev/mapper/ubuntu--vg-data--lv /data ext4 defaults 0 0' | sudo tee -a /etc/fstab

# 4. Expand root logical volume to use remaining space
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv

# 5. Resize the root filesystem
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

# 6. Verify the setup
df -h
lsblk -f
"

echo "=== Storage Summary ==="
echo "After running these commands, you will have:"
echo "- A large data volume mounted at /data"
echo "- An expanded root filesystem using all available space"
echo "- All 5.4TB of storage utilized effectively"