#!/bin/bash

# Security Monitoring Tools Installation Script
# This script installs Suricata, network monitoring, and intrusion detection tools

echo "=== Security Monitoring Tools Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Security Monitoring Tools Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/monitoring_tools.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/monitoring_tools.md
}

# 1. Update package list
log_action "Updating package list..."
sudo apt update

# 2. Install Suricata
log_action "Installing Suricata IDS/IPS..."
sudo apt install -y suricata

# 3. Install network monitoring tools
log_action "Installing network monitoring tools..."
sudo apt install -y \
    nmap \
    tcpdump \
    wireshark \
    tshark \
    netstat-nat \
    iftop \
    nethogs \
    bmon

# 4. Install system monitoring tools
log_action "Installing system monitoring tools..."
sudo apt install -y \
    htop \
    iotop \
    atop \
    glances \
    sysstat \
    dstat

# 5. Install log analysis tools
log_action "Installing log analysis tools..."
sudo apt install -y \
    fail2ban \
    logwatch \
    multitail \
    lnav

# 6. Install Zeek (Bro) network security monitor
log_action "Installing Zeek network security monitor..."
sudo apt install -y zeek

# 7. Install OSSEC (HIDS)
log_action "Installing OSSEC HIDS..."
sudo apt install -y ossec-hids

# 8. Configure Suricata
log_action "Configuring Suricata..."
sudo suricata-update
sudo suricata-update update-sources
sudo suricata-update

# Create Suricata documentation
{
    echo ""
    echo "## Suricata Configuration"
    echo ""
    echo "### Suricata Commands"
    echo "\`\`\`bash"
    echo "# Start Suricata"
    echo "sudo systemctl start suricata"
    echo ""
    echo "# Enable Suricata at boot"
    echo "sudo systemctl enable suricata"
    echo ""
    echo "# Check Suricata status"
    echo "sudo systemctl status suricata"
    echo ""
    echo "# Test Suricata configuration"
    echo "sudo suricata -T -c /etc/suricata/suricata.yaml"
    echo ""
    echo "# View Suricata logs"
    echo "sudo tail -f /var/log/suricata/fast.log"
    echo "\`\`\`"
    echo ""
    echo "### Suricata Configuration Files"
    echo "- Main config: /etc/suricata/suricata.yaml"
    echo "- Rules directory: /etc/suricata/rules/"
    echo "- Log directory: /var/log/suricata/"
} >> $DOCS_DIR/monitoring_tools.md

# 9. Configure Zeek
log_action "Configuring Zeek..."
{
    echo ""
    echo "## Zeek Configuration"
    echo ""
    echo "### Zeek Commands"
    echo "\`\`\`bash"
    echo "# Start Zeek"
    echo "sudo systemctl start zeek"
    echo ""
    echo "# Enable Zeek at boot"
    echo "sudo systemctl enable zeek"
    echo ""
    echo "# Check Zeek status"
    echo "sudo systemctl status zeek"
    echo ""
    echo "# Run Zeek on an interface"
    echo "sudo zeek -i eth0"
    echo ""
    echo "# View Zeek logs"
    echo "ls /opt/zeek/logs/current/"
    echo "\`\`\`"
    echo ""
    echo "### Zeek Configuration Files"
    echo "- Main config: /opt/zeek/etc/node.cfg"
    echo "- Network config: /opt/zeek/etc/networks.cfg"
    echo "- Log directory: /opt/zeek/logs/"
} >> $DOCS_DIR/monitoring_tools.md

# 10. Document other tools
{
    echo ""
    echo "## Other Security Tools"
    echo ""
    echo "### Network Scanning and Analysis"
    echo "- nmap: Network discovery and security auditing"
    echo "- tcpdump: Command-line packet analyzer"
    echo "- wireshark/tshark: Network protocol analyzer"
    echo "- netstat-nat: Network statistics for NAT connections"
    echo ""
    echo "### System Monitoring"
    echo "- htop: Interactive process viewer"
    echo "- iotop: Monitor I/O usage by processes"
    echo "- atop: System and process monitor"
    echo "- glances: System monitoring tool"
    echo "- sysstat: System performance tools"
    echo "- dstat: Versatile resource statistics tool"
    echo ""
    echo "### Log Analysis"
    echo "- fail2ban: Intrusion prevention software"
    echo "- logwatch: Log analyzer and reporter"
    echo "- multitail: View multiple log files simultaneously"
    echo "- lnav: Log file navigator"
    echo ""
    echo "### Host-based IDS"
    echo "- OSSEC: Host-based intrusion detection system"
} >> $DOCS_DIR/monitoring_tools.md

# 11. Create test scripts
log_action "Creating test scripts..."

mkdir -p /home/cbwinslow/security_setup/tests

cat > /home/cbwinslow/security_setup/tests/test_monitoring.sh << 'EOL'
#!/bin/bash

echo "=== Testing Security Monitoring Tools ==="
echo ""

echo "1. Testing Suricata..."
sudo systemctl status suricata --no-pager || echo "Suricata not installed or not running"

echo ""
echo "2. Testing Zeek..."
sudo systemctl status zeek --no-pager || echo "Zeek not installed or not running"

echo ""
echo "3. Testing network tools..."
which nmap tcpdump wireshark &>/dev/null && echo "Network tools installed" || echo "Some network tools missing"

echo ""
echo "4. Testing system monitoring tools..."
which htop atop glances &>/dev/null && echo "System monitoring tools installed" || echo "Some system monitoring tools missing"

echo ""
echo "5. Testing log analysis tools..."
which fail2ban-client logwatch &>/dev/null && echo "Log analysis tools installed" || echo "Some log analysis tools missing"

echo ""
echo "=== Test Complete ==="
EOL

chmod +x /home/cbwinslow/security_setup/tests/test_monitoring.sh

# 12. Final summary
{
    echo ""
    echo "## Installation Complete"
    echo ""
    echo "### Installed Tools"
    echo "- Suricata: Network IDS/IPS"
    echo "- Zeek: Network security monitor"
    echo "- OSSEC: Host-based IDS"
    echo "- Nmap: Network scanner"
    echo "- Tcpdump: Packet capture"
    echo "- Wireshark: Network protocol analyzer"
    echo "- Fail2ban: Intrusion prevention"
    echo "- System monitoring tools (htop, atop, glances, etc.)"
    echo ""
    echo "### Next Steps"
    echo "1. Configure Suricata rules and interfaces"
    echo "2. Configure Zeek for your network"
    echo "3. Configure OSSEC for host monitoring"
    echo "4. Set up fail2ban for intrusion prevention"
    echo "5. Test all tools with the test script:"
    echo "   /home/cbwinslow/security_setup/tests/test_monitoring.sh"
    echo ""
    echo "### Documentation"
    echo "Detailed documentation is available in $DOCS_DIR/monitoring_tools.md"
    echo "Configuration files are in their respective directories"
} >> $DOCS_DIR/monitoring_tools.md

log_action "Security monitoring tools installation complete!"
echo ""
echo "=== Installation Complete ==="
echo "Documentation created in $DOCS_DIR/monitoring_tools.md"
echo "Test script available at /home/cbwinslow/security_setup/tests/test_monitoring.sh"
echo ""
echo "Next steps:"
echo "1. Configure Suricata, Zeek, and OSSEC for your environment"
echo "2. Run the test script to verify installations"
echo "3. Set up monitoring rules and alerts"