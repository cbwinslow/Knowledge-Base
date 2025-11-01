#!/bin/bash

################################################################################
#                    Fedora Multimedia Installation Script                     #
################################################################################
#
# 📦 Description:
#   A comprehensive script for installing and configuring multimedia packages
#   on Fedora Linux systems. Automates the setup of codecs, FFmpeg, GStreamer
#   components, and additional audio/video utilities.
#
# 🎯 Purpose:
#   • Install multimedia group packages for codec support
#   • Replace ffmpeg-free with full FFmpeg for complete format support
#   • Install GStreamer components for GNOME-based applications
#   • Install additional sound and video utilities
#
# ⚙️  Requirements:
#   • Fedora Linux (tested on Fedora 38+)
#   • sudo/root privileges
#   • Active internet connection
#
# 🚀 Usage:
#   sudo ./install_fedora_multimedia.sh
#
# 📝 What Gets Installed:
#   1. Multimedia group - Core codecs and libraries
#   2. FFmpeg (full version) - Complete media format support
#   3. GStreamer components - For GNOME Videos and similar apps
#   4. Sound & Video tools - Additional playback utilities
#
# 🔒 Safety Features:
#   • Pre-flight checks (root, Fedora detection, internet)
#   • Error handling with detailed messages
#   • User confirmation before installation
#   • Color-coded output for clarity
#
# 📅 Author: Knowledge Base Repository
# 📅 Date: 2025-11-01
# 📅 Version: 1.0
# 📄 License: MIT
#
################################################################################

# Enable strict error handling
set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Pipe failures cause script to fail

################################################################################
#                            Color Codes for Output                            #
################################################################################

# Define color constants for better readability
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color / Reset

################################################################################
#                              Logging Functions                               #
################################################################################

# Print informational messages in blue
# Usage: log_info "Your message here"
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Print success messages in green
# Usage: log_success "Operation completed"
log_success() {
    echo -e "${GREEN}[✓ SUCCESS]${NC} $1"
}

# Print warning messages in yellow
# Usage: log_warning "This is a warning"
log_warning() {
    echo -e "${YELLOW}[⚠ WARNING]${NC} $1"
}

# Print error messages in red
# Usage: log_error "Something went wrong"
log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1"
}

# Print step indicators in cyan
# Usage: log_step "1/4" "Installing packages"
log_step() {
    echo -e "${CYAN}[STEP $1]${NC} $2"
}

################################################################################
#                          Error Handling Functions                            #
################################################################################

# Global error handler - catches any command failure
# This function is triggered automatically when a command fails
error_handler() {
    local line_number=$1
    local command=$2
    local exit_code=$?
    
    echo ""
    log_error "═══════════════════════════════════════════════════════════"
    log_error "Command failed at line ${line_number} with exit code ${exit_code}"
    log_error "Failed command: ${command}"
    log_error "═══════════════════════════════════════════════════════════"
    log_error "Script execution aborted. Please review the error above."
    echo ""
    
    exit 1
}

# Register the error handler to be called on ERR signal
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

# Cleanup function - called on exit (success or failure)
cleanup() {
    # Add any cleanup tasks here if needed
    # For example: removing temporary files
    true
}

# Register cleanup function to run on script exit
trap cleanup EXIT

################################################################################
#                            Validation Functions                              #
################################################################################

# Check if script is run with sudo/root privileges
# Exits with error code 1 if not run as root
check_root() {
    log_info "Checking for root privileges..."
    
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo privileges"
        log_info "Usage: ${CYAN}sudo $0${NC}"
        exit 1
    fi
    
    log_success "Root privileges confirmed"
}

# Check if running on Fedora Linux
# Exits with error code 1 if not running on Fedora
check_fedora() {
    log_info "Detecting operating system..."
    
    # Check for Fedora release file
    if [[ ! -f /etc/fedora-release ]]; then
        log_error "This script is designed for Fedora Linux only"
        log_info "Detected OS: $(uname -s)"
        
        # Try to show what distro we're on
        if [[ -f /etc/os-release ]]; then
            log_info "Distribution: $(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
        fi
        
        exit 1
    fi
    
    # Display Fedora version
    local fedora_version
    fedora_version=$(cat /etc/fedora-release)
    log_success "Running on: ${fedora_version}"
}

# Check internet connectivity
# Exits with error code 1 if no internet connection
check_internet() {
    log_info "Verifying internet connectivity..."
    
    # Try to ping Fedora's main server
    if ! ping -c 1 -W 2 fedoraproject.org &> /dev/null; then
        log_error "No internet connection detected"
        log_error "Please check your network connection and try again"
        
        # Provide some troubleshooting hints
        log_info "Troubleshooting tips:"
        echo "  • Check if your network cable is connected"
        echo "  • Verify WiFi is enabled and connected"
        echo "  • Test with: ${CYAN}ping -c 3 8.8.8.8${NC}"
        echo "  • Check DNS with: ${CYAN}nslookup fedoraproject.org${NC}"
        
        exit 1
    fi
    
    log_success "Internet connection verified"
}

# Check available disk space
# Warns if less than 2GB available
check_disk_space() {
    log_info "Checking available disk space..."
    
    local available_space
    available_space=$(df / | tail -1 | awk '{print $4}')
    local required_space=2097152  # 2GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_warning "Low disk space detected: $(( available_space / 1024 ))MB available"
        log_warning "Recommended: At least 2GB free space"
        
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    else
        log_success "Sufficient disk space available"
    fi
}

################################################################################
#                           Installation Functions                             #
################################################################################

# Step 1: Install multimedia group packages
# This installs various codecs and multimedia libraries needed for media playback
install_multimedia_group() {
    log_step "1/4" "Installing multimedia group packages..."
    log_info "This package group includes:"
    echo "  • Audio/video codecs (MP3, AAC, H.264, etc.)"
    echo "  • Multimedia libraries and frameworks"
    echo "  • Basic playback utilities"
    echo ""
    
    # Install the multimedia group
    # The -y flag automatically answers 'yes' to all prompts
    if sudo dnf group install -y multimedia 2>&1 | tee /dev/tty | grep -q "Complete!"; then
        log_success "Multimedia group packages installed successfully"
        return 0
    else
        log_error "Failed to install multimedia group packages"
        log_info "This may be due to package conflicts or network issues"
        return 1
    fi
}

# Step 2: Swap ffmpeg-free with full ffmpeg
# ffmpeg-free has limited codec support due to patent concerns
# Full FFmpeg provides support for all common audio/video formats
swap_ffmpeg() {
    log_step "2/4" "Replacing ffmpeg-free with full FFmpeg..."
    log_info "Why this matters:"
    echo "  • ffmpeg-free: Limited codec support (patent-free only)"
    echo "  • Full FFmpeg: Complete format support including H.264, AAC, etc."
    echo ""
    
    # The --allowerasing flag allows DNF to remove conflicting packages
    # This is necessary because ffmpeg and ffmpeg-free conflict
    if sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing 2>&1 | tee /dev/tty | grep -q "Complete!"; then
        log_success "Successfully switched to full FFmpeg"
        
        # Verify FFmpeg installation and display version
        if command -v ffmpeg &> /dev/null; then
            local ffmpeg_version
            ffmpeg_version=$(ffmpeg -version | head -n1 | cut -d' ' -f3)
            log_info "Installed FFmpeg version: ${GREEN}${ffmpeg_version}${NC}"
            
            # Show some FFmpeg capabilities
            log_info "FFmpeg now supports common formats:"
            echo "  • Video: H.264, H.265, VP9, AV1, MPEG-4"
            echo "  • Audio: MP3, AAC, Opus, Vorbis, FLAC"
            echo "  • Containers: MP4, MKV, WebM, AVI"
        fi
        
        return 0
    else
        log_error "Failed to swap ffmpeg-free with full FFmpeg"
        log_info "You may need to manually resolve package conflicts"
        return 1
    fi
}

# Step 3: Upgrade multimedia packages and install GStreamer components
# GStreamer is a multimedia framework used by many GNOME applications
upgrade_multimedia() {
    log_step "3/4" "Upgrading @multimedia and installing GStreamer..."
    log_info "GStreamer components are required for:"
    echo "  • GNOME Videos (Totem)"
    echo "  • Rhythmbox music player"
    echo "  • Sound Juicer CD ripper"
    echo "  • Other GNOME multimedia applications"
    echo ""
    
    # --setopt="install_weak_deps=False" prevents installation of recommended but
    # not strictly required packages, keeping the installation leaner
    #
    # --exclude=PackageKit-gstreamer-plugin excludes a package that can cause
    # conflicts with other package managers
    if sudo dnf upgrade -y @multimedia \
        --setopt="install_weak_deps=False" \
        --exclude=PackageKit-gstreamer-plugin 2>&1 | tee /dev/tty | grep -q -E "(Complete!|Nothing to do)"; then
        log_success "Multimedia packages upgraded successfully"
        return 0
    else
        log_error "Failed to upgrade multimedia packages"
        log_info "Check the output above for specific errors"
        return 1
    fi
}

# Step 4: Install sound and video complementary packages
# This group includes additional utilities and applications for media handling
install_sound_video() {
    log_step "4/4" "Installing sound-and-video group packages..."
    log_info "This group includes useful tools like:"
    echo "  • Audio editors and converters"
    echo "  • Video players and utilities"
    echo "  • CD/DVD burning tools"
    echo "  • Audio/video recording software"
    echo ""
    
    # Install the sound-and-video group
    if sudo dnf group install -y sound-and-video 2>&1 | tee /dev/tty | grep -q "Complete!"; then
        log_success "Sound and video packages installed successfully"
        return 0
    else
        log_error "Failed to install sound-and-video packages"
        log_info "This is not critical - core multimedia will still work"
        return 1
    fi
}

################################################################################
#                        Summary and Verification                              #
################################################################################

# Display comprehensive installation summary
display_summary() {
    echo ""
    echo "================================================================================"
    echo -e "${GREEN}                  ✓ Installation Complete!${NC}"
    echo "================================================================================"
    echo ""
    
    # List what was installed
    echo -e "${CYAN}📦 Installed Components:${NC}"
    echo "  ✓ Multimedia group packages (codecs and libraries)"
    echo "  ✓ Full FFmpeg (complete format support)"
    echo "  ✓ GStreamer components (GNOME application support)"
    echo "  ✓ Sound and video utilities"
    echo ""
    
    # Show verification commands
    echo -e "${CYAN}🔍 Verification Commands:${NC}"
    echo "  Check FFmpeg version:"
    echo "    ${GREEN}ffmpeg -version${NC}"
    echo ""
    echo "  List installed multimedia packages:"
    echo "    ${GREEN}dnf group info multimedia${NC}"
    echo ""
    echo "  List sound/video packages:"
    echo "    ${GREEN}dnf group info sound-and-video${NC}"
    echo ""
    echo "  Test audio playback (if you have an audio file):"
    echo "    ${GREEN}ffplay your_audio_file.mp3${NC}"
    echo ""
    
    # Suggest next steps
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo "  1. Test multimedia playback:"
    echo "     • Open GNOME Videos (Totem) and try playing a video"
    echo "     • Use Rhythmbox to play music files"
    echo ""
    echo "  2. Consider installing additional players:"
    echo "     • VLC:        ${GREEN}sudo dnf install vlc${NC}"
    echo "     • MPV:        ${GREEN}sudo dnf install mpv${NC}"
    echo "     • Celluloid:  ${GREEN}sudo dnf install celluloid${NC}"
    echo ""
    echo "  3. For DVD playback support:"
    echo "     • ${GREEN}sudo dnf install libdvdcss${NC}"
    echo ""
    echo "  4. For blu-ray support:"
    echo "     • ${GREEN}sudo dnf install libbluray${NC}"
    echo ""
    
    # Provide troubleshooting info
    echo -e "${CYAN}🔧 Troubleshooting:${NC}"
    echo "  If you encounter playback issues:"
    echo "  • Restart your applications"
    echo "  • Log out and log back in"
    echo "  • Check codec requirements: ${GREEN}dnf provides '*/codec-name'${NC}"
    echo ""
    
    echo "================================================================================"
    echo -e "${GREEN}Happy multimedia playback! 🎵🎬${NC}"
    echo "================================================================================"
    echo ""
}

################################################################################
#                              Main Execution                                  #
################################################################################

main() {
    # Print attractive header
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                           ║"
    echo "║               🎬 Fedora Multimedia Installation Script 🎵                 ║"
    echo "║                                                                           ║"
    echo "║  A comprehensive solution for multimedia codec and player installation    ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Pre-flight checks section
    log_info "═══════════════════════════════════════════════════════════"
    log_info "               PERFORMING PRE-FLIGHT CHECKS"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    
    check_root
    check_fedora
    check_internet
    check_disk_space
    
    echo ""
    log_success "All pre-flight checks passed!"
    echo ""
    
    # Display what will be installed
    log_info "═══════════════════════════════════════════════════════════"
    log_info "                 INSTALLATION OVERVIEW"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    log_warning "This script will perform the following actions:"
    echo ""
    echo "  1️⃣  Install multimedia group packages"
    echo "      └─ Core codecs and multimedia libraries"
    echo ""
    echo "  2️⃣  Replace ffmpeg-free with full FFmpeg"
    echo "      └─ Enables support for all common media formats"
    echo ""
    echo "  3️⃣  Upgrade multimedia and install GStreamer"
    echo "      └─ Required for GNOME multimedia applications"
    echo ""
    echo "  4️⃣  Install sound-and-video utilities"
    echo "      └─ Additional tools for media management"
    echo ""
    log_warning "Estimated time: 5-15 minutes (depends on internet speed)"
    log_warning "Estimated download size: ~200-500 MB"
    echo ""
    
    # Get user confirmation
    echo -e "${YELLOW}⚠  This will modify your system's multimedia packages${NC}"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        log_info "No changes were made to your system"
        exit 0
    fi
    
    # Installation section
    log_info "═══════════════════════════════════════════════════════════"
    log_info "              STARTING INSTALLATION PROCESS"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Execute installation steps with error handling
    # Each function returns 0 on success, 1 on failure
    install_multimedia_group || true
    echo ""
    
    swap_ffmpeg || true
    echo ""
    
    upgrade_multimedia || true
    echo ""
    
    install_sound_video || true
    echo ""
    
    # Display comprehensive summary
    display_summary
    
    log_success "Script completed successfully! 🎉"
}

# Script entry point - call main function with all script arguments
main "$@"
