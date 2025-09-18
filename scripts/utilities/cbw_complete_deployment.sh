#!/usr/bin/env bash
#===============================================================================
#  ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ 
# ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ 
# ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
# ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
# ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ 
#===============================================================================
# File: cbw_complete_deployment.sh
# Description: Complete deployment coordinator for CBW infrastructure
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
    echo -e "${BLUE}CBW Complete Deployment Coordinator${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_welcome() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Welcome to CBW Infrastructure Deployment${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo
    echo "This script will guide you through the complete deployment of your CBW infrastructure."
    echo
    echo "The deployment consists of two phases:"
    echo "  1. System-level setup (requires sudo privileges)"
    echo "  2. User-level deployment (runs as regular user)"
    echo
    echo "Before proceeding, ensure you have:"
    echo "  • Sudo access to this system"
    echo "  • Internet connectivity for package downloads"
    echo "  • At least 20GB free disk space"
    echo "  • 8GB+ RAM recommended"
    echo
}

phase1_setup() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Phase 1: System-Level Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo
    echo "This phase will:"
    echo "  • Update package lists"
    echo "  • Install required packages (Docker, PostgreSQL client, etc.)"
    echo "  • Configure Docker daemon"
    echo "  • Setup firewall (UFW)"
    echo "  • Configure security (Fail2Ban, SSH)"
    echo "  • Create necessary directories"
    echo "  • Setup systemd services"
    echo
    
    read -p "Proceed with Phase 1 setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Phase 1 setup skipped"
        return 0
    fi
    
    # Check if sudo setup script exists
    if [[ ! -f "/home/cbwinslow/cbw_sudo_setup.sh" ]]; then
        error "Sudo setup script not found: /home/cbwinslow/cbw_sudo_setup.sh"
        return 1
    fi
    
    # Run sudo setup script
    info "Running sudo setup script..."
    echo -e "${YELLOW}You will be prompted for your password${NC}"
    
    if sudo /home/cbwinslow/cbw_sudo_setup.sh --all; then
        info "Phase 1 setup completed successfully"
        echo -e "${YELLOW}Please log out and log back in for group membership changes to take effect${NC}"
        echo -e "${YELLOW}Or run: newgrp docker${NC}"
        echo
        read -p "Press Enter to continue..."
        return 0
    else
        error "Phase 1 setup failed"
        return 1
    fi
}

phase2_deployment() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Phase 2: User-Level Deployment${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo
    echo "This phase will:"
    echo "  • Deploy monitoring services (Grafana, Prometheus, cAdvisor, Loki)"
    echo "  • Deploy database services (PostgreSQL, Qdrant, MongoDB, OpenSearch, RabbitMQ)"
    echo "  • Deploy API gateway services (Kong)"
    echo "  • Configure service ports using the simple port database"
    echo "  • Verify all services are running correctly"
    echo
    
    read -p "Proceed with Phase 2 deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Phase 2 deployment skipped"
        return 0
    fi
    
    # Check if user deployment script exists
    if [[ ! -f "/home/cbwinslow/cbw_user_deployment.sh" ]]; then
        error "User deployment script not found: /home/cbwinslow/cbw_user_deployment.sh"
        return 1
    fi
    
    # Run user deployment script
    info "Running user deployment script..."
    
    if /home/cbwinslow/cbw_user_deployment.sh --all; then
        info "Phase 2 deployment completed successfully"
        return 0
    else
        error "Phase 2 deployment failed"
        return 1
    fi
}

show_completion() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deployment Completed Successfully${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo
    echo "🎉 Congratulations! Your CBW infrastructure has been deployed successfully."
    echo
    echo "Services are now available at the following endpoints:"
    echo
    
    # Show service endpoints (get from port database)
    if [[ -f "/home/cbwinslow/cbw_simple_port_db.sh" ]] && [[ -x "/home/cbwinslow/cbw_simple_port_db.sh" ]]; then
        local grafana_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get GRAFANA)
        local prometheus_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get PROMETHEUS)
        local cadvisor_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get CADVISOR)
        local postgres_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get POSTGRESQL)
        local mongo_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get MONGODB)
        local qdrant_http_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get QDRANT_HTTP)
        local opensearch_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get OPENSEARCH)
        local rabbitmq_mgmt_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get RABBITMQ_MANAGEMENT)
        local kong_proxy_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get KONG_PROXY)
        local kong_admin_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get KONG_ADMIN)
        
        echo "  • Grafana: http://localhost:$grafana_port (admin / admin)"
        echo "  • Prometheus: http://localhost:$prometheus_port"
        echo "  • cAdvisor: http://localhost:$cadvisor_port"
        echo "  • PostgreSQL: localhost:$postgres_port"
        echo "  • MongoDB: localhost:$mongo_port"
        echo "  • Qdrant: localhost:$qdrant_http_port"
        echo "  • OpenSearch: localhost:$opensearch_port"
        echo "  • RabbitMQ Management: http://localhost:$rabbitmq_mgmt_port"
        echo "  • Kong Proxy: http://localhost:$kong_proxy_port"
        echo "  • Kong Admin: http://localhost:$kong_admin_port"
    else
        echo "  • Grafana: http://localhost:3001 (admin / admin)"
        echo "  • Prometheus: http://localhost:9091"
        echo "  • cAdvisor: http://localhost:8081"
        echo "  • PostgreSQL: localhost:5433"
        echo "  • MongoDB: localhost:27018"
        echo "  • Qdrant: localhost:6333"
        echo "  • OpenSearch: localhost:9200"
        echo "  • RabbitMQ Management: http://localhost:15672"
        echo "  • Kong Proxy: http://localhost:8000"
        echo "  • Kong Admin: http://localhost:8001"
    fi
    
    echo
    echo "Management commands:"
    echo "  • Check deployment status: /home/cbwinslow/cbw_user_deployment.sh --status"
    echo "  • Stop all services: /home/cbwinslow/cbw_user_deployment.sh --stop"
    echo "  • View logs: docker logs <service_name>"
    echo
    echo "Next steps:"
    echo "  1. Access Grafana and configure dashboards"
    echo "  2. Connect to PostgreSQL and set up databases"
    echo "  3. Explore the other services using the endpoints above"
    echo "  4. Review the documentation in /home/cbwinslow/"
    echo
}

show_troubleshooting() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Troubleshooting Guide${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo
    echo "Common issues and solutions:"
    echo
    echo "1. Docker permission denied:"
    echo "   • Log out and log back in to refresh group membership"
    echo "   • Or run: newgrp docker"
    echo
    echo "2. Port conflicts:"
    echo "   • Check which services are using conflicting ports: ss -tuln | grep :<port>"
    echo "   • Stop conflicting services: sudo systemctl stop <service>"
    echo "   • Or change ports in the port database: /home/cbwinslow/cbw_simple_port_db.sh --set <SERVICE> <new_port>"
    echo
    echo "3. Services not starting:"
    echo "   • Check Docker logs: docker logs <service_name>"
    echo "   • Check service status: docker ps -a"
    echo "   • Restart services: /home/cbwinslow/cbw_user_deployment.sh --all"
    echo
    echo "4. Need to redeploy:"
    echo "   • Stop all services: /home/cbwinslow/cbw_user_deployment.sh --stop"
    echo "   • Redeploy: /home/cbwinslow/cbw_user_deployment.sh --all"
    echo
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --phase1            Run Phase 1 (system-level setup) only"
    echo "  --phase2            Run Phase 2 (user-level deployment) only"
    echo "  --all               Run both phases (default)"
    echo "  --status            Show deployment status"
    echo "  --troubleshoot      Show troubleshooting guide"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --phase1"
    echo "  $0 --phase2"
    echo "  $0 --status"
    echo "  $0 --troubleshoot"
}

main() {
    print_header
    show_welcome
    
    # Parse arguments
    local run_phase1=false
    local run_phase2=false
    local show_status=false
    local show_troubleshooting_guide=false
    
    if [[ $# -eq 0 ]]; then
        run_phase1=true
        run_phase2=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --phase1)
                    run_phase1=true
                    shift
                    ;;
                --phase2)
                    run_phase2=true
                    shift
                    ;;
                --all)
                    run_phase1=true
                    run_phase2=true
                    shift
                    ;;
                --status)
                    show_status=true
                    shift
                    ;;
                --troubleshoot)
                    show_troubleshooting_guide=true
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
        if [[ -f "/home/cbwinslow/cbw_user_deployment.sh" ]]; then
            /home/cbwinslow/cbw_user_deployment.sh --status
        else
            error "User deployment script not found"
            exit 1
        fi
        return 0
    fi
    
    if [[ "$show_troubleshooting_guide" == true ]]; then
        show_troubleshooting
        return 0
    fi
    
    if [[ "$run_phase1" == true ]]; then
        if ! phase1_setup; then
            error "Phase 1 setup failed"
            exit 1
        fi
    fi
    
    if [[ "$run_phase2" == true ]]; then
        if ! phase2_deployment; then
            error "Phase 2 deployment failed"
            exit 1
        fi
    fi
    
    # Show completion message if both phases were run or if no specific phase was requested
    if [[ "$run_phase1" == true ]] && [[ "$run_phase2" == true ]]; then
        show_completion
    fi
    
    info "CBW complete deployment process finished!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi