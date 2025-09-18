#!/usr/bin/env bash
#===============================================================================
# ██████╗  ██████╗██████╗ ██╗██████╗ ████████╗███████╗██████╗ 
# ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
# ██████╔╝██║     ██████╔╝██║██████╔╝   ██║   █████╗  ██║  ██║
# ██╔══██╗██║     ██╔══██╗██║██╔═══╝    ██║   ██╔══╝  ██║  ██║
# ██║  ██║╚██████╗██║  ██║██║██║        ██║   ███████╗██████╔╝
# ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝╚═════╝ 
#===============================================================================
# File: resolve_setup_conflicts.sh
# Description: Script to resolve conflicts before running CBW Ubuntu setup
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
    echo -e "${BLUE}CBW Ubuntu Setup Conflict Resolver${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

fix_fstab_duplicates() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Fixing fstab duplicate entries${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Backup current fstab
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp /etc/fstab "/etc/fstab.backup.$timestamp"
    info "Backed up fstab to /etc/fstab.backup.$timestamp"
    
    # Create cleaned fstab without mounting
    grep -v "^#" /etc/fstab | grep -v "^$" | sort | uniq > /tmp/fstab.cleaned
    
    # Count before and after
    local total_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | wc -l)
    local unique_lines=$(wc -l < /tmp/fstab.cleaned)
    
    if [[ $total_lines -ne $unique_lines ]]; then
        info "Removed $((total_lines - unique_lines)) duplicate entries"
        
        # Add back the comments
        grep "^#" /etc/fstab > /tmp/fstab.fixed
        echo "" >> /tmp/fstab.fixed
        cat /tmp/fstab.cleaned >> /tmp/fstab.fixed
        
        # Replace fstab
        cp /tmp/fstab.fixed /etc/fstab
        info "Fixed fstab duplicate entries"
    else
        info "No duplicate entries found in fstab"
    fi
    
    # Clean up
    rm -f /tmp/fstab.cleaned /tmp/fstab.fixed
    
    # Verify syntax using a safer method
    if [[ -f "/etc/fstab" ]]; then
        # Check that each line has 6 fields (device, mountpoint, fstype, options, dump, pass)
        local syntax_errors=0
        while IFS= read -r line; do
            if [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                local field_count=$(echo "$line" | awk '{print NF}')
                if [[ $field_count -ne 6 ]]; then
                    error "Line has $field_count fields, expected 6: $line"
                    syntax_errors=$((syntax_errors + 1))
                fi
            fi
        done < <(grep -v "^#" /etc/fstab | grep -v "^$")
        
        if [[ $syntax_errors -eq 0 ]]; then
            info "fstab syntax is valid"
        else
            error "fstab syntax check failed with $syntax_errors errors"
            return 1
        fi
    else
        error "fstab file not found"
        return 1
    fi
    
    return 0
}

stop_conflicting_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Stopping conflicting services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Services that conflict with Docker containers
    local services_to_stop=(
        "grafana-server"
        "prometheus"
        "snap.prometheus.prometheus"
        "postgresql"
        "postgresql@16-main"
    )
    
    for service in "${services_to_stop[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            info "Stopping $service"
            systemctl stop "$service" || warn "Failed to stop $service"
        else
            info "$service is not running"
        fi
    done
    
    # Check if Rocket.Chat is running on port 3000
    if lsof -i :3000 >/dev/null 2>&1; then
        warn "Rocket.Chat is running on port 3000"
        warn "Either stop Rocket.Chat or modify docker-compose to use a different port"
    fi
}

update_docker_compose_files() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Updating docker-compose files to avoid port conflicts${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local compose_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    
    if [[ ! -d "$compose_dir" ]]; then
        error "Docker compose directory not found: $compose_dir"
        return 1
    fi
    
    # Update monitoring.yml to use different ports
    if [[ -f "$compose_dir/monitoring.yml" ]]; then
        info "Updating monitoring.yml ports"
        
        # Show what we're changing
        info "Before changes:"
        grep -n "3000\|9090" "$compose_dir/monitoring.yml" || true
        
        # Change Grafana from 3000 to 3001
        sed -i 's/- "3000:3000"/- "3001:3000"/' "$compose_dir/monitoring.yml"
        
        # Change Prometheus from 9090 to 9091
        sed -i 's/- "9090:9090"/- "9091:9090"/' "$compose_dir/monitoring.yml"
        
        # Change cAdvisor from 8080 to 8081
        sed -i 's/- "8080:8080"/- "8081:8080"/' "$compose_dir/monitoring.yml"
        
        info "After changes:"
        grep -n "3001\|9091\|8081" "$compose_dir/monitoring.yml" || true
        
        info "Updated monitoring.yml ports"
    fi
    
    # Update databases.yml to use different ports
    if [[ -f "$compose_dir/databases.yml" ]]; then
        info "Updating databases.yml ports"
        
        # Show what we're changing
        info "Before changes:"
        grep -n "5432" "$compose_dir/databases.yml" || true
        
        # Change PostgreSQL from 5432 to 5433
        sed -i 's/- "5432:5432"/- "5433:5432"/' "$compose_dir/databases.yml"
        
        info "After changes:"
        grep -n "5433" "$compose_dir/databases.yml" || true
        
        info "Updated databases.yml ports"
    fi
    
    info "Docker-compose files updated to avoid port conflicts"
}

show_port_summary() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Port Summary After Changes${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Services will now use these ports:"
    echo "  Grafana: 3001 (instead of 3000)"
    echo "  Prometheus: 9091 (instead of 9090)"
    echo "  PostgreSQL: 5433 (instead of 5432)"
    echo "  cAdvisor: 8081 (instead of 8080)"
    echo
    echo "Services still using their original ports:"
    echo "  Rocket.Chat: 3000 (existing service)"
    echo "  Qdrant: 6333, 6334"
    echo "  MongoDB: 27017"
    echo "  OpenSearch: 9200, 9600"
    echo "  RabbitMQ: 5672, 15672"
    echo "  Kong: 8000, 8443, 8001, 8444"
    echo "  Loki: 3100"
    echo "  DCGM Exporter: 9400"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --fix-fstab          Fix duplicate entries in fstab"
    echo "  --stop-services      Stop conflicting services"
    echo "  --update-compose     Update docker-compose files to avoid port conflicts"
    echo "  --all                Run all fixes (default)"
    echo "  --help               Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --fix-fstab"
    echo "  $0 --stop-services --update-compose"
}

main() {
    print_header
    
    check_root
    
    # Default to all actions
    local fix_fstab=false
    local stop_services=false
    local update_compose=false
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        fix_fstab=true
        stop_services=true
        update_compose=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --fix-fstab)
                    fix_fstab=true
                    shift
                    ;;
                --stop-services)
                    stop_services=true
                    shift
                    ;;
                --update-compose)
                    update_compose=true
                    shift
                    ;;
                --all)
                    fix_fstab=true
                    stop_services=true
                    update_compose=true
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
    if [[ "$fix_fstab" == true ]]; then
        fix_fstab_duplicates
    fi
    
    if [[ "$stop_services" == true ]]; then
        stop_conflicting_services
    fi
    
    if [[ "$update_compose" == true ]]; then
        update_docker_compose_files
    fi
    
    show_port_summary
    
    echo
    info "Conflict resolution complete!"
    info "You can now run the CBW Ubuntu setup without port conflicts"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi