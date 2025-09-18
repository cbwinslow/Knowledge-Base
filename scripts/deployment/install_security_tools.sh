#!/bin/bash

# Security Tools Installation Script
# This script installs missing security tools for network monitoring, penetration testing, and forensics

echo "=== Security Tools Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Security Tools Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/security_tools_install.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/security_tools_install.md
}

# 1. Update package list
log_action "Updating package list..."
sudo apt update

# 2. Install network monitoring tools
log_action "Installing network monitoring tools..."

# Install Zeek (Bro)
sudo apt install -y zeek

# Install OSSEC
sudo apt install -y ossec-hids

# Install additional network tools
sudo apt install -y \
    nmap \
    nikto \
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
    sslscan \
    whatweb \
    gobuster \
    dirb \
    wfuzz

# 3. Install web application testing tools
log_action "Installing web application testing tools..."

# Install Burp Suite
sudo apt install -y burpsuite

# Install ZAP (OWASP ZAP)
sudo apt install -y zaproxy

# 4. Install penetration testing frameworks
log_action "Installing penetration testing frameworks..."

# Install Metasploit Framework
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall
rm msfinstall

# 5. Install reverse engineering tools
log_action "Installing reverse engineering tools..."

# Install additional reverse engineering tools
sudo apt install -y \
    radare2 \
    gdb \
    ltrace \
    hexedit \
    bless \
    ghidra

# 6. Install forensic tools
log_action "Installing forensic tools..."

sudo apt install -y \
    volatility \
    foremost \
    sleuthkit \
    autopsy \
    testdisk

# 7. Install threat intelligence tools
log_action "Installing threat intelligence tools..."

# Install Python packages for threat intelligence
pip3 install \
    vt-py \
    greynoise \
    requests \
    pandas \
    numpy

# 8. Install logging and analysis tools
log_action "Installing logging and analysis tools..."

sudo apt install -y \
    logwatch \
    multitail \
    lnav

# 9. Install additional useful tools
log_action "Installing additional useful tools..."

sudo apt install -y \
    yara \
    tcpdump \
    wireshark \
    tshark \
    netstat-nat \
    iftop \
    nethogs \
    bmon

# 10. Create documentation for installed tools
{
    echo ""
    echo "## Installed Security Tools"
    echo ""
    echo "### Network Monitoring"
    echo "- Suricata: Network IDS/IPS (already installed)"
    echo "- Zeek: Network security monitor"
    echo "- OSSEC: Host-based IDS"
    echo "- Nmap: Network scanner"
    echo "- Tcpdump: Packet capture"
    echo "- Wireshark/Tshark: Network protocol analyzer"
    echo "- Netstat-nat: Network statistics for NAT connections"
    echo "- Iftop: Network bandwidth monitoring"
    echo "- Nethogs: Per-process network bandwidth monitoring"
    echo "- Bmon: Network bandwidth monitor and rate estimator"
    echo ""
    echo "### Web Application Testing"
    echo "- Nikto: Web server scanner"
    echo "- SQLMap: SQL injection testing tool"
    echo "- Burp Suite: Web application security testing platform"
    echo "- ZAP (OWASP ZAP): Web application security scanner"
    echo "- SSLScan: SSL/TLS scanner"
    echo "- WhatWeb: Web scanner"
    echo "- Gobuster: Directory/file brute-forcer"
    echo "- Dirb: Web content scanner"
    echo "- Wfuzz: Web application fuzzer"
    echo ""
    echo "### Penetration Testing"
    echo "- Hydra: Network login cracker"
    echo "- John the Ripper: Password cracker"
    echo "- Aircrack-ng: WiFi security auditing suite"
    echo "- Reaver: WPS brute force tool"
    echo "- Ettercap: Network sniffer/interceptor"
    echo "- Dsniff: Network auditing toolkit"
    echo "- Hashcat: Advanced password recovery"
    echo "- Crunch: Wordlist generator"
    echo "- Cewl: Custom word list generator"
    echo "- Wpscan: WordPress security scanner"
    echo "- Metasploit Framework: Penetration testing framework"
    echo ""
    echo "### Reverse Engineering"
    echo "- Radare2: Reverse engineering framework"
    echo "- GDB: GNU Debugger"
    echo "- Ltrace: Library call tracer"
    echo "- Hexedit: Hexadecimal editor"
    echo "- Bless: GUI hexadecimal editor"
    echo "- Ghidra: NSA's software reverse engineering suite"
    echo ""
    echo "### Forensics"
    echo "- Volatility: Memory forensics framework"
    echo "- Foremost: File recovery tool"
    echo "- Sleuth Kit: Digital forensics toolkit"
    echo "- Autopsy: Digital forensics platform"
    echo "- TestDisk: Data recovery tool"
    echo ""
    echo "### Threat Intelligence"
    echo "- VirusTotal API: Python library for VirusTotal"
    echo "- GreyNoise: Python library for GreyNoise API"
    echo "- YARA: Pattern matching tool for malware identification"
    echo "- Requests: HTTP library for Python"
    echo "- Pandas: Data analysis library for Python"
    echo "- NumPy: Numerical computing library for Python"
    echo ""
    echo "### Logging and Analysis"
    echo "- Logwatch: Log analyzer and reporter"
    echo "- Multitail: View multiple log files simultaneously"
    echo "- Lnav: Log file navigator"
    echo ""
} >> $DOCS_DIR/security_tools_install.md

# 11. Create test script to verify installations
log_action "Creating test script..."

mkdir -p /home/cbwinslow/security_setup/tests

cat > /home/cbwinslow/security_setup/tests/test_security_tools.sh << 'EOL'
#!/bin/bash

echo "=== Testing Security Tools ==="
echo ""

echo "1. Testing network monitoring tools..."
which suricata zeek ossec-agent nmap nikto sqlmap &>/dev/null && echo "Network monitoring tools installed" || echo "Some network monitoring tools missing"

echo ""
echo "2. Testing penetration testing tools..."
which hydra john aircrack-ng reaver ettercap dsniff hashcat crunch cewl wpscan sslscan whatweb gobuster dirb wfuzz &>/dev/null && echo "Penetration testing tools installed" || echo "Some penetration testing tools missing"

echo ""
echo "3. Testing web application testing tools..."
which burpsuite zaproxy &>/dev/null && echo "Web application testing tools installed" || echo "Some web application testing tools missing"

echo ""
echo "4. Testing reverse engineering tools..."
which radare2 gdb ltrace hexedit bless ghidra &>/dev/null && echo "Reverse engineering tools installed" || echo "Some reverse engineering tools missing"

echo ""
echo "5. Testing forensic tools..."
which volatility foremost sleuthkit autopsy testdisk &>/dev/null && echo "Forensic tools installed" || echo "Some forensic tools missing"

echo ""
echo "6. Testing threat intelligence tools..."
python3 -c "import vt, greynoise, requests, pandas, numpy; print('Python threat intelligence libraries installed')" 2>/dev/null || echo "Some Python threat intelligence libraries missing"

echo ""
echo "7. Testing logging and analysis tools..."
which logwatch multitail lnav &>/dev/null && echo "Logging and analysis tools installed" || echo "Some logging and analysis tools missing"

echo ""
echo "8. Testing additional tools..."
which yara tcpdump wireshark tshark iftop nethogs bmon &>/dev/null && echo "Additional tools installed" || echo "Some additional tools missing"

echo ""
echo "=== Test Complete ==="
EOL

chmod +x /home/cbwinslow/security_setup/tests/test_security_tools.sh

# 12. Final summary
{
    echo ""
    echo "## Installation Complete"
    echo ""
    echo "### Next Steps"
    echo "1. Run the test script to verify installations:"
    echo "   /home/cbwinslow/security_setup/tests/test_security_tools.sh"
    echo ""
    echo "2. Configure tools for your specific environment:"
    echo "   - Suricata: /etc/suricata/suricata.yaml"
    echo "   - Zeek: /opt/zeek/etc/node.cfg"
    echo "   - OSSEC: /var/ossec/etc/ossec.conf"
    echo ""
    echo "3. Start services as needed:"
    echo "   - Suricata: sudo systemctl start suricata"
    echo "   - Zeek: sudo systemctl start zeek"
    echo "   - OSSEC: sudo /var/ossec/bin/ossec-control start"
    echo ""
    echo "4. Check documentation in $DOCS_DIR/security_tools_install.md"
    echo ""
    echo "### Important Notes"
    echo "- Some tools may require additional configuration"
    echo "- Metasploit Framework was installed separately and may require database setup"
    echo "- Web application tools (Burp Suite, ZAP) may require GUI access"
    echo "- Some tools may have licensing restrictions"
    echo "- Always follow responsible disclosure practices when using these tools"
} >> $DOCS_DIR/security_tools_install.md

log_action "Security tools installation complete!"
echo ""
echo "=== Installation Complete ==="
echo "Documentation created in $DOCS_DIR/security_tools_install.md"
echo "Test script available at /home/cbwinslow/security_setup/tests/test_security_tools.sh"
echo ""
echo "Next steps:"
echo "1. Run the test script to verify installations"
echo "2. Configure tools for your specific environment"
echo "3. Start services as needed"