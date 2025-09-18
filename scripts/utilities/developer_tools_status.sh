#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ 
# ██║     ██║   ██║███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗
# ██║     ██║   ██║╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║
# ███████╗╚██████╔╝███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: developer_tools_status.sh
# Description: Check the status of all installed developer tools
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
USERNAME="$(whoami)"
HOME_DIR="/home/$USERNAME"

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Developer Tools Status${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to check code-server status
check_code_server() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Code Server Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if code-server is installed
    if [[ -f "$HOME_DIR/.local/bin/code-server" ]]; then
        echo -e "Installation: ${GREEN}Installed${NC}"
        
        # Check service status
        if systemctl --user is-active --quiet code-server; then
            echo -e "Service: ${GREEN}Running${NC}"
            
            # Get port from config
            if [[ -f "$HOME_DIR/.config/code-server/config.yaml" ]]; then
                local port=$(grep "bind-addr" "$HOME_DIR/.config/code-server/config.yaml" | cut -d: -f3)
                echo -e "Port: ${GREEN}${port}${NC}"
                
                # Get password
                if [[ -f "$HOME_DIR/.config/code-server/password.txt" ]]; then
                    local password=$(cat "$HOME_DIR/.config/code-server/password.txt")
                    echo -e "Password: ${YELLOW}${password}${NC}"
                fi
                
                # Show access URLs
                local local_ip=$(hostname -I | awk '{print $1}')
                echo -e "Local Access: ${YELLOW}http://localhost:${port}${NC}"
                echo -e "Network Access: ${YELLOW}http://${local_ip}:${port}${NC}"
            fi
        else
            echo -e "Service: ${RED}Stopped${NC}"
        fi
    else
        echo -e "Installation: ${RED}Not installed${NC}"
    fi
}

# Function to check VS Code status
check_vscode() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}VS Code Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v code >/dev/null 2>&1; then
        echo -e "Installation: ${GREEN}Installed${NC}"
        local version=$(code --version | head -1)
        echo -e "Version: ${GREEN}${version}${NC}"
    else
        echo -e "Installation: ${RED}Not installed${NC}"
        echo -e "To install: ${YELLOW}sudo /home/cbwinslow/install_additional_ide.sh --vscode${NC}"
    fi
}

# Function to check Cursor status
check_cursor() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Cursor Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if [[ -f "$HOME_DIR/Applications/Cursor.AppImage" ]]; then
        echo -e "Installation: ${GREEN}Installed${NC}"
        echo -e "Run with: ${YELLOW}$HOME_DIR/Applications/Cursor.AppImage${NC}"
    else
        echo -e "Installation: ${RED}Not installed${NC}"
        echo -e "To install: ${YELLOW}sudo /home/cbwinslow/install_additional_ide.sh --cursor${NC}"
    fi
}

# Function to check Windsurf status
check_windsurf() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Windsurf Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if [[ -f "$HOME_DIR/Applications/Windsurf.AppImage" ]]; then
        echo -e "Installation: ${GREEN}Installed${NC}"
        echo -e "Run with: ${YELLOW}$HOME_DIR/Applications/Windsurf.AppImage${NC}"
    else
        echo -e "Installation: ${RED}Not installed${NC}"
        echo -e "To install: ${YELLOW}sudo /home/cbwinslow/install_additional_ide.sh --windsurf${NC}"
    fi
}

# Function to show firewall status
check_firewall() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Firewall Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v ufw >/dev/null 2>&1; then
        if sudo ufw status | grep -q "inactive"; then
            echo -e "Firewall: ${YELLOW}Inactive${NC}"
        else
            echo -e "Firewall: ${GREEN}Active${NC}"
            echo -e "Rules:"
            sudo ufw status | grep -E "(8082|80|443)" | sed 's/^/  /'
        fi
    else
        echo -e "Firewall: ${RED}Not installed${NC}"
    fi
}

# Function to show network information
show_network_info() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Network Information${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "Local IP Address: ${GREEN}$(hostname -I | awk '{print $1}')${NC}"
    
    # Try to get public IP
    if command -v curl >/dev/null 2>&1; then
        local public_ip=$(curl -s https://api.ipify.org)
        if [[ -n "$public_ip" ]]; then
            echo -e "Public IP Address: ${GREEN}${public_ip}${NC}"
        fi
    fi
}

# Main function
main() {
    print_header
    
    # Check code-server
    check_code_server
    echo
    
    # Check VS Code
    check_vscode
    echo
    
    # Check Cursor
    check_cursor
    echo
    
    # Check Windsurf
    check_windsurf
    echo
    
    # Check firewall
    check_firewall
    echo
    
    # Show network info
    show_network_info
    echo
    
    # Show remote access instructions
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Remote Access Instructions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "For remote access setup, see: ${YELLOW}/home/cbwinslow/DEVELOPER_TOOLS_REMOTE_ACCESS.md${NC}"
    echo -e "To install additional IDEs: ${YELLOW}sudo /home/cbwinslow/install_additional_ide.sh --all${NC}"
}

# Run main function
main "$@"