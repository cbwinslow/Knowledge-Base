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
