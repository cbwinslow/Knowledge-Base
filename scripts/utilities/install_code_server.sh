#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ 
# ██║     ██║   ██║███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗
# ██║     ██║   ██║╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║
# ███████╗╚██████╔╝███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: install_code_server.sh
# Description: Install and configure code-server for remote access
# Author: System Administrator
# Date: 2025-09-18
#===============================================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PORT_DB_FILE="/home/cbwinslow/.cbw_port_database.json"
CODE_SERVER_PORT=""
CODE_SERVER_DIR="/var/lib/cbw/code-server"
CODE_SERVER_CONFIG_DIR="/home/$(whoami)/.config/code-server"
DOMAIN="cloudcurio.cc"
USERNAME="$(whoami)"

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Code Server Installation${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to get port from database
get_port() {
    local service_name=$1
    
    # Check if database file exists
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        error "Port database not found: $PORT_DB_FILE"
        return 1
    fi
    
    # Try to get port from database
    if command -v jq >/dev/null 2>&1; then
        local port=$(jq -r --arg service "$service_name" '.services[$service].port // "0"' "$PORT_DB_FILE" 2>/dev/null)
        if [[ "$port" != "0" ]] && [[ -n "$port" ]]; then
            echo "$port"
            return 0
        fi
    else
        # Fallback to grep if jq is not available
        local port=$(grep -A 5 "\"$service_name\":" "$PORT_DB_FILE" 2>/dev/null | grep '"port"' | sed -E 's/.*"port"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
        if [[ -n "$port" ]]; then
            echo "$port"
            return 0
        fi
    fi
    
    error "Could not find port for service: $service_name"
    return 1
}

# Function to check if port is available
is_port_available() {
    local port_number=$1
    
    # Check if database file exists
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        # Fallback to system check
        if command -v ss >/dev/null 2>&1; then
            if ss -tuln | grep -q ":$port_number "; then
                return 1  # Port in use
            else
                return 0  # Port available
            fi
        else
            # Cannot check, assume available
            return 0
        fi
    fi
    
    # Check in database
    if command -v jq >/dev/null 2>&1; then
        local count=$(jq --arg port "$port_number" '[.services[] | select(.active == true and .port == ($port | tonumber))] | length' "$PORT_DB_FILE")
        if [[ "$count" -eq 0 ]]; then
            return 0  # Available
        else
            return 1  # Not available
        fi
    else
        # Fallback to grep
        if grep -q "\"port\"[[:space:]]*:[[:space:]]*$port_number" "$PORT_DB_FILE" 2>/dev/null; then
            return 1  # Not available
        else
            return 0  # Available
        fi
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking Prerequisites${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        return 1
    fi
    info "Docker is available"
    
    # Check if we can access the port database
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        error "Port database not found: $PORT_DB_FILE"
        return 1
    fi
    info "Port database available"
    
    # Get the port for code-server
    CODE_SERVER_PORT=$(get_port "CODE_SERVER")
    if [[ -z "$CODE_SERVER_PORT" ]] || [[ "$CODE_SERVER_PORT" == "0" ]]; then
        error "Could not get port for CODE_SERVER from database"
        return 1
    fi
    info "Code Server will use port: $CODE_SERVER_PORT"
    
    # Check if port is available
    if ! is_port_available "$CODE_SERVER_PORT"; then
        warn "Port $CODE_SERVER_PORT may be in use, but it's registered for CODE_SERVER"
    else
        info "Port $CODE_SERVER_PORT is available"
    fi
    
    return 0
}

# Function to create directories
create_directories() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Directories${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create code-server directory
    if [[ ! -d "$CODE_SERVER_DIR" ]]; then
        sudo mkdir -p "$CODE_SERVER_DIR"
        sudo chown "$USERNAME:$USERNAME" "$CODE_SERVER_DIR"
        info "Created directory: $CODE_SERVER_DIR"
    else
        info "Directory already exists: $CODE_SERVER_DIR"
    fi
    
    # Create config directory
    mkdir -p "$CODE_SERVER_CONFIG_DIR"
    info "Created directory: $CODE_SERVER_CONFIG_DIR"
}

# Function to generate password
generate_password() {
    local length=${1:-16}
    # Generate a random password
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

# Function to create code-server config
create_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Configuration${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Generate a password for code-server
    local password=$(generate_password 20)
    
    # Create config directory if it doesn't exist
    mkdir -p "$CODE_SERVER_CONFIG_DIR"
    
    # Create code-server config
    cat > "$CODE_SERVER_CONFIG_DIR/config.yaml" <<EOF
bind-addr: 0.0.0.0:${CODE_SERVER_PORT}
auth: password
password: ${password}
cert: false
EOF
    
    # Save password to a file for reference
    echo "$password" > "$CODE_SERVER_CONFIG_DIR/password.txt"
    
    info "Created code-server configuration"
    info "Password saved to: $CODE_SERVER_CONFIG_DIR/password.txt"
    echo -e "${YELLOW}Code Server Password: ${NC}${password}"
}

# Function to create Docker container
create_docker_container() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Docker Container${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Stop existing container if it exists
    if docker ps -a --format '{{.Names}}' | grep -q "^code-server$"; then
        info "Stopping existing code-server container"
        docker stop code-server >/dev/null 2>&1 || true
        docker rm code-server >/dev/null 2>&1 || true
    fi
    
    # Run code-server container
    docker run -d \
        --name=code-server \
        --restart=unless-stopped \
        -p ${CODE_SERVER_PORT}:${CODE_SERVER_PORT} \
        -v "$CODE_SERVER_DIR:/home/coder/project" \
        -v "$CODE_SERVER_CONFIG_DIR:/home/coder/.config/code-server" \
        -u "$(id -u):$(id -g)" \
        -e "DOCKER_USER=$USERNAME" \
        codercom/code-server:latest
    
    if [[ $? -eq 0 ]]; then
        info "Code Server container started successfully"
        info "Access URL: http://$(hostname -I | awk '{print $1}'):${CODE_SERVER_PORT}"
    else
        error "Failed to start Code Server container"
        return 1
    fi
}

# Function to configure firewall
configure_firewall() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Configuring Firewall${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if UFW is available
    if command -v ufw >/dev/null 2>&1; then
        # Allow the code-server port
        sudo ufw allow "$CODE_SERVER_PORT"/tcp comment "Code Server" >/dev/null 2>&1
        info "Firewall configured to allow port $CODE_SERVER_PORT"
    else
        warn "UFW not available, skipping firewall configuration"
    fi
}

# Function to create systemd service (optional)
create_systemd_service() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Systemd Service${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create systemd service file
    sudo tee /etc/systemd/system/code-server.service > /dev/null <<EOF
[Unit]
Description=Code Server
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=/home/$USERNAME
ExecStart=/usr/bin/docker start -a code-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable code-server.service >/dev/null 2>&1
    info "Systemd service created and enabled"
}

# Function to show access information
show_access_info() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Access Information${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local ip=$(hostname -I | awk '{print $1}')
    local password=$(cat "$CODE_SERVER_CONFIG_DIR/password.txt")
    
    echo -e "${GREEN}Code Server is now running!${NC}"
    echo
    echo -e "Local Access: ${YELLOW}http://localhost:${CODE_SERVER_PORT}${NC}"
    echo -e "Network Access: ${YELLOW}http://${ip}:${CODE_SERVER_PORT}${NC}"
    echo
    echo -e "Login Password: ${YELLOW}${password}${NC}"
    echo
    echo -e "${BLUE}Note:${NC} For remote access via domain (cloudcurio.cc), you'll need to:"
    echo -e "  1. Configure DNS to point to this server's IP"
    echo -e "  2. Set up reverse proxy (nginx) for HTTPS access"
    echo -e "  3. Configure Cloudflare if needed"
    echo
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --install        Install and configure code-server (default)"
    echo "  --start          Start code-server container"
    echo "  --stop           Stop code-server container"
    echo "  --restart        Restart code-server container"
    echo "  --status         Show code-server status"
    echo "  --password       Show current password"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --install"
    echo "  $0 --start"
    echo "  $0 --status"
}

# Function to start code-server
start_code_server() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Starting Code Server${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^code-server$"; then
        if docker start code-server; then
            info "Code Server started successfully"
        else
            error "Failed to start Code Server"
            return 1
        fi
    else
        error "Code Server container not found, please install first"
        return 1
    fi
}

# Function to stop code-server
stop_code_server() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Stopping Code Server${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^code-server$"; then
        if docker stop code-server; then
            info "Code Server stopped successfully"
        else
            error "Failed to stop Code Server"
            return 1
        fi
    else
        warn "Code Server container not found"
    fi
}

# Function to check status
check_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Code Server Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^code-server$"; then
        local status=$(docker inspect --format='{{.State.Status}}' code-server)
        local port=$(docker port code-server 2>/dev/null | head -1)
        
        echo -e "Container Status: ${GREEN}${status}${NC}"
        if [[ -n "$port" ]]; then
            echo -e "Port Mapping: ${GREEN}${port}${NC}"
        fi
        
        if [[ "$status" == "running" ]]; then
            echo -e "Access URL: ${YELLOW}http://$(hostname -I | awk '{print $1}'):${CODE_SERVER_PORT}${NC}"
        fi
    else
        echo -e "Container Status: ${RED}Not installed${NC}"
    fi
}

# Function to show password
show_password() {
    if [[ -f "$CODE_SERVER_CONFIG_DIR/password.txt" ]]; then
        local password=$(cat "$CODE_SERVER_CONFIG_DIR/password.txt")
        echo -e "Current Password: ${YELLOW}${password}${NC}"
    else
        error "Password file not found"
        return 1
    fi
}

# Main installation function
install_code_server() {
    print_header
    
    # Check prerequisites
    check_prerequisites || return 1
    
    # Create directories
    create_directories || return 1
    
    # Create configuration
    create_config || return 1
    
    # Create Docker container
    create_docker_container || return 1
    
    # Configure firewall
    configure_firewall || return 1
    
    # Create systemd service
    create_systemd_service || return 1
    
    # Show access information
    show_access_info || return 1
    
    info "Installation completed successfully!"
    return 0
}

# Main function
main() {
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        install_code_server
        return $?
    fi
    
    case $1 in
        --install)
            install_code_server
            ;;
        --start)
            start_code_server
            ;;
        --stop)
            stop_code_server
            ;;
        --restart)
            stop_code_server
            start_code_server
            ;;
        --status)
            check_status
            ;;
        --password)
            show_password
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi