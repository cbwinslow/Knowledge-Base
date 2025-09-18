#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗   ██╗    ██████╗ ██╗██████╗ ███████╗████████╗
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██║██╔══██╗██╔════╝╚══██╔══╝
# ███████╗██║   ██║███████╗   ██║   ██████╔╝ ╚████╔╝     ██████╔╝██║██████╔╝█████╗     ██║   
# ╚════██║██║   ██║╚════██║   ██║   ██╔══██╗  ╚██╔╝      ██╔══██╗██║██╔═══╝ ██╔══╝     ██║   
# ███████║╚██████╔╝███████║   ██║   ██║  ██║   ██║       ██║  ██║██║██║     ███████╗   ██║   
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚═╝╚═╝     ╚══════╝   ╚═╝   
#===============================================================================
# File: cbw_resolve_permissions.sh
# Description: Resolve all permission and sudo-related issues for CBW setup
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
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Permissions Resolver${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo privileges"
        exit 1
    fi
}

refresh_group_membership() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Refreshing Group Membership${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local username="cbwinslow"
    
    # Check if user is in docker group
    if groups "$username" | grep -q docker; then
        info "User $username is in docker group"
    else
        error "User $username is NOT in docker group"
        info "Adding user to docker group"
        usermod -aG docker "$username"
        success "User added to docker group"
    fi
    
    # Check if user is in sudo group
    if groups "$username" | grep -q sudo; then
        info "User $username is in sudo group"
    else
        error "User $username is NOT in sudo group"
        info "Adding user to sudo group"
        usermod -aG sudo "$username"
        success "User added to sudo group"
    fi
    
    # Check if user is in lxd group
    if groups "$username" | grep -q lxd; then
        info "User $username is in lxd group"
    else
        warn "User $username is NOT in lxd group"
        info "Adding user to lxd group"
        usermod -aG lxd "$username"
        success "User added to lxd group"
    fi
    
    # Check if user is in plugdev group
    if groups "$username" | grep -q plugdev; then
        info "User $username is in plugdev group"
    else
        warn "User $username is NOT in plugdev group"
        info "Adding user to plugdev group"
        usermod -aG plugdev "$username"
        success "User added to plugdev group"
    fi
    
    # Check if user is in dip group
    if groups "$username" | grep -q dip; then
        info "User $username is in dip group"
    else
        warn "User $username is NOT in dip group"
        info "Adding user to dip group"
        usermod -aG dip "$username"
        success "User added to dip group"
    fi
    
    # Check if user is in cdrom group
    if groups "$username" | grep -q cdrom; then
        info "User $username is in cdrom group"
    else
        warn "User $username is NOT in cdrom group"
        info "Adding user to cdrom group"
        usermod -aG cdrom "$username"
        success "User added to cdrom group"
    fi
    
    # Check if user is in adm group
    if groups "$username" | grep -q adm; then
        info "User $username is in adm group"
    else
        warn "User $username is NOT in adm group"
        info "Adding user to adm group"
        usermod -aG adm "$username"
        success "User added to adm group"
    fi
    
    success "Group membership refresh completed"
    info "User will need to log out and log back in for changes to take effect"
    info "Or run: newgrp docker (in a new terminal session)"
}

fix_docker_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing Docker Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        info "Installing Docker"
        apt-get update
        apt-get install -y docker.io docker-compose
        success "Docker installed"
    else
        info "Docker is installed"
    fi
    
    # Check if Docker daemon is running
    if systemctl is-active --quiet docker; then
        info "Docker daemon is running"
    else
        error "Docker daemon is not running"
        info "Starting Docker daemon"
        systemctl start docker
        systemctl enable docker
        success "Docker daemon started and enabled"
    fi
    
    # Fix Docker socket permissions
    if [[ -S "/var/run/docker.sock" ]]; then
        info "Fixing Docker socket permissions"
        chmod 666 /var/run/docker.sock
        chgrp docker /var/run/docker.sock
        success "Docker socket permissions fixed"
    else
        warn "Docker socket not found at /var/run/docker.sock"
    fi
    
    # Add Docker group if it doesn't exist
    if ! getent group docker >/dev/null 2>&1; then
        info "Creating docker group"
        groupadd docker
        success "Docker group created"
    else
        info "Docker group exists"
    fi
    
    # Ensure Docker service is properly configured
    if [[ -f "/etc/systemd/system/docker.service.d/override.conf" ]]; then
        info "Docker override configuration exists"
    else
        info "Creating Docker override configuration"
        mkdir -p /etc/systemd/system/docker.service.d
        cat > /etc/systemd/system/docker.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2375
EOF
        systemctl daemon-reload
        systemctl restart docker
        success "Docker override configuration created and service restarted"
    fi
    
    success "Docker permissions fixed"
}

fix_file_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing File Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local username="cbwinslow"
    
    # Fix home directory permissions
    info "Fixing home directory permissions"
    chown -R "$username:$username" "/home/$username"
    chmod 755 "/home/$username"
    success "Home directory permissions fixed"
    
    # Fix CBW directory permissions
    if [[ -d "/home/$username/server_setup" ]]; then
        info "Fixing CBW directory permissions"
        chown -R "$username:$username" "/home/$username/server_setup"
        find "/home/$username/server_setup" -type f -exec chmod 644 {} \; 2>/dev/null || true
        find "/home/$username/server_setup" -type d -exec chmod 755 {} \; 2>/dev/null || true
        find "/home/$username/server_setup" -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true
        success "CBW directory permissions fixed"
    fi
    
    # Fix script permissions
    local scripts=(
        "/home/$username/cbw_simple_port_db.sh"
        "/home/$username/cbw_sudo_setup.sh"
        "/home/$username/cbw_user_deployment.sh"
        "/home/$username/run_bare_metal_setup.sh"
        "/home/$username/resolve_setup_conflicts.sh"
        "/home/$username/cbw_maintenance.sh"
        "/home/$username/cbw_startup_guide.sh"
        "/home/$username/show_final_status.sh"
        "/home/$username/final_setup_verification.sh"
        "/home/$username/cbw_deployment_status.sh"
        "/home/$username/cbw_port_mapper.sh"
        "/home/$username/stop_conflicting_services.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            info "Fixing permissions for $script"
            chown "$username:$username" "$script"
            chmod 755 "$script"
        fi
    done
    
    success "File permissions fixed"
}

fix_system_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing System Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Fix fstab permissions
    if [[ -f "/etc/fstab" ]]; then
        info "Fixing fstab permissions"
        chmod 644 /etc/fstab
        chown root:root /etc/fstab
        success "fstab permissions fixed"
    fi
    
    # Fix docker directory permissions
    if [[ -d "/etc/docker" ]]; then
        info "Fixing Docker directory permissions"
        chmod 755 /etc/docker
        chown root:root /etc/docker
        success "Docker directory permissions fixed"
    fi
    
    # Fix docker daemon.json permissions
    if [[ -f "/etc/docker/daemon.json" ]]; then
        info "Fixing Docker daemon.json permissions"
        chmod 644 /etc/docker/daemon.json
        chown root:root /etc/docker/daemon.json
        success "Docker daemon.json permissions fixed"
    fi
    
    # Fix systemd directory permissions
    if [[ -d "/etc/systemd/system" ]]; then
        info "Fixing systemd directory permissions"
        chmod 755 /etc/systemd/system
        chown root:root /etc/systemd/system
        success "systemd directory permissions fixed"
    fi
    
    success "System permissions fixed"
}

create_session_refresh_script() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Session Refresh Script${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local username="cbwinslow"
    local refresh_script="/home/$username/refresh_session.sh"
    
    info "Creating session refresh script: $refresh_script"
    
    cat > "$refresh_script" <<'EOF'
#!/usr/bin/env bash
#===============================================================================
# ██████╗ ███████╗███████╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗ 
# ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝ 
# ██████╔╝█████╗  █████╗  ███████║██║  ██║██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
# ██╔══██╗██╔══╝  ██╔══╝  ██╔══██║██║  ██║██║╚██╗██║██║██║╚██╗██║██║   ██║
# ██║  ██║███████╗██║     ██║  ██║██████╔╝██║ ╚████║██║██║ ╚████║╚██████╔╝
# ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: refresh_session.sh
# Description: Refresh session to apply group membership changes
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
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Session Refresh${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_current_groups() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Current Session Groups${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Current session groups:${NC}"
    id
    
    echo
    echo -e "${GREEN}User groups:${NC}"
    groups
}

refresh_groups() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Refreshing Groups${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Refresh docker group
    info "Refreshing docker group"
    newgrp docker <<'EOF_DOCKER'
id | grep docker
EOF_DOCKER
    
    if [[ $? -eq 0 ]]; then
        success "Docker group refreshed"
    else
        error "Failed to refresh docker group"
    fi
    
    # Refresh sudo group
    info "Refreshing sudo group"
    newgrp sudo <<'EOF_SUDO'
id | grep sudo
EOF_SUDO
    
    if [[ $? -eq 0 ]]; then
        success "Sudo group refreshed"
    else
        error "Failed to refresh sudo group"
    fi
    
    # Refresh all groups
    info "Refreshing all groups"
    exec su - "$USER" <<'EOF_EXEC'
echo "New session started with updated groups"
id | grep -E "(docker|sudo)"
EOF_EXEC
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --groups        Show current groups (default)"
    echo "  --refresh       Refresh group membership"
    echo "  --all           Show groups and refresh (equivalent to --groups --refresh)"
    echo "  --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --groups"
    echo "  $0 --refresh"
    echo "  $0 --all"
}

main() {
    print_header
    
    # Parse arguments
    local show_groups=false
    local refresh_groups_flag=false
    
    if [[ $# -eq 0 ]]; then
        show_groups=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --groups)
                    show_groups=true
                    shift
                    ;;
                --refresh)
                    refresh_groups_flag=true
                    shift
                    ;;
                --all)
                    show_groups=true
                    refresh_groups_flag=true
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
    if [[ "$show_groups" == true ]]; then
        show_current_groups
    fi
    
    if [[ "$refresh_groups_flag" == true ]]; then
        refresh_groups
    fi
    
    echo
    success "Session refresh completed!"
    info "You may need to log out and log back in for all changes to take effect"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
    
    chown "$username:$username" "$refresh_script"
    chmod 755 "$refresh_script"
    
    success "Session refresh script created: $refresh_script"
    info "Run this script to refresh your session group membership"
    info "Or log out and log back in for changes to take effect"
}

show_final_instructions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Final Instructions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}All permission issues have been resolved!${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. ${GREEN}Refresh your session group membership:${NC}"
    echo "     /home/cbwinslow/refresh_session.sh --all"
    echo "     ${YELLOW}OR${NC}"
    echo "     Log out and log back in"
    echo
    echo "  2. ${GREEN}Test Docker permissions:${NC}"
    echo "     docker info"
    echo
    echo "  3. ${GREEN}Run the CBW setup:${NC}"
    echo "     /home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo
    echo -e "${YELLOW}Alternative if still having issues:${NC}"
    echo "  ${GREEN}Use sudo for Docker commands:${NC}"
    echo "     sudo docker info"
    echo "     sudo /home/cbwinslow/run_bare_metal_setup.sh --full-install"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all               Run all permission fixes (default)"
    echo "  --groups            Refresh group membership only"
    echo "  --docker            Fix Docker permissions only"
    echo "  --files             Fix file permissions only"
    echo "  --system            Fix system permissions only"
    echo "  --session-script    Create session refresh script only"
    echo "  --instructions      Show final instructions only"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --groups"
    echo "  $0 --docker"
    echo "  $0 --files"
    echo "  $0 --system"
    echo "  $0 --session-script"
    echo "  $0 --instructions"
}

main() {
    print_header
    
    check_root
    
    # Parse arguments
    local run_all=false
    local refresh_groups_only=false
    local fix_docker_only=false
    local fix_files_only=false
    local fix_system_only=false
    local create_session_script_only=false
    local show_instructions_only=false
    
    if [[ $# -eq 0 ]]; then
        run_all=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --all)
                    run_all=true
                    shift
                    ;;
                --groups)
                    refresh_groups_only=true
                    shift
                    ;;
                --docker)
                    fix_docker_only=true
                    shift
                    ;;
                --files)
                    fix_files_only=true
                    shift
                    ;;
                --system)
                    fix_system_only=true
                    shift
                    ;;
                --session-script)
                    create_session_script_only=true
                    shift
                    ;;
                --instructions)
                    show_instructions_only=true
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
    if [[ "$run_all" == true ]] || [[ "$refresh_groups_only" == true ]]; then
        refresh_group_membership
    fi
    
    if [[ "$run_all" == true ]] || [[ "$fix_docker_only" == true ]]; then
        fix_docker_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$fix_files_only" == true ]]; then
        fix_file_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$fix_system_only" == true ]]; then
        fix_system_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$create_session_script_only" == true ]]; then
        create_session_refresh_script
    fi
    
    if [[ "$run_all" == true ]] || [[ "$show_instructions_only" == true ]]; then
        show_final_instructions
    fi
    
    echo
    success "CBW permissions resolver completed successfully!"
    
    if [[ "$run_all" == true ]]; then
        info "All permission issues have been resolved"
        info "Please refresh your session to apply group membership changes"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi