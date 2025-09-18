#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗   ██╗    ██████╗ ██╗██████╗ ███████╗████████╗
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██║██╔══██╗██╔════╝╚══██╔══╝
# ███████╗██║   ██║███████╗   ██║   ██████╔╝ ╚████╔╝     ██████╔╝██║██████╔╝█████╗     ██║   
# ╚════██║██║   ██║╚════██║   ██║   ██╔══██╗  ╚██╔╝      ██╔═══╝ ██║██╔═══╝ ██╔══╝     ██║   
# ███████║╚██████╔╝███████║   ██║   ██║  ██║   ██║       ██║     ██║██║     ███████╗   ██║   
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝       ╚═╝     ╚═╝╚═╝     ╚══════╝   ╚═╝   
#===============================================================================
# File: cbw_simple_fix_permissions.sh
# Description: Simple script to fix common permission issues for CBW setup
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
    echo -e "${BLUE}CBW Simple Permission Fixer${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

fix_docker_socket_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing Docker Socket Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if Docker socket exists
    if [[ -S "/var/run/docker.sock" ]]; then
        info "Docker socket found at /var/run/docker.sock"
        
        # Fix permissions
        info "Fixing Docker socket permissions"
        chmod 666 /var/run/docker.sock 2>/dev/null || true
        chgrp docker /var/run/docker.sock 2>/dev/null || true
        
        success "Docker socket permissions fixed"
    else
        warn "Docker socket not found at /var/run/docker.sock"
        info "This might be because Docker is not running or not installed"
    fi
}

fix_script_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing Script Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local username="cbwinslow"
    local home_dir="/home/$username"
    
    # Check if home directory exists
    if [[ ! -d "$home_dir" ]]; then
        error "Home directory not found: $home_dir"
        return 1
    fi
    
    # Fix script permissions
    local scripts=(
        "$home_dir/cbw_simple_port_db.sh"
        "$home_dir/cbw_sudo_setup.sh"
        "$home_dir/cbw_user_deployment.sh"
        "$home_dir/run_bare_metal_setup.sh"
        "$home_dir/resolve_setup_conflicts.sh"
        "$home_dir/stop_conflicting_services.sh"
        "$home_dir/cbw_maintenance.sh"
        "$home_dir/cbw_startup_guide.sh"
        "$home_dir/show_final_status.sh"
        "$home_dir/final_setup_verification.sh"
        "$home_dir/cbw_deployment_status.sh"
        "$home_dir/cbw_port_mapper.sh"
        "$home_dir/cbw_resolve_permissions.sh"
        "$home_dir/cbw_simple_fix_permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            info "Fixing permissions for $script"
            chmod 755 "$script" 2>/dev/null || true
            chown "$username:$username" "$script" 2>/dev/null || true
        fi
    done
    
    success "Script permissions fixed"
}

fix_directory_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing Directory Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local username="cbwinslow"
    local home_dir="/home/$username"
    
    # Check if home directory exists
    if [[ ! -d "$home_dir" ]]; then
        error "Home directory not found: $home_dir"
        return 1
    fi
    
    # Fix home directory permissions
    info "Fixing home directory permissions"
    chmod 755 "$home_dir" 2>/dev/null || true
    chown "$username:$username" "$home_dir" 2>/dev/null || true
    
    # Fix CBW directory permissions
    local cbw_dirs=(
        "$home_dir/server_setup"
        "$home_dir/server_setup/cbw-ubuntu-setup-baremetal"
        "$home_dir/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup"
        "$home_dir/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker"
        "$home_dir/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
        "$home_dir/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/scripts"
        "$home_dir/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/scripts/partials"
    )
    
    for dir in "${cbw_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "Fixing permissions for $dir"
            chmod 755 "$dir" 2>/dev/null || true
            chown "$username:$username" "$dir" 2>/dev/null || true
            
            # Fix file permissions within directory
            find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
            find "$dir" -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true
            find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
        fi
    done
    
    success "Directory permissions fixed"
}

fix_json_permissions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing JSON Configuration Permissions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local username="cbwinslow"
    local home_dir="/home/$username"
    
    # Fix port database permissions
    local json_files=(
        "$home_dir/.cbw_port_database.json"
    )
    
    for json_file in "${json_files[@]}"; do
        if [[ -f "$json_file" ]]; then
            info "Fixing permissions for $json_file"
            chmod 644 "$json_file" 2>/dev/null || true
            chown "$username:$username" "$json_file" 2>/dev/null || true
        fi
    done
    
    success "JSON configuration permissions fixed"
}

show_docker_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Docker Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if Docker is installed
    if command -v docker >/dev/null 2>&1; then
        info "Docker: ${GREEN}INSTALLED${NC} ($(docker --version | head -1))"
    else
        error "Docker: ${RED}NOT INSTALLED${NC}"
        info "Please install Docker:"
        echo "  sudo apt install docker.io"
        return 1
    fi
    
    # Check if Docker daemon is running
    if systemctl is-active --quiet docker; then
        info "Docker Daemon: ${GREEN}RUNNING${NC}"
    else
        error "Docker Daemon: ${RED}NOT RUNNING${NC}"
        info "Please start Docker daemon:"
        echo "  sudo systemctl start docker"
        echo "  sudo systemctl enable docker"
        return 1
    fi
    
    # Check Docker socket permissions
    if [[ -S "/var/run/docker.sock" ]]; then
        local socket_perms=$(stat -c "%a" /var/run/docker.sock)
        if [[ "$socket_perms" == "666" ]]; then
            info "Docker Socket Permissions: ${GREEN}CORRECT${NC} ($socket_perms)"
        else
            warn "Docker Socket Permissions: ${YELLOW}INCORRECT${NC} ($socket_perms)"
            info "Run this script with sudo to fix permissions"
        fi
    else
        error "Docker Socket: ${RED}NOT FOUND${NC}"
        return 1
    fi
    
    # Check user group membership
    local username="cbwinslow"
    if groups "$username" | grep -q docker; then
        info "User Group Membership: ${GREEN}IN DOCKER GROUP${NC}"
    else
        error "User Group Membership: ${RED}NOT IN DOCKER GROUP${NC}"
        info "Add user to docker group:"
        echo "  sudo usermod -aG docker $username"
        info "Then log out and log back in"
        return 1
    fi
    
    # Test Docker access
    if docker info >/dev/null 2>&1; then
        info "Docker Access: ${GREEN}WORKING${NC}"
        success "Docker is properly configured and accessible"
    else
        error "Docker Access: ${RED}NOT WORKING${NC}"
        info "This might be due to session group membership not being refreshed"
        info "Log out and log back in, or run: newgrp docker"
        return 1
    fi
    
    return 0
}

show_next_steps() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Next Steps${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Permissions have been fixed!${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. ${GREEN}Refresh session group membership:${NC}"
    echo "     Log out and log back in"
    echo "     ${YELLOW}OR${NC}"
    echo "     Run: newgrp docker"
    echo
    echo "  2. ${GREEN}Test Docker access:${NC}"
    echo "     docker info"
    echo
    echo "  3. ${GREEN}Run the CBW setup:${NC}"
    echo "     /home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo
    echo "  4. ${GREEN}Monitor installation:${NC}"
    echo "     tail -f /tmp/CBW-install.log"
    echo
    echo -e "${YELLOW}If Docker still doesn't work, run with sudo:${NC}"
    echo "  sudo /home/cbwinslow/run_bare_metal_setup.sh --full-install"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all               Fix all permissions (default)"
    echo "  --docker            Fix Docker socket permissions only"
    echo "  --scripts           Fix script permissions only"
    echo "  --directories       Fix directory permissions only"
    echo "  --json              Fix JSON configuration permissions only"
    echo "  --status            Show Docker status only"
    echo "  --next-steps        Show next steps only"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --docker"
    echo "  $0 --scripts"
    echo "  $0 --directories"
    echo "  $0 --json"
    echo "  $0 --status"
    echo "  $0 --next-steps"
}

main() {
    print_header
    
    # Parse arguments
    local run_all=false
    local fix_docker_only=false
    local fix_scripts_only=false
    local fix_directories_only=false
    local fix_json_only=false
    local show_status_only=false
    local show_next_steps_only=false
    
    if [[ $# -eq 0 ]]; then
        run_all=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --all)
                    run_all=true
                    shift
                    ;;
                --docker)
                    fix_docker_only=true
                    shift
                    ;;
                --scripts)
                    fix_scripts_only=true
                    shift
                    ;;
                --directories)
                    fix_directories_only=true
                    shift
                    ;;
                --json)
                    fix_json_only=true
                    shift
                    ;;
                --status)
                    show_status_only=true
                    shift
                    ;;
                --next-steps)
                    show_next_steps_only=true
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
    if [[ "$run_all" == true ]] || [[ "$fix_docker_only" == true ]]; then
        fix_docker_socket_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$fix_scripts_only" == true ]]; then
        fix_script_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$fix_directories_only" == true ]]; then
        fix_directory_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$fix_json_only" == true ]]; then
        fix_json_permissions
    fi
    
    if [[ "$run_all" == true ]] || [[ "$show_status_only" == true ]]; then
        show_docker_status
    fi
    
    if [[ "$run_all" == true ]] || [[ "$show_next_steps_only" == true ]]; then
        show_next_steps
    fi
    
    if [[ "$run_all" == true ]]; then
        echo
        success "CBW simple permission fixer completed successfully!"
        info "Please refresh your session to apply group membership changes"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi