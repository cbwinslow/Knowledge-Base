#!/bin/bash

# Storage Decision Helper Script
# This script helps determine the best approach for your storage configuration

echo "=== Storage Decision Helper ==="
echo "This script will help you determine the best approach for your storage configuration."
echo ""

echo "1. Checking if you have any important data on the unmounted drives..."
echo "   (This is a manual check - please verify if any of these drives contain important data)"
echo "   - sdb: 1.1TB (ZFS member)"
echo "   - sdc: 1.1TB (ZFS member)"
echo "   - sdd: 1.1TB (ZFS member)"
echo "   - sde: 586GB (ext4, unmounted)"
echo "   - sdf: 1.1TB (ZFS member)"
echo ""

echo "2. Checking your preferences for storage management..."
echo "   Do you prefer ZFS or LVM for your storage management?"
echo "   - ZFS: Better for data integrity, snapshots, and built-in volume management"
echo "   - LVM: More flexible, widely supported, easier to integrate with existing systems"
echo ""

echo "3. Recommendation based on your setup:"
echo "   - If you were previously using ZFS and are comfortable with it, use recover_zfs.sh"
echo "   - If you want maximum flexibility and easier management, use optimize_storage.sh"
echo "   - If you're unsure, LVM is generally recommended for most use cases"
echo ""

echo "4. Storage capacity you'll gain:"
echo "   - Total additional space: ~5TB"
echo "   - With LVM approach: One large data volume (~4TB) and one backup volume (~1TB)"
echo "   - With ZFS approach: One large pool (~5TB)"
echo ""

echo "=== Next Steps ==="
echo "1. If you have important data on any of the drives, back it up first"
echo "2. If you want to keep your existing ZFS setup, run: ./recover_zfs.sh"
echo "3. If you want to use LVM with the original sizing, run: ./optimize_storage.sh"
echo "4. If you want to use LVM with better volume sizes, run: ./optimize_storage_better_sizes.sh"
echo "5. To just check your current configuration, run: ./check_storage.sh"
echo ""