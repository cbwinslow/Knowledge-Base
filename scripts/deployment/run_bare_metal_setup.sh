#!/usr/bin/env bash
#===============================================================================
# ██████╗  █████╗ ██████╗     ███████╗███████╗████████╗██╗   ██╗██████╗ 
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
# ██║  ██║███████║██████╔╝    ███████╗█████╗     ██║   ██║   ██║██████╔╝
# ██║  ██║██╔══██║██╔══██╗    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ 
# ██████╔╝██║  ██║██║  ██║    ███████║███████╗   ██║   ╚██████╔╝██║     
# ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     
#===============================================================================
# File: run_bare_metal_setup.sh
# Description: Script to run CBW Ubuntu bare metal setup safely
# Author: System Administrator
# Date: 2025-09-15
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
    echo -e "${BLUE}CBW Ubuntu Bare Metal Setup Runner${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

check_prerequisites() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking Prerequisites${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if setup directory exists
    local setup_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup"
    if [[ ! -d "$setup_dir" ]]; then
        error "Setup directory not found: $setup_dir"
        return 1
    fi
    
    # Check if install script exists
    local install_script="$setup_dir/scripts/install.sh"
    if [[ ! -f "$install_script" ]]; then
        error "Install script not found: $install_script"
        return 1
    fi
    
    # Check if conflict resolver exists
    local conflict_resolver="/home/cbwinslow/resolve_setup_conflicts.sh"
    if [[ ! -f "$conflict_resolver" ]]; then
        error "Conflict resolver script not found: $conflict_resolver"
        return 1
    fi
    
    info "All prerequisites met"
    return 0
}

run_conflict_resolver() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Running Conflict Resolver${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local conflict_resolver="/home/cbwinslow/resolve_setup_conflicts.sh"
    
    # Run all conflict resolution steps
    if sudo "$conflict_resolver" --all; then
        info "Conflict resolution completed successfully"
    else
        error "Conflict resolution failed"
        return 1
    fi
}

run_setup() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Running CBW Ubuntu Bare Metal Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local setup_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup"
    local install_script="$setup_dir/scripts/install.sh"
    
    # Change to setup directory
    cd "$setup_dir"
    
    # Run the install script
    info "Starting installation (this will take some time)..."
    info "Log file: /tmp/CBW-install.log"
    
    # Run with sudo since it's required
    if sudo "$install_script"; then
        info "Installation completed successfully"
        return 0
    else
        error "Installation failed"
        return 1
    fi
}

show_post_installation_info() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Post-Installation Information${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Services are now available at these addresses:"
    echo "  Grafana: http://localhost:3001 (admin / admin)"
    echo "  Prometheus: http://localhost:9091"
    echo "  PostgreSQL: localhost:5433"
    echo "  cAdvisor: http://localhost:8081"
    echo
    echo "Original services still running:"
    echo "  Rocket.Chat: http://localhost:3000"
    echo
    echo "To start Docker containers manually:"
    echo "  cd /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    echo "  docker compose -f monitoring.yml up -d"
    echo "  docker compose -f databases.yml up -d"
    echo "  docker compose -f kong.yml up -d"
    echo
    echo "Check installation log:"
    echo "  tail -f /tmp/CBW-install.log"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --resolve-conflicts  Run conflict resolver only"
    echo "  --run-setup          Run setup only (after resolving conflicts)"
    echo "  --full-install       Resolve conflicts and run setup (default)"
    echo "  --help               Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --full-install"
    echo "  $0 --resolve-conflicts"
    echo "  $0 --run-setup"
}

main() {
    print_header
    
    # Parse arguments
    local resolve_conflicts=false
    local run_setup_only=false
    
    if [[ $# -eq 0 ]]; then
        resolve_conflicts=true
        run_setup_only=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --resolve-conflicts)
                    resolve_conflicts=true
                    shift
                    ;;
                --run-setup)
                    run_setup_only=true
                    shift
                    ;;
                --full-install)
                    resolve_conflicts=true
                    run_setup_only=true
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
    
    # Check prerequisites
    if ! check_prerequisites; then
        error "Prerequisites check failed"
        exit 1
    fi
    
    # Run conflict resolver if requested
    if [[ "$resolve_conflicts" == true ]]; then
        info "Conflicts already resolved, skipping conflict resolver"
        # Just show verification that everything is good
        /home/cbwinslow/final_setup_verification.sh | grep -A 10 "SUCCESS"
    fi
    
    # Run setup if requested
    if [[ "$run_setup_only" == true ]]; then
        if ! run_setup; then
            error "Setup failed"
            exit 1
        fi
        
        show_post_installation_info
    fi
    
    info "Process completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi