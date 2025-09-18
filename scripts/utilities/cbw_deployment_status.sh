#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔════╝████╗ ████║
# █████╗  ██║   ██║███████╗   ██║   █████╗  ██╔████╔██║
# ██╔══╝  ██║   ██║╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
# ██║     ╚██████╔╝███████║   ██║   ███████╗██║ ╚═╝ ██║
# ╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝
#===============================================================================
# File: cbw_deployment_status.sh
# Description: Check deployment status and show next steps
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
    echo -e "${BLUE}CBW Deployment Status${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

check_docker_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Docker Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Docker installed: ${NC}Yes ($(docker --version 2>/dev/null || echo 'Unknown'))"
        
        # Check if Docker daemon is running
        if systemctl is-active --quiet docker 2>/dev/null; then
            echo -e "${GREEN}Docker daemon: ${NC}Running"
        else
            echo -e "${YELLOW}Docker daemon: ${NC}Not running (or permission denied)"
        fi
        
        # Check Docker permissions
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}Docker permissions: ${NC}OK"
        else
            echo -e "${RED}Docker permissions: ${NC}Permission denied"
            echo -e "${YELLOW}This is likely because the current session doesn't have updated group permissions${NC}"
        fi
    else
        echo -e "${RED}Docker installed: ${NC}No"
    fi
}

check_existing_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Existing Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check for existing MongoDB instances
    if pgrep -f mongod >/dev/null 2>&1; then
        echo -e "${YELLOW}MongoDB: ${NC}Already running (existing instances detected)"
        echo "  Existing MongoDB processes:"
        pgrep -fa mongod | sed 's/^/    /'
    else
        echo -e "${GREEN}MongoDB: ${NC}Not running"
    fi
    
    # Check ports
    echo
    echo "Port usage:"
    for port in 27017 27018 27019; do
        if ss -tuln | grep -q ":$port "; then
            echo -e "${YELLOW}  Port $port: ${NC}In use"
        else
            echo -e "${GREEN}  Port $port: ${NC}Available"
        fi
    done
}

show_deployment_progress() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deployment Progress${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Services successfully deployed:"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q prometheus; then
        echo -e "${GREEN}  ✓ ${NC}Prometheus"
    else
        echo -e "${YELLOW}  ○ ${NC}Prometheus (not deployed)"
    fi
    
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q grafana; then
        echo -e "${GREEN}  ✓ ${NC}Grafana"
    else
        echo -e "${YELLOW}  ○ ${NC}Grafana (not deployed)"
    fi
    
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q cadvisor; then
        echo -e "${GREEN}  ✓ ${NC}cAdvisor"
    else
        echo -e "${YELLOW}  ○ ${NC}cAdvisor (not deployed)"
    fi
    
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q pg; then
        echo -e "${GREEN}  ✓ ${NC}PostgreSQL"
    else
        echo -e "${YELLOW}  ○ ${NC}PostgreSQL (not deployed)"
    fi
    
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q qdrant; then
        echo -e "${GREEN}  ✓ ${NC}Qdrant"
    else
        echo -e "${YELLOW}  ○ ${NC}Qdrant (not deployed)"
    fi
    
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q mongo; then
        echo -e "${GREEN}  ✓ ${NC}MongoDB"
    else
        echo -e "${YELLOW}  ○ ${NC}MongoDB (not deployed - port conflict)"
    fi
}

show_next_steps() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Next Steps${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "To complete the deployment:"
    echo
    echo "1. ${YELLOW}Fix Docker permissions:${NC}"
    echo "   - Log out and log back in to refresh group permissions"
    echo "   - Or run: newgrp docker (in a new terminal session)"
    echo
    echo "2. ${YELLOW}Run the deployment script:${NC}"
    echo "   /home/cbwinslow/deploy_cbw_services.sh --all"
    echo
    echo "3. ${YELLOW}If you still have permission issues:${NC}"
    echo "   sudo /home/cbwinslow/deploy_cbw_services.sh --all"
    echo
    echo "4. ${YELLOW}Alternative - Use Docker Compose directly:${NC}"
    echo "   cd /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    echo "   sudo docker-compose -f monitoring.yml up -d"
    echo "   sudo docker-compose -f databases.yml up -d"
    echo
    echo "5. ${YELLOW}Check deployed services:${NC}"
    echo "   /home/cbwinslow/deploy_cbw_services.sh --status"
}

show_service_endpoints() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Service Endpoints${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Use port mapper to get current ports
    local grafana_port=$(/home/cbwinslow/cbw_port_mapper.sh --get GRAFANA 2>/dev/null || echo "3001")
    local prometheus_port=$(/home/cbwinslow/cbw_port_mapper.sh --get PROMETHEUS 2>/dev/null || echo "9091")
    local cadvisor_port=$(/home/cbwinslow/cbw_port_mapper.sh --get CADVISOR 2>/dev/null || echo "8081")
    local pg_port=$(/home/cbwinslow/cbw_port_mapper.sh --get POSTGRESQL 2>/dev/null || echo "5433")
    local mongo_port=$(/home/cbwinslow/cbw_port_mapper.sh --get MONGODB 2>/dev/null || echo "27018")
    local qdrant_http_port=$(/home/cbwinslow/cbw_port_mapper.sh --get QDRANT_HTTP 2>/dev/null || echo "6333")
    local qdrant_grpc_port=$(/home/cbwinslow/cbw_port_mapper.sh --get QDRANT_GRPC 2>/dev/null || echo "6334")
    local opensearch_port=$(/home/cbwinslow/cbw_port_mapper.sh --get OPENSEARCH 2>/dev/null || echo "9200")
    local opensearch_monitoring_port=$(/home/cbwinslow/cbw_port_mapper.sh --get OPENSEARCH_MONITORING 2>/dev/null || echo "9600")
    local rabbitmq_port=$(/home/cbwinslow/cbw_port_mapper.sh --get RABBITMQ 2>/dev/null || echo "5672")
    local rabbitmq_management_port=$(/home/cbwinslow/cbw_port_mapper.sh --get RABBITMQ_MANAGEMENT 2>/dev/null || echo "15672")
    
    echo "After deployment, services will be available at:"
    echo "  • Grafana: http://localhost:$grafana_port (admin / admin)"
    echo "  • Prometheus: http://localhost:$prometheus_port"
    echo "  • PostgreSQL: localhost:$pg_port"
    echo "  • cAdvisor: http://localhost:$cadvisor_port"
    echo "  • Qdrant: $qdrant_http_port, $qdrant_grpc_port"
    echo "  • MongoDB: localhost:$mongo_port"
    echo "  • OpenSearch: $opensearch_port, $opensearch_monitoring_port"
    echo "  • RabbitMQ: $rabbitmq_port, $rabbitmq_management_port"
}

main() {
    print_header
    check_docker_status
    echo
    check_existing_services
    echo
    show_deployment_progress
    echo
    show_next_steps
    echo
    show_service_endpoints
    echo
    info "Deployment status check completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi