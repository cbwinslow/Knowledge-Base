#!/bin/bash

# Server Setup Verification Script
# This script verifies that all components have been installed correctly

echo "=== Server Setup Verification ==="
echo ""

{
    echo "# Server Setup Verification Report"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Verification Results"
    echo ""
} > /home/cbwinslow/server_setup/docs/verification_report.md

# Function to check and document
check_component() {
    local component="$1"
    local command="$2"
    local description="$3"
    
    echo -n "Checking $component... "
    if eval $command &>/dev/null; then
        echo "OK"
        echo "- $component: OK - $description" >> /home/cbwinslow/server_setup/docs/verification_report.md
    else
        echo "NOT FOUND"
        echo "- $component: NOT FOUND - $description" >> /home/cbwinslow/server_setup/docs/verification_report.md
    fi
}

# Check all components
check_component "SSH" "systemctl is-active ssh | grep active" "Secure shell service"
check_component "Squid" "systemctl is-active squid | grep active" "Proxy server"
check_component "ZeroTier" "systemctl is-active zerotier-one | grep active" "VPN networking"
check_component "Docker" "systemctl is-active docker | grep active" "Container platform"
check_component "Nginx" "systemctl is-active nginx | grep active" "Web server"
check_component "fail2ban" "systemctl is-active fail2ban | grep active" "Security tool"
check_component "Ansible" "which ansible" "Automation tool"
check_component "Node.js" "which node" "JavaScript runtime"
check_component "Python pip" "which pip3" "Python package manager"
check_component "WireGuard" "which wg" "VPN tunnel"

# Check firewall
echo -n "Checking Firewall... "
if sudo ufw status | grep -q "Status: active"; then
    echo "ACTIVE"
    echo "- Firewall: ACTIVE" >> /home/cbwinslow/server_setup/docs/verification_report.md
else
    echo "INACTIVE"
    echo "- Firewall: INACTIVE" >> /home/cbwinslow/server_setup/docs/verification_report.md
fi

# Check open ports
echo ""
echo "Open Ports:"
sudo ufw status verbose | grep -E "^\d+|" >> /home/cbwinslow/server_setup/docs/verification_report.md

# Check service versions
{
    echo ""
    echo "## Service Versions"
    echo ""
} >> /home/cbwinslow/server_setup/docs/verification_report.md

echo "Service Versions:"
for service in "SSH:sshd" "Squid:squid" "Docker:docker" "Nginx:nginx" "Ansible:ansible" "Node.js:node" "Python:python3"; do
    name=${service%:*}
    cmd=${service#*:}
    if which $cmd &>/dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        echo "  $name: $version"
        echo "- $name: $version" >> /home/cbwinslow/server_setup/docs/verification_report.md
    fi
done

echo ""
echo "Verification complete."
echo "Full report available in /home/cbwinslow/server_setup/docs/verification_report.md"