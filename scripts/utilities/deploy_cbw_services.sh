#!/usr/bin/env bash
#===============================================================================
# ██████╗ ███████╗██████╗ ██╗██████╗ ████████╗
# ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
# ██║  ██║█████╗  ██████╔╝██║██████╔╝   ██║   
# ██║  ██║██╔══╝  ██╔══██╗██║██╔═══╝    ██║   
# ██████╔╝███████╗██████╔╝██║██║        ██║   
# ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝        ╚═╝   
#===============================================================================
# File: deploy_cbw_services.sh
# Description: Deploy CBW services using Docker directly with port mapping config
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

# Configuration files (check multiple locations)
PORT_CONFIGS=("/home/cbwinslow/cbw_port_mapping.conf" "/etc/cbw-ports.conf" "/etc/cbw/cbw-ports.conf")

# Function to find the first existing config file
find_config_file() {
    for config in "${PORT_CONFIGS[@]}"; do
        if [[ -f "$config" ]] && [[ -s "$config" ]]; then
            echo "$config"
            return 0
        fi
    done
    
    # If no config found, return the primary one
    echo "${PORT_CONFIGS[0]}"
    return 1
}

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Deploying CBW Services${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to read port from simple database or config file
get_port() {
    local service=$1
    
    # Try to use simple port database first
    if [[ -f "/home/cbwinslow/cbw_simple_port_db.sh" ]] && [[ -x "/home/cbwinslow/cbw_simple_port_db.sh" ]]; then
        local db_port=$(/home/cbwinslow/cbw_simple_port_db.sh --get "$service" 2>/dev/null)
        if [[ -n "$db_port" ]] && [[ "$db_port" != "0" ]]; then
            echo "$db_port"
            return 0
        fi
    fi
    
    # Fallback to file-based config
    local config_file=$(find_config_file)
    
    if [[ -f "$config_file" ]] && [[ -s "$config_file" ]]; then
        local port=$(grep "^${service}=" "$config_file" | cut -d'=' -f2)
        if [[ -n "$port" ]]; then
            echo "$port"
            return 0
        fi
    fi
    
    # Return default port if not found in config
    case $service in
        GRAFANA) echo "3001" ;;
        PROMETHEUS) echo "9091" ;;
        CADVISOR) echo "8081" ;;
        LOKI) echo "3100" ;;
        PROMTAIL) echo "9080" ;;
        NODE_EXPORTER) echo "9100" ;;
        DCGM_EXPORTER) echo "9400" ;;
        POSTGRESQL) echo "5433" ;;
        QDRANT_HTTP) echo "6333" ;;
        QDRANT_GRPC) echo "6334" ;;
        MONGODB) echo "27018" ;;
        OPENSEARCH) echo "9200" ;;
        OPENSEARCH_MONITORING) echo "9600" ;;
        RABBITMQ) echo "5672" ;;
        RABBITMQ_MANAGEMENT) echo "15672" ;;
        KONG_PROXY) echo "8000" ;;
        KONG_PROXY_SSL) echo "8443" ;;
        KONG_ADMIN) echo "8001" ;;
        KONG_ADMIN_SSL) echo "8444" ;;
        NETDATA) echo "19999" ;;
        *) echo "" ;;
    esac
}

check_docker() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking Docker${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        return 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        error "Docker daemon is not running"
        return 1
    fi
    
    echo -e "${GREEN}Docker is installed and running${NC}"
    echo -e "${GREEN}Docker version: ${NC}$(docker --version)"
    
    # Check if port config file exists
    local config_file=$(find_config_file)
    if [[ -f "$config_file" ]] && [[ -s "$config_file" ]]; then
        echo -e "${GREEN}Port configuration file: ${NC}$config_file"
    else
        echo -e "${YELLOW}Port configuration file not found or empty: ${NC}$config_file"
        echo -e "${YELLOW}Using default port mappings${NC}"
    fi
    
    return 0
}

stop_existing_containers() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Stopping existing containers${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local containers=("prometheus" "grafana" "loki" "promtail" "node_exporter" "cadvisor" "dcgm-exporter" 
                     "pg" "qdrant" "mongo" "opensearch" "rabbitmq")
    
    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            echo -e "${YELLOW}Stopping container: ${NC}$container"
            docker stop "$container" >/dev/null 2>&1 || true
            docker rm "$container" >/dev/null 2>&1 || true
        else
            echo -e "${GREEN}Container not running: ${NC}$container"
        fi
    done
}

deploy_monitoring_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying Monitoring Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Get ports from config
    local grafana_port=$(get_port GRAFANA)
    local prometheus_port=$(get_port PROMETHEUS)
    local cadvisor_port=$(get_port CADVISOR)
    local loki_port=$(get_port LOKI)
    local promtail_port=$(get_port PROMTAIL)
    local node_exporter_port=$(get_port NODE_EXPORTER)
    local dcgm_exporter_port=$(get_port DCGM_EXPORTER)
    
    # Create volumes
    docker volume create grafana-data >/dev/null 2>&1 || true
    
    # Prometheus
    echo -e "${GREEN}Deploying Prometheus on port $prometheus_port...${NC}"
    docker run -d \
        --name prometheus \
        --restart unless-stopped \
        -p $prometheus_port:9090 \
        prom/prometheus:latest
    
    # Grafana
    echo -e "${GREEN}Deploying Grafana on port $grafana_port...${NC}"
    docker run -d \
        --name grafana \
        --restart unless-stopped \
        -p $grafana_port:3000 \
        -e GF_SECURITY_ADMIN_PASSWORD=admin \
        -v grafana-data:/var/lib/grafana \
        grafana/grafana:latest
    
    # cAdvisor
    echo -e "${GREEN}Deploying cAdvisor on port $cadvisor_port...${NC}"
    docker run -d \
        --name cadvisor \
        --restart unless-stopped \
        -p $cadvisor_port:8080 \
        --privileged \
        -v /:/rootfs:ro \
        -v /var/run:/var/run:ro \
        -v /sys:/sys:ro \
        -v /var/lib/docker/:/var/lib/docker:ro \
        -v /dev/disk/:/dev/disk:ro \
        gcr.io/cadvisor/cadvisor:latest
    
    echo -e "${GREEN}Monitoring services deployed successfully${NC}"
}

deploy_database_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying Database Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Get ports from config
    local pg_port=$(get_port POSTGRESQL)
    local qdrant_http_port=$(get_port QDRANT_HTTP)
    local qdrant_grpc_port=$(get_port QDRANT_GRPC)
    local mongo_port=$(get_port MONGODB)
    local opensearch_port=$(get_port OPENSEARCH)
    local opensearch_monitoring_port=$(get_port OPENSEARCH_MONITORING)
    local rabbitmq_port=$(get_port RABBITMQ)
    local rabbitmq_management_port=$(get_port RABBITMQ_MANAGEMENT)
    
    # Create volumes
    docker volume create pg_data >/dev/null 2>&1 || true
    docker volume create qdrant_data >/dev/null 2>&1 || true
    docker volume create mongo_data >/dev/null 2>&1 || true
    docker volume create os_data >/dev/null 2>&1 || true
    
    # PostgreSQL
    echo -e "${GREEN}Deploying PostgreSQL on port $pg_port...${NC}"
    docker run -d \
        --name pg \
        --restart unless-stopped \
        -p $pg_port:5432 \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_DB=app \
        -v pg_data:/var/lib/postgresql/data \
        docker.io/postgres:16
    
    # Qdrant
    echo -e "${GREEN}Deploying Qdrant on ports $qdrant_http_port,$qdrant_grpc_port...${NC}"
    docker run -d \
        --name qdrant \
        --restart unless-stopped \
        -p $qdrant_http_port:6333 \
        -p $qdrant_grpc_port:6334 \
        -v qdrant_data:/qdrant/storage \
        qdrant/qdrant:latest
    
    # MongoDB
    echo -e "${GREEN}Deploying MongoDB on port $mongo_port...${NC}"
    docker run -d \
        --name mongo \
        --restart unless-stopped \
        -p $mongo_port:27017 \
        -v mongo_data:/data/db \
        mongo:7
    
    # OpenSearch
    echo -e "${GREEN}Deploying OpenSearch on ports $opensearch_port,$opensearch_monitoring_port...${NC}"
    docker run -d \
        --name opensearch \
        --restart unless-stopped \
        -p $opensearch_port:9200 \
        -p $opensearch_monitoring_port:9600 \
        -e discovery.type=single-node \
        -e bootstrap.memory_lock=true \
        -e OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g" \
        -v os_data:/usr/share/opensearch/data \
        opensearchproject/opensearch:2.17.1
    
    # RabbitMQ
    echo -e "${GREEN}Deploying RabbitMQ on ports $rabbitmq_port,$rabbitmq_management_port...${NC}"
    docker run -d \
        --name rabbitmq \
        --restart unless-stopped \
        -p $rabbitmq_port:5672 \
        -p $rabbitmq_management_port:15672 \
        rabbitmq:3-management
    
    echo -e "${GREEN}Database services deployed successfully${NC}"
}

show_deployed_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deployed Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Get ports from config
    local prometheus_port=$(get_port PROMETHEUS)
    local grafana_port=$(get_port GRAFANA)
    local cadvisor_port=$(get_port CADVISOR)
    local loki_port=$(get_port LOKI)
    local pg_port=$(get_port POSTGRESQL)
    local qdrant_http_port=$(get_port QDRANT_HTTP)
    local qdrant_grpc_port=$(get_port QDRANT_GRPC)
    local mongo_port=$(get_port MONGODB)
    local opensearch_port=$(get_port OPENSEARCH)
    local opensearch_monitoring_port=$(get_port OPENSEARCH_MONITORING)
    local rabbitmq_port=$(get_port RABBITMQ)
    local rabbitmq_management_port=$(get_port RABBITMQ_MANAGEMENT)
    local kong_proxy_port=$(get_port KONG_PROXY)
    local kong_proxy_ssl_port=$(get_port KONG_PROXY_SSL)
    local kong_admin_port=$(get_port KONG_ADMIN)
    local kong_admin_ssl_port=$(get_port KONG_ADMIN_SSL)
    
    echo "Monitoring Services:"
    echo "  • Prometheus: http://localhost:$prometheus_port"
    echo "  • Grafana: http://localhost:$grafana_port (admin / admin)"
    echo "  • cAdvisor: http://localhost:$cadvisor_port"
    echo
    echo "Database Services:"
    echo "  • PostgreSQL: localhost:$pg_port"
    echo "  • Qdrant: $qdrant_http_port, $qdrant_grpc_port"
    echo "  • MongoDB: localhost:$mongo_port"
    echo "  • OpenSearch: $opensearch_port, $opensearch_monitoring_port"
    echo "  • RabbitMQ: $rabbitmq_port, $rabbitmq_management_port (management)"
    echo
    echo "Volumes created:"
    echo "  • grafana-data"
    echo "  • pg_data"
    echo "  • qdrant_data"
    echo "  • mongo_data"
    echo "  • os_data"
}

show_running_containers() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Running Containers${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        docker ps --format "table {{.Names}}	{{.Image}}	{{.Ports}}	{{.Status}}"
    else
        echo -e "${YELLOW}Docker not available${NC}"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all            Deploy all services (default)"
    echo "  --monitoring     Deploy monitoring services only"
    echo "  --databases      Deploy database services only"
    echo "  --stop           Stop all deployed services"
    echo "  --status         Show status of deployed services"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --monitoring"
    echo "  $0 --databases"
    echo "  $0 --status"
}

main() {
    print_header
    
    # Parse arguments
    local deploy_all=false
    local deploy_monitoring=false
    local deploy_databases=false
    local stop_services=false
    local show_status=false
    
    if [[ $# -eq 0 ]]; then
        deploy_all=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --all)
                    deploy_all=true
                    shift
                    ;;
                --monitoring)
                    deploy_monitoring=true
                    shift
                    ;;
                --databases)
                    deploy_databases=true
                    shift
                    ;;
                --stop)
                    stop_services=true
                    shift
                    ;;
                --status)
                    show_status=true
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
    
    # Check Docker
    if ! check_docker; then
        error "Docker check failed"
        exit 1
    fi
    
    # Handle stop request
    if [[ "$stop_services" == true ]]; then
        stop_existing_containers
        info "All services stopped"
        exit 0
    fi
    
    # Handle status request
    if [[ "$show_status" == true ]]; then
        show_running_containers
        exit 0
    fi
    
    # Stop existing containers
    stop_existing_containers
    
    # Deploy services
    if [[ "$deploy_all" == true ]] || [[ "$deploy_monitoring" == true ]]; then
        deploy_monitoring_services
    fi
    
    if [[ "$deploy_all" == true ]] || [[ "$deploy_databases" == true ]]; then
        deploy_database_services
    fi
    
    # Show results
    show_deployed_services
    echo
    show_running_containers
    
    echo
    info "Deployment completed successfully!"
    info "Services are now available at the endpoints listed above."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi