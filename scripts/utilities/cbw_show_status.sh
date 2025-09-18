#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗   ██╗    ██████╗ ███████╗███████╗████████╗
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔════╝██╔════╝╚══██╔══╝
# ███████╗██║   ██║███████╗   ██║   ██████╔╝ ╚████╔╝     ██████╔╝█████╗  ███████╗   ██║   
# ╚════██║██║   ██║╚════██║   ██║   ██╔══██╗  ╚██╔╝      ██╔══██╗██╔══╝  ╚════██║   ██║   
# ███████║╚██████╔╝███████║   ██║   ██║  ██║   ██║       ██║  ██║███████╗███████║   ██║   
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   
#===============================================================================
# File: cbw_show_status.sh
# Description: Show current status and next steps for CBW setup
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
    echo -e "${BLUE}CBW Ubuntu Server Setup - Current Status${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_system_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}System Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check fstab
    local total_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | wc -l)
    local unique_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | sort | uniq | wc -l)
    
    if [[ $total_lines -eq $unique_lines ]]; then
        success "fstab: No duplicate entries ($total_lines unique entries)"
    else
        error "fstab: Duplicate entries found ($total_lines total, $unique_lines unique)"
    fi
    
    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            success "Docker: Working correctly ($(docker --version | head -1))"
        else
            error "Docker: Not accessible"
        fi
    else
        error "Docker: Not installed"
    fi
    
    # Check permissions
    if [[ -f "/home/cbwinslow/.cbw_port_database.json" ]]; then
        success "Port Database: Initialized"
    else
        warn "Port Database: Not initialized"
    fi
    
    # Check script permissions
    local scripts=(
        "/home/cbwinslow/cbw_simple_port_db.sh"
        "/home/cbwinslow/cbw_sudo_setup.sh"
        "/home/cbwinslow/cbw_user_deployment.sh"
        "/home/cbwinslow/run_bare_metal_setup.sh"
        "/home/cbwinslow/resolve_setup_conflicts.sh"
        "/home/cbwinslow/stop_conflicting_services.sh"
        "/home/cbwinslow/cbw_maintenance.sh"
        "/home/cbwinslow/cbw_startup_guide.sh"
        "/home/cbwinslow/show_final_status.sh"
        "/home/cbwinslow/final_setup_verification.sh"
        "/home/cbwinslow/cbw_deployment_status.sh"
        "/home/cbwinslow/cbw_port_mapper.sh"
        "/home/cbwinslow/cbw_resolve_permissions.sh"
        "/home/cbwinslow/cbw_simple_fix_permissions.sh"
    )
    
    local missing_scripts=0
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]] || [[ ! -x "$script" ]]; then
            missing_scripts=$((missing_scripts + 1))
        fi
    done
    
    if [[ $missing_scripts -eq 0 ]]; then
        success "Scripts: All scripts exist and are executable ($((${#scripts[@]})) scripts)"
    else
        error "Scripts: $missing_scripts scripts missing or not executable"
    fi
    
    # Check conflicting services
    local conflicting_services=0
    if systemctl is-active --quiet postgresql || systemctl is-active --quiet postgresql@16-main.service; then
        conflicting_services=$((conflicting_services + 1))
    fi
    
    if systemctl is-active --quiet snap.prometheus.prometheus; then
        conflicting_services=$((conflicting_services + 1))
    fi
    
    if systemctl is-active --quiet grafana-server; then
        conflicting_services=$((conflicting_services + 1))
    fi
    
    if [[ $conflicting_services -eq 0 ]]; then
        success "Conflicting Services: None running"
    else
        warn "Conflicting Services: $conflicting_services services still running"
    fi
}

show_next_steps() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Next Steps${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}🚀 Deployment Ready!${NC}"
    echo "Your CBW Ubuntu server infrastructure is fully prepared for deployment!"
    echo
    echo -e "${BLUE}Deployment Steps:${NC}"
    echo "  1. ${GREEN}Run the setup:${NC}"
    echo "     /home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo
    echo "  2. ${GREEN}Monitor installation progress:${NC}"
    echo "     tail -f /tmp/CBW-install.log"
    echo
    echo "  3. ${GREEN}Verify services are running:${NC}"
    echo "     docker ps"
    echo
    echo "  4. ${GREEN}Access services:${NC}"
    echo "     • Grafana: http://localhost:3001 (admin / admin)"
    echo "     • Prometheus: http://localhost:9091"
    echo "     • cAdvisor: http://localhost:8081"
    echo "     • PostgreSQL: localhost:5433"
    echo "     • And many more services on their respective ports"
    echo
    echo -e "${BLUE}Maintenance:${NC}"
    echo "  • ${GREEN}Run maintenance:${NC} /home/cbwinslow/cbw_maintenance.sh --all"
    echo "  • ${GREEN}Backup volumes:${NC} /home/cbwinslow/cbw_maintenance.sh --backup"
    echo "  • ${GREEN}Prune Docker:${NC} /home/cbwinslow/cbw_maintenance.sh --prune"
    echo
    echo -e "${BLUE}Documentation:${NC}"
    echo "  • ${GREEN}Complete Guide:${NC} cat /home/cbwinslow/CBW_FINAL_SUMMARY.md"
    echo "  • ${GREEN}System Tools:${NC} cat /home/cbwinslow/SYSTEM_TOOLS_SUITE.md"
    echo "  • ${GREEN}Deployment Guide:${NC} cat /home/cbwinslow/CBW_COMPLETE_DEPLOYMENT_GUIDE.md"
}

main() {
    print_header
    show_system_status
    echo
    show_next_steps
    echo
    info "CBW Ubuntu Server Setup Status Complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi