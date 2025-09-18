#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗   ██╗     ██████╗ ███████╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔════╝ ██╔════╝██╔═══██╗
# ███████╗██║   ██║███████╗   ██║   ██████╔╝ ╚████╔╝     ██║  ███╗█████╗  ██║   ██║
# ╚════██║██║   ██║╚════██║   ██║   ██╔══██╗  ╚██╔╝      ██║   ██║██╔══╝  ██║   ██║
# ███████║╚██████╔╝███████║   ██║   ██║  ██║   ██║       ╚██████╔╝███████╗╚██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝        ╚═════╝ ╚══════╝ ╚═════╝ 
#===============================================================================
# File: cbw_sudo_setup.sh
# Description: System-level setup script with sudo privileges for CBW infrastructure
# Author: System Administrator
# Date: 2025-09-17
#===============================================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW System-Level Setup (Requires Sudo Privileges)${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to check if running as root or with sudo
check_privileges() {
    if [[ $EUID -ne 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
        error "This script must be run as root or with sudo privileges"
        return 1
    fi
    
    if [[ $EUID -eq 0 ]] && [[ -n "${SUDO_USER:-}" ]]; then
        info "Running with sudo privileges as user: $SUDO_USER"
    elif [[ $EUID -eq 0 ]]; then
        info "Running as root user"
    fi
    
    return 0
}

# Function to update package lists
update_packages() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Updating Package Lists${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v apt >/dev/null 2>&1; then
        info "Updating APT package lists"
        apt update -y
    elif command -v dnf >/dev/null 2>&1; then
        info "Updating DNF package lists"
        dnf check-update -y
    elif command -v yum >/dev/null 2>&1; then
        info "Updating YUM package lists"
        yum check-update -y
    else
        error "No supported package manager found"
        return 1
    fi
    
    return 0
}

# Function to install required packages
install_packages() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installing Required Packages${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Load package list from configuration file
    local packages_config="/home/cbwinslow/.cbw_packages.conf"
    local packages=()
    
    # Check if config file exists
    if [[ -f "$packages_config" ]]; then
        info "Loading packages from configuration file"
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            
            # Trim whitespace
            line=$(echo "$line" | xargs)
            [[ -n "$line" ]] && packages+=("$line")
        done < "$packages_config"
    else
        info "Using default package list"
        packages=(
            "curl"
            "wget"
            "jq"
            "git"
            "unzip"
            "docker.io"
            "docker-compose"
            "postgresql-client"
            "postgresql-common"
            "ufw"
            "net-tools"
            "iproute2"
            "iptables-persistent"
            "fail2ban"
            "openssh-server"
        )
    fi
    
    # Install packages
    if command -v apt >/dev/null 2>&1; then
        info "Installing packages with APT"
        apt install -y "${packages[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        info "Installing packages with DNF"
        dnf install -y "${packages[@]}"
    elif command -v yum >/dev/null 2>&1; then
        info "Installing packages with YUM"
        yum install -y "${packages[@]}"
    else
        error "No supported package manager found"
        return 1
    fi
    
    return 0
}

# Function to setup Docker
setup_docker() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Setting Up Docker${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if Docker is already installed and running
    if command -v docker >/dev/null 2>&1 && systemctl is-active --quiet docker; then
        info "Docker is already installed and running"
        
        # Check if user is in docker group
        if [[ -n "${SUDO_USER:-}" ]]; then
            if id "$SUDO_USER" | grep -q docker; then
                info "User $SUDO_USER is already in docker group"
            else
                info "Adding user $SUDO_USER to docker group"
                usermod -aG docker "$SUDO_USER"
            fi
        fi
    else
        # Install Docker if not installed
        if ! command -v docker >/dev/null 2>&1; then
            info "Installing Docker"
            if command -v apt >/dev/null 2>&1; then
                apt install -y docker.io
            elif command -v dnf >/dev/null 2>&1; then
                dnf install -y docker
            elif command -v yum >/dev/null 2>&1; then
                yum install -y docker
            fi
        fi
        
        # Start and enable Docker service
        info "Starting Docker service"
        systemctl start docker
        
        info "Enabling Docker service to start on boot"
        systemctl enable docker
        
        # Add user to docker group if specified
        if [[ -n "${SUDO_USER:-}" ]]; then
            info "Adding user $SUDO_USER to docker group"
            usermod -aG docker "$SUDO_USER"
        fi
    fi
    
    # Configure Docker daemon
    info "Configuring Docker daemon"
    mkdir -p /etc/docker
    
    # Only update config if it doesn't exist or is different
    local docker_config="/etc/docker/daemon.json"
    local temp_config=$(mktemp)
    
    cat > "$temp_config" <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
    
    # Compare with existing config
    if [[ -f "$docker_config" ]]; then
        if ! cmp -s "$temp_config" "$docker_config"; then
            info "Updating Docker daemon configuration"
            mv "$temp_config" "$docker_config"
            systemctl restart docker
        else
            info "Docker daemon configuration is already up to date"
            rm -f "$temp_config"
        fi
    else
        info "Creating Docker daemon configuration"
        mv "$temp_config" "$docker_config"
        systemctl restart docker
    fi
    
    return 0
}

# Function to setup firewall
setup_firewall() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Setting Up Firewall (UFW)${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if UFW is available
    if ! command -v ufw >/dev/null 2>&1; then
        warn "UFW not available, skipping firewall setup"
        return 0
    fi
    
    # Check if UFW is already enabled
    if ufw status | grep -q "active"; then
        info "UFW is already active"
    else
        # Enable UFW
        info "Enabling UFW firewall"
        echo "y" | ufw enable
    fi
    
    # Set default policies (only if not already set)
    info "Setting firewall policies"
    ufw default deny incoming || true
    ufw default allow outgoing || true
    
    # Load firewall rules from configuration
    local firewall_config="/home/cbwinslow/.cbw_firewall_rules.conf"
    
    if [[ -f "$firewall_config" ]]; then
        info "Loading firewall rules from configuration file"
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            
            # Trim whitespace
            line=$(echo "$line" | xargs)
            
            # Check if rule already exists
            if ! ufw status | grep -q "$line"; then
                info "Adding firewall rule: $line"
                ufw allow "$line" >/dev/null 2>&1 || true
            else
                info "Firewall rule already exists: $line"
            fi
        done < "$firewall_config"
    else
        info "Using default firewall rules"
        
        # Essential services
        local rules=(
            "ssh"
            "http"
            "https"
        )
        
        # CBW services (load from port database if available)
        if [[ -f "/home/cbwinslow/cbw_simple_port_db.sh" ]] && [[ -x "/home/cbwinslow/cbw_simple_port_db.sh" ]]; then
            # Get ports from simple database
            local grafana_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get GRAFANA)
            local prometheus_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get PROMETHEUS)
            local cadvisor_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get CADVISOR)
            local loki_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get LOKI)
            local pg_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get POSTGRESQL)
            local mongo_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get MONGODB)
            local qdrant_http_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get QDRANT_HTTP)
            local opensearch_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get OPENSEARCH)
            local rabbitmq_mgmt_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get RABBITMQ_MANAGEMENT)
            local kong_proxy_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get KONG_PROXY)
            local kong_proxy_ssl_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get KONG_PROXY_SSL)
            local kong_admin_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get KONG_ADMIN)
            local kong_admin_ssl_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get KONG_ADMIN_SSL)
            
            # Add CBW specific rules
            rules+=(
                "$grafana_port/tcp"
                "$prometheus_port/tcp"
                "$cadvisor_port/tcp"
                "$loki_port/tcp"
                "$pg_port/tcp"
                "$mongo_port/tcp"
                "$qdrant_http_port/tcp"
                "$opensearch_port/tcp"
                "$rabbitmq_mgmt_port/tcp"
                "$kong_proxy_port/tcp"
                "$kong_proxy_ssl_port/tcp"
                "$kong_admin_port/tcp"
                "$kong_admin_ssl_port/tcp"
            )
        else
            # Default ports
            rules+=(
                "3001/tcp"  # Grafana
                "9091/tcp"  # Prometheus
                "8081/tcp"  # cAdvisor
                "3100/tcp"  # Loki
                "5433/tcp"  # PostgreSQL
                "27018/tcp" # MongoDB
                "6333/tcp"  # Qdrant HTTP
                "9200/tcp"  # OpenSearch
                "15672/tcp" # RabbitMQ Management
                "8000/tcp"  # Kong Proxy
                "8443/tcp"  # Kong Proxy SSL
                "8001/tcp"  # Kong Admin
                "8444/tcp"  # Kong Admin SSL
            )
        fi
        
        # Apply rules
        for rule in "${rules[@]}"; do
            if ! ufw status | grep -q "$rule"; then
                info "Adding firewall rule: $rule"
                ufw allow "$rule" >/dev/null 2>&1 || true
            else
                info "Firewall rule already exists: $rule"
            fi
        done
    fi
    
    # Reload firewall
    info "Reloading firewall"
    ufw reload
    
    return 0
}

# Function to setup security
setup_security() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Setting Up Security${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Configure Fail2Ban
    info "Configuring Fail2Ban"
    if systemctl is-active --quiet fail2ban; then
        info "Fail2Ban is already running"
    else
        systemctl start fail2ban || true
        systemctl enable fail2ban || true
    fi
    
    # Configure SSH security
    info "Configuring SSH security"
    local ssh_config="/etc/ssh/sshd_config"
    local ssh_config_changed=false
    
    # Disable password authentication (only if not already disabled)
    if ! grep -q "^PasswordAuthentication no" "$ssh_config"; then
        info "Disabling SSH password authentication"
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$ssh_config" 2>/dev/null || true
        sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "$ssh_config" 2>/dev/null || true
        ssh_config_changed=true
    else
        info "SSH password authentication already disabled"
    fi
    
    # Disable root login (only if not already disabled)
    if ! grep -q "^PermitRootLogin no" "$ssh_config"; then
        info "Disabling SSH root login"
        sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' "$ssh_config" 2>/dev/null || true
        sed -i 's/PermitRootLogin yes/PermitRootLogin no/' "$ssh_config" 2>/dev/null || true
        ssh_config_changed=true
    else
        info "SSH root login already disabled"
    fi
    
    # Restart SSH if configuration changed
    if [[ "$ssh_config_changed" == true ]]; then
        info "Restarting SSH service"
        systemctl restart ssh
    fi
    
    return 0
}

# Function to create system directories
create_directories() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating System Directories${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Load directory list from configuration
    local dirs_config="/home/cbwinslow/.cbw_directories.conf"
    local dirs=()
    
    # Check if config file exists
    if [[ -f "$dirs_config" ]]; then
        info "Loading directories from configuration file"
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            
            # Trim whitespace
            line=$(echo "$line" | xargs)
            [[ -n "$line" ]] && dirs+=("$line")
        done < "$dirs_config"
    else
        info "Using default directory list"
        dirs=(
            "/var/lib/cbw"
            "/var/lib/cbw/postgresql"
            "/var/lib/cbw/mongodb"
            "/var/lib/cbw/qdrant"
            "/var/lib/cbw/opensearch"
            "/var/lib/cbw/rabbitmq"
            "/var/log/cbw"
            "/etc/cbw"
        )
    fi
    
    # Create directories
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "Directory already exists: $dir"
        else
            info "Creating directory: $dir"
            mkdir -p "$dir"
        fi
        
        # Set ownership if user is specified
        if [[ -n "${SUDO_USER:-}" ]]; then
            chown "$SUDO_USER:$SUDO_USER" "$dir" 2>/dev/null || true
        fi
        
        chmod 755 "$dir"
    done
    
    return 0
}

# Function to setup systemd services
setup_systemd_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Setting Up Systemd Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create a systemd service for CBW port database (as example)
    info "Creating CBW port database service"
    
    local service_file="/etc/systemd/system/cbw-port-db.service"
    local temp_service=$(mktemp)
    
    cat > "$temp_service" <<'EOF'
[Unit]
Description=CBW Port Database Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true

[Install]
WantedBy=multi-user.target
EOF
    
    # Compare with existing service file
    if [[ -f "$service_file" ]]; then
        if ! cmp -s "$temp_service" "$service_file"; then
            info "Updating CBW port database service"
            mv "$temp_service" "$service_file"
            systemctl daemon-reload
        else
            info "CBW port database service is already up to date"
            rm -f "$temp_service"
        fi
    else
        info "Creating CBW port database service"
        mv "$temp_service" "$service_file"
        systemctl daemon-reload
    fi
    
    # Enable the service if not already enabled
    if systemctl is-enabled --quiet cbw-port-db.service; then
        info "CBW port database service already enabled"
    else
        info "Enabling CBW port database service"
        systemctl enable cbw-port-db.service
    fi
    
    return 0
}

# Function to setup cron jobs
setup_cron_jobs() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Setting Up Cron Jobs${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create a cron job for CBW maintenance (as example)
    if [[ -n "${SUDO_USER:-}" ]]; then
        info "Creating CBW maintenance cron job"
        
        local cron_file="/etc/cron.d/cbw-maintenance"
        local temp_cron=$(mktemp)
        
        # Create cron entry
        cat > "$temp_cron" <<EOF
# CBW Maintenance Cron Job
0 2 * * * $SUDO_USER /home/$SUDO_USER/cbw_maintenance.sh >/var/log/cbw/maintenance.log 2>&1
EOF
        
        # Compare with existing cron file
        if [[ -f "$cron_file" ]]; then
            if ! cmp -s "$temp_cron" "$cron_file"; then
                info "Updating CBW maintenance cron job"
                mv "$temp_cron" "$cron_file"
                chmod 644 "$cron_file"
            else
                info "CBW maintenance cron job is already up to date"
                rm -f "$temp_cron"
            fi
        else
            info "Creating CBW maintenance cron job"
            mv "$temp_cron" "$cron_file"
            chmod 644 "$cron_file"
        fi
    fi
    
    return 0
}

# Function to setup log rotation
setup_log_rotation() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Setting Up Log Rotation${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create logrotate configuration for CBW
    info "Creating logrotate configuration for CBW"
    
    local logrotate_file="/etc/logrotate.d/cbw"
    local temp_logrotate=$(mktemp)
    
    cat > "$temp_logrotate" <<'EOF'
/var/log/cbw/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOF
    
    # Compare with existing logrotate file
    if [[ -f "$logrotate_file" ]]; then
        if ! cmp -s "$temp_logrotate" "$logrotate_file"; then
            info "Updating logrotate configuration"
            mv "$temp_logrotate" "$logrotate_file"
        else
            info "Logrotate configuration is already up to date"
            rm -f "$temp_logrotate"
        fi
    else
        info "Creating logrotate configuration"
        mv "$temp_logrotate" "$logrotate_file"
    fi
    
    return 0
}

# Function to verify setup
verify_setup() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Verifying Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check Docker
    if systemctl is-active --quiet docker; then
        info "Docker: ${GREEN}RUNNING${NC}"
    else
        warn "Docker: ${YELLOW}NOT RUNNING${NC}"
    fi
    
    # Check firewall
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "active"; then
        info "Firewall: ${GREEN}ACTIVE${NC}"
    else
        warn "Firewall: ${YELLOW}INACTIVE${NC}"
    fi
    
    # Check required services
    local services=("ssh" "docker" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            info "$service: ${GREEN}RUNNING${NC}"
        else
            warn "$service: ${YELLOW}NOT RUNNING${NC}"
        fi
    done
    
    # Check directories
    local dirs=("/var/lib/cbw" "/var/log/cbw" "/etc/cbw")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "Directory $dir: ${GREEN}EXISTS${NC}"
        else
            warn "Directory $dir: ${YELLOW}MISSING${NC}"
        fi
    done
    
    return 0
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all               Run all setup steps (default)"
    echo "  --packages          Update and install packages only"
    echo "  --docker            Setup Docker only"
    echo "  --firewall          Setup firewall only"
    echo "  --security          Setup security only"
    echo "  --directories       Create directories only"
    echo "  --services          Setup systemd services only"
    echo "  --cron              Setup cron jobs only"
    echo "  --logrotate         Setup log rotation only"
    echo "  --verify            Verify setup only"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --packages"
    echo "  $0 --docker --firewall"
    echo "  $0 --verify"
}

main() {
    print_header
    
    # Check privileges
    if ! check_privileges; then
        error "Insufficient privileges to run setup"
        exit 1
    fi
    
    # Parse arguments
    local run_all=false
    local run_packages=false
    local run_docker=false
    local run_firewall=false
    local run_security=false
    local run_directories=false
    local run_services=false
    local run_cron=false
    local run_logrotate=false
    local run_verify=false
    
    if [[ $# -eq 0 ]]; then
        run_all=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --all)
                    run_all=true
                    shift
                    ;;
                --packages)
                    run_packages=true
                    shift
                    ;;
                --docker)
                    run_docker=true
                    shift
                    ;;
                --firewall)
                    run_firewall=true
                    shift
                    ;;
                --security)
                    run_security=true
                    shift
                    ;;
                --directories)
                    run_directories=true
                    shift
                    ;;
                --services)
                    run_services=true
                    shift
                    ;;
                --cron)
                    run_cron=true
                    shift
                    ;;
                --logrotate)
                    run_logrotate=true
                    shift
                    ;;
                --verify)
                    run_verify=true
                    shift
                    ;;
                --help|-h)
                    show_usage
                    exit 0
                    ;;
                *)
                    error "Unknown option: $1"
                    show_usage
                    exit 1
                    ;;
            esac
        done
    fi
    
    # Execute requested actions
    if [[ "$run_all" == true ]] || [[ "$run_packages" == true ]]; then
        update_packages
        install_packages
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_docker" == true ]]; then
        setup_docker
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_firewall" == true ]]; then
        setup_firewall
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_security" == true ]]; then
        setup_security
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_directories" == true ]]; then
        create_directories
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_services" == true ]]; then
        setup_systemd_services
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_cron" == true ]]; then
        setup_cron_jobs
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_logrotate" == true ]]; then
        setup_log_rotation
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_verify" == true ]]; then
        verify_setup
    fi
    
    echo
    info "CBW system-level setup completed successfully!"
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        info "Please log out and log back in for group membership changes to take effect"
        info "Or run: newgrp docker"
    fi
    
    info "You can now run the CBW deployment scripts as a regular user"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi