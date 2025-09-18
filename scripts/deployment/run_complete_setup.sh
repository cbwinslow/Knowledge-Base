#!/bin/bash

# Master Server Setup Script
# This script runs all the server setup processes

echo "=== Master Server Setup ==="
echo ""
echo "This script will run all server setup processes in sequence."
echo "It will install networking tools, essential services, and create documentation."
echo ""
echo "Estimated time: 15-30 minutes depending on internet connection."
echo ""
read -p "Do you want to continue? (yes/no): " confirmation

if [[ $confirmation != "yes" ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "=== Starting Server Setup ==="
echo ""

# Run networking and services setup
echo "1. Setting up networking tools and services..."
/home/cbwinslow/server_setup/setup_networking_services.sh
echo ""

# Run essential services installation
echo "2. Installing essential services..."
/home/cbwinslow/server_setup/install_essential_services.sh
echo ""

# Run ZeroTier setup
echo "3. Setting up ZeroTier documentation..."
/home/cbwinslow/server_setup/setup_zerotier.sh
echo ""

# Run WireGuard setup
echo "4. Setting up WireGuard documentation..."
/home/cbwinslow/server_setup/setup_wireguard.sh
echo ""

# Create a summary document
DOCS_DIR="/home/cbwinslow/server_setup/docs"
{
    echo "# Server Setup Summary"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Setup Process Completed"
    echo ""
    echo "The following components have been installed and configured:"
    echo ""
    echo "1. Networking Tools:"
    echo "   - Squid Proxy Server (Port 3128)"
    echo "   - ZeroTier (Installed, documentation provided)"
    echo "   - WireGuard (Installed, documentation provided)"
    echo "   - SSH Security Enhanced"
    echo "   - Firewall (UFW) with ports configured"
    echo ""
    echo "2. Essential Services:"
    echo "   - Docker & Docker Compose"
    echo "   - Nginx Web Server"
    echo "   - Certbot for SSL certificates"
    echo "   - Node.js Runtime"
    echo "   - Python3-pip Package Manager"
    echo "   - fail2ban Security Tool"
    echo "   - logrotate Log Management"
    echo ""
    echo "3. Documentation:"
    echo "   - All setup processes documented"
    echo "   - Service management instructions"
    echo "   - Configuration guides"
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Configure ZeroTier:"
    echo "   - Create account at https://my.zerotier.com/"
    echo "   - Create a network"
    echo "   - Join network: sudo zerotier-cli join <network_id>"
    echo "   - Approve node in web interface"
    echo ""
    echo "2. Configure WireGuard (if needed):"
    echo "   - Follow instructions in $DOCS_DIR/wireguard_setup.md"
    echo ""
    echo "3. Log out and log back in to use Docker without sudo"
    echo ""
    echo "4. Verify all services are running:"
    echo "   - systemctl status ssh squid zerotier-one docker nginx"
    echo ""
    echo "5. Test proxy functionality:"
    echo "   - curl -x http://localhost:3128 http://google.com"
    echo ""
    echo "6. Run Ansible test playbook:"
    echo "   - cd /home/cbwinslow/ansible"
    echo "   - ansible-playbook test-playbook.yml"
    echo ""
    echo "## Important Notes"
    echo ""
    echo "- SSH is configured for key-based authentication only"
    echo "- Password authentication has been disabled"
    echo "- Firewall is active with essential ports open"
    echo "- All documentation is in $DOCS_DIR/"
    echo "- Configuration files are backed up with .backup extension"
    echo ""
    echo "## Services and Ports"
    echo ""
    echo "| Service | Port | Protocol | Purpose |"
    echo "|---------|------|----------|---------|"
    echo "| SSH | 22 | TCP | Secure shell access |"
    echo "| HTTP | 80 | TCP | Web server |"
    echo "| HTTPS | 443 | TCP | Secure web server |"
    echo "| Squid Proxy | 3128 | TCP | HTTP proxy |"
    echo "| ZeroTier | 9993 | UDP | VPN networking |"
    echo "| WireGuard | 51820 | UDP | VPN tunnel |"
    echo ""
    echo "Setup process completed successfully!"
} > $DOCS_DIR/setup_summary.md

echo "=== Setup Complete ==="
echo ""
echo "All server setup processes have been completed."
echo "Summary documentation created in $DOCS_DIR/setup_summary.md"
echo ""
echo "Next steps:"
echo "1. Review documentation in /home/cbwinslow/server_setup/docs/"
echo "2. Configure ZeroTier and/or WireGuard as needed"
echo "3. Log out and back in to use Docker without sudo"
echo "4. Verify all services are running properly"