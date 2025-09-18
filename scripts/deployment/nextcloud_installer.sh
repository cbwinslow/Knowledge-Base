#!/usr/bin/env bash
#===============================================================================
# ███╗   ██╗███████╗██╗  ██╗ ██████╗██╗      ██████╗  █████╗ ██████╗     ██████╗ 
# ████╗  ██║██╔════╝╚██╗██╔╝██╔════╝██║     ██╔═══██╗██╔══██╗██╔══██╗    ╚════██╗
# ██╔██╗ ██║█████╗   ╚███╔╝ ██║     ██║     ██║   ██║███████║██║  ██║     █████╔╝
# ██║╚██╗██║██╔══╝   ██╔██╗ ██║     ██║     ██║   ██║██╔══██║██║  ██║     ╚═══██╗
# ██║ ╚████║███████╗██╔╝ ██╗╚██████╗███████╗╚██████╔╝██║  ██║██████╔╝    ██████╔╝
# ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚═════╝ 
#===============================================================================
# File: nextcloud_installer.sh
# Description: Nextcloud installation and configuration script
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/nextcloud_installer.log"
TEMP_DIR="/tmp/nextcloud_installer"
NEXTCLOUD_DATA_DIR="/var/lib/nextcloud"
NEXTCLOUD_CONFIG_DIR="/etc/nextcloud"
NEXTCLOUD_VERSION="latest"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${PURPLE}[DEBUG]${NC} $*" | tee -a "$LOG_FILE" || true; }

# Utility functions
print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Nextcloud Installer - Self-hosted File Sharing and Collaboration${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

print_section_header() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

print_divider() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
        exit 1
    fi
}

create_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

cleanup() {
    rm -rf "$TEMP_DIR"
    debug "Cleaned up temporary files"
}

trap cleanup EXIT

# Nextcloud installation functions
check_prerequisites() {
    print_section_header "Checking Prerequisites"
    
    # Check for Docker
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        echo "Please install Docker first:"
        echo "  Ubuntu/Debian: sudo apt install docker.io"
        echo "  CentOS/RHEL: sudo yum install docker"
        return 1
    fi
    
    echo -e "${GREEN}Docker: ${NC}INSTALLED ($(docker --version | head -1))"
    
    # Check Docker daemon status
    if ! systemctl is-active --quiet docker; then
        error "Docker daemon is not running"
        echo "Start Docker daemon:"
        echo "  sudo systemctl start docker"
        echo "  sudo systemctl enable docker"
        return 1
    fi
    
    echo -e "${GREEN}Docker Daemon: ${NC}RUNNING"
    
    # Check available disk space
    local available_space=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $available_space -lt 10 ]]; then
        error "Insufficient disk space. At least 10GB required, ${available_space}GB available."
        return 1
    fi
    
    echo -e "${GREEN}Disk Space: ${NC}${available_space}GB available"
    
    # Check available RAM
    local available_ram=$(free -g | awk '/^Mem:/{print $7}')
    if [[ $available_ram -lt 2 ]]; then
        warn "Recommended minimum RAM is 2GB, ${available_ram}GB available"
    else
        echo -e "${GREEN}RAM: ${NC}${available_ram}GB available"
    fi
    
    info "All prerequisites met"
    return 0
}

install_nextcloud_docker() {
    local admin_user=${1:-"admin"}
    local admin_password=${2:-"$(openssl rand -base64 12 | tr -d /=+ | cut -c1-12)A1!"}
    local domain=${3:-"localhost"}
    
    print_section_header "Installing Nextcloud via Docker"
    
    # Create directories
    mkdir -p "$NEXTCLOUD_DATA_DIR"
    mkdir -p "$NEXTCLOUD_CONFIG_DIR"
    
    # Set proper permissions
    chown -R 33:33 "$NEXTCLOUD_DATA_DIR" 2>/dev/null || true
    chown -R 33:33 "$NEXTCLOUD_CONFIG_DIR" 2>/dev/null || true
    
    echo -e "${GREEN}Using Admin User: ${NC}$admin_user"
    echo -e "${GREEN}Domain: ${NC}$domain"
    echo -e "${GREEN}Generated Password: ${NC}$admin_password"
    echo -e "${YELLOW}Please save this password - you'll need it for first login${NC}"
    echo
    
    # Stop existing Nextcloud container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^nextcloud$"; then
        echo -e "${YELLOW}Stopping existing Nextcloud container${NC}"
        docker stop nextcloud >/dev/null 2>&1 || true
        docker rm nextcloud >/dev/null 2>&1 || true
    fi
    
    # Pull Nextcloud image
    echo -e "${GREEN}Pulling Nextcloud Docker image${NC}"
    docker pull nextcloud:"$NEXTCLOUD_VERSION"
    
    if [[ $? -ne 0 ]]; then
        error "Failed to pull Nextcloud Docker image"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Nextcloud image pulled${NC}"
    
    # Run Nextcloud container
    echo -e "${GREEN}Starting Nextcloud container${NC}"
    docker run -d \
        --name nextcloud \
        -p 8080:80 \
        -e NEXTCLOUD_ADMIN_USER="$admin_user" \
        -e NEXTCLOUD_ADMIN_PASSWORD="$admin_password" \
        -e NEXTCLOUD_TRUSTED_DOMAINS="$domain" \
        -e SQLITE_DATABASE=nextcloud \
        -v "$NEXTCLOUD_DATA_DIR":/var/www/html \
        -v "$NEXTCLOUD_CONFIG_DIR":/var/www/html/config \
        --restart=unless-stopped \
        nextcloud:"$NEXTCLOUD_VERSION"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Nextcloud container started${NC}"
        echo -e "${GREEN}Access Nextcloud at: http://$domain:8080${NC}"
        echo -e "${YELLOW}Initial setup may take a few minutes${NC}"
        
        # Create info file with credentials
        cat > "$NEXTCLOUD_CONFIG_DIR/INSTALL_INFO.txt" <<EOF
Nextcloud Installation Information
=================================

Admin User: $admin_user
Admin Password: $admin_password
Access URL: http://$domain:8080

Database: SQLite (built-in, suitable for small installations)
Data Directory: $NEXTCLOUD_DATA_DIR
Config Directory: $NEXTCLOUD_CONFIG_DIR

For production use, consider:
1. Using a proper database (PostgreSQL/MySQL)
2. Configuring HTTPS with a reverse proxy
3. Setting up proper backups
4. Configuring trusted domains for external access
EOF
        
        echo -e "${GREEN}Installation info saved to: $NEXTCLOUD_CONFIG_DIR/INSTALL_INFO.txt${NC}"
    else
        error "Failed to start Nextcloud container"
        return 1
    fi
    
    info "Nextcloud Docker installation completed"
    return 0
}

install_nextcloud_native() {
    local admin_user=${1:-"admin"}
    local admin_password=${2:-"$(openssl rand -base64 12 | tr -d /=+ | cut -c1-12)A1!"}
    local domain=${3:-"localhost"}
    
    print_section_header "Installing Nextcloud Natively"
    
    # Check if Apache or Nginx is installed
    if command -v apache2 >/dev/null 2>&1; then
        echo -e "${GREEN}Web Server: ${NC}Apache2"
        WEB_SERVER="apache2"
    elif command -v nginx >/dev/null 2>&1; then
        echo -e "${GREEN}Web Server: ${NC}Nginx"
        WEB_SERVER="nginx"
    else
        error "No web server (Apache/Nginx) found. Installing Apache2."
        apt-get update
        apt-get install -y apache2
        WEB_SERVER="apache2"
    fi
    
    # Install PHP and required modules
    echo -e "${GREEN}Installing PHP and required modules${NC}"
    apt-get install -y \
        php8.3 \
        php8.3-cli \
        php8.3-common \
        php8.3-curl \
        php8.3-gd \
        php8.3-imagick \
        php8.3-intl \
        php8.3-mbstring \
        php8.3-mysql \
        php8.3-pgsql \
        php8.3-sqlite3 \
        php8.3-xml \
        php8.3-zip \
        php8.3-bz2 \
        php8.3-redis \
        php8.3-apcu \
        libapache2-mod-php8.3
    
    if [[ $? -ne 0 ]]; then
        error "Failed to install PHP packages"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: PHP installed${NC}"
    
    # Download Nextcloud
    echo -e "${GREEN}Downloading Nextcloud${NC}"
    mkdir -p /var/www
    cd /var/www
    wget -O nextcloud.zip https://download.nextcloud.com/server/releases/latest.zip
    unzip nextcloud.zip
    rm nextcloud.zip
    
    # Set permissions
    chown -R www-data:www-data nextcloud
    chmod -R 755 nextcloud
    
    # Configure Apache virtual host
    if [[ "$WEB_SERVER" == "apache2" ]]; then
        cat > /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:8080>
    DocumentRoot /var/www/nextcloud
    ServerName $domain
    
    <Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>
    
    # Enable pretty urls
    RewriteEngine on
    RewriteRule ^/\.well-known/host-meta /public.php?service=host-meta [QSA,L]
    RewriteRule ^/\.well-known/host-meta\.json /public.php?service=host-meta-json [QSA,L]
    RewriteRule ^/\.well-known/webfinger /public.php?service=webfinger [QSA,L]
    RewriteRule ^/\.well-known/carddav /remote.php/dav/ [R=301,L]
    RewriteRule ^/\.well-known/caldav /remote.php/dav/ [R=301,L]
    RewriteRule ^/remote/(.*) remote.php [QSA,L]
    RewriteRule ^/api/(.*) api.php [QSA,L]
    RewriteRule ^(/core/doc/[^\/]+/)$ \$1/index.html [QSA,L]
</VirtualHost>
EOF
        
        # Enable site and required modules
        a2ensite nextcloud.conf
        a2enmod rewrite headers env dir mime
        systemctl reload apache2
    fi
    
    echo -e "${GREEN}SUCCESS: Nextcloud installed natively${NC}"
    echo -e "${GREEN}Access Nextcloud at: http://$domain:8080${NC}"
    
    info "Nextcloud native installation completed"
    return 0
}

configure_https_reverse_proxy() {
    local domain=$1
    
    if [[ -z "$domain" ]]; then
        error "Domain is required for HTTPS configuration"
        return 1
    fi
    
    print_section_header "Configuring HTTPS Reverse Proxy"
    
    # Check for Nginx
    if ! command -v nginx >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Nginx for reverse proxy${NC}"
        apt-get update
        apt-get install -y nginx
    fi
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/nextcloud-proxy <<EOF
upstream nextcloud_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name $domain;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;
    
    # SSL configuration (you'll need to obtain certificates)
    # For testing, you can use self-signed certificates:
    # openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # HSTS (ngx_http_headers_module is required)
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
    
    # MIME type sniffing protection
    add_header X-Content-Type-Options nosniff;
    
    # XSS protection
    add_header X-XSS-Protection "1; mode=block";
    
    # Frame protection
    add_header X-Frame-Options "SAMEORIGIN";
    
    # Content security policy
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';";
    
    location / {
        proxy_pass http://nextcloud_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeout settings
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
    
    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://nextcloud_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/nextcloud-proxy /etc/nginx/sites-enabled/
    systemctl reload nginx
    
    echo -e "${GREEN}SUCCESS: HTTPS reverse proxy configured${NC}"
    echo -e "${GREEN}Access Nextcloud at: https://$domain${NC}"
    echo -e "${YELLOW}Note: You'll need valid SSL certificates for production use${NC}"
    
    info "HTTPS reverse proxy configuration completed"
    return 0
}

show_nextcloud_status() {
    print_section_header "Nextcloud Status"
    
    # Check if Nextcloud container is running
    if docker ps --format '{{.Names}}' | grep -q "^nextcloud$"; then
        echo -e "${GREEN}Nextcloud Docker Container: ${NC}RUNNING"
        echo -e "${GREEN}Container ID: ${NC}$(docker ps --filter "name=nextcloud" --format '{{.ID}}')"
        echo -e "${GREEN}Image: ${NC}$(docker ps --filter "name=nextcloud" --format '{{.Image}}')"
        echo -e "${GREEN}Status: ${NC}$(docker ps --filter "name=nextcloud" --format '{{.Status}}')"
        
        # Show port mapping
        local ports=$(docker port nextcloud)
        if [[ -n "$ports" ]]; then
            echo -e "${GREEN}Port Mapping: ${NC}"
            echo "$ports" | sed "s/^/  /"
        fi
    elif systemctl is-active --quiet nextcloud; then
        echo -e "${GREEN}Nextcloud Service: ${NC}RUNNING"
        echo -e "${GREEN}Service Status: ${NC}$(systemctl status nextcloud --no-pager -l | head -3 | tail -1)"
    else
        echo -e "${YELLOW}Nextcloud: ${NC}NOT RUNNING"
    fi
    
    # Show data directory
    if [[ -d "$NEXTCLOUD_DATA_DIR" ]]; then
        echo -e "${GREEN}Data Directory: ${NC}$NEXTCLOUD_DATA_DIR"
        echo -e "${GREEN}Data Size: ${NC}$(du -sh "$NEXTCLOUD_DATA_DIR" 2>/dev/null | cut -f1 || echo 'Unknown')"
    fi
    
    # Show config directory
    if [[ -d "$NEXTCLOUD_CONFIG_DIR" ]]; then
        echo -e "${GREEN}Config Directory: ${NC}$NEXTCLOUD_CONFIG_DIR"
        if [[ -f "$NEXTCLOUD_CONFIG_DIR/INSTALL_INFO.txt" ]]; then
            echo -e "${GREEN}Install Info: ${NC}Available (cat $NEXTCLOUD_CONFIG_DIR/INSTALL_INFO.txt)"
        fi
    fi
    
    info "Nextcloud status check completed"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  install-docker [user] [password] [domain]  Install Nextcloud via Docker"
    echo "  install-native [user] [password] [domain]  Install Nextcloud natively"
    echo "  https-proxy <domain>                       Configure HTTPS reverse proxy"
    echo "  status                                     Show Nextcloud status"
    echo "  help                                       Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install-docker admin mypassword localhost"
    echo "  $0 install-native admin mypassword mydomain.com"
    echo "  $0 https-proxy mydomain.com"
    echo "  $0 status"
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case "$command" in
        install-docker)
            check_root
            check_prerequisites
            
            local user="${2:-admin}"
            local password="${3:-$(openssl rand -base64 12 | tr -d /=+ | cut -c1-12)A1!}"
            local domain="${4:-localhost}"
            
            install_nextcloud_docker "$user" "$password" "$domain"
            ;;
        install-native)
            check_root
            
            local user="${2:-admin}"
            local password="${3:-$(openssl rand -base64 12 | tr -d /=+ | cut -c1-12)A1!}"
            local domain="${4:-localhost}"
            
            install_nextcloud_native "$user" "$password" "$domain"
            ;;
        https-proxy)
            check_root
            
            if [[ -z "${2:-}" ]]; then
                error "Domain required for HTTPS proxy configuration"
                show_usage
                exit 1
            fi
            
            local domain="$2"
            configure_https_reverse_proxy "$domain"
            ;;
        status)
            show_nextcloud_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi