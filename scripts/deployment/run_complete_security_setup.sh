#!/bin/bash

# Master Security Setup Script
# This script runs all security setup processes in sequence

echo "=== Master Security Setup ==="
echo ""
echo "This script will configure SSH access, install monitoring tools,"
echo "set up threat intelligence tools, and install penetration testing tools."
echo ""
echo "Estimated time: 30-60 minutes depending on internet connection."
echo ""
read -p "Do you want to continue? (yes/no): " confirmation

if [[ $confirmation != "yes" ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "=== Starting Security Setup ==="
echo ""

# Run SSH configuration
echo "1. Configuring SSH access..."
/home/cbwinslow/security_setup/configure_ssh_access.sh
echo ""

# Run monitoring tools installation
echo "2. Installing monitoring tools..."
/home/cbwinslow/security_setup/install_monitoring_tools.sh
echo ""

# Run threat intelligence tools installation
echo "3. Installing threat intelligence tools..."
/home/cbwinslow/security_setup/install_threat_intel_tools.sh
echo ""

# Run penetration testing tools installation
echo "4. Installing penetration testing tools..."
/home/cbwinslow/security_setup/install_pen_testing_tools.sh
echo ""

# Create a summary document
DOCS_DIR="/home/cbwinslow/security_setup/docs"
{
    echo "# Security Setup Summary"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Setup Process Completed"
    echo ""
    echo "The following security components have been installed and configured:"
    echo ""
    echo "1. SSH and Network Access:"
    echo "   - SSH configured for external access"
    echo "   - Firewall configured with appropriate rules"
    echo "   - Ansible remote access configured"
    echo ""
    echo "2. Monitoring Tools:"
    echo "   - Suricata: Network IDS/IPS"
    echo "   - Zeek: Network security monitor"
    echo "   - OSSEC: Host-based IDS"
    echo "   - System and network monitoring tools"
    echo ""
    echo "3. Threat Intelligence Tools:"
    echo "   - MISP: Threat intelligence platform"
    echo "   - TheHive/Cortex: Incident response (documentation provided)"
    echo "   - VirusTotal/GreyNoise APIs"
    echo "   - Snyk: Developer security platform"
    echo "   - Security testing tools (Nikto, SQLMap, Burp Suite, etc.)"
    echo ""
    echo "4. Penetration Testing Tools:"
    echo "   - Kali Linux tools suite"
    echo "   - Metasploit Framework"
    echo "   - Network and web application testing tools"
    echo "   - Reverse engineering tools"
    echo "   - Docker for containerized tools"
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Configure Suricata, Zeek, and OSSEC for your environment"
    echo "2. Set up MISP database and web server"
    echo "3. Manually install TheHive and Cortex if needed"
    echo "4. Register for API keys for VirusTotal and GreyNoise"
    echo "5. Configure Burp Suite for web testing"
    echo "6. Log out and back in to use Docker without sudo"
    echo ""
    echo "## Important Notes"
    echo ""
    echo "- SSH is configured for key-based authentication only"
    echo "- Password authentication has been disabled"
    echo "- Firewall is active with appropriate ports open"
    echo "- All documentation is in $DOCS_DIR/"
    echo "- Configuration files are backed up with timestamps"
    echo "- These tools should only be used on systems you own or have permission to test"
    echo ""
    echo "## Services and Ports"
    echo ""
    echo "| Service | Port | Protocol | Purpose |"
    echo "|---------|------|----------|---------|"
    echo "| SSH | 22 | TCP | Secure shell access |"
    echo "| HTTP | 80 | TCP | Web server |"
    echo "| HTTPS | 443 | TCP | Secure web server |"
    echo "| Squid Proxy | 3128 | TCP | HTTP proxy |"
    echo ""
    echo "## Verification"
    echo ""
    echo "Test scripts are available in /home/cbwinslow/security_setup/tests/:"
    echo "- test_monitoring.sh: Test monitoring tools"
    echo "- test_threat_intel.sh: Test threat intelligence tools"
    echo "- test_pen_testing.sh: Test penetration testing tools"
    echo ""
    echo "Setup process completed successfully!"
} > $DOCS_DIR/security_setup_summary.md

echo "=== Security Setup Complete ==="
echo ""
echo "All security setup processes have been completed."
echo "Summary documentation created in $DOCS_DIR/security_setup_summary.md"
echo ""
echo "Next steps:"
echo "1. Review documentation in /home/cbwinslow/security_setup/docs/"
echo "2. Configure tools for your specific environment"
echo "3. Log out and back in to use Docker without sudo"
echo "4. Run test scripts to verify installations"
echo "5. Set up monitoring rules and alerts"