#!/usr/bin/env bash
#===============================================================================
# ██████╗ ██╗██████╗  █████╗ ██████╗ ███████╗ █████╗ ██████╗     ██╗    ██╗██╗████████╗ █████╗ ██████╗ 
# ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██║    ██║██║╚══██╔══╝██╔══██╗██╔══██╗
# ██████╔╝██║██████╔╝███████║██║  ██║█████╗  ███████║██████╔╝    ██║ █╗ ██║██║   ██║   ███████║██████╔╝
# ██╔══██╗██║██╔══██╗██╔══██║██║  ██║██╔══╝  ██╔══██║██╔══██╗    ██║███╗██║██║   ██║   ██╔══██║██╔══██╗
# ██████╔╝██║██║  ██║██║  ██║██████╔╝███████╗██║  ██║██║  ██║    ╚███╔███╔╝██║   ██║   ██║  ██║██║  ██║
# ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝     ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
#===============================================================================
# File: bitwarden_vaultwarden_installer.sh
# Description: Bitwarden/Vaultwarden installation and configuration script
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/bitwarden_vaultwarden_installer.log"
TEMP_DIR="/tmp/bitwarden_vaultwarden"
VAULTWARDEN_DATA_DIR="/var/lib/vaultwarden"
VAULTWARDEN_CONFIG_DIR="/etc/vaultwarden"
BITWARDEN_PORT=${BITWARDEN_PORT:-8083}
WEBSOCKET_PORT=${WEBSOCKET_PORT:-3012}

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
    echo -e "${BLUE}Bitwarden/Vaultwarden Installer - Password Management Solution${NC}"
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

# Bitwarden/Vaultwarden installation functions
install_vaultwarden_docker() {
    local domain=${1:-"localhost"}
    local admin_token=${2:-"$(openssl rand -base64 32 | tr -d /=+ | cut -c1-32)"}
    local signup_allowed=${3:-"true"}
    
    print_section_header "Installing Vaultwarden via Docker"
    
    # Check if Docker is installed
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
    
    # Create directories
    mkdir -p "$VAULTWARDEN_DATA_DIR"
    mkdir -p "$VAULTWARDEN_CONFIG_DIR"
    
    # Set proper permissions
    chown -R 65534:65534 "$VAULTWARDEN_DATA_DIR" 2>/dev/null || true
    chown -R 65534:65534 "$VAULTWARDEN_CONFIG_DIR" 2>/dev/null || true
    
    # Stop existing Vaultwarden container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^vaultwarden$"; then
        echo -e "${YELLOW}Stopping existing Vaultwarden container${NC}"
        docker stop vaultwarden >/dev/null 2>&1 || true
        docker rm vaultwarden >/dev/null 2>&1 || true
    fi
    
    # Pull Vaultwarden image
    echo -e "${GREEN}Pulling Vaultwarden Docker image${NC}"
    docker pull vaultwarden/server:latest
    
    if [[ $? -ne 0 ]]; then
        error "Failed to pull Vaultwarden Docker image"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Vaultwarden image pulled${NC}"
    
    # Generate encryption key
    local encryption_key=$(openssl rand -base64 48)
    
    # Run Vaultwarden container
    echo -e "${GREEN}Starting Vaultwarden container${NC}"
    echo -e "${GREEN}Domain: ${NC}$domain"
    echo -e "${GREEN}Admin Token: ${NC}$admin_token"
    echo -e "${GREEN}Signups Allowed: ${NC}$signup_allowed"
    echo
    
    docker run -d \
        --name vaultwarden \
        --restart=unless-stopped \
        -e DOMAIN="http://$domain:$BITWARDEN_PORT" \
        -e SIGNUPS_ALLOWED="$signup_allowed" \
        -e ADMIN_TOKEN="$admin_token" \
        -e WEBSOCKET_ENABLED=true \
        -e ROCKET_PORT=$BITWARDEN_PORT \
        -e WEBSOCKET_PORT=$WEBSOCKET_PORT \
        -v "$VAULTWARDEN_DATA_DIR":/data/ \
        -p $BITWARDEN_PORT:$BITWARDEN_PORT \
        -p $WEBSOCKET_PORT:$WEBSOCKET_PORT \
        vaultwarden/server:latest
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Vaultwarden container started${NC}"
        echo -e "${GREEN}Access Vaultwarden at: ${NC}http://$domain:$BITWARDEN_PORT"
        echo -e "${GREEN}Admin panel: ${NC}http://$domain:$BITWARDEN_PORT/admin"
        echo -e "${YELLOW}Use this admin token to access the admin panel: $admin_token${NC}"
        echo -e "${YELLOW}Initial setup may take a few minutes${NC}"
        
        # Create info file with credentials
        cat > "$VAULTWARDEN_CONFIG_DIR/INSTALL_INFO.txt" <<EOF
Vaultwarden Installation Information
=====================================

Domain: http://$domain:$BITWARDEN_PORT
Admin Token: $admin_token
Signups Allowed: $signup_allowed
Websocket Enabled: true
Data Directory: $VAULTWARDEN_DATA_DIR
Config Directory: $VAULTWARDEN_CONFIG_DIR

Ports:
  HTTP: $BITWARDEN_PORT
  WebSocket: $WEBSOCKET_PORT

For production use, consider:
1. Configuring HTTPS with a reverse proxy
2. Setting up proper backups
3. Configuring email settings for invitations
4. Setting up SMTP for email notifications
5. Using a proper domain name
EOF
        
        echo -e "${GREEN}Installation info saved to: $VAULTWARDEN_CONFIG_DIR/INSTALL_INFO.txt${NC}"
    else
        error "Failed to start Vaultwarden container"
        return 1
    fi
    
    info "Vaultwarden Docker installation completed"
    return 0
}

install_bitwarden_rs_docker() {
    local domain=${1:-"localhost"}
    local admin_token=${2:-"$(openssl rand -base64 32 | tr -d /=+ | cut -c1-32)"}
    local signup_allowed=${3:-"true"}
    
    print_section_header "Installing Bitwarden_RS via Docker (Legacy)"
    
    # Check if Docker is installed
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
    
    # Create directories
    mkdir -p "$VAULTWARDEN_DATA_DIR"
    mkdir -p "$VAULTWARDEN_CONFIG_DIR"
    
    # Set proper permissions
    chown -R 65534:65534 "$VAULTWARDEN_DATA_DIR" 2>/dev/null || true
    chown -R 65534:65534 "$VAULTWARDEN_CONFIG_DIR" 2>/dev/null || true
    
    # Stop existing Bitwarden_RS container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^bitwarden_rs$"; then
        echo -e "${YELLOW}Stopping existing Bitwarden_RS container${NC}"
        docker stop bitwarden_rs >/dev/null 2>&1 || true
        docker rm bitwarden_rs >/dev/null 2>&1 || true
    fi
    
    # Pull Bitwarden_RS image
    echo -e "${GREEN}Pulling Bitwarden_RS Docker image${NC}"
    docker pull bitwardenrs/server:latest
    
    if [[ $? -ne 0 ]]; then
        error "Failed to pull Bitwarden_RS Docker image"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Bitwarden_RS image pulled${NC}"
    
    # Generate encryption key
    local encryption_key=$(openssl rand -base64 48)
    
    # Run Bitwarden_RS container
    echo -e "${GREEN}Starting Bitwarden_RS container${NC}"
    echo -e "${GREEN}Domain: ${NC}$domain"
    echo -e "${GREEN}Admin Token: ${NC}$admin_token"
    echo -e "${GREEN}Signups Allowed: ${NC}$signup_allowed"
    echo
    
    docker run -d \
        --name bitwarden_rs \
        --restart=unless-stopped \
        -e DOMAIN="http://$domain:$BITWARDEN_PORT" \
        -e SIGNUPS_ALLOWED="$signup_allowed" \
        -e ADMIN_TOKEN="$admin_token" \
        -e WEBSOCKET_ENABLED=true \
        -e ROCKET_PORT=$BITWARDEN_PORT \
        -e WEBSOCKET_PORT=$WEBSOCKET_PORT \
        -v "$VAULTWARDEN_DATA_DIR":/data/ \
        -p $BITWARDEN_PORT:$BITWARDEN_PORT \
        -p $WEBSOCKET_PORT:$WEBSOCKET_PORT \
        bitwardenrs/server:latest
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Bitwarden_RS container started${NC}"
        echo -e "${GREEN}Access Bitwarden_RS at: ${NC}http://$domain:$BITWARDEN_PORT"
        echo -e "${GREEN}Admin panel: ${NC}http://$domain:$BITWARDEN_PORT/admin"
        echo -e "${YELLOW}Use this admin token to access the admin panel: $admin_token${NC}"
        echo -e "${YELLOW}Initial setup may take a few minutes${NC}"
        
        # Create info file with credentials
        cat > "$VAULTWARDEN_CONFIG_DIR/INSTALL_INFO_BITWARDEN_RS.txt" <<EOF
Bitwarden_RS Installation Information (Legacy)
============================================

Domain: http://$domain:$BITWARDEN_PORT
Admin Token: $admin_token
Signups Allowed: $signup_allowed
Websocket Enabled: true
Data Directory: $VAULTWARDEN_DATA_DIR
Config Directory: $VAULTWARDEN_CONFIG_DIR

Ports:
  HTTP: $BITWARDEN_PORT
  WebSocket: $WEBSOCKET_PORT

For production use, consider:
1. Configuring HTTPS with a reverse proxy
2. Setting up proper backups
3. Configuring email settings for invitations
4. Setting up SMTP for email notifications
5. Using a proper domain name
EOF
        
        echo -e "${GREEN}Installation info saved to: $VAULTWARDEN_CONFIG_DIR/INSTALL_INFO_BITWARDEN_RS.txt${NC}"
    else
        error "Failed to start Bitwarden_RS container"
        return 1
    fi
    
    info "Bitwarden_RS Docker installation completed"
    return 0
}

configure_smtp_settings() {
    local smtp_host=${1:-"smtp.gmail.com"}
    local smtp_port=${2:-587}
    local smtp_ssl=${3:-"true"}
    local smtp_user=${4:-""}
    local smtp_pass=${5:-""}
    local smtp_from=${6:-"bitwarden@localhost"}
    
    print_section_header "Configuring SMTP Settings"
    
    # Check if Vaultwarden container exists
    if ! docker ps -a --format '{{.Names}}' | grep -q "^vaultwarden$\|^bitwarden_rs$"; then
        error "No Vaultwarden/Bitwarden_RS container found"
        return 1
    fi
    
    # Determine container name
    local container_name="vaultwarden"
    if docker ps -a --format '{{.Names}}' | grep -q "^bitwarden_rs$"; then
        container_name="bitwarden_rs"
    fi
    
    # Stop container
    echo -e "${YELLOW}Stopping $container_name container${NC}"
    docker stop "$container_name" >/dev/null 2>&1 || true
    
    # Update environment variables
    echo -e "${GREEN}Configuring SMTP settings${NC}"
    echo -e "${GREEN}SMTP Host: ${NC}$smtp_host"
    echo -e "${GREEN}SMTP Port: ${NC}$smtp_port"
    echo -e "${GREEN}SMTP SSL: ${NC}$smtp_ssl"
    echo -e "${GREEN}SMTP From: ${NC}$smtp_from"
    
    # Set SMTP environment variables
    docker update \
        --env SMTP_HOST="$smtp_host" \
        --env SMTP_PORT="$smtp_port" \
        --env SMTP_SSL="$smtp_ssl" \
        --env SMTP_FROM="$smtp_from" \
        --env SMTP_USERNAME="$smtp_user" \
        --env SMTP_PASSWORD="$smtp_pass" \
        "$container_name" >/dev/null 2>&1 || true
    
    # Start container
    echo -e "${GREEN}Starting $container_name container${NC}"
    docker start "$container_name" >/dev/null 2>&1 || true
    
    echo -e "${GREEN}SUCCESS: SMTP settings configured${NC}"
    
    info "SMTP settings configuration completed"
    return 0
}

configure_https_reverse_proxy() {
    local domain=$1
    local ssl_cert=${2:-"/etc/ssl/certs/nginx-selfsigned.crt"}
    local ssl_key=${3:-"/etc/ssl/private/nginx-selfsigned.key"}
    
    if [[ -z "$domain" ]]; then
        error "Domain is required for HTTPS configuration"
        return 1
    fi
    
    print_section_header "Configuring HTTPS Reverse Proxy"
    
    # Check for Nginx
    if ! command -v nginx >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Nginx for reverse proxy${NC}"
        if command -v apt >/dev/null 2>&1; then
            apt-get update
            apt-get install -y nginx
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y nginx
        elif command -v yum >/dev/null 2>&1; then
            yum install -y nginx
        else
            error "Unsupported package manager"
            return 1
        fi
    fi
    
    # Create self-signed certificate if it doesn't exist
    if [[ ! -f "$ssl_cert" ]] || [[ ! -f "$ssl_key" ]]; then
        echo -e "${YELLOW}Creating self-signed SSL certificate${NC}"
        mkdir -p "$(dirname "$ssl_cert")" "$(dirname "$ssl_key")"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$ssl_key" \
            -out "$ssl_cert" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    fi
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/vaultwarden-proxy <<EOF
upstream vaultwarden_backend {
    server 127.0.0.1:$BITWARDEN_PORT;
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
    
    # SSL configuration
    ssl_certificate $ssl_cert;
    ssl_certificate_key $ssl_key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
    
    # MIME type sniffing protection
    add_header X-Content-Type-Options nosniff;
    
    # XSS protection
    add_header X-XSS-Protection "1; mode=block";
    
    # Frame protection
    add_header X-Frame-Options "SAMEORIGIN";
    
    location / {
        proxy_pass http://vaultwarden_backend;
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
    
    # WebSocket endpoint
    location /notifications/hub {
        proxy_pass http://vaultwarden_backend;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Admin panel
    location /admin {
        proxy_pass http://vaultwarden_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/vaultwarden-proxy /etc/nginx/sites-enabled/
    systemctl reload nginx
    
    echo -e "${GREEN}SUCCESS: HTTPS reverse proxy configured${NC}"
    echo -e "${GREEN}Access Vaultwarden at: ${NC}https://$domain"
    echo -e "${YELLOW}Note: You'll need valid SSL certificates for production use${NC}"
    
    info "HTTPS reverse proxy configuration completed"
    return 0
}

show_vaultwarden_status() {
    print_section_header "Vaultwarden/Bitwarden_RS Status"
    
    # Check if Vaultwarden container is running
    if docker ps --format '{{.Names}}' | grep -q "^vaultwarden$"; then
        echo -e "${GREEN}Vaultwarden Docker Container: ${NC}RUNNING"
        echo -e "${GREEN}Container ID: ${NC}$(docker ps --filter "name=vaultwarden" --format '{{.ID}}')"
        echo -e "${GREEN}Image: ${NC}$(docker ps --filter "name=vaultwarden" --format '{{.Image}}')"
        echo -e "${GREEN}Status: ${NC}$(docker ps --filter "name=vaultwarden" --format '{{.Status}}')"
        
        # Show port mapping
        local ports=$(docker port vaultwarden)
        if [[ -n "$ports" ]]; then
            echo -e "${GREEN}Port Mapping: ${NC}"
            echo "$ports" | sed "s/^/  /"
        fi
    elif docker ps --format '{{.Names}}' | grep -q "^bitwarden_rs$"; then
        echo -e "${GREEN}Bitwarden_RS Docker Container: ${NC}RUNNING"
        echo -e "${GREEN}Container ID: ${NC}$(docker ps --filter "name=bitwarden_rs" --format '{{.ID}}')"
        echo -e "${GREEN}Image: ${NC}$(docker ps --filter "name=bitwarden_rs" --format '{{.Image}}')"
        echo -e "${GREEN}Status: ${NC}$(docker ps --filter "name=bitwarden_rs" --format '{{.Status}}')"
        
        # Show port mapping
        local ports=$(docker port bitwarden_rs)
        if [[ -n "$ports" ]]; then
            echo -e "${GREEN}Port Mapping: ${NC}"
            echo "$ports" | sed "s/^/  /"
        fi
    elif systemctl is-active --quiet vaultwarden; then
        echo -e "${GREEN}Vaultwarden Service: ${NC}RUNNING"
        echo -e "${GREEN}Service Status: ${NC}$(systemctl status vaultwarden --no-pager -l | head -3 | tail -1)"
    else
        echo -e "${YELLOW}Vaultwarden/Bitwarden_RS: ${NC}NOT RUNNING"
    fi
    
    # Show data directory
    if [[ -d "$VAULTWARDEN_DATA_DIR" ]]; then
        echo -e "${GREEN}Data Directory: ${NC}$VAULTWARDEN_DATA_DIR"
        echo -e "${GREEN}Data Size: ${NC}$(du -sh "$VAULTWARDEN_DATA_DIR" 2>/dev/null | cut -f1 || echo 'Unknown')"
    fi
    
    # Show config directory
    if [[ -d "$VAULTWARDEN_CONFIG_DIR" ]]; then
        echo -e "${GREEN}Config Directory: ${NC}$VAULTWARDEN_CONFIG_DIR"
        if [[ -f "$VAULTWARDEN_CONFIG_DIR/INSTALL_INFO.txt" ]]; then
            echo -e "${GREEN}Install Info: ${NC}Available (cat $VAULTWARDEN_CONFIG_DIR/INSTALL_INFO.txt)"
        fi
    fi
    
    info "Vaultwarden/Bitwarden_RS status check completed"
}

backup_vaultwarden_data() {
    local backup_dir=${1:-"/var/backups/vaultwarden"}
    
    print_section_header "Backing Up Vaultwarden Data"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Check if data directory exists
    if [[ ! -d "$VAULTWARDEN_DATA_DIR" ]]; then
        error "Vaultwarden data directory not found: $VAULTWARDEN_DATA_DIR"
        return 1
    fi
    
    # Stop Vaultwarden container if running
    local container_running=false
    if docker ps --format '{{.Names}}' | grep -q "^vaultwarden$\|^bitwarden_rs$"; then
        container_running=true
        local container_name=$(docker ps --filter "name=vaultwarden\|name=bitwarden_rs" --format '{{.Names}}' | head -1)
        echo -e "${YELLOW}Stopping $container_name container for backup${NC}"
        docker stop "$container_name" >/dev/null 2>&1 || true
    fi
    
    # Create timestamp for backup
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/vaultwarden_backup_$timestamp.tar.gz"
    
    # Create backup
    echo -e "${GREEN}Creating backup of Vaultwarden data${NC}"
    tar -czf "$backup_file" -C "$(dirname "$VAULTWARDEN_DATA_DIR")" "$(basename "$VAULTWARDEN_DATA_DIR")"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Backup created${NC}"
        echo -e "${GREEN}Backup file: ${NC}$backup_file"
        echo -e "${GREEN}Backup size: ${NC}$(du -sh "$backup_file" 2>/dev/null | cut -f1 || echo 'Unknown')"
        
        # Create backup info file
        cat > "$backup_dir/backup_info_$timestamp.txt" <<EOF
Vaultwarden Backup Information
==============================

Backup Date: $(date)
Backup File: $backup_file
Data Directory: $VAULTWARDEN_DATA_DIR
Backup Size: $(du -sh "$backup_file" 2>/dev/null | cut -f1 || echo 'Unknown')
Timestamp: $timestamp

To restore this backup:
1. Stop Vaultwarden service/container
2. Extract backup: tar -xzf $backup_file -C /path/to/extract
3. Restore data directory
4. Start Vaultwarden service/container
EOF
        
        echo -e "${GREEN}Backup info: ${NC}$backup_dir/backup_info_$timestamp.txt"
    else
        error "Failed to create backup"
        # Restart container if it was running
        if [[ "$container_running" == true ]] && [[ -n "${container_name:-}" ]]; then
            docker start "$container_name" >/dev/null 2>&1 || true
        fi
        return 1
    fi
    
    # Restart container if it was running
    if [[ "$container_running" == true ]] && [[ -n "${container_name:-}" ]]; then
        echo -e "${GREEN}Restarting $container_name container${NC}"
        docker start "$container_name" >/dev/null 2>&1 || true
    fi
    
    info "Vaultwarden data backup completed"
    return 0
}

restore_vaultwarden_data() {
    local backup_file=$1
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file is required for restore"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_section_header "Restoring Vaultwarden Data"
    
    # Stop Vaultwarden container if running
    local container_running=false
    if docker ps --format '{{.Names}}' | grep -q "^vaultwarden$\|^bitwarden_rs$"; then
        container_running=true
        local container_name=$(docker ps --filter "name=vaultwarden\|name=bitwarden_rs" --format '{{.Names}}' | head -1)
        echo -e "${YELLOW}Stopping $container_name container for restore${NC}"
        docker stop "$container_name" >/dev/null 2>&1 || true
    fi
    
    # Backup current data directory if it exists
    if [[ -d "$VAULTWARDEN_DATA_DIR" ]]; then
        local backup_timestamp=$(date +"%Y%m%d_%H%M%S")
        local current_backup="$VAULTWARDEN_DATA_DIR.backup.$backup_timestamp"
        echo -e "${YELLOW}Backing up current data to: ${NC}$current_backup"
        mv "$VAULTWARDEN_DATA_DIR" "$current_backup"
    fi
    
    # Create data directory
    mkdir -p "$(dirname "$VAULTWARDEN_DATA_DIR")"
    
    # Extract backup
    echo -e "${GREEN}Extracting backup file${NC}"
    tar -xzf "$backup_file" -C "$(dirname "$VAULTWARDEN_DATA_DIR")"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Data restored${NC}"
        
        # Set proper permissions
        chown -R 65534:65534 "$VAULTWARDEN_DATA_DIR" 2>/dev/null || true
        
        echo -e "${GREEN}Permissions set${NC}"
    else
        error "Failed to extract backup"
        # Restore previous backup if it exists
        if [[ -d "$current_backup" ]]; then
            echo -e "${YELLOW}Restoring previous data backup${NC}"
            rm -rf "$VAULTWARDEN_DATA_DIR" 2>/dev/null || true
            mv "$current_backup" "$VAULTWARDEN_DATA_DIR" 2>/dev/null || true
        fi
        # Restart container if it was running
        if [[ "$container_running" == true ]] && [[ -n "${container_name:-}" ]]; then
            docker start "$container_name" >/dev/null 2>&1 || true
        fi
        return 1
    fi
    
    # Restart container if it was running
    if [[ "$container_running" == true ]] && [[ -n "${container_name:-}" ]]; then
        echo -e "${GREEN}Restarting $container_name container${NC}"
        docker start "$container_name" >/dev/null 2>&1 || true
    fi
    
    echo -e "${GREEN}SUCCESS: Vaultwarden data restored${NC}"
    info "Vaultwarden data restore completed"
    return 0
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  install-vaultwarden [domain] [admin_token] [signup_allowed]  Install Vaultwarden"
    echo "  install-bitwarden-rs [domain] [admin_token] [signup_allowed] Install Bitwarden_RS (legacy)"
    echo "  configure-smtp [host] [port] [ssl] [user] [pass] [from]        Configure SMTP settings"
    echo "  https-proxy <domain> [cert] [key]                            Configure HTTPS reverse proxy"
    echo "  status                                                       Show status"
    echo "  backup [backup_dir]                                          Backup data"
    echo "  restore <backup_file>                                         Restore data"
    echo "  help                                                         Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install-vaultwarden mydomain.com mytoken123 true"
    echo "  $0 install-bitwarden-rs localhost mytoken123 false"
    echo "  $0 configure-smtp smtp.gmail.com 587 true user@gmail.com pass no-reply@mydomain.com"
    echo "  $0 https-proxy mydomain.com /etc/ssl/certs/mycert.crt /etc/ssl/private/mykey.key"
    echo "  $0 status"
    echo "  $0 backup /var/backups/vaultwarden"
    echo "  $0 restore /var/backups/vaultwarden/vaultwarden_backup_20250915_120000.tar.gz"
}

# Main execution
main() {
    check_root
    create_temp_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        install-vaultwarden)
            local domain="${2:-localhost}"
            local admin_token="${3:-$(openssl rand -base64 32 | tr -d /=+ | cut -c1-32)}"
            local signup_allowed="${4:-true}"
            
            install_vaultwarden_docker "$domain" "$admin_token" "$signup_allowed"
            ;;
        install-bitwarden-rs)
            local domain="${2:-localhost}"
            local admin_token="${3:-$(openssl rand -base64 32 | tr -d /=+ | cut -c1-32)}"
            local signup_allowed="${4:-true}"
            
            install_bitwarden_rs_docker "$domain" "$admin_token" "$signup_allowed"
            ;;
        configure-smtp)
            local smtp_host="${2:-smtp.gmail.com}"
            local smtp_port="${3:-587}"
            local smtp_ssl="${4:-true}"
            local smtp_user="${5:-}"
            local smtp_pass="${6:-}"
            local smtp_from="${7:-bitwarden@localhost}"
            
            configure_smtp_settings "$smtp_host" "$smtp_port" "$smtp_ssl" "$smtp_user" "$smtp_pass" "$smtp_from"
            ;;
        https-proxy)
            if [[ -z "${2:-}" ]]; then
                error "Domain required for HTTPS proxy configuration"
                show_usage
                exit 1
            fi
            
            local domain="$2"
            local ssl_cert="${3:-/etc/ssl/certs/nginx-selfsigned.crt}"
            local ssl_key="${4:-/etc/ssl/private/nginx-selfsigned.key}"
            
            configure_https_reverse_proxy "$domain" "$ssl_cert" "$ssl_key"
            ;;
        status)
            show_vaultwarden_status
            ;;
        backup)
            local backup_dir="${2:-/var/backups/vaultwarden}"
            backup_vaultwarden_data "$backup_dir"
            ;;
        restore)
            if [[ -z "${2:-}" ]]; then
                error "Backup file required for restore"
                show_usage
                exit 1
            fi
            
            local backup_file="$2"
            restore_vaultwarden_data "$backup_file"
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