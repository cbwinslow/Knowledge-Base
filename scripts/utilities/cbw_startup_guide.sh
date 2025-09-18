#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗   ██╗    ███████╗████████╗ █████╗ ██████╗ ████████╗
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
# ███████╗██║   ██║███████╗   ██║   ██████╔╝ ╚████╔╝     ███████╗   ██║   ███████║██████╔╝   ██║   
# ╚════██║██║   ██║╚════██║   ██║   ██╔══██╗  ╚██╔╝      ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   
# ███████║╚██████╔╝███████║   ██║   ██║  ██║   ██║       ███████║   ██║   ██║  ██║██║  ██║   ██║   
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝       ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
#===============================================================================
# File: cbw_startup_guide.sh
# Description: Startup guide for CBW Ubuntu server
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

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Ubuntu Server - Ready for Deployment${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_final_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}System Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if all preparations are complete
    local all_ready=true
    
    # Check fstab
    local total_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | wc -l)
    local unique_lines=$(grep -v "^#" /etc/fstab | grep -v "^$" | sort | uniq | wc -l)
    
    if [[ $total_lines -eq $unique_lines ]]; then
        info "fstab: ${GREEN}NO DUPLICATE ENTRIES${NC} ($total_lines unique entries)"
    else
        error "fstab: ${RED}DUPLICATE ENTRIES FOUND${NC} ($total_lines total, $unique_lines unique)"
        all_ready=false
    fi
    
    # Check port database
    if [[ -f "/home/cbwinslow/.cbw_port_database.json" ]]; then
        info "Port Database: ${GREEN}INITIALIZED${NC}"
    else
        error "Port Database: ${RED}NOT INITIALIZED${NC}"
        all_ready=false
    fi
    
    # Check required scripts
    local scripts=(
        "/home/cbwinslow/cbw_sudo_setup.sh"
        "/home/cbwinslow/cbw_user_deployment.sh"
        "/home/cbwinslow/cbw_simple_port_db.sh"
        "/home/cbwinslow/cbw_maintenance.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]] && [[ -x "$script" ]]; then
            info "Script: ${GREEN}$script${NC} (executable)"
        else
            error "Script: ${RED}$script${NC} (missing or not executable)"
            all_ready=false
        fi
    done
    
    # Check docker-compose files
    local compose_files=(
        "/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose/monitoring.yml"
        "/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose/databases.yml"
    )
    
    for compose_file in "${compose_files[@]}"; do
        if [[ -f "$compose_file" ]]; then
            info "Compose File: ${GREEN}$compose_file${NC} (exists)"
        else
            error "Compose File: ${RED}$compose_file${NC} (missing)"
            all_ready=false
        fi
    done
    
    echo
    if [[ "$all_ready" == true ]]; then
        success "All preparations are complete! Your system is ready for deployment."
    else
        warn "Some preparations are incomplete. Please review the status above."
    fi
    
    return 0
}

show_next_steps() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Next Steps${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}🚀 Ready to Deploy${NC}"
    echo "Your CBW Ubuntu server infrastructure is ready for deployment!"
    echo
    echo -e "${BLUE}Deployment Options:${NC}"
    echo "  1. ${GREEN}System-Level Setup${NC} (if not already done):"
    echo "     sudo /home/cbwinslow/cbw_sudo_setup.sh --all"
    echo
    echo "  2. ${GREEN}User-Level Deployment${NC} (recommended):"
    echo "     /home/cbwinslow/cbw_user_deployment.sh --all"
    echo
    echo "  3. ${GREEN}Monitor Installation${NC}:"
    echo "     tail -f /tmp/CBW-install.log"
    echo
    echo "  4. ${GREEN}Verify Services${NC}:"
    echo "     docker ps"
    echo
    echo "  5. ${GREEN}Access Services${NC}:"
    echo "     • Grafana: http://localhost:3001 (admin / admin)"
    echo "     • Prometheus: http://localhost:9091"
    echo "     • cAdvisor: http://localhost:8081"
    echo "     • PostgreSQL: localhost:5433"
    echo "     • And many more services on their respective ports"
    echo
    echo -e "${BLUE}Maintenance:${NC}"
    echo "  • ${GREEN}Run Maintenance${NC}: /home/cbwinslow/cbw_maintenance.sh --all"
    echo "  • ${GREEN}Backup Volumes${NC}: /home/cbwinslow/cbw_maintenance.sh --backup"
    echo "  • ${GREEN}Prune Docker${NC}: /home/cbwinslow/cbw_maintenance.sh --prune"
    echo
    echo -e "${BLUE}Documentation:${NC}"
    echo "  • ${GREEN}System Setup Guide${NC}: cat /home/cbwinslow/SYSTEM_TOOLS_SUITE.md"
    echo "  • ${GREEN}Deployment Guide${NC}: cat /home/cbwinslow/CBW_COMPLETE_DEPLOYMENT_GUIDE.md"
    echo "  • ${GREEN}Port Database${NC}: cat /home/cbwinslow/CBW_DATABASE_PORT_MAPPING.md"
    echo "  • ${GREEN}Final Status${NC}: cat /home/cbwinslow/FINAL_VERIFICATION_COMPLETE.md"
}

success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --status            Show system status (default)"
    echo "  --next-steps        Show next steps"
    echo "  --deploy            Guide through deployment"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --status"
    echo "  $0 --next-steps"
    echo "  $0 --deploy"
}

main() {
    print_header
    
    # Parse arguments
    local show_status=true
    local show_next_steps=false
    local guide_deployment=false
    
    if [[ $# -gt 0 ]]; then
        show_status=false
        while [[ $# -gt 0 ]]; do
            case $1 in
                --status)
                    show_status=true
                    shift
                    ;;
                --next-steps)
                    show_next_steps=true
                    shift
                    ;;
                --deploy)
                    guide_deployment=true
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
    if [[ "$show_status" == true ]]; then
        show_final_status
        echo
    fi
    
    if [[ "$show_next_steps" == true ]] || [[ "$guide_deployment" == true ]]; then
        show_next_steps
        echo
    fi
    
    if [[ "$guide_deployment" == true ]]; then
        echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
        echo -e "${BLUE}Deployment Guide${NC}"
        echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
        
        echo -e "${GREEN}Step 1: System-Level Setup${NC} (skip if already done)"
        echo "sudo /home/cbwinslow/cbw_sudo_setup.sh --all"
        echo
        echo -e "${GREEN}Step 2: User-Level Deployment${NC}"
        echo "/home/cbwinslow/cbw_user_deployment.sh --all"
        echo
        echo -e "${GREEN}Step 3: Monitor Installation${NC}"
        echo "tail -f /tmp/CBW-install.log"
        echo
        echo -e "${GREEN}Step 4: Verify Services${NC}"
        echo "docker ps"
        echo
        echo -e "${GREEN}Step 5: Access Services${NC}"
        echo "• Grafana: http://localhost:3001 (admin / admin)"
        echo "• Prometheus: http://localhost:9091"
        echo "• cAdvisor: http://localhost:8081"
        echo "• PostgreSQL: localhost:5433"
    fi
    
    info "CBW Ubuntu Server Startup Guide Complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi