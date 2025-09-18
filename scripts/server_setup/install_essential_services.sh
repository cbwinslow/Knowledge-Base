#!/bin/bash

# Essential Services Installation Script
# This script installs the essential services for a production server

echo "=== Installing Essential Services ==="
echo ""

# Create documentation
DOCS_DIR="/home/cbwinslow/server_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Essential Services Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/essential_services.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/essential_services.md
}

# Update package list
log_action "Updating package list..."
sudo apt update

# 1. Docker
log_action "Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo usermod -aG docker $(whoami)

# 2. Docker Compose
log_action "Installing Docker Compose..."
sudo apt install -y docker-compose

# 3. Nginx
log_action "Installing Nginx..."
sudo apt install -y nginx
sudo systemctl enable nginx

# 4. Certbot
log_action "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# 5. Node.js
log_action "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# 6. Python3-pip
log_action "Installing Python3-pip..."
sudo apt install -y python3-pip

# 7. fail2ban
log_action "Installing fail2ban..."
sudo apt install -y fail2ban
sudo systemctl enable fail2ban

# 8. logrotate
log_action "Installing logrotate..."
sudo apt install -y logrotate
sudo systemctl enable logrotate

# 9. Additional useful tools
log_action "Installing additional tools..."
sudo apt install -y \
    unzip \
    zip \
    tree \
    ncdu \
    sysstat \
    iotop \
    iftop

# Create documentation of installed services
{
    echo ""
    echo "## Installed Services"
    echo ""
    echo "| Service | Purpose | Management Command |"
    echo "|---------|---------|-------------------|"
    echo "| Docker | Containerization platform | systemctl {start|stop|restart|status} docker |"
    echo "| Docker Compose | Multi-container management | docker-compose |"
    echo "| Nginx | Web server and reverse proxy | systemctl {start|stop|restart|status} nginx |"
    echo "| Certbot | SSL certificate management | certbot |"
    echo "| Node.js | JavaScript runtime | node, npm |"
    echo "| Python3-pip | Python package manager | pip3 |"
    echo "| fail2ban | Intrusion prevention | systemctl {start|stop|restart|status} fail2ban |"
    echo "| logrotate | Log file management | systemctl {start|stop|restart|status} logrotate |"
    echo ""
    echo "## Verification Commands"
    echo ""
    echo "```bash"
    echo "# Check service status"
    echo "systemctl status docker nginx fail2ban logrotate"
    echo ""
    echo "# Check Docker version"
    echo "docker --version"
    echo ""
    echo "# Check Node.js version"
    echo "node --version"
    echo ""
    echo "# Check Python pip version"
    echo "pip3 --version"
    echo "```"
    echo ""
    echo "## Next Steps"
    echo "1. Log out and log back in to apply Docker group membership"
    echo "2. Configure services as needed for your specific use case"
    echo "3. Set up SSL certificates with Certbot if running web services"
    echo "4. Configure fail2ban for your security requirements"
    echo ""
    echo "## Important Notes"
    echo "- Docker requires you to log out and back in to use without sudo"
    echo "- Nginx is installed but not configured with any sites"
    echo "- fail2ban is installed with default configuration"
    echo "- Certbot is installed but no certificates have been requested"
} >> $DOCS_DIR/essential_services.md

log_action "Essential services installation complete!"
echo ""
echo "=== Installation Complete ==="
echo "Documentation has been created in $DOCS_DIR/essential_services.md"
echo ""
echo "Important: Log out and log back in to use Docker without sudo"