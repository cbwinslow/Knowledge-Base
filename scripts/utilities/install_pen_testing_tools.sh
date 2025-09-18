#!/bin/bash

# Penetration Testing Tools Installation Script
# This script installs penetration testing tools including BlackArch tools

echo "=== Penetration Testing Tools Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Penetration Testing Tools Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/pen_testing_tools.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/pen_testing_tools.md
}

# 1. Update package list
log_action "Updating package list..."
sudo apt update

# 2. Install Kali Linux penetration testing tools
log_action "Installing Kali Linux penetration testing tools..."
sudo apt install -y \
    kali-linux-default \
    kali-tools-web \
    kali-tools-passwords \
    kali-tools-wireless \
    kali-tools-exploitation \
    kali-tools-social-engineering

# 3. Install additional penetration testing tools
log_action "Installing additional penetration testing tools..."
sudo apt install -y \
    metasploit-framework \
    nmap \
    sqlmap \
    hydra \
    john \
    aircrack-ng \
    reaver \
    ettercap-graphical \
    dsniff \
    hashcat \
    crunch \
    cewl \
    wpscan \
    nikto \
    sslscan \
    whatweb \
    gobuster \
    dirb \
    wfuzz \
    burpsuite \
    zaproxy

# 4. Install reverse engineering tools
log_action "Installing reverse engineering tools..."
sudo apt install -y \
    radare2 \
    gdb \
    strace \
    ltrace \
    objdump \
    readelf \
    hexedit \
    bless \
    ghidra

# 5. Install BlackArch repository (alternative to full installation)
log_action "Setting up BlackArch repository..."

# Add BlackArch GPG key
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
# Note: We won't actually run strap.sh as it modifies the system significantly
# Instead, we'll document how to do it safely

{
    echo ""
    echo "## BlackArch Repository Setup"
    echo ""
    echo "To install BlackArch tools, you can add the BlackArch repository:"
    echo ""
    echo "1. Download and verify the strap script:"
    echo "   `curl -O https://blackarch.org/strap.sh`"
    echo "   `chmod +x strap.sh`"
    echo ""
    echo "2. Verify the script checksum:"
    echo "   `sha1sum strap.sh`"
    echo "   Compare with the checksum on https://blackarch.org/downloads.html"
    echo ""
    echo "3. Run the strap script:"
    echo "   **WARNING: This will significantly modify your system**"
    echo "   `sudo ./strap.sh`"
    echo ""
    echo "4. After installation, you can install individual tools:"
    echo "   `sudo pacman -S <tool-name>`"
    echo ""
    echo "Or install all tools (NOT RECOMMENDED on production systems):"
    echo "   `sudo pacman -S blackarch`"
    echo ""
    echo "### Safer Alternative"
    echo ""
    echo "Instead of adding the full BlackArch repository, you can:"
    echo "1. Use Docker to run BlackArch tools:"
    echo "   `docker run -it blackarchlinux/blackarch`"
    echo ""
    echo "2. Download individual tools from the BlackArch website:"
    echo "   https://blackarch.org/tools.html"
} >> $DOCS_DIR/pen_testing_tools.md

# 6. Install Docker for containerized security tools
log_action "Installing Docker for containerized tools..."
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $(whoami)

# 7. Create documentation for tools
{
    echo ""
    echo "## Installed Penetration Testing Tools"
    echo ""
    echo "### Network Scanning and Enumeration"
    echo "- Nmap: Network discovery and security auditing"
    echo "- Nikto: Web server scanner"
    echo "- SSLScan: SSL/TLS scanner"
    echo "- WhatWeb: Web scanner"
    echo "- Gobuster: Directory/file brute-forcer"
    echo "- Dirb: Web content scanner"
    echo "- Wfuzz: Web application fuzzer"
    echo ""
    echo "### Exploitation Frameworks"
    echo "- Metasploit Framework: Penetration testing framework"
    echo "- Sqlmap: SQL injection testing tool"
    echo "- Hydra: Network login cracker"
    echo "- John the Ripper: Password cracker"
    echo ""
    echo "### Wireless Testing"
    echo "- Aircrack-ng: WiFi security auditing suite"
    echo "- Reaver: WPS brute force tool"
    echo ""
    echo "### Sniffing and Spoofing"
    echo "- Ettercap: Network sniffer/interceptor"
    echo "- Dsniff: Network auditing toolkit"
    echo ""
    echo "### Password and Hash Cracking"
    echo "- Hashcat: Advanced password recovery"
    echo "- Crunch: Wordlist generator"
    echo "- Cewl: Custom word list generator"
    echo ""
    echo "### Web Application Testing"
    echo "- Burp Suite: Web application security testing platform"
    echo "- OWASP ZAP: Web application security scanner"
    echo "- WPScan: WordPress security scanner"
    echo ""
    echo "### Reverse Engineering"
    echo "- Radare2: Reverse engineering framework"
    echo "- GDB: GNU Debugger"
    echo "- Ghidra: NSA's software reverse engineering suite"
    echo ""
    echo "### Social Engineering"
    echo "- SET (Social-Engineer Toolkit): Social engineering toolkit"
} >> $DOCS_DIR/pen_testing_tools.md

# 8. Document tool usage examples
{
    echo ""
    echo "## Tool Usage Examples"
    echo ""
    echo "### Nmap"
    echo "\`\`\`bash"
    echo "# Basic scan"
    echo "nmap 192.168.1.1"
    echo ""
    echo "# Service detection"
    echo "nmap -sV 192.168.1.1"
    echo ""
    echo "# OS detection"
    echo "nmap -O 192.168.1.1"
    echo "\`\`\`"
    echo ""
    echo "### Sqlmap"
    echo "\`\`\`bash"
    echo "# Test for SQL injection"
    echo "sqlmap -u 'http://target.com/page.php?id=1'"
    echo "\`\`\`"
    echo ""
    echo "### Hydra"
    echo "\`\`\`bash"
    echo "# SSH brute force"
    echo "hydra -l user -P passwords.txt ssh://192.168.1.1"
    echo "\`\`\`"
    echo ""
    echo "### Metasploit"
    echo "\`\`\`bash"
    echo "# Start Metasploit console"
    echo "msfconsole"
    echo ""
    echo "# Search for exploits"
    echo "search ms17-010"
    echo "\`\`\`"
    echo ""
    echo "### Burp Suite"
    echo "\`\`\`bash"
    echo "# Start Burp Suite"
    echo "burpsuite"
    echo "\`\`\`"
} >> $DOCS_DIR/pen_testing_tools.md

# 9. Create test script
log_action "Creating test script..."

mkdir -p /home/cbwinslow/security_setup/tests

cat > /home/cbwinslow/security_setup/tests/test_pen_testing.sh << 'EOL'
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
EOL

chmod +x /home/cbwinslow/security_setup/tests/test_pen_testing.sh

# 10. Document Docker security tools
{
    echo ""
    echo "## Docker Security Tools"
    echo ""
    echo "You can also run security tools in Docker containers:"
    echo ""
    echo "### Kali Linux"
    echo "\`\`\`bash"
    echo "docker run -it kalilinux/kali-rolling"
    echo "\`\`\`"
    echo ""
    echo "### BlackArch"
    echo "\`\`\`bash"
    echo "docker run -it blackarchlinux/blackarch"
    echo "\`\`\`"
    echo ""
    echo "### Specific tools"
    echo "\`\`\`bash"
    echo "# Nmap"
    echo "docker run -it --rm instrumentisto/nmap 192.168.1.1"
    echo ""
    echo "# Nikto"
    echo "docker run -it --rm instrumentisto/nikto -h http://target.com"
    echo "\`\`\`"
} >> $DOCS_DIR/pen_testing_tools.md

# 11. Final summary
{
    echo ""
    echo "## Installation Complete"
    echo ""
    echo "### Installed Tools"
    echo "- Kali Linux penetration testing tools"
    echo "- Metasploit Framework"
    echo "- Nmap, Nikto, Sqlmap, Hydra, John"
    echo "- Aircrack-ng, Reaver"
    echo "- Ettercap, Dsniff"
    echo "- Hashcat, Crunch, Cewl"
    echo "- Burp Suite, OWASP ZAP, WPScan"
    echo "- Radare2, GDB, Ghidra"
    echo "- Docker for containerized tools"
    echo ""
    echo "### Next Steps"
    echo "1. Log out and back in to use Docker without sudo"
    echo "2. Configure tools for your testing environment"
    echo "3. Review BlackArch installation options for more tools"
    echo "4. Test all tools with the test script:"
    echo "   /home/cbwinslow/security_setup/tests/test_pen_testing.sh"
    echo ""
    echo "### Important Notes"
    echo "- These tools should only be used on systems you own or have explicit permission to test"
    echo "- Some tools may be restricted in certain jurisdictions"
    echo "- Always follow responsible disclosure practices"
    echo "- Docker provides a safer way to run these tools without affecting your host system"
    echo ""
    echo "### Documentation"
    echo "Detailed documentation is available in $DOCS_DIR/pen_testing_tools.md"
} >> $DOCS_DIR/pen_testing_tools.md

log_action "Penetration testing tools installation complete!"
echo ""
echo "=== Installation Complete ==="
echo "Documentation created in $DOCS_DIR/pen_testing_tools.md"
echo "Test script available at /home/cbwinslow/security_setup/tests/test_pen_testing.sh"
echo ""
echo "Next steps:"
echo "1. Log out and back in to use Docker without sudo"
echo "2. Configure tools for your testing environment"
echo "3. Run the test script to verify installations"