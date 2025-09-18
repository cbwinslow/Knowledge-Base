#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ 
# ██║     ██║   ██║███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗
# ██║     ██║   ██║╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║
# ███████╗╚██████╔╝███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: cbw_simple_port_db.sh
# Description: Simple file-based port database for CBW services
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

# Configuration file
PORT_DB_FILE="/home/cbwinslow/.cbw_port_database.json"

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Simple Port Database${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to initialize database
init_database() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Initializing Port Database${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create database file if it doesn't exist
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        # Create initial database with default ports
        cat > "$PORT_DB_FILE" <<'EOF'
{
  "services": {
    "GRAFANA": {
      "port": 3001,
      "type": "MONITORING",
      "description": "Grafana dashboard",
      "active": true
    },
    "PROMETHEUS": {
      "port": 9091,
      "type": "MONITORING",
      "description": "Prometheus metrics",
      "active": true
    },
    "CADVISOR": {
      "port": 8081,
      "type": "MONITORING",
      "description": "cAdvisor container monitoring",
      "active": true
    },
    "LOKI": {
      "port": 3100,
      "type": "MONITORING",
      "description": "Loki log aggregation",
      "active": true
    },
    "PROMTAIL": {
      "port": 9080,
      "type": "MONITORING",
      "description": "Promtail log shipping",
      "active": true
    },
    "NODE_EXPORTER": {
      "port": 9100,
      "type": "MONITORING",
      "description": "Node exporter metrics",
      "active": true
    },
    "DCGM_EXPORTER": {
      "port": 9400,
      "type": "MONITORING",
      "description": "DCGM GPU metrics",
      "active": true
    },
    "POSTGRESQL": {
      "port": 5433,
      "type": "DATABASE",
      "description": "PostgreSQL database",
      "active": true
    },
    "QDRANT_HTTP": {
      "port": 6333,
      "type": "DATABASE",
      "description": "Qdrant vector database HTTP",
      "active": true
    },
    "QDRANT_GRPC": {
      "port": 6334,
      "type": "DATABASE",
      "description": "Qdrant vector database gRPC",
      "active": true
    },
    "MONGODB": {
      "port": 27018,
      "type": "DATABASE",
      "description": "MongoDB document database",
      "active": true
    },
    "OPENSEARCH": {
      "port": 9200,
      "type": "DATABASE",
      "description": "OpenSearch search engine",
      "active": true
    },
    "OPENSEARCH_MONITORING": {
      "port": 9600,
      "type": "DATABASE",
      "description": "OpenSearch monitoring",
      "active": true
    },
    "RABBITMQ": {
      "port": 5672,
      "type": "DATABASE",
      "description": "RabbitMQ message broker",
      "active": true
    },
    "RABBITMQ_MANAGEMENT": {
      "port": 15672,
      "type": "DATABASE",
      "description": "RabbitMQ management interface",
      "active": true
    },
    "KONG_PROXY": {
      "port": 8000,
      "type": "API_GATEWAY",
      "description": "Kong API proxy",
      "active": true
    },
    "KONG_PROXY_SSL": {
      "port": 8443,
      "type": "API_GATEWAY",
      "description": "Kong API proxy SSL",
      "active": true
    },
    "KONG_ADMIN": {
      "port": 8001,
      "type": "API_GATEWAY",
      "description": "Kong admin API",
      "active": true
    },
    "KONG_ADMIN_SSL": {
      "port": 8444,
      "type": "API_GATEWAY",
      "description": "Kong admin API SSL",
      "active": true
    },
    "NETDATA": {
      "port": 19999,
      "type": "MONITORING",
      "description": "Netdata system monitoring",
      "active": true
    }
  },
  "metadata": {
    "created": "$(date -Iseconds)",
    "version": "1.0"
  }
}
EOF
        echo -e "${GREEN}Port database initialized: ${NC}$PORT_DB_FILE"
    else
        echo -e "${GREEN}Port database already exists: ${NC}$PORT_DB_FILE"
    fi
    
    # Validate JSON
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$PORT_DB_FILE" >/dev/null 2>&1; then
            echo -e "${GREEN}Port database validated successfully${NC}"
        else
            error "Port database validation failed"
            return 1
        fi
    else
        warn "jq not available, skipping JSON validation"
    fi
    
    return 0
}

# Function to get port by service name
get_port() {
    local service_name=$1
    
    # Check if database file exists
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        # Fallback to default ports
        case $(echo "$service_name" | tr '[:lower:]' '[:upper:]') in
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
        return 0
    fi
    
    # Try to get port from database
    if command -v jq >/dev/null 2>&1; then
        local port=$(jq -r --arg service "$service_name" '.services[$service].port // "0"' "$PORT_DB_FILE" 2>/dev/null)
        if [[ "$port" != "0" ]] && [[ -n "$port" ]]; then
            echo "$port"
            return 0
        fi
    else
        # Fallback to grep if jq is not available
        local port=$(grep -A 5 "\"$service_name\":" "$PORT_DB_FILE" 2>/dev/null | grep '"port"' | sed -E 's/.*"port"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
        if [[ -n "$port" ]]; then
            echo "$port"
            return 0
        fi
    fi
    
    # Fallback to default ports
    case $(echo "$service_name" | tr '[:lower:]' '[:upper:]') in
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

# Function to set port for a service
set_port() {
    local service_name=$1
    local port_number=$2
    local service_type=${3:-"GENERAL"}
    local description=${4:-""}
    
    # Validate port number
    if ! [[ "$port_number" =~ ^[0-9]+$ ]] || [[ "$port_number" -lt 1 ]] || [[ "$port_number" -gt 65535 ]]; then
        error "Invalid port number: $port_number"
        return 1
    fi
    
    # Check if database file exists
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        init_database || return 1
    fi
    
    # Update database
    if command -v jq >/dev/null 2>&1; then
        # Create backup
        cp "$PORT_DB_FILE" "${PORT_DB_FILE}.bak" 2>/dev/null || true
        
        # Update with jq
        jq --arg service "$service_name" \
           --arg port "$port_number" \
           --arg type "$service_type" \
           --arg desc "$description" \
           '.services[$service] = {
             "port": ($port | tonumber),
             "type": $type,
             "description": $desc,
             "active": true
           }' "$PORT_DB_FILE" > "${PORT_DB_FILE}.tmp" && mv "${PORT_DB_FILE}.tmp" "$PORT_DB_FILE"
        
        echo -e "${GREEN}Port set successfully: ${NC}$service_name=$port_number"
    else
        error "jq is required to modify the database"
        return 1
    fi
    
    return 0
}

# Function to list all ports
list_ports() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Current Port Mappings${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if database file exists
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        echo -e "${YELLOW}Database not initialized, showing default ports${NC}"
        echo -e "${GREEN}Service${NC}                     ${GREEN}Port${NC}  ${GREEN}Type${NC}        ${GREEN}Description${NC}"
        echo -e "${GREEN}-------${NC}                     ${GREEN}----${NC}  ${GREEN}----${NC}        ${GREEN}-----------${NC}"
        echo "GRAFANA                        3001  MONITORING    Grafana dashboard"
        echo "PROMETHEUS                     9091  MONITORING    Prometheus metrics"
        echo "CADVISOR                       8081  MONITORING    cAdvisor container monitoring"
        echo "LOKI                           3100  MONITORING    Loki log aggregation"
        echo "PROMTAIL                       9080  MONITORING    Promtail log shipping"
        echo "NODE_EXPORTER                  9100  MONITORING    Node exporter metrics"
        echo "DCGM_EXPORTER                  9400  MONITORING    DCGM GPU metrics"
        echo "POSTGRESQL                     5433  DATABASE      PostgreSQL database"
        echo "QDRANT_HTTP                    6333  DATABASE      Qdrant vector database HTTP"
        echo "QDRANT_GRPC                    6334  DATABASE      Qdrant vector database gRPC"
        echo "MONGODB                        27018 DATABASE      MongoDB document database"
        echo "OPENSEARCH                     9200  DATABASE      OpenSearch search engine"
        echo "OPENSEARCH_MONITORING          9600  DATABASE      OpenSearch monitoring"
        echo "RABBITMQ                       5672  DATABASE      RabbitMQ message broker"
        echo "RABBITMQ_MANAGEMENT            15672 DATABASE      RabbitMQ management interface"
        echo "KONG_PROXY                     8000  API_GATEWAY   Kong API proxy"
        echo "KONG_PROXY_SSL                 8443  API_GATEWAY   Kong API proxy SSL"
        echo "KONG_ADMIN                     8001  API_GATEWAY   Kong admin API"
        echo "KONG_ADMIN_SSL                 8444  API_GATEWAY   Kong admin API SSL"
        echo "NETDATA                        19999 MONITORING    Netdata system monitoring"
        return 1
    fi
    
    if command -v jq >/dev/null 2>&1; then
        echo -e "${GREEN}Service${NC}                     ${GREEN}Port${NC}  ${GREEN}Type${NC}        ${GREEN}Description${NC}"
        echo -e "${GREEN}-------${NC}                     ${GREEN}----${NC}  ${GREEN}----${NC}        ${GREEN}-----------${NC}"
        
        jq -r '.services | to_entries[] | 
               select(.value.active == true) |
               "\(.key)|\(.value.port)|\(.value.type)|\(.value.description)"' "$PORT_DB_FILE" | \
        while IFS='|' read -r service port type desc; do
            printf "%-30s %-6s %-12s %s\n" "$service" "$port" "$type" "$desc"
        done
    else
        # Fallback to grep if jq is not available
        echo -e "${GREEN}Service${NC}                     ${GREEN}Port${NC}  ${GREEN}Type${NC}        ${GREEN}Description${NC}"
        echo -e "${GREEN}-------${NC}                     ${GREEN}----${NC}  ${GREEN}----${NC}        ${GREEN}-----------${NC}"
        
        grep -E '"[A-Z_]+":' "$PORT_DB_FILE" | \
        sed -E 's/[[:space:]]*"([A-Z_]+)":.*/\1/' | \
        while read -r service; do
            local port=$(grep -A 5 "\"$service\":" "$PORT_DB_FILE" | grep '"port"' | sed -E 's/.*"port"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
            local type=$(grep -A 5 "\"$service\":" "$PORT_DB_FILE" | grep '"type"' | sed -E 's/.*"type"[[:space:]]*:"([^"]+)".*/\1/')
            local desc=$(grep -A 5 "\"$service\":" "$PORT_DB_FILE" | grep '"description"' | sed -E 's/.*"description"[[:space:]]*:"([^"]+)".*/\1/')
            printf "%-30s %-6s %-12s %s\n" "$service" "$port" "$type" "$desc"
        done
    fi
}

# Function to check if port is available
is_port_available() {
    local port_number=$1
    
    # Check if database file exists
    if [[ ! -f "$PORT_DB_FILE" ]]; then
        # Fallback to system check
        if command -v ss >/dev/null 2>&1; then
            if ss -tuln | grep -q ":$port_number "; then
                return 1  # Port in use
            else
                return 0  # Port available
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -tuln | grep -q ":$port_number "; then
                return 1  # Port in use
            else
                return 0  # Port available
            fi
        else
            # Cannot check, assume available
            return 0
        fi
    fi
    
    # Check in database
    if command -v jq >/dev/null 2>&1; then
        local count=$(jq --arg port "$port_number" '[.services[] | select(.active == true and .port == ($port | tonumber))] | length' "$PORT_DB_FILE")
        if [[ "$count" -eq 0 ]]; then
            return 0  # Available
        else
            return 1  # Not available
        fi
    else
        # Fallback to grep
        if grep -q "\"port\"[[:space:]]*:[[:space:]]*$port_number" "$PORT_DB_FILE" 2>/dev/null; then
            return 1  # Not available
        else
            return 0  # Available
        fi
    fi
}

# Function to find available port
find_available_port() {
    local start_port=${1:-8000}
    
    # Try to find in database first
    for ((port=start_port; port<=65535; port++)); do
        if is_port_available "$port"; then
            echo "$port"
            return 0
        fi
    done
    
    # Fallback to system check
    if command -v ss >/dev/null 2>&1; then
        for ((port=start_port; port<=65535; port++)); do
            if ! ss -tuln | grep -q ":$port "; then
                echo "$port"
                return 0
            fi
        done
    elif command -v netstat >/dev/null 2>&1; then
        for ((port=start_port; port<=65535; port++)); do
            if ! netstat -tuln | grep -q ":$port "; then
                echo "$port"
                return 0
            fi
        done
    else
        # Just return the start port
        echo "$start_port"
        return 0
    fi
    
    echo ""
    return 1
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --init              Initialize port database"
    echo "  --list              List all port mappings"
    echo "  --get <service>     Get port for a specific service"
    echo "  --set <service> <port> [type] [description]  Set port for a specific service"
    echo "  --check <port>      Check if a port is available"
    echo "  --find [start]      Find an available port (starting from start or 8000)"
    echo "  --status            Show database status"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --init"
    echo "  $0 --list"
    echo "  $0 --get GRAFANA"
    echo "  $0 --set GRAFANA 3001 MONITORING \"Grafana dashboard\""
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
        --init)
            init_database
            ;;
        --list)
            list_ports
            ;;
        --get)
            if [[ -z "${2:-}" ]]; then
                error "Service name required for get command"
                show_usage
                exit 1
            fi
            get_port "$2"
            ;;
        --set)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                error "Service name and port required for set command"
                show_usage
                exit 1
            fi
            
            if ! [[ "$3" =~ ^[0-9]+$ ]] || [[ "$3" -lt 1 ]] || [[ "$3" -gt 65535 ]]; then
                error "Invalid port number: $3"
                exit 1
            fi
            
            set_port "$2" "$3" "${4:-GENERAL}" "${5:-}"
            ;;
        --check)
            if [[ -z "${2:-}" ]]; then
                error "Port number required for check command"
                show_usage
                exit 1
            fi
            
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                error "Invalid port number: $2"
                exit 1
            fi
            
            if is_port_available "$2"; then
                echo -e "${GREEN}Port $2 is available${NC}"
            else
                echo -e "${YELLOW}Port $2 is in use${NC}"
            fi
            ;;
        --find)
            local start_port=${2:-8000}
            
            if ! [[ "$start_port" =~ ^[0-9]+$ ]]; then
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
        --status)
            if [[ -f "$PORT_DB_FILE" ]]; then
                echo -e "${GREEN}Port database: ${NC}$PORT_DB_FILE"
                echo -e "${GREEN}Status: ${NC}Initialized"
                
                if command -v jq >/dev/null 2>&1; then
                    local count=$(jq '.services | length' "$PORT_DB_FILE")
                    echo -e "${GREEN}Services: ${NC}$count"
                fi
            else
                echo -e "${YELLOW}Port database: ${NC}$PORT_DB_FILE"
                echo -e "${YELLOW}Status: ${NC}Not initialized"
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