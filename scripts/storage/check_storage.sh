#!/bin/bash

# Storage Information Script
# This script displays information about the current storage configuration

echo "=== Current Storage Configuration ==="
echo ""

echo "Block devices and filesystems:"
lsblk -f
echo ""

echo "Disk space usage:"
df -h
echo ""

echo "Partition information:"
cat /proc/partitions
echo ""

echo "Mount information:"
cat /proc/mounts | grep -E 'sd|mapper' | grep -v tmpfs
echo ""

echo "=== End of Storage Information ==="