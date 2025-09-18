#!/bin/bash

# Security Setup Troubleshooting Script
# This script helps troubleshoot common issues with the security setup

echo "=== Security Setup Troubleshooting ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Security Setup Troubleshooting Guide"
    echo ""
    echo "Date: $(date)"
    echo ""
} > $DOCS_DIR/troubleshooting.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/troubleshooting.md
}

# 1. Check SSH configuration
log_action "Checking SSH configuration..."
echo "1. SSH Configuration:"
echo "   SSH service status:"
systemctl status ssh --no-pager | grep -E "Active|Loaded"
echo ""

# 2. Check firewall status
log_action "Checking firewall status..."
echo "2. Firewall Status:"
if command -v ufw &> /dev/null; then
    sudo ufw status verbose
else
    echo "   UFW firewall not installed"
fi
echo ""

# 3. Check installed security tools
log_action "Checking installed security tools..."
echo "3. Installed Security Tools:"
which suricata zeek ossec-control nmap nikto sqlmap burpsuite 2>/dev/null || echo "   Some security tools not installed"
echo ""

# 4. Check Docker status
log_action "Checking Docker status..."
echo "4. Docker Status:"
if command -v docker &> /dev/null; then
    systemctl status docker --no-pager | grep -E "Active|Loaded"
    echo "   Docker version: $(docker --version)"
else
    echo "   Docker not installed"
fi
echo ""

# 5. Check Python packages
log_action "Checking Python packages..."
echo "5. Python Security Packages:"
pip3 list | grep -E "(vt|greynoise|snyk)" 2>/dev/null || echo "   Threat intelligence packages not installed"
echo ""

# 6. Check network connectivity
log_action "Checking network connectivity..."
echo "6. Network Connectivity:"
echo "   Local IP addresses:"
ip addr show | grep -E "inet.*eth|inet.*ens|inet.*enp" | awk '{print "   "$2" "$4}'
echo "   Default gateway:"
ip route | grep default
echo ""

# 7. Document common issues and solutions
{
    echo ""
    echo "## Common Issues and Solutions"
    echo ""
    echo "### SSH Issues"
    echo "- Problem: Cannot connect via SSH"
    echo "  Solution: Check SSH config (/etc/ssh/sshd_config), firewall rules, and public key in ~/.ssh/authorized_keys"
    echo ""
    echo "- Problem: Permission denied (publickey)"
    echo "  Solution: Ensure your public key is in ~/.ssh/authorized_keys with correct permissions (600)"
    echo ""
    echo "### Firewall Issues"
    echo "- Problem: Cannot access services"
    echo "  Solution: Check UFW rules with 'sudo ufw status' and add rules as needed"
    echo ""
    echo "### Docker Issues"
    echo "- Problem: Permission denied when running Docker"
    echo "  Solution: Add user to docker group with 'sudo usermod -aG docker $USER' and log out/in"
    echo ""
    echo "### Package Installation Issues"
    echo "- Problem: Missing packages like libjpeg62-turbo-dev"
    echo "  Solution: Use alternative packages like libjpeg-turbo8-dev"
    echo ""
    echo "### PostgreSQL Issues"
    echo "- Problem: PostgreSQL not starting"
    echo "  Solution: Check logs with 'sudo journalctl -u postgresql' and config in /etc/postgresql/"
    echo ""
    echo "### Monitoring Tools Issues"
    echo "- Problem: Suricata not detecting traffic"
    echo "  Solution: Check interface configuration in /etc/suricata/suricata.yaml"
    echo ""
    echo "### Penetration Testing Tools Issues"
    echo "- Problem: Metasploit database not connected"
    echo "  Solution: Initialize database with 'msfdb init' and check PostgreSQL connection"
} >> $DOCS_DIR/troubleshooting.md

# 8. Create quick fix scripts
log_action "Creating quick fix scripts..."

mkdir -p /home/cbwinslow/security_setup/fixes

cat > /home/cbwinslow/security_setup/fixes/fix_ssh.sh << 'EOL'
#!/bin/bash
echo "Fixing SSH issues..."
sudo systemctl restart ssh
echo "SSH service restarted."
EOL

cat > /home/cbwinslow/security_setup/fixes/fix_firewall.sh << 'EOL'
#!/bin/bash
echo "Fixing firewall issues..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3128/tcp
sudo ufw reload
echo "Firewall rules updated."
EOL

cat > /home/cbwinslow/security_setup/fixes/fix_docker.sh << 'EOL'
#!/bin/bash
echo "Fixing Docker issues..."
sudo usermod -aG docker $USER
echo "User added to docker group. Please log out and back in."
EOL

chmod +x /home/cbwinslow/security_setup/fixes/fix_ssh.sh
chmod +x /home/cbwinslow/security_setup/fixes/fix_firewall.sh
chmod +x /home/cbwinslow/security_setup/fixes/fix_docker.sh

# 9. Final summary
{
    echo ""
    echo "## Troubleshooting Complete"
    echo ""
    echo "### Quick Fix Scripts"
    echo "Available in /home/cbwinslow/security_setup/fixes/:"
    echo "- fix_ssh.sh: Restart SSH service"
    echo "- fix_firewall.sh: Update firewall rules"
    echo "- fix_docker.sh: Fix Docker permissions"
    echo ""
    echo "### Additional Resources"
    echo "- Full troubleshooting guide: $DOCS_DIR/troubleshooting.md"
    echo "- Check service status: systemctl status <service_name>"
    echo "- Check logs: journalctl -u <service_name>"
    echo "- View listening ports: ss -tlnp"
} >> $DOCS_DIR/troubleshooting.md

log_action "Troubleshooting complete!"
echo ""
echo "=== Troubleshooting Complete ==="
echo "Documentation created in $DOCS_DIR/troubleshooting.md"
echo "Quick fix scripts available in /home/cbwinslow/security_setup/fixes/"
echo ""
echo "Common issues and solutions have been documented."