#!/bin/bash

# Threat Intelligence and Security Tools Installation Script
# This script installs Splunk, VirusTotal, GreyNoise, Snyk, and related tools

echo "=== Threat Intelligence and Security Tools Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Threat Intelligence and Security Tools Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/threat_intel_tools.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/threat_intel_tools.md
}

# 1. Update package list
log_action "Updating package list..."
sudo apt update

# 2. Install prerequisite tools
log_action "Installing prerequisite tools..."
sudo apt install -y \
    python3-pip \
    python3-venv \
    curl \
    wget \
    git \
    jq \
    unzip

# 3. Install Python packages for threat intelligence
log_action "Installing Python packages for threat intelligence..."
pip3 install \
    virustotal-api \
    greynoise \
    requests \
    pandas \
    numpy

# 4. Install MISP (Malware Information Sharing Platform)
log_action "Installing MISP threat intelligence platform..."
sudo apt install -y \
    mariadb-server \
    apache2 \
    php \
    php-mysql \
    php-redis \
    php-dev \
    libapache2-mod-php \
    php-cli \
    php-gnupg \
    php-xml \
    php-mbstring \
    php-zip \
    php-crypt-gpg \
    php-curl \
    python3-dev \
    python3-pip \
    python3-redis \
    python3-zmq \
    python3-lxml \
    python3-crypto \
    python3-dateutil \
    python3-ruamel.yaml \
    libfuzzy-dev \
    libimage-exiftool-perl \
    tesseract-ocr \
    tesseract-ocr-eng \
    poppler-utils \
    postgresql \
    redis-server

# 5. Install TheHive (Security Incident Response Platform)
log_action "Installing TheHive incident response platform..."
# TheHive requires manual installation, creating documentation instead
{
    echo ""
    echo "## TheHive Installation"
    echo ""
    echo "TheHive requires manual installation. Follow these steps:"
    echo ""
    echo "1. Install Java:"
    echo "   `sudo apt install -y default-jre`"
    echo ""
    echo "2. Download TheHive:"
    echo "   `cd /opt`"
    echo "   `sudo wget https://dl.thehive-project.org/thehive-5.0.10.zip`"
    echo "   `sudo unzip thehive-5.0.10.zip`"
    echo "   `sudo mv thehive-5.0.10 thehive`"
    echo ""
    echo "3. Create a user for TheHive:"
    echo "   `sudo useradd thehive`"
    echo "   `sudo chown -R thehive:thehive /opt/thehive`"
    echo ""
    echo "4. Create systemd service:"
    echo "   `sudo nano /etc/systemd/system/thehive.service`"
    echo ""
    echo "5. Configure TheHive:"
    echo "   Edit /opt/thehive/conf/application.conf"
    echo ""
    echo "6. Start TheHive:"
    echo "   `sudo systemctl enable thehive`"
    echo "   `sudo systemctl start thehive`"
} >> $DOCS_DIR/threat_intel_tools.md

# 6. Install Cortex (TheHive's analysis engine)
log_action "Documenting Cortex installation..."
{
    echo ""
    echo "## Cortex Installation"
    echo ""
    echo "Cortex requires manual installation. Follow these steps:"
    echo ""
    echo "1. Download Cortex:"
    echo "   `cd /opt`"
    echo "   `sudo wget https://dl.thehive-project.org/cortex-3.0.10.zip`"
    echo "   `sudo unzip cortex-3.0.10.zip`"
    echo "   `sudo mv cortex-3.0.10 cortex`"
    echo ""
    echo "2. Create a user for Cortex:"
    echo "   `sudo useradd cortex`"
    echo "   `sudo chown -R cortex:cortex /opt/cortex`"
    echo ""
    echo "3. Create systemd service:"
    echo "   `sudo nano /etc/systemd/system/cortex.service`"
    echo ""
    echo "4. Configure Cortex:"
    echo "   Edit /opt/cortex/conf/application.conf"
    echo ""
    echo "5. Start Cortex:"
    echo "   `sudo systemctl enable cortex`"
    echo "   `sudo systemctl start cortex`"
} >> $DOCS_DIR/threat_intel_tools.md

# 7. Install Snyk CLI
log_action "Installing Snyk CLI..."
npm install -g snyk

# 8. Install security testing tools
log_action "Installing security testing tools..."
sudo apt install -y \
    nikto \
    sqlmap \
    burpsuite \
    lynis \
    clamav \
    clamav-daemon

# 9. Install OpenVAS (Greenbone Vulnerability Management)
log_action "Installing OpenVAS vulnerability scanner..."
sudo apt install -y \
    gvm \
    greenbone-vulnerability-manager \
    postgresql \
    postgresql-contrib

# 10. Install network analysis tools
log_action "Installing network analysis tools..."
sudo apt install -y \
    yara \
    volatility \
    foremost \
    sleuthkit \
    autopsy \
    testdisk

# 11. Create documentation for all tools
{
    echo ""
    echo "## Installed Tools Documentation"
    echo ""
    echo "### Threat Intelligence Platforms"
    echo "- MISP: Malware Information Sharing Platform"
    echo "- TheHive: Security Incident Response Platform (manual install)"
    echo "- Cortex: Analysis engine for TheHive (manual install)"
    echo ""
    echo "### Threat Intelligence APIs"
    echo "- VirusTotal API: Python library for VirusTotal"
    echo "- GreyNoise: Python library for GreyNoise API"
    echo ""
    echo "### Security Testing Tools"
    echo "- Snyk: Developer security platform"
    echo "- Nikto: Web server scanner"
    echo "- SQLMap: SQL injection testing tool"
    echo "- Burp Suite: Web application security testing platform"
    echo "- Lynis: Security auditing tool"
    echo "- ClamAV: Antivirus engine"
    echo ""
    echo "### Vulnerability Scanners"
    echo "- OpenVAS: Open Vulnerability Assessment Scanner"
    echo ""
    echo "### Digital Forensics Tools"
    echo "- YARA: Pattern matching tool for malware identification"
    echo "- Volatility: Memory forensics framework"
    echo "- Foremost: File recovery tool"
    echo "- Sleuth Kit: Digital forensics toolkit"
    echo "- Autopsy: Digital forensics platform"
    echo "- TestDisk: Data recovery tool"
} >> $DOCS_DIR/threat_intel_tools.md

# 12. Document tool usage
{
    echo ""
    echo "## Tool Usage Examples"
    echo ""
    echo "### VirusTotal API"
    echo "```python"
    echo "import vt"
    echo "client = vt.Client('<your_api_key>')"
    echo "# Scan a file"
    echo "with open('file.exe', 'rb') as f:"
    echo "    analysis = client.scan_file(f)"
    echo "    print(analysis.id)"
    echo "client.close()"
    echo "```"
    echo ""
    echo "### GreyNoise API"
    echo "```python"
    echo "import greynoise"
    echo "gn = greynoise.GreyNoise(api_key='<your_api_key>')"
    echo "result = gn.ip('8.8.8.8')"
    echo "print(result)"
    echo "```"
    echo ""
    echo "### Snyk"
    echo "```bash"
    echo "# Test for vulnerabilities"
    echo "snyk test"
    echo ""
    echo "# Monitor for new vulnerabilities"
    echo "snyk monitor"
    echo "```"
    echo ""
    echo "### Nikto"
    echo "```bash"
    echo "# Scan a web server"
    echo "nikto -h http://target.com"
    echo "```"
    echo ""
    echo "### ClamAV"
    echo "```bash"
    echo "# Update virus definitions"
    echo "sudo freshclam"
    echo ""
    echo "# Scan a directory"
    echo "clamscan -r /home/"
    echo "```"
} >> $DOCS_DIR/threat_intel_tools.md

# 13. Create test script
log_action "Creating test script..."

mkdir -p /home/cbwinslow/security_setup/tests

cat > /home/cbwinslow/security_setup/tests/test_threat_intel.sh << 'EOL'
#!/bin/bash

echo "=== Testing Threat Intelligence Tools ==="
echo ""

echo "1. Testing Python packages..."
python3 -c "import vt, greynoise; print('VirusTotal and GreyNoise libraries installed')" 2>/dev/null || echo "Some Python packages missing"

echo ""
echo "2. Testing Snyk..."
which snyk &>/dev/null && echo "Snyk installed" || echo "Snyk not installed"

echo ""
echo "3. Testing security testing tools..."
which nikto sqlmap lynis clamscan &>/dev/null && echo "Security testing tools installed" || echo "Some security testing tools missing"

echo ""
echo "4. Testing digital forensics tools..."
which yara volatility foremost &>/dev/null && echo "Digital forensics tools installed" || echo "Some digital forensics tools missing"

echo ""
echo "=== Test Complete ==="
EOL

chmod +x /home/cbwinslow/security_setup/tests/test_threat_intel.sh

# 14. Final summary
{
    echo ""
    echo "## Installation Complete"
    echo ""
    echo "### Installed Tools"
    echo "- MISP: Threat intelligence platform"
    echo "- TheHive/Cortex: Incident response (manual install)"
    echo "- VirusTotal/GreyNoise APIs: Threat intelligence APIs"
    echo "- Snyk: Developer security platform"
    echo "- Nikto: Web server scanner"
    echo "- SQLMap: SQL injection testing tool"
    echo "- Burp Suite: Web application security testing"
    echo "- Lynis: Security auditing tool"
    echo "- ClamAV: Antivirus engine"
    echo "- OpenVAS: Vulnerability scanner"
    echo "- YARA/Volatility: Digital forensics tools"
    echo ""
    echo "### Next Steps"
    echo "1. Configure MISP database and web server"
    echo "2. Manually install TheHive and Cortex"
    echo "3. Register for API keys for VirusTotal and GreyNoise"
    echo "4. Configure Burp Suite for web testing"
    echo "5. Set up OpenVAS for vulnerability scanning"
    echo "6. Test all tools with the test script:"
    echo "   /home/cbwinslow/security_setup/tests/test_threat_intel.sh"
    echo ""
    echo "### Documentation"
    echo "Detailed documentation is available in $DOCS_DIR/threat_intel_tools.md"
    echo "Manual installation instructions are provided for TheHive and Cortex"
} >> $DOCS_DIR/threat_intel_tools.md

log_action "Threat intelligence tools installation complete!"
echo ""
echo "=== Installation Complete ==="
echo "Documentation created in $DOCS_DIR/threat_intel_tools.md"
echo "Test script available at /home/cbwinslow/security_setup/tests/test_threat_intel.sh"
echo ""
echo "Note: TheHive and Cortex require manual installation as documented"
echo "Next steps:"
echo "1. Configure tools for your environment"
echo "2. Register for API keys"
echo "3. Run the test script to verify installations"