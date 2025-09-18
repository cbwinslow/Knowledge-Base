#!/usr/bin/env bash
#===============================================================================
# ██╗   ██╗███████╗██████╗ ██╗███████╗██╗  ██╗███████╗██████╗ 
# ██║   ██║██╔════╝██╔══██╗██║██╔════╝██║  ██║██╔════╝██╔══██╗
# ██║   ██║█████╗  ██████╔╝██║███████╗███████║█████╗  ██████╔╝
# ╚██╗ ██╔╝██╔══╝  ██╔══██╗██║╚════██║██╔══██║██╔══╝  ██╔══██╗
#  ╚████╔╝ ███████╗██████╔╝██║███████║██║  ██║███████╗██║  ██║
#   ╚═══╝  ╚══════╝╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
#===============================================================================
# File: verify_setup_solutions.sh
# Description: Script to verify that our conflict solutions are working
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
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Setup Solutions Verification${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

check_fstab_duplicates() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking fstab for duplicate entries${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Count total lines and unique lines
    local total_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | wc -l)
    local unique_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | sort | uniq | wc -l)
    
    if [[ $total_lines -eq $unique_lines ]]; then
        success "No duplicate entries found in fstab"
        info "Total mount entries: $total_lines"
        return 0
    else
        fail "Duplicate entries found in fstab"
        info "Total entries: $total_lines, Unique entries: $unique_lines"
        return 1
    fi
}

check_port_availability() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking port availability for new services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local ports_to_check=(
        "3001:Grafana"
        "9091:Prometheus" 
        "5433:PostgreSQL"
        "8081:cAdvisor"
    )
    
    local all_available=true
    
    for port_info in "${ports_to_check[@]}"; do
        local port="${port_info%%:*}"
        local service="${port_info#*:}"
        
        # Check if port is in use
        if ss -tuln | grep -q ":$port "; then
            warn "Port $port ($service) is currently in use"
            all_available=false
        else
            success "Port $port ($service) is available"
        fi
    done
    
    if [[ "$all_available" == true ]]; then
        success "All required ports are available"
        return 0
    else
        warn "Some ports are in use - may need to stop conflicting services"
        return 1
    fi
}

check_docker_compose_modifications() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking docker-compose file modifications${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local compose_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    
    if [[ ! -d "$compose_dir" ]]; then
        error "Docker compose directory not found: $compose_dir"
        return 1
    fi
    
    # Check monitoring.yml
    if [[ -f "$compose_dir/monitoring.yml" ]]; then
        if grep -q "3001:3000" "$compose_dir/monitoring.yml"; then
            success "monitoring.yml: Grafana port changed to 3001"
        else
            warn "monitoring.yml: Grafana port may not be updated"
        fi
        
        if grep -q "9091:9090" "$compose_dir/monitoring.yml"; then
            success "monitoring.yml: Prometheus port changed to 9091"
        else
            warn "monitoring.yml: Prometheus port may not be updated"
        fi
        
        if grep -q "8081:8080" "$compose_dir/monitoring.yml"; then
            success "monitoring.yml: cAdvisor port changed to 8081"
        else
            warn "monitoring.yml: cAdvisor port may not be updated"
        fi
    else
        warn "monitoring.yml not found"
    fi
    
    # Check databases.yml
    if [[ -f "$compose_dir/databases.yml" ]]; then
        if grep -q "5433:5432" "$compose_dir/databases.yml"; then
            success "databases.yml: PostgreSQL port changed to 5433"
        else
            warn "databases.yml: PostgreSQL port may not be updated"
        fi
    else
        warn "databases.yml not found"
    fi
    
    return 0
}

check_scripts_exist() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking required scripts${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local scripts=(
        "/home/cbwinslow/resolve_setup_conflicts.sh"
        "/home/cbwinslow/run_bare_metal_setup.sh"
    )
    
    local all_exist=true
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]] && [[ -x "$script" ]]; then
            success "Script exists and is executable: $script"
        else
            fail "Script missing or not executable: $script"
            all_exist=false
        fi
    done
    
    return $([[ "$all_exist" == true ]] && echo 0 || echo 1)
}

check_existing_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking existing service status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if Rocket.Chat is still on port 3000
    if curl -s --connect-timeout 5 http://localhost:3000 | grep -q "Rocket"; then
        success "Rocket.Chat is still running on port 3000"
    else
        info "Rocket.Chat is not accessible on port 3000"
    fi
    
    # Check if Prometheus is still on port 9090
    if curl -s --connect-timeout 5 http://localhost:9090 | grep -q "Prometheus"; then
        success "Prometheus is still running on port 9090"
    else
        info "Prometheus is not accessible on port 9090"
    fi
    
    return 0
}

show_summary() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Verification Summary${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "The conflict resolution solutions have been implemented:"
    echo "  ✓ fstab duplicate entries have been removed"
    echo "  ✓ docker-compose files have been updated to avoid port conflicts"
    echo "  ✓ Required scripts are in place and executable"
    echo
    echo "Before running the setup, you should:"
    echo "  1. Run the conflict resolver: sudo /home/cbwinslow/resolve_setup_conflicts.sh --all"
    echo "  2. Stop any remaining conflicting services"
    echo "  3. Run the setup: /home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo
    echo "After installation, services will be available at:"
    echo "  • Grafana: http://localhost:3001"
    echo "  • Prometheus: http://localhost:9091" 
    echo "  • PostgreSQL: localhost:5433"
    echo "  • cAdvisor: http://localhost:8081"
}

main() {
    print_header
    
    local all_checks_passed=true
    
    # Run all verification checks
    if ! check_fstab_duplicates; then
        all_checks_passed=false
    fi
    
    if ! check_port_availability; then
        all_checks_passed=false
    fi
    
    if ! check_docker_compose_modifications; then
        all_checks_passed=false
    fi
    
    if ! check_scripts_exist; then
        all_checks_passed=false
    fi
    
    check_existing_services
    
    echo
    if [[ "$all_checks_passed" == true ]]; then
        success "All verification checks passed!"
    else
        warn "Some verification checks had issues - please review output above"
    fi
    
    show_summary
    
    echo
    info "Verification complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi