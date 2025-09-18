#!/usr/bin/env bash
#===============================================================================
# ██╗   ██╗██████╗ ██╗     ██████╗     ██████╗ ███████╗██████╗ ██╗███████╗████████╗
# ██║   ██║██╔══██╗██║     ██╔══██╗    ██╔══██╗██╔════╝██╔══██╗██║██╔════╝╚══██╔══╝
# ██║   ██║██████╔╝██║     ██║  ██║    ██║  ██║█████╗  ██████╔╝██║███████╗   ██║   
# ██║   ██║██╔══██╗██║     ██║  ██║    ██║  ██║██╔══╝  ██╔══██╗██║╚════██║   ██║   
# ╚██████╔╝██████╔╝███████╗██████╔╝    ██████╔╝███████╗██║  ██║██║███████║   ██║   
#  ╚═════╝ ╚═════╝ ╚══════╝╚═════╝     ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝   ╚═╝   
#===============================================================================
# File: cbw_user_deployment.sh
# Description: User-level deployment script for CBW infrastructure
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
    echo -e "${BLUE}CBW User-Level Deployment${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking Prerequisites${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check Docker access
    if ! docker info >/dev/null 2>&1; then
        error "Cannot connect to Docker daemon"
        echo -e "${YELLOW}Please ensure Docker is running and you have permissions${NC}"
        echo -e "${YELLOW}Run: newgrp docker${NC}"
        echo -e "${YELLOW}Or log out and log back in${NC}"
        return 1
    fi
    
    # Check Docker compose
    if ! docker-compose --version >/dev/null 2>&1; then
        warn "Docker-compose not found, will use docker compose"
    fi
    
    # Check required commands
    local required_commands=("docker" "jq" "curl" "git")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing_commands[*]}"
        echo -e "${YELLOW}Please run the sudo setup script:${NC}"
        echo -e "${YELLOW}  sudo /home/cbwinslow/cbw_sudo_setup.sh --all${NC}"
        return 1
    fi
    
    # Check port database
    if [[ ! -f "/home/cbwinslow/.cbw_port_database.json" ]]; then
        warn "Port database not found"
        echo -e "${YELLOW}Initializing port database...${NC}"
        if [[ -f "/home/cbwinslow/cbw_simple_port_db.sh" ]]; then
            /home/cbwinslow/cbw_simple_port_db.sh --init
        else
            error "Port database initialization script not found"
            return 1
        fi
    fi
    
    info "All prerequisites met"
    return 0
}

# Function to get port from simple database
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
    
    # Fallback to default ports
    case $(echo "$service" | tr '[:lower:]' '[:upper:]') in
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
        *) echo "0" ;;
    esac
}

# Function to check if port is available
is_port_available() {
    local port=$1
    
    # Check if port is in use
    if ss -tuln | grep -q ":$port "; then
        return 1  # Port in use
    else
        return 0  # Port available
    fi
}

# Function to find available port
find_available_port() {
    local start_port=${1:-8000}
    
    for ((port=start_port; port<=65535; port++)); do
        if ! ss -tuln | grep -q ":$port "; then
            echo "$port"
            return 0
        fi
    done
    
    echo ""
    return 1
}

# Function to check if Docker container is already running
is_container_running() {
    local container_name=$1
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0  # Container is running
    else
        return 1  # Container is not running
    fi
}

# Function to check if Docker container exists
does_container_exist() {
    local container_name=$1
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0  # Container exists
    else
        return 1  # Container does not exist
    fi
}

# Function to stop and remove container if it exists
stop_and_remove_container() {
    local container_name=$1
    
    if does_container_exist "$container_name"; then
        info "Container $container_name exists, stopping and removing"
        docker stop "$container_name" >/dev/null 2>&1 || true
        docker rm "$container_name" >/dev/null 2>&1 || true
    fi
}

# Function to deploy monitoring services
deploy_monitoring() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying Monitoring Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create volumes (idempotent - won't fail if volumes already exist)
    docker volume create grafana-data >/dev/null 2>&1 || true
    docker volume create prometheus-data >/dev/null 2>&1 || true
    docker volume create loki-data >/dev/null 2>&1 || true
    
    # Get ports
    local grafana_port=$(get_port GRAFANA)
    local prometheus_port=$(get_port PROMETHEUS)
    local cadvisor_port=$(get_port CADVISOR)
    local loki_port=$(get_port LOKI)
    
    # Check port availability and adjust if needed
    local ports_to_check=(
        "$grafana_port:GRAFANA"
        "$prometheus_port:PROMETHEUS"
        "$cadvisor_port:CADVISOR"
        "$loki_port:LOKI"
    )
    
    for port_service in "${ports_to_check[@]}"; do
        local port=${port_service%:*}
        local service=${port_service#*:}
        
        if ! is_port_available "$port"; then
            if is_container_running "$service"; then
                info "Port $port is in use by container $service (OK)"
            else
                local new_port=$(find_available_port "$port")
                if [[ -n "$new_port" ]]; then
                    warn "Port $port is in use, updating port database to use $new_port instead"
                    if [[ -f "/home/cbwinslow/cbw_simple_port_db.sh" ]] && [[ -x "/home/cbwinslow/cbw_simple_port_db.sh" ]]; then
                        /home/cbwinslow/cbw_simple_port_db.sh --set "$service" "$new_port" "MONITORING" "Updated port for $service"
                    fi
                else
                    error "No available ports found for $service"
                    return 1
                fi
            fi
        fi
    done
    
    # Redefine ports after potential adjustments
    grafana_port=$(get_port GRAFANA)
    prometheus_port=$(get_port PROMETHEUS)
    cadvisor_port=$(get_port CADVISOR)
    loki_port=$(get_port LOKI)
    
    # Deploy services using docker-compose if available
    local compose_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    
    if [[ -f "$compose_dir/monitoring.yml" ]]; then
        info "Deploying monitoring services with docker-compose"
        cd "$compose_dir"
        docker-compose -f monitoring.yml up -d
    else
        # Deploy services individually (idempotent)
        info "Deploying monitoring services individually"
        
        # Prometheus
        if ! is_container_running "prometheus"; then
            info "Deploying Prometheus on port $prometheus_port"
            stop_and_remove_container "prometheus"
            
            docker run -d \
                --name prometheus \
                --restart unless-stopped \
                -p "$prometheus_port:9090" \
                -v prometheus-data:/etc/prometheus \
                prom/prometheus:latest
        else
            info "Prometheus is already running"
        fi
        
        # Grafana
        if ! is_container_running "grafana"; then
            info "Deploying Grafana on port $grafana_port"
            stop_and_remove_container "grafana"
            
            docker run -d \
                --name grafana \
                --restart unless-stopped \
                -p "$grafana_port:3000" \
                -e GF_SECURITY_ADMIN_PASSWORD=admin \
                -v grafana-data:/var/lib/grafana \
                grafana/grafana:latest
        else
            info "Grafana is already running"
        fi
        
        # cAdvisor
        if ! is_container_running "cadvisor"; then
            info "Deploying cAdvisor on port $cadvisor_port"
            stop_and_remove_container "cadvisor"
            
            docker run -d \
                --name cadvisor \
                --restart unless-stopped \
                -p "$cadvisor_port:8080" \
                --privileged \
                -v /:/rootfs:ro \
                -v /var/run:/var/run:ro \
                -v /sys:/sys:ro \
                -v /var/lib/docker/:/var/lib/docker:ro \
                -v /dev/disk/:/dev/disk:ro \
                gcr.io/cadvisor/cadvisor:latest
        else
            info "cAdvisor is already running"
        fi
        
        # Loki
        if ! is_container_running "loki"; then
            info "Deploying Loki on port $loki_port"
            stop_and_remove_container "loki"
            
            docker run -d \
                --name loki \
                --restart unless-stopped \
                -p "$loki_port:3100" \
                grafana/loki:2.9.8
        else
            info "Loki is already running"
        fi
    fi
    
    info "Monitoring services deployed successfully"
    return 0
}

# Function to deploy database services
deploy_databases() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying Database Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create volumes (idempotent)
    docker volume create pg-data >/dev/null 2>&1 || true
    docker volume create qdrant-data >/dev/null 2>&1 || true
    docker volume create mongo-data >/dev/null 2>&1 || true
    docker volume create opensearch-data >/dev/null 2>&1 || true
    
    # Get ports
    local pg_port=$(get_port POSTGRESQL)
    local qdrant_http_port=$(get_port QDRANT_HTTP)
    local qdrant_grpc_port=$(get_port QDRANT_GRPC)
    local mongo_port=$(get_port MONGODB)
    local opensearch_port=$(get_port OPENSEARCH)
    local opensearch_monitoring_port=$(get_port OPENSEARCH_MONITORING)
    local rabbitmq_port=$(get_port RABBITMQ)
    local rabbitmq_management_port=$(get_port RABBITMQ_MANAGEMENT)
    
    # Check port availability and adjust if needed
    local ports_to_check=(
        "$pg_port:POSTGRESQL"
        "$qdrant_http_port:QDRANT_HTTP"
        "$qdrant_grpc_port:QDRANT_GRPC"
        "$mongo_port:MONGODB"
        "$opensearch_port:OPENSEARCH"
        "$opensearch_monitoring_port:OPENSEARCH_MONITORING"
        "$rabbitmq_port:RABBITMQ"
        "$rabbitmq_management_port:RABBITMQ_MANAGEMENT"
    )
    
    for port_service in "${ports_to_check[@]}"; do
        local port=${port_service%:*}
        local service=${port_service#*:}
        
        if ! is_port_available "$port"; then
            if is_container_running "$service"; then
                info "Port $port is in use by container $service (OK)"
            else
                local new_port=$(find_available_port "$port")
                if [[ -n "$new_port" ]]; then
                    warn "Port $port is in use, updating port database to use $new_port instead"
                    if [[ -f "/home/cbwinslow/cbw_simple_port_db.sh" ]] && [[ -x "/home/cbwinslow/cbw_simple_port_db.sh" ]]; then
                        /home/cbwinslow/cbw_simple_port_db.sh --set "$service" "$new_port" "DATABASE" "Updated port for $service"
                    fi
                else
                    error "No available ports found for $service"
                    return 1
                fi
            fi
        fi
    done
    
    # Redefine ports after potential adjustments
    pg_port=$(get_port POSTGRESQL)
    qdrant_http_port=$(get_port QDRANT_HTTP)
    qdrant_grpc_port=$(get_port QDRANT_GRPC)
    mongo_port=$(get_port MONGODB)
    opensearch_port=$(get_port OPENSEARCH)
    opensearch_monitoring_port=$(get_port OPENSEARCH_MONITORING)
    rabbitmq_port=$(get_port RABBITMQ)
    rabbitmq_management_port=$(get_port RABBITMQ_MANAGEMENT)
    
    # Deploy services using docker-compose if available
    local compose_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    
    if [[ -f "$compose_dir/databases.yml" ]]; then
        info "Deploying database services with docker-compose"
        cd "$compose_dir"
        docker-compose -f databases.yml up -d
    else
        # Deploy services individually (idempotent)
        info "Deploying database services individually"
        
        # PostgreSQL
        if ! is_container_running "pg"; then
            info "Deploying PostgreSQL on port $pg_port"
            stop_and_remove_container "pg"
            
            docker run -d \
                --name pg \
                --restart unless-stopped \
                -p "$pg_port:5432" \
                -e POSTGRES_PASSWORD=postgres \
                -e POSTGRES_USER=postgres \
                -e POSTGRES_DB=app \
                -v pg-data:/var/lib/postgresql/data \
                docker.io/postgres:16
        else
            info "PostgreSQL is already running"
        fi
        
        # Qdrant
        if ! is_container_running "qdrant"; then
            info "Deploying Qdrant on ports $qdrant_http_port,$qdrant_grpc_port"
            stop_and_remove_container "qdrant"
            
            docker run -d \
                --name qdrant \
                --restart unless-stopped \
                -p "$qdrant_http_port:6333" \
                -p "$qdrant_grpc_port:6334" \
                -v qdrant-data:/qdrant/storage \
                qdrant/qdrant:latest
        else
            info "Qdrant is already running"
        fi
        
        # MongoDB
        if ! is_container_running "mongo"; then
            info "Deploying MongoDB on port $mongo_port"
            stop_and_remove_container "mongo"
            
            docker run -d \
                --name mongo \
                --restart unless-stopped \
                -p "$mongo_port:27017" \
                -v mongo-data:/data/db \
                mongo:7
        else
            info "MongoDB is already running"
        fi
        
        # OpenSearch
        if ! is_container_running "opensearch"; then
            info "Deploying OpenSearch on ports $opensearch_port,$opensearch_monitoring_port"
            stop_and_remove_container "opensearch"
            
            docker run -d \
                --name opensearch \
                --restart unless-stopped \
                -p "$opensearch_port:9200" \
                -p "$opensearch_monitoring_port:9600" \
                -e discovery.type=single-node \
                -e bootstrap.memory_lock=true \
                -e OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g" \
                -v opensearch-data:/usr/share/opensearch/data \
                opensearchproject/opensearch:2.17.1
        else
            info "OpenSearch is already running"
        fi
        
        # RabbitMQ
        if ! is_container_running "rabbitmq"; then
            info "Deploying RabbitMQ on ports $rabbitmq_port,$rabbitmq_management_port"
            stop_and_remove_container "rabbitmq"
            
            docker run -d \
                --name rabbitmq \
                --restart unless-stopped \
                -p "$rabbitmq_port:5672" \
                -p "$rabbitmq_management_port:15672" \
                rabbitmq:3-management
        else
            info "RabbitMQ is already running"
        fi
    fi
    
    info "Database services deployed successfully"
    return 0
}

# Function to show deployment status
show_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deployment Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Show running containers
    if command -v docker >/dev/null 2>&1; then
        info "Running containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
    else
        warn "Docker not available"
    fi
    
    # Show port mappings
    echo
    info "Service endpoints:"
    
    # Get ports from database
    local grafana_port=$(get_port GRAFANA)
    local prometheus_port=$(get_port PROMETHEUS)
    local cadvisor_port=$(get_port CADVISOR)
    local pg_port=$(get_port POSTGRESQL)
    local mongo_port=$(get_port MONGODB)
    local qdrant_http_port=$(get_port QDRANT_HTTP)
    local opensearch_port=$(get_port OPENSEARCH)
    
    echo "  • Grafana: http://localhost:$grafana_port (admin / admin)"
    echo "  • Prometheus: http://localhost:$prometheus_port"
    echo "  • cAdvisor: http://localhost:$cadvisor_port"
    echo "  • PostgreSQL: localhost:$pg_port"
    echo "  • MongoDB: localhost:$mongo_port"
    echo "  • Qdrant: localhost:$qdrant_http_port"
    echo "  • OpenSearch: localhost:$opensearch_port"
}

# Function to stop all services
stop_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Stopping All Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Stop services using docker-compose if available
    local compose_dir="/home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    
    if [[ -f "$compose_dir/monitoring.yml" ]] && [[ -f "$compose_dir/databases.yml" ]]; then
        info "Stopping services with docker-compose"
        cd "$compose_dir"
        docker-compose -f monitoring.yml down
        docker-compose -f databases.yml down
    else
        # Stop individual containers
        info "Stopping individual containers"
        
        local containers=("prometheus" "grafana" "cadvisor" "loki" "pg" "qdrant" "mongo" "opensearch" "rabbitmq")
        for container in "${containers[@]}"; do
            if does_container_exist "$container"; then
                info "Stopping container: $container"
                docker stop "$container" >/dev/null 2>&1 || true
                docker rm "$container" >/dev/null 2>&1 || true
            else
                info "Container $container does not exist"
            fi
        done
    fi
    
    info "All services stopped"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all               Deploy all services (default)"
    echo "  --prerequisites     Check prerequisites only"
    echo "  --monitoring        Deploy monitoring services only"
    echo "  --databases         Deploy database services only"
    echo "  --status            Show deployment status"
    echo "  --stop              Stop all services"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --prerequisites"
    echo "  $0 --monitoring"
    echo "  $0 --databases"
    echo "  $0 --status"
    echo "  $0 --stop"
}

main() {
    print_header
    
    # Parse arguments
    local run_all=false
    local check_prerequisites_only=false
    local deploy_monitoring_only=false
    local deploy_databases_only=false
    local show_status_only=false
    local stop_services_only=false
    
    if [[ $# -eq 0 ]]; then
        run_all=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --all)
                    run_all=true
                    shift
                    ;;
                --prerequisites)
                    check_prerequisites_only=true
                    shift
                    ;;
                --monitoring)
                    deploy_monitoring_only=true
                    shift
                    ;;
                --databases)
                    deploy_databases_only=true
                    shift
                    ;;
                --status)
                    show_status_only=true
                    shift
                    ;;
                --stop)
                    stop_services_only=true
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
    if [[ "$check_prerequisites_only" == true ]]; then
        if ! check_prerequisites; then
            error "Prerequisites check failed"
            exit 1
        fi
        return 0
    fi
    
    if [[ "$show_status_only" == true ]]; then
        show_status
        return 0
    fi
    
    if [[ "$stop_services_only" == true ]]; then
        stop_services
        return 0
    fi
    
    # Check prerequisites for deployment actions
    if [[ "$run_all" == true ]] || [[ "$deploy_monitoring_only" == true ]] || [[ "$deploy_databases_only" == true ]]; then
        if ! check_prerequisites; then
            error "Prerequisites not met"
            exit 1
        fi
    fi
    
    # Execute deployment actions
    if [[ "$run_all" == true ]] || [[ "$deploy_monitoring_only" == true ]]; then
        if ! deploy_monitoring; then
            error "Failed to deploy monitoring services"
            exit 1
        fi
    fi
    
    if [[ "$run_all" == true ]] || [[ "$deploy_databases_only" == true ]]; then
        if ! deploy_databases; then
            error "Failed to deploy database services"
            exit 1
        fi
    fi
    
    # Show status if deploying services
    if [[ "$run_all" == true ]] || [[ "$deploy_monitoring_only" == true ]] || [[ "$deploy_databases_only" == true ]]; then
        echo
        show_status
    fi
    
    echo
    info "CBW user-level deployment completed successfully!"
    
    if [[ "$run_all" == true ]]; then
        info "All services are now running. You can access them using the endpoints listed above."
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi