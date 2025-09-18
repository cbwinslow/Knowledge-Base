#!/usr/bin/env bash
#===============================================================================
# ██████╗  ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
# ██╔══██╗██╔═══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
# ██████╔╝██║   ██║██████╔╝██╔████╔██║███████║   ██║   ██║██║   ██║██╔██╗ ██║
# ██╔═══╝ ██║   ██║██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
# ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
#===============================================================================
# File: cbw_port_mapper.sh
# Description: Port mapping utility for CBW services
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -euo pipefail

# Color codes
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

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
    echo -e "${BLUE}CBW Port Mapper Utility${NC}"
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

# Function to set port in config file
set_port() {
    local service=$1
    local port=$2
    
    if [[ -f "$PORT_CONFIG" ]]; then
        # Check if service already exists
        if grep -q "^${service}=" "$PORT_CONFIG"; then
            # Update existing entry
            sed -i "s/^${service}=.*/${service}=${port}/" "$PORT_CONFIG"
        else
            # Add new entry
            echo "${service}=${port}" >> "$PORT_CONFIG"
        fi
        echo -e "${GREEN}Port updated: ${NC}${service}=${port}"
    else
        error "Port configuration file not found: $PORT_CONFIG"
        return 1
    fi
}

# Function to list all ports
list_ports() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Current Port Mappings${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if [[ -f "$PORT_CONFIG" ]]; then
        echo -e "${GREEN}Service${NC}                     ${GREEN}Port${NC}"
        echo -e "${GREEN}-------${NC}                     ${GREEN}----${NC}"
        while IFS='=' read -r service port; do
            # Skip comments and empty lines
            [[ $service =~ ^#.*$ ]] && continue
            [[ -z $service ]] && continue
            printf "%-30s %s\\n" "$service" "$port"
        done < "$PORT_CONFIG"
    else
        error "Port configuration file not found: $PORT_CONFIG"
        return 1
    fi
}

# Function to validate port
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if port is available
check_port_available() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        return 1  # Port in use
    else
        return 0  # Port available
    fi
}

# Function to find available port
find_available_port() {
    local start_port=${1:-8000}
    local port=$start_port
    
    while [[ $port -le 65535 ]]; do
        if ! ss -tuln | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo ""
    return 1
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --list              List all port mappings"
    echo "  --get <service>     Get port for a specific service"
    echo "  --set <service> <port>  Set port for a specific service"
    echo "  --check <port>      Check if a port is available"
    echo "  --find [start]      Find an available port (starting from start or 8000)"
    echo "  --config            Show configuration file location"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --get GRAFANA"
    echo "  $0 --set GRAFANA 3001"
    echo "  $0 --check 3001"
    echo "  $0 --find 8000"
}

main() {
    print_header
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        list_ports
        return 0
    fi
    
    case $1 in
        --list)
            list_ports
            ;;
        --get)
            if [[ -z "${2:-}" ]]; then
                error "Service name required for get command"
                show_usage
                exit 1
            fi
            local port=$(get_port "$2")
            if [[ -n "$port" ]]; then
                echo "$port"
            else
                error "Service $2 not found in configuration"
                exit 1
            fi
            ;;
        --set)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                error "Service name and port required for set command"
                show_usage
                exit 1
            fi
            
            if ! validate_port "$3"; then
                error "Invalid port number: $3"
                exit 1
            fi
            
            set_port "$2" "$3"
            ;;
        --check)
            if [[ -z "${2:-}" ]]; then
                error "Port number required for check command"
                show_usage
                exit 1
            fi
            
            if ! validate_port "$2"; then
                error "Invalid port number: $2"
                exit 1
            fi
            
            if check_port_available "$2"; then
                echo -e "${GREEN}Port $2 is available${NC}"
            else
                echo -e "${YELLOW}Port $2 is in use${NC}"
            fi
            ;;
        --find)
            local start_port=${2:-8000}
            
            if ! validate_port "$start_port"; then
                error "Invalid start port number: $start_port"
                exit 1
            fi
            
            local available_port=$(find_available_port "$start_port")
            if [[ -n "$available_port" ]]; then
                echo -e "${GREEN}Available port: ${NC}$available_port"
            else
                error "No available ports found"
                exit 1
            fi
            ;;
        --config)
            echo "Port configuration file: $PORT_CONFIG"
            if [[ -f "$PORT_CONFIG" ]]; then
                echo -e "${GREEN}File exists${NC}"
            else
                echo -e "${YELLOW}File does not exist${NC}"
            fi
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi