#!/usr/bin/env bash
#===============================================================================
# ╔╦╗╔═╗╦═╗╔═╗╔╗╔╔═╗╔╦╗╔═╗  ╦  ╦╔═╗╦  ╦  ╔═╗╦═╗
#  ║ ║╣ ╠╦╝║╣ ║║║╠═╣ ║ ║╣   ╚╗╔╝║╣ ║  ║  ║╣ ╠╦╝
#  ╩ ╚═╝╩╚═╚═╝╝╚╝╩ ╩ ╩ ╚═╝   ╚╝ ╚═╝╩═╝╩═╝╚═╝╩╚═
#===============================================================================
# File: cbw_manual_deployment.sh
# Description: Manual deployment of CBW services
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
    echo -e "${BLUE}CBW Manual Deployment${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_system_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}System Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    
    echo
    echo "Docker Status:"
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}  Installed: ${NC}Yes ($(docker --version 2>/dev/null || echo 'Unknown version'))"
        if systemctl is-active --quiet docker 2>/dev/null; then
            echo -e "${GREEN}  Service: ${NC}Running"
        else
            echo -e "${YELLOW}  Service: ${NC}Not running (or permission denied)"
        fi
    else
        echo -e "${RED}  Installed: ${NC}No"
    fi
    
    echo
    echo "Services Status:"
    # Check if services are running on their ports
    for port in 3001 9091 5433 8081; do
        if ss -tuln | grep -q ":$port "; then
            echo -e "${GREEN}  Port $port: ${NC}In use"
        else
            echo -e "${YELLOW}  Port $port: ${NC}Available"
        fi
    done
}

show_deployment_plan() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deployment Plan${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Services to be deployed:"
    echo "  1. Grafana - Port 3001 (instead of 3000)"
    echo "  2. Prometheus - Port 9091 (instead of 9090)"
    echo "  3. PostgreSQL - Port 5433 (instead of 5432)"
    echo "  4. cAdvisor - Port 8081 (instead of 8080)"
    echo "  5. Qdrant - Ports 6333, 6334"
    echo "  6. MongoDB - Port 27017"
    echo "  7. OpenSearch - Ports 9200, 9600"
    echo "  8. RabbitMQ - Ports 5672, 15672"
    
    echo
    echo "Deployment method:"
    echo "  - Docker containers (if Docker permissions allow)"
    echo "  - Manual installation (if Docker is not available)"
    
    echo
    echo "Configuration files have already been prepared:"
    echo "  - Port conflicts resolved"
    echo "  - fstab duplicates removed"
    echo "  - All scripts verified"
}

show_next_steps() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Next Steps${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Since we're unable to deploy automatically due to Docker permissions,"
    echo "here are the manual steps you can take:"
    echo
    echo "1. Fix Docker permissions:"
    echo "   - Log out and log back in to refresh group permissions"
    echo "   - Or run: newgrp docker"
    echo
    echo "2. If Docker works, deploy services:"
    echo "   /home/cbwinslow/deploy_cbw_services.sh --all"
    echo
    echo "3. Alternatively, use the prepared Docker Compose files:"
    echo "   cd /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    echo "   docker-compose -f monitoring.yml up -d"
    echo "   docker-compose -f databases.yml up -d"
    echo
    echo "4. If Docker is not available, install services manually:"
    echo "   - Install packages using apt"
    echo "   - Configure services to use the non-conflicting ports"
    echo "   - Use the configuration files in /home/cbwinslow/server_setup/"
}

show_service_endpoints() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Service Endpoints${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "After deployment, services will be available at:"
    echo "  • Grafana: http://localhost:3001 (admin / admin)"
    echo "  • Prometheus: http://localhost:9091"
    echo "  • PostgreSQL: localhost:5433"
    echo "  • cAdvisor: http://localhost:8081"
    echo "  • Qdrant: 6333, 6334"
    echo "  • MongoDB: 27018 (instead of 27017 due to existing MongoDB instance)"
    echo "  • OpenSearch: 9200, 9600"
    echo "  • RabbitMQ: 5672, 15672"
}

show_master_configs() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Master Configuration Files${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "All configuration files have been prepared to prevent conflicts:"
    echo "  • /home/cbwinslow/server_setup.conf"
    echo "  • /home/cbwinslow/cbw_ansible/cbw_config.yml"
    echo "  • /home/cbwinslow/cbw_terraform/cbw_terraform_config.yml"
    echo "  • /home/cbwinslow/cbw_pulumi/cbw_pulumi_config.yml"
    echo
    echo "These files contain all service configurations and port mappings."
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --status         Show system status"
    echo "  --plan           Show deployment plan"
    echo "  --steps          Show next steps"
    echo "  --endpoints      Show service endpoints"
    echo "  --configs        Show master configuration files"
    echo "  --all            Show all information (default)"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --status"
    echo "  $0 --plan"
    echo "  $0 --all"
}

main() {
    print_header
    
    # Parse arguments
    local show_status=false
    local show_plan=false
    local show_steps=false
    local show_endpoints=false
    local show_configs=false
    
    if [[ $# -eq 0 ]]; then
        show_status=true
        show_plan=true
        show_steps=true
        show_endpoints=true
        show_configs=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --status)
                    show_status=true
                    shift
                    ;;
                --plan)
                    show_plan=true
                    shift
                    ;;
                --steps)
                    show_steps=true
                    shift
                    ;;
                --endpoints)
                    show_endpoints=true
                    shift
                    ;;
                --configs)
                    show_configs=true
                    shift
                    ;;
                --all)
                    show_status=true
                    show_plan=true
                    show_steps=true
                    show_endpoints=true
                    show_configs=true
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
    
    # Show requested information
    if [[ "$show_status" == true ]]; then
        show_system_status
        echo
    fi
    
    if [[ "$show_plan" == true ]]; then
        show_deployment_plan
        echo
    fi
    
    if [[ "$show_steps" == true ]]; then
        show_next_steps
        echo
    fi
    
    if [[ "$show_endpoints" == true ]]; then
        show_service_endpoints
        echo
    fi
    
    if [[ "$show_configs" == true ]]; then
        show_master_configs
        echo
    fi
    
    info "Manual deployment guide completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi