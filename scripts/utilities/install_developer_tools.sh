#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ 
# ██║     ██║   ██║███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗
# ██║     ██║   ██║╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║
# ███████╗╚██████╔╝███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: install_developer_tools.sh
# Description: Install code-server, Cursor, Windsurf, and VS Code on bare metal
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
USERNAME="$(whoami)"
HOME_DIR="/home/$USERNAME"

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Developer Tools Installation${NC}"
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

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking Prerequisites${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
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
    
    return 0
}

# Function to install code-server (bare metal)
install_code_server() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installing Code Server (Bare Metal)${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Run the official install script
    if curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/home/$USERNAME/.local; then
        info "Code Server installed successfully"
    else
        error "Failed to install Code Server"
        return 1
    fi
    
    # Create code-server config directory
    mkdir -p "$HOME_DIR/.config/code-server"
    
    # Generate a password for code-server
    local password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)
    
    # Create code-server config
    cat > "$HOME_DIR/.config/code-server/config.yaml" <<EOF
bind-addr: 0.0.0.0:${CODE_SERVER_PORT}
auth: password
password: ${password}
cert: false
EOF
    
    # Save password to a file for reference
    echo "$password" > "$HOME_DIR/.config/code-server/password.txt"
    
    info "Created code-server configuration"
    info "Password saved to: $HOME_DIR/.config/code-server/password.txt"
    echo -e "${YELLOW}Code Server Password: ${NC}${password}"
    
    # Create systemd user service
    mkdir -p "$HOME_DIR/.config/systemd/user"
    cat > "$HOME_DIR/.config/systemd/user/code-server.service" <<EOF
[Unit]
Description=Code Server
After=network.target

[Service]
Type=simple
Environment=HOME=$HOME_DIR
ExecStart=$HOME_DIR/.local/bin/code-server
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    # Enable and start the service
    systemctl --user daemon-reload
    systemctl --user enable code-server.service >/dev/null 2>&1
    systemctl --user start code-server.service
    
    info "Code Server systemd user service created and started"
    info "Access URL: http://$(hostname -I | awk '{print $1}'):${CODE_SERVER_PORT}"
}

# Function to install VS Code
install_vscode() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installing VS Code${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if we're on Ubuntu/Debian
    if command -v apt >/dev/null 2>&1; then
        # Download and install VS Code
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
        sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm microsoft.gpg
        
        sudo apt update
        sudo apt install -y code
        
        info "VS Code installed successfully"
    elif command -v dnf >/dev/null 2>&1; then
        # For Fedora/RHEL
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf install -y code
        
        info "VS Code installed successfully"
    else
        warn "Unsupported package manager. Please install VS Code manually."
        return 1
    fi
}

# Function to install Cursor
install_cursor() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installing Cursor${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Download Cursor AppImage
    local cursor_dir="$HOME_DIR/Applications"
    mkdir -p "$cursor_dir"
    
    # Try to download the latest AppImage
    if wget -O "$cursor_dir/Cursor.AppImage" "https://downloader.cursor.sh/linux/appImage/x64" 2>/dev/null; then
        chmod +x "$cursor_dir/Cursor.AppImage"
        
        # Create a desktop entry
        mkdir -p "$HOME_DIR/.local/share/applications"
        cat > "$HOME_DIR/.local/share/applications/cursor.desktop" <<EOF
[Desktop Entry]
Name=Cursor
Exec=$cursor_dir/Cursor.AppImage %U
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Comment=The AI-first Code Editor
Categories=Development;IDE;
EOF
        
        info "Cursor installed successfully"
        info "You can run Cursor with: $cursor_dir/Cursor.AppImage"
    else
        warn "Failed to download Cursor. Please download it manually from https://www.cursor.so/"
        return 1
    fi
}

# Function to install Windsurf
install_windsurf() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installing Windsurf${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Download Windsurf AppImage
    local windsurf_dir="$HOME_DIR/Applications"
    mkdir -p "$windsurf_dir"
    
    # Try to download the latest AppImage
    if wget -O "$windsurf_dir/Windsurf.AppImage" "https://codeiumstorage.googleapis.com/releases/1.0.0/windsurf-1.0.0.AppImage" 2>/dev/null; then
        chmod +x "$windsurf_dir/Windsurf.AppImage"
        
        # Create a desktop entry
        mkdir -p "$HOME_DIR/.local/share/applications"
        cat > "$HOME_DIR/.local/share/applications/windsurf.desktop" <<EOF
[Desktop Entry]
Name=Windsurf
Exec=$windsurf_dir/Windsurf.AppImage %U
Terminal=false
Type=Application
Icon=windsurf
StartupWMClass=Windsurf
Comment=Codeium's AI-powered IDE
Categories=Development;IDE;
EOF
        
        info "Windsurf installed successfully"
        info "You can run Windsurf with: $windsurf_dir/Windsurf.AppImage"
    else
        warn "Failed to download Windsurf. Please download it manually from https://codeium.com/windsurf"
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
        # Allow the code-server port (this requires sudo)
        info "Please run 'sudo ufw allow $CODE_SERVER_PORT/tcp comment \"Code Server\"' to configure firewall"
    else
        warn "UFW not available, skipping firewall configuration"
    fi
}

# Function to show access information
show_access_info() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Access Information${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local ip=$(hostname -I | awk '{print $1}')
    local password=$(cat "$HOME_DIR/.config/code-server/password.txt")
    
    echo -e "${GREEN}Developer Tools Installation Completed!${NC}"
    echo
    echo -e "Code Server:"
    echo -e "  Access URL: ${YELLOW}http://${ip}:${CODE_SERVER_PORT}${NC}"
    echo -e "  Password: ${YELLOW}${password}${NC}"
    echo -e "  Service: ${YELLOW}systemctl --user {start|stop|status} code-server${NC}"
    echo
    echo -e "VS Code:"
    echo -e "  Run with: ${YELLOW}code${NC}"
    echo
    echo -e "Cursor:"
    echo -e "  Run with: ${YELLOW}$HOME_DIR/Applications/Cursor.AppImage${NC}"
    echo
    echo -e "Windsurf:"
    echo -e "  Run with: ${YELLOW}$HOME_DIR/Applications/Windsurf.AppImage${NC}"
    echo
    echo -e "${BLUE}Note:${NC} For remote access via domain (cloudcurio.cc), you'll need to:"
    echo -e "  1. Configure DNS to point to this server's IP"
    echo -e "  2. Set up reverse proxy (nginx) for HTTPS access"
    echo -e "  3. Configure Cloudflare if needed"
    echo -e "  4. Run 'sudo ufw allow $CODE_SERVER_PORT/tcp comment \"Code Server\"' to configure firewall"
    echo
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --install        Install all developer tools (default)"
    echo "  --code-server    Install only code-server"
    echo "  --vscode         Install only VS Code"
    echo "  --cursor         Install only Cursor"
    echo "  --windsurf       Install only Windsurf"
    echo "  --status         Show installation status"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --install"
    echo "  $0 --code-server"
    echo "  $0 --status"
}

# Function to check status
check_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installation Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check code-server
    if [[ -f "$HOME_DIR/.local/bin/code-server" ]]; then
        echo -e "Code Server: ${GREEN}Installed${NC}"
        if systemctl --user is-active --quiet code-server; then
            echo -e "  Service Status: ${GREEN}Running${NC}"
        else
            echo -e "  Service Status: ${YELLOW}Stopped${NC}"
        fi
    else
        echo -e "Code Server: ${RED}Not installed${NC}"
    fi
    
    # Check VS Code
    if command -v code >/dev/null 2>&1; then
        echo -e "VS Code: ${GREEN}Installed${NC}"
    else
        echo -e "VS Code: ${RED}Not installed${NC}"
    fi
    
    # Check Cursor
    if [[ -f "$HOME_DIR/Applications/Cursor.AppImage" ]]; then
        echo -e "Cursor: ${GREEN}Installed${NC}"
    else
        echo -e "Cursor: ${RED}Not installed${NC}"
    fi
    
    # Check Windsurf
    if [[ -f "$HOME_DIR/Applications/Windsurf.AppImage" ]]; then
        echo -e "Windsurf: ${GREEN}Installed${NC}"
    else
        echo -e "Windsurf: ${RED}Not installed${NC}"
    fi
}

# Main installation function
install_all_tools() {
    print_header
    
    # Check prerequisites
    check_prerequisites || return 1
    
    # Install code-server
    install_code_server || return 1
    
    # Install VS Code
    install_vscode || warn "VS Code installation failed"
    
    # Install Cursor
    install_cursor || warn "Cursor installation failed"
    
    # Install Windsurf
    install_windsurf || warn "Windsurf installation failed"
    
    # Configure firewall
    configure_firewall || return 1
    
    # Show access information
    show_access_info || return 1
    
    info "All developer tools installation completed!"
    return 0
}

# Main function
main() {
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        install_all_tools
        return $?
    fi
    
    case $1 in
        --install)
            install_all_tools
            ;;
        --code-server)
            check_prerequisites
            install_code_server
            ;;
        --vscode)
            install_vscode
            ;;
        --cursor)
            install_cursor
            ;;
        --windsurf)
            install_windsurf
            ;;
        --status)
            check_status
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