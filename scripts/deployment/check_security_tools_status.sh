#!/bin/bash

# Security Tools Status Check Script
# This script checks the status of all installed security tools

echo "=== Security Tools Status Check ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Security Tools Status Check"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Status Report"
    echo ""
} > $DOCS_DIR/security_tools_status.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/security_tools_status.md
}

# 1. Check SSH status
log_action "Checking SSH status..."
echo "1. SSH Status:"
systemctl status ssh --no-pager | grep -E "Active|Loaded" || echo "SSH service not found"
echo ""

# 2. Check Docker status
log_action "Checking Docker status..."
echo "2. Docker Status:"
systemctl status docker --no-pager | grep -E "Active|Loaded" || echo "Docker service not found"
echo ""

# 3. Check PostgreSQL status
log_action "Checking PostgreSQL status..."
echo "3. PostgreSQL Status:"
systemctl status postgresql --no-pager | grep -E "Active|Loaded" || echo "PostgreSQL service not found"
echo ""

# 4. Check Apache status
log_action "Checking Apache status..."
echo "4. Apache Status:"
systemctl status apache2 --no-pager | grep -E "Active|Loaded" || echo "Apache service not found"
echo ""

# 5. Check Suricata status
log_action "Checking Suricata status..."
echo "5. Suricata Status:"
systemctl status suricata --no-pager | grep -E "Active|Loaded" || echo "Suricata service not found"
echo ""

# 6. Check Zeek status
log_action "Checking Zeek status..."
echo "6. Zeek Status:"
systemctl status zeek --no-pager | grep -E "Active|Loaded" || echo "Zeek service not found"
echo ""

# 7. Check OSSEC status
log_action "Checking OSSEC status..."
echo "7. OSSEC Status:"
systemctl status ossec --no-pager | grep -E "Active|Loaded" || echo "OSSEC service not found"
echo ""

# 8. Check Fail2ban status
log_action "Checking Fail2ban status..."
echo "8. Fail2ban Status:"
systemctl status fail2ban --no-pager | grep -E "Active|Loaded" || echo "Fail2ban service not found"
echo ""

# 9. Check firewall status
log_action "Checking firewall status..."
echo "9. Firewall Status:"
sudo ufw status verbose 2>/dev/null || echo "UFW firewall not found"
echo ""

# 10. Check installed security tools
log_action "Checking installed security tools..."
echo "10. Installed Security Tools:"

# Network monitoring tools
echo "   Network Monitoring Tools:"
which suricata zeek ossec-agent nmap nikto sqlmap hydra john aircrack-ng reaver ettercap dsniff hashcat crunch cewl wpscan sslscan whatweb gobuster dirb wfuzz burpsuite zaproxy metasploit-framework radare2 gdb strace ltrace objdump readelf hexedit bless ghidra &>/dev/null && echo "     - Network monitoring tools installed" || echo "     - Some network monitoring tools missing"

# Threat intelligence tools
echo "   Threat Intelligence Tools:"
which misp zeek ossec-server &>/dev/null && echo "     - Threat intelligence tools installed" || echo "     - Some threat intelligence tools missing"

# Penetration testing tools
echo "   Penetration Testing Tools:"
which msfconsole sqlmap hydra john aircrack-ng reaver ettercap dsniff hashcat crunch cewl wpscan sslscan whatweb gobuster dirb wfuzz burpsuite zaproxy &>/dev/null && echo "     - Penetration testing tools installed" || echo "     - Some penetration testing tools missing"

# Reverse engineering tools
echo "   Reverse Engineering Tools:"
which radare2 gdb ltrace strace objdump readelf hexedit bless ghidra &>/dev/null && echo "     - Reverse engineering tools installed" || echo "     - Some reverse engineering tools missing"

echo ""

# 11. Check listening ports
log_action "Checking listening ports..."
{
    echo ""
    echo "## Listening Ports"
    echo ""
    echo "\`\`\`"
} >> $DOCS_DIR/security_tools_status.md

echo "11. Listening Ports:"
ss -tlnp | grep -E "(22|80|443|5432|3128|9090|9099)" >> $DOCS_DIR/security_tools_status.md
echo "\`\`\`" >> $DOCS_DIR/security_tools_status.md

echo ""

# 12. Summary
{
    echo ""
    echo "## Summary"
    echo ""
} >> $DOCS_DIR/security_tools_status.md

echo "=== Status Check Complete ==="
echo "Documentation created in $DOCS_DIR/security_tools_status.md"
echo ""
echo "Next steps:"
echo "1. Review the status report to identify any missing tools"
echo "2. Install any missing tools as needed"
echo "3. Configure tools that are installed but not running"
echo "4. Check documentation in $DOCS_DIR/security_tools_status.md"