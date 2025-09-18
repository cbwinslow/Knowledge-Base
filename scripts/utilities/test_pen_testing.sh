#!/bin/bash

echo "=== Testing Penetration Testing Tools ==="
echo ""

echo "1. Testing network tools..."
which nmap nikto sslscan whatweb &>/dev/null && echo "Network tools installed" || echo "Some network tools missing"

echo ""
echo "2. Testing exploitation frameworks..."
which msfconsole sqlmap hydra john &>/dev/null && echo "Exploitation frameworks installed" || echo "Some exploitation frameworks missing"

echo ""
echo "3. Testing web application tools..."
which burpsuite zaproxy wpscan &>/dev/null && echo "Web application tools installed" || echo "Some web application tools missing"

echo ""
echo "4. Testing reverse engineering tools..."
which radare2 gdb ghidra &>/dev/null && echo "Reverse engineering tools installed" || echo "Some reverse engineering tools missing"

echo ""
echo "=== Test Complete ==="
