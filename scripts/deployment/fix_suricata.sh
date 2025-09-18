#!/bin/bash

# Suricata Configuration Fix Script
# This script fixes the Suricata configuration to use the correct network interface

echo "=== Suricata Configuration Fix ==="
echo ""

# Create backup of original configuration
sudo cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.backup.$(date +%Y%m%d_%H%M%S)

echo "Created backup of Suricata configuration"

# Fix the interface configuration
sudo sed -i 's/interface: eth0/interface: eno1/g' /etc/suricata/suricata.yaml

# Also fix other interface references
sudo sed -i 's/interface: eth2/interface: eno2/g' /etc/suricata/suricata.yaml

echo "Updated Suricata configuration to use correct interfaces"

# Restart Suricata service
echo "Restarting Suricata service..."
sudo systemctl restart suricata

# Check if Suricata is now running
sleep 5
SURICATA_STATUS=$(systemctl is-active suricata)

if [ "$SURICATA_STATUS" = "active" ]; then
    echo "✅ Suricata is now running successfully!"
else
    echo "❌ Suricata failed to start. Checking logs..."
    journalctl -u suricata --no-pager | tail -10
fi

# Create documentation
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Suricata Configuration Fix"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Issue"
    echo "Suricata was configured to use 'eth0' interface, but the system has interfaces named 'eno1', 'eno2', etc."
    echo ""
    echo "## Solution"
    echo "Updated Suricata configuration to use the correct network interfaces:"
    echo "- Changed 'eth0' to 'eno1' in /etc/suricata/suricata.yaml"
    echo "- Changed 'eth2' to 'eno2' in /etc/suricata/suricata.yaml"
    echo "- Created backup of original configuration"
    echo "- Restarted Suricata service"
    echo ""
    echo "## Result"
    echo "Suricata service status: $SURICATA_STATUS"
    echo ""
    echo "## Next Steps"
    echo "1. Verify Suricata is capturing traffic properly:"
    echo "   sudo suricatactl pcap --help"
    echo ""
    echo "2. Check Suricata logs for any errors:"
    echo "   sudo journalctl -u suricata -f"
    echo ""
    echo "3. Review Suricata configuration:"
    echo "   sudo nano /etc/suricata/suricata.yaml"
    echo ""
    echo "4. Test Suricata rules:"
    echo "   sudo suricata -T -c /etc/suricata/suricata.yaml"
    echo ""
    echo "## Backup"
    echo "Original configuration backed up to:"
    echo "/etc/suricata/suricata.yaml.backup.$(date +%Y%m%d_%H%M%S)"
} > $DOCS_DIR/suricata_fix.md

echo ""
echo "=== Suricata Configuration Fix Complete ==="
echo "Documentation created in $DOCS_DIR/suricata_fix.md"
echo ""
echo "Next steps:"
echo "1. Verify Suricata is capturing traffic properly"
echo "2. Check Suricata logs for any errors"
echo "3. Review Suricata configuration"
echo "4. Test Suricata rules"