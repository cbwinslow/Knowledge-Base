#!/bin/bash

################################################################################
# Fedora Multimedia Installation Script
################################################################################
#
# Description:
#   This script automates the installation and configuration of multimedia
#   packages on Fedora Linux systems. It installs the necessary codec packages,
#   switches to the full-featured FFmpeg implementation, and installs
#   complementary sound and video tools.
#
# Purpose:
#   - Install multimedia group packages for codec support
#   - Replace ffmpeg-free with full FFmpeg for complete format support
#   - Install GStreamer components for GNOME-based applications
#   - Install additional sound and video utilities
#
# Requirements:
#   - Fedora Linux (tested on Fedora 38+)
#   - sudo privileges
#   - Active internet connection
#
# Usage:
#   sudo ./install_fedora_multimedia.sh
#
# Author: Knowledge Base Repository
# Date: 2025-11-01
# Version: 1.0
#
################################################################################

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Pipe failures cause script to fail

################################################################################
# Color Codes for Output
################################################################################
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# Logging Functions
################################################################################

# Print informational messages in blue
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Print success messages in green
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Print warning messages in yellow
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Print error messages in red
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Error Handling Functions
################################################################################

# Function to handle errors and provide meaningful messages
error_handler() {
    local line_number=$1
    local command=$2
    log_error "Command failed at line ${line_number}: ${command}"
    log_error "Script execution aborted."
    exit 1
}

# Set trap to catch errors
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

################################################################################
# Validation Functions
################################################################################

# Check if script is run with sudo/root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo privileges"
        log_info "Usage: sudo $0"
        exit 1
    fi
}

# Check if running on Fedora
check_fedora() {
    if [[ ! -f /etc/fedora-release ]]; then
        log_error "This script is designed for Fedora Linux only"
        log_info "Detected OS: $(uname -s)"
        exit 1
    fi
    
    log_success "Fedora Linux detected: $(cat /etc/fedora-release)"
}

# Check internet connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    if ! ping -c 1 -W 2 fedoraproject.org &> /dev/null; then
        log_error "No internet connection detected"
        log_error "Please check your network connection and try again"
        exit 1
    fi
    log_success "Internet connection verified"
}

################################################################################
# Installation Functions
################################################################################

# Step 1: Install multimedia group packages
install_multimedia_group() {
    log_info "Step 1/4: Installing multimedia group packages..."
    log_info "This includes various codecs and multimedia libraries"
    
    if sudo dnf group install -y multimedia; then
        log_success "Multimedia group packages installed successfully"
    else
        log_error "Failed to install multimedia group packages"
        return 1
    fi
}

# Step 2: Swap ffmpeg-free with full ffmpeg
swap_ffmpeg() {
    log_info "Step 2/4: Replacing ffmpeg-free with full FFmpeg..."
    log_info "Full FFmpeg provides support for additional codecs and formats"
    
    # The --allowerasing flag allows DNF to remove conflicting packages
    if sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing; then
        log_success "Successfully switched to full FFmpeg"
        
        # Verify FFmpeg installation
        if command -v ffmpeg &> /dev/null; then
            local ffmpeg_version
            ffmpeg_version=$(ffmpeg -version | head -n1)
            log_info "Installed: ${ffmpeg_version}"
        fi
    else
        log_error "Failed to swap ffmpeg-free with full FFmpeg"
        return 1
    fi
}

# Step 3: Upgrade multimedia packages and install GStreamer components
upgrade_multimedia() {
    log_info "Step 3/4: Upgrading @multimedia group and installing GStreamer..."
    log_info "GStreamer components are required for GNOME Videos and similar applications"
    
    # --setopt="install_weak_deps=False" prevents installation of weak dependencies
    # --exclude=PackageKit-gstreamer-plugin excludes a specific problematic package
    if sudo dnf upgrade -y @multimedia \
        --setopt="install_weak_deps=False" \
        --exclude=PackageKit-gstreamer-plugin; then
        log_success "Multimedia packages upgraded successfully"
    else
        log_error "Failed to upgrade multimedia packages"
        return 1
    fi
}

# Step 4: Install sound and video complementary packages
install_sound_video() {
    log_info "Step 4/4: Installing sound-and-video group packages..."
    log_info "This includes additional utilities for audio and video playback"
    
    if sudo dnf group install -y sound-and-video; then
        log_success "Sound and video packages installed successfully"
    else
        log_error "Failed to install sound-and-video packages"
        return 1
    fi
}

################################################################################
# Summary and Verification
################################################################################

# Display installation summary
display_summary() {
    echo ""
    echo "================================================================================"
    log_success "Fedora Multimedia Installation Complete!"
    echo "================================================================================"
    echo ""
    log_info "Installed Components:"
    echo "  ✓ Multimedia group packages (codecs and libraries)"
    echo "  ✓ Full FFmpeg (complete format support)"
    echo "  ✓ GStreamer components (GNOME application support)"
    echo "  ✓ Sound and video utilities"
    echo ""
    log_info "Verification Commands:"
    echo "  - Check FFmpeg version:     ffmpeg -version"
    echo "  - List multimedia packages: dnf group info multimedia"
    echo "  - List sound/video packages: dnf group info sound-and-video"
    echo ""
    log_info "Next Steps:"
    echo "  1. Test multimedia playback with your preferred applications"
    echo "  2. Install additional codecs if needed for specific formats"
    echo "  3. Consider installing VLC or MPV for comprehensive media playback"
    echo ""
    echo "================================================================================"
}

################################################################################
# Main Execution
################################################################################

main() {
    # Print header
    echo "================================================================================"
    echo "          Fedora Multimedia Installation Script"
    echo "================================================================================"
    echo ""
    
    # Pre-flight checks
    log_info "Performing pre-flight checks..."
    check_root
    check_fedora
    check_internet
    echo ""
    
    # Confirm before proceeding
    log_warning "This script will install and configure multimedia packages on your system"
    log_warning "This may take several minutes depending on your internet speed"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    echo ""
    
    # Execute installation steps
    install_multimedia_group
    echo ""
    
    swap_ffmpeg
    echo ""
    
    upgrade_multimedia
    echo ""
    
    install_sound_video
    echo ""
    
    # Display summary
    display_summary
    
    log_success "Script completed successfully!"
}

# Run main function
main "$@"
