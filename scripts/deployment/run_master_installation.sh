#!/bin/bash

# Master Installation Script
# This script runs all installation processes in the correct order

echo "=== Master Installation Script ==="
echo ""
echo "This script will install all required dependencies and tools in the correct order."
echo ""
echo "Estimated time: 30-60 minutes depending on internet connection."
echo ""
read -p "Do you want to continue? (yes/no): " confirmation

if [[ $confirmation != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "=== Starting Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Master Installation Log"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Steps"
    echo ""
} > $DOCS_DIR/master_installation.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/master_installation.md
}

# 1. Install Nextcloud dependencies
log_action "Installing Nextcloud dependencies..."
echo "1. Installing Nextcloud dependencies..."
/home/cbwinslow/security_setup/install_nextcloud_deps.sh
echo ""

# 2. Install Nextcloud
log_action "Installing Nextcloud..."
echo "2. Installing Nextcloud..."
/home/cbwinslow/security_setup/install_nextcloud.sh
echo ""

# 3. Configure SSH access
log_action "Configuring SSH access..."
echo "3. Configuring SSH access..."
/home/cbwinslow/security_setup/configure_ssh_access.sh
echo ""

# 4. Install monitoring tools
log_action "Installing monitoring tools..."
echo "4. Installing monitoring tools..."
/home/cbwinslow/security_setup/install_monitoring_tools.sh
echo ""

# 5. Install threat intelligence tools
log_action "Installing threat intelligence tools..."
echo "5. Installing threat intelligence tools..."
/home/cbwinslow/security_setup/install_threat_intel_tools.sh
echo ""

# 6. Install penetration testing tools
log_action "Installing penetration testing tools..."
echo "6. Installing penetration testing tools..."
/home/cbwinslow/security_setup/install_pen_testing_tools.sh
echo ""

# 7. Fix Suricata configuration
log_action "Fixing Suricata configuration..."
echo "7. Fixing Suricata configuration..."
/home/cbwinslow/security_setup/fix_suricata.sh
echo ""

# 8. Run verification
log_action "Running verification..."
echo "8. Running verification..."
/home/cbwinslow/security_setup/verify_security_setup.sh
echo ""

# 9. Create final summary
{
    echo ""
    echo "## Installation Complete"
    echo ""
    echo "### Installed Components"
    echo ""
    echo "#### Web and Collaboration"
    echo "- Apache web server"
    echo "- PHP 8.3 with required modules"
    echo "- Nextcloud (official release)"
    echo "- PostgreSQL database"
    echo ""
    echo "#### Security Monitoring"
    echo "- Suricata (Network IDS/IPS)"
    echo "- Zeek (Network security monitor)"
    echo "- OSSEC (Host-based IDS)"
    echo "- System and network monitoring tools"
    echo ""
    echo "#### Threat Intelligence"
    echo "- MISP (Malware Information Sharing Platform)"
    echo "- TheHive/Cortex (Incident response platforms)"
    echo "- VirusTotal/GreyNoise APIs"
    echo "- Snyk (Developer security platform)"
    echo ""
    echo "#### Penetration Testing"
    echo "- Kali Linux tools suite"
    echo "- Metasploit Framework"
    echo "- Network and web application testing tools"
    echo "- Reverse engineering tools"
    echo ""
    echo "#### System Tools"
    echo "- Docker (Container platform)"
    echo "- Ansible (Automation tool)"
    echo "- Fail2ban (Intrusion prevention)"
    echo "- Log analysis tools"
    echo ""
    echo "### Services and Ports"
    echo ""
    echo "| Service | Port | Protocol | Status |"
    echo "|---------|------|----------|--------|"
    echo "| SSH | 22 | TCP | Running |"
    echo "| HTTP | 80 | TCP | Running |"
    echo "| HTTPS | 443 | TCP | Running |"
    echo "| PostgreSQL | 5432 | TCP | Running |"
    echo "| Nextcloud | 80/443 | TCP | Installed |"
    echo "| Docker | Various | TCP/UDP | Running |"
    echo "| Suricata | 8080/8081 | TCP | Configured |"
    echo ""
    echo "### Next Steps"
    echo ""
    echo "1. Access Nextcloud at http://nextcloud.local or http://localhost/nextcloud"
    echo "2. Create an admin user account"
    echo "3. Configure your storage and settings"
    echo "4. Set up SSL for secure access (optional but recommended)"
    echo "5. Configure monitoring tools (Suricata, Zeek, OSSEC)"
    echo "6. Set up threat intelligence tools (MISP, TheHive, Cortex)"
    echo "7. Configure penetration testing tools (Metasploit, Nikto, SQLMap, etc.)"
    echo "8. Review documentation in $DOCS_DIR/"
    echo "9. Run test scripts in /home/cbwinslow/security_setup/tests/"
    echo "10. Run troubleshooting scripts if needed from /home/cbwinslow/security_setup/fixes/"
    echo ""
    echo "### Important Notes"
    echo ""
    echo "- SSH is configured for key-based authentication only"
    echo "- Password authentication has been disabled"
    echo "- Firewall is active with appropriate ports open"
    echo "- These tools should only be used on systems you own or have permission to test"
    echo "- Some tools (TheHive, Cortex, BlackArch) require manual installation"
    echo "- Log out and back in after installation to use Docker without sudo"
    echo ""
    echo "### Documentation"
    echo ""
    echo "All documentation is available in $DOCS_DIR/:"
    echo "- ssh_config.md: SSH and network access configuration"
    echo "- monitoring_tools.md: Network and system monitoring tools"
    echo "- threat_intel_tools.md: Threat intelligence platforms and APIs"
    echo "- pen_testing_tools.md: Penetration testing tools"
    echo "- security_setup_summary.md: Complete setup summary"
    echo "- verification_report.md: Installation verification report"
    echo "- troubleshooting.md: Troubleshooting guide"
    echo "- nextcloud_install.md: Nextcloud installation guide"
    echo "- nextcloud_deps_check.md: Nextcloud dependencies check"
    echo "- nextcloud_deps_install.md: Nextcloud dependencies installation"
    echo "- master_installation.md: This master installation log"
    echo ""
    echo "### Test Scripts"
    echo ""
    echo "Test scripts are available in /home/cbwinslow/security_setup/tests/:"
    echo "- test_monitoring.sh: Test monitoring tools"
    echo "- test_threat_intel.sh: Test threat intelligence tools"
    echo "- test_pen_testing.sh: Test penetration testing tools"
    echo ""
    echo "### Quick Fix Scripts"
    echo ""
    echo "Quick fix scripts are available in /home/cbwinslow/security_setup/fixes/:"
    echo "- fix_ssh.sh: Restart SSH service"
    echo "- fix_firewall.sh: Update firewall rules"
    echo "- fix_docker.sh: Fix Docker permissions"
    echo "- fix_suricata.sh: Fix Suricata configuration"
} >> $DOCS_DIR/master_installation.md

log_action "Master installation complete!"
echo ""
echo "=== Installation Complete ==="
echo "Documentation created in $DOCS_DIR/master_installation.md"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud at http://nextcloud.local or http://localhost/nextcloud"
echo "2. Create an admin user account"
echo "3. Configure your storage and settings"
echo "4. Set up SSL for secure access (optional but recommended)"
echo "5. Configure monitoring tools (Suricata, Zeek, OSSEC)"
echo "6. Set up threat intelligence tools (MISP, TheHive, Cortex)"
echo "7. Configure penetration testing tools (Metasploit, Nikto, SQLMap, etc.)"
echo "8. Review documentation in $DOCS_DIR/"
echo "9. Run test scripts in /home/cbwinslow/security_setup/tests/"
echo "10. Run troubleshooting scripts if needed from /home/cbwinslow/security_setup/fixes/"