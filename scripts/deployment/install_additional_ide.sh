#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ 
# ██║     ██║   ██║███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗
# ██║     ██║   ██║╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║
# ███████╗╚██████╔╝███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: install_additional_ide.sh
# Description: Install VS Code, Cursor, and Windsurf with sudo privileges
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
    echo -e "${BLUE}CBW Additional IDE Installation${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to install VS Code
install_vscode() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installing VS Code${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if we're on Ubuntu/Debian
    if command -v apt >/dev/null 2>&1; then
        # Download and install VS Code
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
        sudo install -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/
        sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm /tmp/microsoft.gpg
        
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
    sudo -u $USERNAME mkdir -p "$cursor_dir"
    
    # Try to download the latest AppImage
    if sudo -u $USERNAME wget -O "$cursor_dir/Cursor.AppImage" "https://downloader.cursor.sh/linux/appImage/x64" 2>/dev/null; then
        sudo -u $USERNAME chmod +x "$cursor_dir/Cursor.AppImage"
        
        # Create a desktop entry
        sudo -u $USERNAME mkdir -p "$HOME_DIR/.local/share/applications"
        sudo -u $USERNAME tee "$HOME_DIR/.local/share/applications/cursor.desktop" > /dev/null <<EOF
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
    sudo -u $USERNAME mkdir -p "$windsurf_dir"
    
    # Try to download the latest AppImage
    if sudo -u $USERNAME wget -O "$windsurf_dir/Windsurf.AppImage" "https://codeiumstorage.googleapis.com/releases/1.0.0/windsurf-1.0.0.AppImage" 2>/dev/null; then
        sudo -u $USERNAME chmod +x "$windsurf_dir/Windsurf.AppImage"
        
        # Create a desktop entry
        sudo -u $USERNAME mkdir -p "$HOME_DIR/.local/share/applications"
        sudo -u $USERNAME tee "$HOME_DIR/.local/share/applications/windsurf.desktop" > /dev/null <<EOF
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --vscode         Install only VS Code"
    echo "  --cursor         Install only Cursor"
    echo "  --windsurf       Install only Windsurf"
    echo "  --all            Install all IDEs (default)"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  sudo $0 --vscode"
    echo "  sudo $0 --all"
}

# Main installation function
install_all_ide() {
    print_header
    
    # Install VS Code
    install_vscode || warn "VS Code installation failed"
    
    # Install Cursor
    install_cursor || warn "Cursor installation failed"
    
    # Install Windsurf
    install_windsurf || warn "Windsurf installation failed"
    
    info "All IDEs installation completed!"
    return 0
}

# Main function
main() {
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        install_all_ide
        return $?
    fi
    
    case $1 in
        --vscode)
            install_vscode
            ;;
        --cursor)
            install_cursor
            ;;
        --windsurf)
            install_windsurf
            ;;
        --all)
            install_all_ide
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