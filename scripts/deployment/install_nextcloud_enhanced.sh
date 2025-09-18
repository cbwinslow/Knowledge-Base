#!/bin/bash

# Enhanced Nextcloud Installation Script with Cloudflare Tunnel Support
# This script installs Nextcloud and optionally sets up Cloudflare Tunnel

echo "=== Enhanced Nextcloud Installation ==="
echo ""

# Function to print usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --cloudflare    Setup Cloudflare Tunnel (optional)"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Install Nextcloud only"
    echo "  $0 --cloudflare # Install Nextcloud and setup Cloudflare Tunnel"
    echo ""
}

# Parse command line arguments
CLOUDFLARE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --cloudflare)
            CLOUDFLARE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Enhanced Nextcloud Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/enhanced_nextcloud_install.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/enhanced_nextcloud_install.md
}

echo "Starting Nextcloud installation..."
log_action "Starting Nextcloud installation"

# Check prerequisites
log_action "Checking prerequisites..."

# Check if Apache is installed
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | head -1)
    log_action "✅ Apache installed ($APACHE_VERSION)"
else
    echo "❌ Apache is not installed. Installing Apache..."
    log_action "Installing Apache web server..."
    sudo apt install -y apache2
fi

# Check if PHP is installed
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -1)
    log_action "✅ PHP installed ($PHP_VERSION)"
else
    echo "❌ PHP is not installed. Installing PHP..."
    log_action "Installing PHP 8.3 and required modules..."
    sudo apt install -y \
        php8.3 \
        php8.3-cli \
        php8.3-common \
        php8.3-curl \
        php8.3-gd \
        php8.3-imagick \
        php8.3-intl \
        php8.3-mbstring \
        php8.3-pgsql \
        php8.3-opcache \
        php8.3-zip \
        php8.3-xml \
        php8.3-bz2 \
        php8.3-fpm \
        libapache2-mod-php8.3
fi

# Check if PostgreSQL is installed
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | head -1)
    log_action "✅ PostgreSQL installed ($PG_VERSION)"
else
    echo "❌ PostgreSQL is not installed. Installing PostgreSQL..."
    log_action "Installing PostgreSQL database..."
    sudo apt install -y postgresql postgresql-contrib
fi

# 1. Move Nextcloud files to web directory
log_action "Moving Nextcloud files to web directory..."
echo ""
echo "1. Moving Nextcloud files to web directory..."

if [ -d "/tmp/nextcloud" ]; then
    sudo mv /tmp/nextcloud /var/www/
    sudo chown -R www-data:www-data /var/www/nextcloud
    log_action "✅ Nextcloud files moved to /var/www/nextcloud"
    echo "✅ Nextcloud files moved to /var/www/nextcloud"
else
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
    log_action "❌ Nextcloud files not found in /tmp/nextcloud"
    exit 1
fi

# 2. Create Nextcloud database
log_action "Creating Nextcloud database..."
echo ""
echo "2. Creating Nextcloud database..."

# Create database user and database for Nextcloud
sudo -u postgres psql -c "CREATE USER nextcloud WITH PASSWORD 'nextcloud';" 2>/dev/null || echo "Database user 'nextcloud' may already exist"
sudo -u postgres psql -c "CREATE DATABASE nextcloud OWNER nextcloud;" 2>/dev/null || echo "Database 'nextcloud' may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;" 2>/dev/null || echo "Privileges may already be granted"

echo "✅ Nextcloud database created"
log_action "✅ Nextcloud database created"

# 3. Configure Apache virtual host for Nextcloud
log_action "Configuring Apache virtual host for Nextcloud..."
echo ""
echo "3. Configuring Apache virtual host for Nextcloud..."

sudo bash -c "cat > /etc/apache2/sites-available/nextcloud.conf" << 'EOL'
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud/
    ServerName localhost

    <Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    <IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteRule ^\.well-known/host-meta /public.php?service=host-meta [QSA,L]
        RewriteRule ^\.well-known/host-meta\.json /public.php?service=host-meta-json [QSA,L]
        RewriteRule ^\.well-known/carddav /remote.php/dav/ [R=301,L]
        RewriteRule ^\.well-known/caldav /remote.php/dav/ [R=301,L]
        RewriteRule ^remote/(.*) remote.php [QSA,L]
        RewriteRule ^(build|tests|config|lib|3rdparty|templates)/.* - [R=404,L]
        RewriteRule ^(\.|autotest|occ|issue|indie|db_|console).* - [R=404,L]
    </IfModule>

    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOL

# Enable the Nextcloud site
sudo a2ensite nextcloud.conf

# Enable required Apache modules
sudo a2enmod rewrite headers env dir mime ssl

echo "✅ Nextcloud Apache virtual host configured"
log_action "✅ Nextcloud Apache virtual host configured"

# 4. Restart Apache to apply changes
log_action "Restarting Apache to apply all changes..."
echo ""
echo "4. Restarting Apache to apply all changes..."
sudo systemctl restart apache2

# 5. Setup Cloudflare Tunnel if requested
if [ "$CLOUDFLARE" = true ]; then
    echo ""
    echo "5. Setting up Cloudflare Tunnel..."
    log_action "Setting up Cloudflare Tunnel..."
    
    # Check if cloudflared is installed
    if ! command -v cloudflared &> /dev/null; then
        echo "Installing Cloudflare Tunnel (cloudflared)..."
        log_action "Installing Cloudflare Tunnel (cloudflared)..."
        
        # Download and install cloudflared
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared-linux-amd64.deb
        
        # Verify installation
        if command -v cloudflared &> /dev/null; then
            echo "✅ Cloudflared installed successfully"
            log_action "✅ Cloudflared installed successfully"
        else
            echo "❌ Failed to install cloudflared"
            log_action "❌ Failed to install cloudflared"
        fi
    else
        echo "✅ Cloudflared is already installed"
        log_action "✅ Cloudflared is already installed"
    fi
    
    echo ""
    echo "Please authenticate with Cloudflare by running:"
    echo "cloudflared tunnel login"
    echo ""
    echo "This will open a browser window for authentication."
    echo "After authenticating, press Enter to continue..."
    read -p "Press Enter after authenticating..."
    
    # Create a tunnel for Nextcloud
    echo ""
    echo "Creating Cloudflare Tunnel for Nextcloud..."
    TUNNEL_OUTPUT=$(cloudflared tunnel create nextcloud 2>&1)
    echo "$TUNNEL_OUTPUT"
    log_action "Cloudflare Tunnel creation output: $TUNNEL_OUTPUT"
    
    # Extract tunnel ID
    TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
    if [ -n "$TUNNEL_ID" ]; then
        echo "✅ Tunnel created with ID: $TUNNEL_ID"
        log_action "✅ Tunnel created with ID: $TUNNEL_ID"
        
        # Create configuration directory
        sudo mkdir -p /etc/cloudflared
        
        # Prompt for domain name
        echo ""
        read -p "Enter your domain name (e.g., nextcloud.yourdomain.com): " DOMAIN_NAME
        
        # Create the configuration file
        echo ""
        echo "Creating tunnel configuration..."
        sudo tee /etc/cloudflared/$TUNNEL_ID.json > /dev/null <<EOF
{
  "tunnel": "$TUNNEL_ID",
  "credentials-file": "/home/$USER/.cloudflared/$TUNNEL_ID.json",
  "ingress": [
    {
      "hostname": "$DOMAIN_NAME",
      "service": "http://localhost:80"
    },
    {
      "service": "http_status:404"
    }
  ]
}
EOF
        
        echo "✅ Configuration file created at /etc/cloudflared/$TUNNEL_ID.json"
        log_action "✅ Configuration file created at /etc/cloudflared/$TUNNEL_ID.json"
        
        # Route traffic to the tunnel
        echo ""
        echo "Routing DNS traffic to tunnel..."
        cloudflared tunnel route dns nextcloud $DOMAIN_NAME
        
        echo "✅ DNS route created for $DOMAIN_NAME"
        log_action "✅ DNS route created for $DOMAIN_NAME"
        
        echo ""
        echo "=== Cloudflare Tunnel Setup Complete ==="
        echo "Next steps:"
        echo "1. Start the tunnel: cloudflared tunnel --config /etc/cloudflared/$TUNNEL_ID.json run"
        echo "2. For production use, install as a service:"
        echo "   sudo cloudflared service install --config /etc/cloudflared/$TUNNEL_ID.json"
        echo "   sudo systemctl enable cloudflared"
        echo "   sudo systemctl start cloudflared"
        echo "3. Access your Nextcloud at https://$DOMAIN_NAME"
        echo ""
        log_action "Cloudflare Tunnel setup complete. Next steps provided above."
    else
        echo "❌ Failed to extract tunnel ID"
        echo "Please check the output above and ensure the tunnel was created successfully"
        log_action "❌ Failed to extract tunnel ID"
    fi
fi

# 6. Create documentation for Nextcloud
{
    echo ""
    echo "## Nextcloud Installation Complete"
    echo ""
    echo "### Access Information"
    echo "- Local URL: http://localhost/nextcloud"
    echo "- Database: PostgreSQL (nextcloud/nextcloud)"
    echo "- Admin User: Will be created during first access"
    if [ "$CLOUDFLARE" = true ]; then
        echo "- Public URL: https://$DOMAIN_NAME (after Cloudflare Tunnel is running)"
    fi
    echo ""
    echo "### Configuration Files"
    echo "- Main config: /var/www/nextcloud/config/config.php"
    echo "- Apache site: /etc/apache2/sites-available/nextcloud.conf"
    echo "- Data directory: /var/www/nextcloud/data"
    echo "- Log files: /var/log/apache2/nextcloud_*.log"
    if [ "$CLOUDFLARE" = true ]; then
        echo "- Cloudflare config: /etc/cloudflared/$TUNNEL_ID.json"
    fi
    echo ""
    echo "### Next Steps"
    echo "1. Access Nextcloud in your browser at http://localhost/nextcloud"
    echo "2. Create an admin user account"
    echo "3. Configure your storage and settings"
    echo "4. Set up SSL for secure access (recommended)"
    if [ "$CLOUDFLARE" = true ]; then
        echo "5. Start Cloudflare Tunnel for public access:"
        echo "   cloudflared tunnel --config /etc/cloudflared/$TUNNEL_ID.json run"
        echo "6. For production use, install as a service:"
        echo "   sudo cloudflared service install --config /etc/cloudflared/$TUNNEL_ID.json"
        echo "   sudo systemctl enable cloudflared"
        echo "   sudo systemctl start cloudflared"
        echo "7. Access your Nextcloud at https://$DOMAIN_NAME"
        echo "8. Optional: Configure Cloudflare Access for authentication"
    fi
    echo ""
    echo "### Useful Commands"
    echo "- Check Apache status: sudo systemctl status apache2"
    echo "- Restart Apache: sudo systemctl restart apache2"
    echo "- Check Nextcloud logs: tail -f /var/log/apache2/nextcloud_*.log"
    echo "- Access PostgreSQL: sudo -u postgres psql nextcloud"
    if [ "$CLOUDFLARE" = true ]; then
        echo "- Check tunnel status: cloudflared tunnel list"
        echo "- View tunnel logs: sudo journalctl -u cloudflared -f"
    fi
    echo ""
    echo "### Troubleshooting"
    echo "- If you can't access Nextcloud, check Apache configuration:"
    echo "  sudo apache2ctl configtest"
    echo "- Check Apache error logs: sudo tail -f /var/log/apache2/error.log"
    echo "- Verify PHP modules: php -m | grep -E '(pdo|gd|curl|intl|zip)'"
    echo "- Check database connection: sudo -u postgres psql -c '\\conninfo'"
    if [ "$CLOUDFLARE" = true ]; then
        echo "- Cloudflare Tunnel troubleshooting:"
        echo "  Check tunnel logs: sudo journalctl -u cloudflared -f"
        echo "  Validate configuration: cloudflared tunnel validate --config /etc/cloudflared/$TUNNEL_ID.json"
    fi
} >> $DOCS_DIR/enhanced_nextcloud_install.md

log_action "Nextcloud installation complete!"
echo ""
echo "=== Nextcloud Installation Complete ==="
echo "Documentation created in $DOCS_DIR/enhanced_nextcloud_install.md"
echo ""
echo "Next steps:"
echo "1. Access Nextcloud in your browser at http://localhost/nextcloud"
echo "2. Create an admin user account"
echo "3. Configure your storage and settings"
echo "4. Set up SSL for secure access (recommended)"
if [ "$CLOUDFLARE" = true ]; then
    echo "5. Start Cloudflare Tunnel for public access (instructions above)"
fi