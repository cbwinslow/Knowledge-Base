#!/bin/bash

# System Setup Documentation Generator
# This script creates a comprehensive documentation of your Ubuntu server setup

echo "=== Ubuntu Server Setup Documentation Generator ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/server_setup_docs"
mkdir -p $DOCS_DIR

echo "Creating documentation in: $DOCS_DIR"
echo ""

# 1. System Information
echo "1. Collecting System Information..."
{
    echo "# Ubuntu Server Setup Documentation"
    echo ""
    echo "## System Information"
    echo ""
    echo "### Basic System Info"
    echo "\`\`\`"
    uname -a
    echo "\`\`\`"
    echo ""
    echo "### OS Release Info"
    echo "\`\`\`"
    cat /etc/os-release
    echo "\`\`\`"
    echo ""
    echo "### CPU Info"
    echo "\`\`\`"
    lscpu | head -20
    echo "\`\`\`"
    echo ""
    echo "### Memory Info"
    echo "\`\`\`"
    free -h
    echo "\`\`\`"
} > $DOCS_DIR/system_info.md

# 2. Storage Configuration
echo "2. Documenting Storage Configuration..."
{
    echo "## Storage Configuration"
    echo ""
    echo "### Block Devices and Filesystems"
    echo "\`\`\`"
    lsblk -f
    echo "\`\`\`"
    echo ""
    echo "### Disk Space Usage"
    echo "\`\`\`"
    df -h
    echo "\`\`\`"
    echo ""
    echo "### LVM Configuration (if any)"
    echo "\`\`\`"
    if command -v pvs &> /dev/null; then
        echo "Physical Volumes:"
        pvs 2>/dev/null || echo "No physical volumes found or permission denied"
        echo ""
        echo "Volume Groups:"
        vgs 2>/dev/null || echo "No volume groups found or permission denied"
        echo ""
        echo "Logical Volumes:"
        lvs 2>/dev/null || echo "No logical volumes found or permission denied"
    else
        echo "LVM tools not installed"
    fi
    echo "\`\`\`"
} >> $DOCS_DIR/system_info.md

# 3. Network Configuration
echo "3. Documenting Network Configuration..."
{
    echo "## Network Configuration"
    echo ""
    echo "### Network Interfaces"
    echo "\`\`\`"
    ip addr show
    echo "\`\`\`"
    echo ""
    echo "### Routing Table"
    echo "\`\`\`"
    ip route show
    echo "\`\`\`"
    echo ""
    echo "### DNS Configuration"
    echo "\`\`\`"
    cat /etc/resolv.conf
    echo "\`\`\`"
} >> $DOCS_DIR/system_info.md

# 4. Installed Packages
echo "4. Documenting Installed Packages..."
{
    echo "## Installed Packages"
    echo ""
    echo "### Recently Installed Packages"
    echo "\`\`\`"
    grep " install " /var/log/dpkg.log | tail -20
    echo "\`\`\`"
    echo ""
    echo "### Currently Installed Packages (sample)"
    echo "\`\`\`"
    dpkg -l | tail -20
    echo "\`\`\`"
} >> $DOCS_DIR/system_info.md

# 5. User and Security
echo "5. Documenting User and Security Info..."
{
    echo "## User and Security Information"
    echo ""
    echo "### Current User"
    echo "\`\`\`"
    whoami
    echo "\`\`\`"
    echo ""
    echo "### Users"
    echo "\`\`\`"
    cut -d: -f1 /etc/passwd
    echo "\`\`\`"
    echo ""
    echo "### Groups"
    echo "\`\`\`"
    cut -d: -f1 /etc/group
    echo "\`\`\`"
} >> $DOCS_DIR/system_info.md

echo "System information documentation created."
echo ""

# 6. Extract and document scripts
echo "6. Documenting Created Scripts..."
{
    echo "## Created Scripts"
    echo ""
    echo "### Script Files"
    echo ""
} > $DOCS_DIR/scripts.md

for script in /home/cbwinslow/*.sh; do
    SCRIPT_NAME=$(basename $script)
    echo "#### $SCRIPT_NAME" >> $DOCS_DIR/scripts.md
    echo "" >> $DOCS_DIR/scripts.md
    echo "Location: $script" >> $DOCS_DIR/scripts.md
    echo "" >> $DOCS_DIR/scripts.md
    echo "\`\`\`bash" >> $DOCS_DIR/scripts.md
    cat $script >> $DOCS_DIR/scripts.md
    echo "\`\`\`" >> $DOCS_DIR/scripts.md
    echo "" >> $DOCS_DIR/scripts.md
done

echo "Script documentation created."
echo ""

# 7. Create a summary report
echo "7. Creating Summary Report..."
{
    echo "# Ubuntu Server Setup - Summary Report"
    echo ""
    echo "## Overview"
    echo "This document summarizes the Ubuntu server setup process and current configuration."
    echo ""
    echo "## Key Components"
    echo ""
    echo "### Storage Management System"
    echo "- Created comprehensive storage management suite"
    echo "- Developed scripts for LVM optimization with better logical volume sizing"
    echo "- Created tools for ZFS recovery and storage diagnostics"
    echo ""
    echo "### Scripts Created"
} > $DOCS_DIR/summary.md

for script in /home/cbwinslow/*.sh; do
    SCRIPT_NAME=$(basename $script)
    echo "- $SCRIPT_NAME" >> $DOCS_DIR/summary.md
done

{
    echo ""
    echo "### Documentation Files"
    echo "- system_info.md: Detailed system information"
    echo "- scripts.md: All created scripts with source code"
    echo "- summary.md: This summary report"
    echo ""
    echo "## Next Steps"
    echo "1. Review the documentation files in $DOCS_DIR"
    echo "2. Test the storage management scripts as needed"
    echo "3. Backup important data before running any optimization scripts"
    echo "4. Consider setting up automatic logging for future activities"
    echo ""
    echo "## Important Notes"
    echo "- The optimization scripts will erase data on drives sdb, sdc, sdd, sde, and sdf"
    echo "- Always backup important data before running optimization scripts"
    echo "- Root privileges are required for system-level operations"
} >> $DOCS_DIR/summary.md

echo "Summary report created."
echo ""

# 8. Create a setup log
echo "8. Creating Setup Log..."
{
    echo "# Setup Process Log"
    echo ""
    echo "## Session Information"
    echo "- Date: $(date)"
    echo "- User: $(whoami)"
    echo "- Working Directory: $(pwd)"
    echo ""
    echo "## Generated Documentation Files"
    echo "- $DOCS_DIR/system_info.md"
    echo "- $DOCS_DIR/scripts.md"
    echo "- $DOCS_DIR/summary.md"
    echo ""
    echo "## Process Completed"
    echo "- Date: $(date)"
    echo "- Status: Success"
} > $DOCS_DIR/setup_log.md

echo "Setup log created."
echo ""

# 9. Create a README
echo "9. Creating README..."
{
    echo "# Ubuntu Server Setup Documentation"
    echo ""
    echo "## Overview"
    echo "This directory contains comprehensive documentation of the Ubuntu server setup process."
    echo ""
    echo "## Contents"
    echo "- **system_info.md**: Detailed system information including storage, network, and package details"
    echo "- **scripts.md**: All created scripts with source code"
    echo "- **summary.md**: Summary report of the setup process"
    echo "- **setup_log.md**: Log of the documentation generation process"
    echo ""
    echo "## Storage Management System"
    echo "A comprehensive suite of tools was created to manage storage:"
    echo "- Storage manager with menu-driven interface"
    echo "- Storage checking and diagnostic tools"
    echo "- LVM optimization scripts with improved logical volume sizing"
    echo "- ZFS recovery script for maintaining existing setup"
    echo ""
    echo "## Usage"
    echo "Review the markdown files to understand the current system configuration and available tools."
    echo ""
    echo "## Important Notes"
    echo "- The optimization scripts will erase data on drives sdb, sdc, sdd, sde, and sdf"
    echo "- Always backup important data before running optimization scripts"
    echo "- Root privileges are required for system-level operations"
} > $DOCS_DIR/README.md

echo "README created."
echo ""

echo "=== Documentation Generation Complete ==="
echo ""
echo "All documentation has been created in: $DOCS_DIR"
echo ""
echo "Files created:"
echo "  - README.md: Overview and usage instructions"
echo "  - system_info.md: Detailed system information"
echo "  - scripts.md: All created scripts with source code"
echo "  - summary.md: Summary report of the setup process"
echo "  - setup_log.md: Log of the documentation generation process"
echo ""
echo "You can now review these documents to understand your server's current configuration and the tools available for storage management."