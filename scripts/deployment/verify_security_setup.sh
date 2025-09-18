#!/bin/bash

# Security Setup Verification Script
# This script verifies that all security components have been installed correctly

echo "=== Security Setup Verification ==="
echo ""

{
    echo "# Security Setup Verification Report"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Verification Results"
    echo ""
} > /home/cbwinslow/security_setup/docs/verification_report.md

# Function to check and document
check_component() {
    local component="$1"
    local command="$2"
    local description="$3"
    
    echo -n "Checking $component... "
    if eval $command &>/dev/null; then
        echo "OK"
        echo "- $component: OK - $description" >> /home/cbwinslow/security_setup/docs/verification_report.md
    else
        echo "NOT FOUND"
        echo "- $component: NOT FOUND - $description" >> /home/cbwinslow/security_setup/docs/verification_report.md
    fi
}

# Check SSH and network access
check_component "SSH Service" "systemctl is-active ssh | grep active" "Secure shell service"
check_component "SSH Listening" "ss -tlnp | grep :22" "SSH port listening"
check_component "Firewall" "sudo ufw status | grep active" "Firewall status"

# Check monitoring tools
check_component "Suricata" "which suricata" "Network IDS/IPS"
check_component "Zeek" "which zeek" "Network security monitor"
check_component "OSSEC" "which ossec-control" "Host-based IDS"
check_component "Nmap" "which nmap" "Network scanner"
check_component "Tcpdump" "which tcpdump" "Packet capture"
check_component "Wireshark" "which wireshark" "Network protocol analyzer"
check_component "Fail2ban" "which fail2ban-client" "Intrusion prevention"

# Check threat intelligence tools
check_component "MISP" "which mysql" "Threat intelligence platform dependency"
check_component "VirusTotal API" "python3 -c 'import vt'" "VirusTotal Python library"
check_component "GreyNoise API" "python3 -c 'import greynoise'" "GreyNoise Python library"
check_component "Snyk" "which snyk" "Developer security platform"
check_component "Nikto" "which nikto" "Web server scanner"
check_component "SQLMap" "which sqlmap" "SQL injection testing tool"
check_component "Burp Suite" "which burpsuite" "Web application security testing"
check_component "ClamAV" "which clamscan" "Antivirus engine"

# Check penetration testing tools
check_component "Metasploit" "which msfconsole" "Penetration testing framework"
check_component "Hydra" "which hydra" "Network login cracker"
check_component "John" "which john" "Password cracker"
check_component "Aircrack-ng" "which aircrack-ng" "WiFi security auditing"
check_component "Radare2" "which radare2" "Reverse engineering framework"
check_component "GDB" "which gdb" "GNU Debugger"
check_component "Docker" "which docker" "Container platform"

# Check open ports
echo ""
echo "Open Ports:"
{
    echo ""
    echo "## Open Ports"
    echo ""
    echo "\`\`\`"
} >> /home/cbwinslow/security_setup/docs/verification_report.md

ss -tlnp | grep -E "(22|80|443|3128)" >> /home/cbwinslow/security_setup/docs/verification_report.md
echo "\`\`\`" >> /home/cbwinslow/security_setup/docs/verification_report.md

# Check service versions
{
    echo ""
    echo "## Service Versions"
    echo ""
} >> /home/cbwinslow/security_setup/docs/verification_report.md

echo "Service Versions:"
for service in "SSH:sshd" "Docker:docker" "Nmap:nmap" "Metasploit:msfconsole"; do
    name=${service%:*}
    cmd=${service#*:}
    if which $cmd &>/dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        echo "  $name: $version"
        echo "- $name: $version" >> /home/cbwinslow/security_setup/docs/verification_report.md
    fi
done

echo ""
echo "Verification complete."
echo "Full report available in /home/cbwinslow/security_setup/docs/verification_report.md"