#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗
# ██║     ██║   ██║███████╗   ██║   █████╗  ██╔████╔██║██║  ██║
# ██║     ██║   ██║╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║██║  ██║
# ███████╗╚██████╔╝███████║   ██║   ███████╗██║ ╚═╝ ██║██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═════╝ 
#===============================================================================
# File: final_setup_verification.sh
# Description: Final verification before running CBW Ubuntu setup
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
    echo -e "${BLUE}Final Setup Verification${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

check_fstab() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking fstab${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local total_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | wc -l)
    local unique_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | sort | uniq | wc -l)
    
    if [[ $total_lines -eq $unique_lines ]]; then
        success "fstab has no duplicate entries ($total_lines entries)"
        return 0
    else
        fail "fstab has duplicate entries ($total_lines total, $unique_lines unique)"
        return 1
    fi
}

check_docker_compose_ports() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking docker-compose port modifications${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local compose_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    local all_correct=true
    
    # Check monitoring.yml
    if [[ -f "$compose_dir/monitoring.yml" ]]; then
        if grep -q "3001:3000" "$compose_dir/monitoring.yml"; then
            success "monitoring.yml: Grafana port changed to 3001"
        else
            fail "monitoring.yml: Grafana port not updated"
            all_correct=false
        fi
        
        if grep -q "9091:9090" "$compose_dir/monitoring.yml"; then
            success "monitoring.yml: Prometheus port changed to 9091"
        else
            fail "monitoring.yml: Prometheus port not updated"
            all_correct=false
        fi
        
        if grep -q "8081:8080" "$compose_dir/monitoring.yml"; then
            success "monitoring.yml: cAdvisor port changed to 8081"
        else
            fail "monitoring.yml: cAdvisor port not updated"
            all_correct=false
        fi
    else
        warn "monitoring.yml not found"
        all_correct=false
    fi
    
    # Check databases.yml
    if [[ -f "$compose_dir/databases.yml" ]]; then
        if grep -q "5433:5432" "$compose_dir/databases.yml"; then
            success "databases.yml: PostgreSQL port changed to 5433"
        else
            fail "databases.yml: PostgreSQL port not updated"
            all_correct=false
        fi
    else
        warn "databases.yml not found"
        all_correct=false
    fi
    
    return $([[ "$all_correct" == true ]] && echo 0 || echo 1)
}

check_conflicting_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking conflicting services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local services_running=false
    
    # Check if PostgreSQL is running
    if systemctl is-active --quiet postgresql || systemctl is-active --quiet postgresql@16-main.service; then
        warn "PostgreSQL is still running - should be stopped before setup"
        services_running=true
    else
        success "PostgreSQL is not running"
    fi
    
    # Check if Prometheus is running
    if systemctl is-active --quiet snap.prometheus.prometheus; then
        warn "Prometheus is still running - should be stopped before setup"
        services_running=true
    else
        success "Prometheus is not running"
    fi
    
    # Check if Grafana is running
    if systemctl is-active --quiet grafana-server; then
        warn "Grafana is still running - should be stopped before setup"
        services_running=true
    else
        success "Grafana is not running"
    fi
    
    if [[ "$services_running" == true ]]; then
        info "Run '/home/cbwinslow/stop_conflicting_services.sh' to stop these services"
        return 1
    else
        success "No conflicting services are running"
        return 0
    fi
}

check_required_scripts() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking required scripts${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local scripts=(
        "/home/cbwinslow/run_bare_metal_setup.sh"
        "/home/cbwinslow/resolve_setup_conflicts.sh"
        "/home/cbwinslow/stop_conflicting_services.sh"
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

show_final_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Final Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "System is ready for CBW Ubuntu bare metal setup!"
    echo
    echo "What has been completed:"
    echo "  ✓ fstab duplicate entries removed"
    echo "  ✓ docker-compose files updated with alternative ports"
    echo "  ✓ Required scripts are in place"
    echo
    echo "Next steps:"
    echo "  1. Stop any remaining conflicting services (if needed)"
    echo "     /home/cbwinslow/stop_conflicting_services.sh"
    echo "  2. Run the bare metal setup"
    echo "     /home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo "  3. Monitor installation progress"
    echo "     tail -f /tmp/CBW-install.log"
    echo
    echo "Services will be available at:"
    echo "  • Grafana: http://localhost:3001"
    echo "  • Prometheus: http://localhost:9091"
    echo "  • PostgreSQL: localhost:5433"
    echo "  • cAdvisor: http://localhost:8081"
}

main() {
    print_header
    
    local all_checks_passed=true
    
    # Run all verification checks
    if ! check_fstab; then
        all_checks_passed=false
    fi
    
    if ! check_docker_compose_ports; then
        all_checks_passed=false
    fi
    
    if ! check_conflicting_services; then
        all_checks_passed=false
    fi
    
    if ! check_required_scripts; then
        all_checks_passed=false
    fi
    
    echo
    if [[ "$all_checks_passed" == true ]]; then
        success "All verification checks passed!"
        show_final_status
    else
        warn "Some verification checks had issues - please review output above"
        echo
        info "Fix any issues and run this verification script again"
    fi
    
    echo
    info "Verification complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi