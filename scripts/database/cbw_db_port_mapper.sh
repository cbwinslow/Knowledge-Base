#!/usr/bin/env bash
#===============================================================================
# ██████╗  █████╗ ██████╗      ██████╗ ██╗   ██╗███████╗██████╗ ██╗██████╗ ████████╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝ ██║   ██║██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
# ██║  ██║███████║██████╔╝    ██║  ███╗██║   ██║█████╗  ██████╔╝██║██████╔╝   ██║   
# ██║  ██║██╔══██║██╔═══╝     ██║   ██║██║   ██║██╔══╝  ██╔══██╗██║██╔═══╝    ██║   
# ██████╔╝██║  ██║██║         ╚██████╔╝╚██████╔╝███████╗██████╔╝██║██║        ██║   
# ╚═════╝ ╚═╝  ╚═╝╚═╝          ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝        ╚═╝   
#===============================================================================
# File: cbw_db_port_mapper.sh
# Description: Database-based port mapping utility for CBW services
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

# Logging functions
info() { echo -e \"${GREEN}[INFO]${NC} $*\"; }
warn() { echo -e \"${YELLOW}[WARN]${NC} $*\"; }
error() { echo -e \"${RED}[ERROR]${NC} $*\"; }

print_header() {
    echo -e \"${BLUE}===============================================================================${NC}\"
    echo -e \"${BLUE}CBW Database Port Mapper Utility${NC}\"
    echo -e \"${BLUE}===============================================================================${NC}\"
    echo
}

# Database configuration
DB_HOST=\"localhost\"
DB_PORT=\"5433\"  # Our non-conflicting PostgreSQL port
DB_NAME=\"cbw_infra\"
DB_USER=\"postgres\"
DB_PASS=\"postgres\"

# Function to check database connection
check_db_connection() {
    if ! command -v psql >/dev/null 2>&1; then
        error \"PostgreSQL client (psql) not installed\"
        return 1
    fi
    
    if ! PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -p \"$DB_PORT\" -U \"$DB_USER\" -d \"$DB_NAME\" -c \"SELECT 1;\" >/dev/null 2>&1; then
        error \"Cannot connect to PostgreSQL database\"
        echo \"Please ensure:\"
        echo \"1. PostgreSQL is running on $DB_HOST:$DB_PORT\"
        echo \"2. Database '$DB_NAME' exists\"
        echo \"3. User '$DB_USER' has access\"
        return 1
    fi
    
    return 0
}

# Function to get port by service name
get_port() {
    local service_name=$1
    
    if ! check_db_connection; then
        # Fallback to default ports
        case $(echo \"$service_name\" | tr '[:lower:]' '[:upper:]') in
            GRAFANA) echo \"3001\" ;;
            PROMETHEUS) echo \"9091\" ;;
            CADVISOR) echo \"8081\" ;;
            LOKI) echo \"3100\" ;;
            PROMTAIL) echo \"9080\" ;;
            NODE_EXPORTER) echo \"9100\" ;;
            DCGM_EXPORTER) echo \"9400\" ;;
            POSTGRESQL) echo \"5433\" ;;
            QDRANT_HTTP) echo \"6333\" ;;
            QDRANT_GRPC) echo \"6334\" ;;
            MONGODB) echo \"27018\" ;;
            OPENSEARCH) echo \"9200\" ;;
            OPENSEARCH_MONITORING) echo \"9600\" ;;
            RABBITMQ) echo \"5672\" ;;
            RABBITMQ_MANAGEMENT) echo \"15672\" ;;
            KONG_PROXY) echo \"8000\" ;;
            KONG_PROXY_SSL) echo \"8443\" ;;
            KONG_ADMIN) echo \"8001\" ;;
            KONG_ADMIN_SSL) echo \"8444\" ;;
            NETDATA) echo \"19999\" ;;
            *) echo \"0\" ;;
        esac
        return 1
    fi
    
    local port=$(PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -p \"$DB_PORT\" -U \"$DB_USER\" -d \"$DB_NAME\" -t -c \"SELECT get_port_by_service('$service_name');\" 2>/dev/null)
    
    if [[ -n \"$port\" ]] && [[ \"$port\" != \"0\" ]]; then
        echo \"$port\" | xargs  # trim whitespace
    else
        # Fallback to default ports
        case $(echo \"$service_name\" | tr '[:lower:]' '[:upper:]') in
            GRAFANA) echo \"3001\" ;;
            PROMETHEUS) echo \"9091\" ;;
            CADVISOR) echo \"8081\" ;;
            LOKI) echo \"3100\" ;;
            PROMTAIL) echo \"9080\" ;;
            NODE_EXPORTER) echo \"9100\" ;;
            DCGM_EXPORTER) echo \"9400\" ;;
            POSTGRESQL) echo \"5433\" ;;
            QDRANT_HTTP) echo \"6333\" ;;
            QDRANT_GRPC) echo \"6334\" ;;
            MONGODB) echo \"27018\" ;;
            OPENSEARCH) echo \"9200\" ;;
            OPENSEARCH_MONITORING) echo \"9600\" ;;
            RABBITMQ) echo \"5672\" ;;
            RABBITMQ_MANAGEMENT) echo \"15672\" ;;
            KONG_PROXY) echo \"8000\" ;;
            KONG_PROXY_SSL) echo \"8443\" ;;
            KONG_ADMIN) echo \"8001\" ;;
            KONG_ADMIN_SSL) echo \"8444\" ;;
            NETDATA) echo \"19999\" ;;
            *) echo \"0\" ;;
        esac
    fi
}

# Function to set port for a service
set_port() {
    local service_name=$1
    local port_number=$2
    local service_type=${3:-\"GENERAL\"}
    local description=${4:-\"\"}
    
    if ! check_db_connection; then
        error \"Cannot connect to database to set port\"
        return 1
    fi
    
    # Validate port number
    if ! [[ \"$port_number\" =~ ^[0-9]+$ ]] || [[ \"$port_number\" -lt 1 ]] || [[ \"$port_number\" -gt 65535 ]]; then
        error \"Invalid port number: $port_number\"
        return 1
    fi
    
    # Check if port is available
    if ! is_port_available \"$port_number\"; then
        error \"Port $port_number is already in use by another active service\"
        return 1
    fi
    
    # Insert or update port mapping
    if PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -p \"$DB_PORT\" -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
        INSERT INTO cbw_port_mappings (service_name, port_number, service_type, description, is_active) 
        VALUES (UPPER('$service_name'), $port_number, UPPER('$service_type'), '$description', TRUE)
        ON CONFLICT (service_name) 
        DO UPDATE SET 
            port_number = $port_number, 
            service_type = UPPER('$service_type'), 
            description = '$description',
            updated_at = CURRENT_TIMESTAMP;
    \" >/dev/null 2>&1; then
        error \"Failed to set port for service $service_name\"
        return 1
    fi
    
    echo -e \"${GREEN}Port set successfully: ${NC}$service_name=$port_number\"
    return 0
}

# Function to check if port is available
is_port_available() {
    local port_number=$1
    
    if ! check_db_connection; then
        # Fallback check using netstat/ss
        if command -v ss >/dev/null 2>&1; then
            if ss -tuln | grep -q \":$port_number \"; then
                return 1  # Port in use
            else
                return 0  # Port available
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -tuln | grep -q \":$port_number \"; then
                return 1  # Port in use
            else
                return 0  # Port available
            fi
        else
            # Cannot check, assume available
            return 0
        fi
    fi
    
    local available=$(PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -p \"$DB_PORT\" -U \"$DB_USER\" -d \"$DB_NAME\" -t -c \"SELECT is_port_available($port_number);\" 2>/dev/null)
    
    if [[ \"$available\" == \"t\" ]]; then
        return 0  # Available
    else
        return 1  # Not available
    fi
}

# Function to list all ports
list_ports() {
    echo -e \"${BLUE}-------------------------------------------------------------------------------${NC}\"
    echo -e \"${BLUE}Current Port Mappings${NC}\"
    echo -e \"${BLUE}-------------------------------------------------------------------------------${NC}\"
    
    if ! check_db_connection; then
        error \"Cannot connect to database to list ports\"
        echo -e \"${YELLOW}Using fallback configuration${NC}\"
        
        # Show default ports
        echo -e \"${GREEN}Service${NC}                     ${GREEN}Port${NC}  ${GREEN}Type${NC}\"
        echo -e \"${GREEN}-------${NC}                     ${GREEN}----${NC}  ${GREEN}----${NC}\"
        echo \"GRAFANA                        3001  MONITORING\"
        echo \"PROMETHEUS                     9091  MONITORING\"
        echo \"CADVISOR                       8081  MONITORING\"
        echo \"LOKI                           3100  MONITORING\"
        echo \"PROMTAIL                       9080  MONITORING\"
        echo \"NODE_EXPORTER                  9100  MONITORING\"
        echo \"DCGM_EXPORTER                  9400  MONITORING\"
        echo \"POSTGRESQL                     5433  DATABASE\"
        echo \"QDRANT_HTTP                    6333  DATABASE\"
        echo \"QDRANT_GRPC                    6334  DATABASE\"
        echo \"MONGODB                        27018 DATABASE\"
        echo \"OPENSEARCH                     9200  DATABASE\"
        echo \"OPENSEARCH_MONITORING          9600  DATABASE\"
        echo \"RABBITMQ                       5672  DATABASE\"
        echo \"RABBITMQ_MANAGEMENT            15672 DATABASE\"
        echo \"KONG_PROXY                     8000  API_GATEWAY\"
        echo \"KONG_PROXY_SSL                 8443  API_GATEWAY\"
        echo \"KONG_ADMIN                     8001  API_GATEWAY\"
        echo \"KONG_ADMIN_SSL                 8444  API_GATEWAY\"
        echo \"NETDATA                        19999 MONITORING\"
        return 1
    fi
    
    echo -e \"${GREEN}Service${NC}                     ${GREEN}Port${NC}  ${GREEN}Type${NC}        ${GREEN}Description${NC}\"
    echo -e \"${GREEN}-------${NC}                     ${GREEN}----${NC}  ${GREEN}----${NC}        ${GREEN}-----------${NC}\"
    
    PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -p \"$DB_PORT\" -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
        SELECT 
            rpad(service_name, 30) as service,
            lpad(port_number::text, 6) as port,
            rpad(service_type, 12) as type,
            COALESCE(description, '') as desc
        FROM cbw_active_port_mappings 
        ORDER BY service_type, service_name;
    \" --no-align -t | sed 's/^/  /'
}

# Function to find available port
find_available_port() {
    local start_port=${1:-8000}
    
    # Try to find in database first
    if check_db_connection; then
        # Look for the first available port starting from start_port
        for ((port=start_port; port<=65535; port++)); do
            if is_port_available \"$port\"; then
                echo \"$port\"
                return 0
            fi
        done
    fi
    
    # Fallback to system check
    if command -v ss >/dev/null 2>&1; then
        for ((port=start_port; port<=65535; port++)); do
            if ! ss -tuln | grep -q \":$port \"; then
                echo \"$port\"
                return 0
            fi
        done
    elif command -v netstat >/dev/null 2>&1; then
        for ((port=start_port; port<=65535; port++)); do
            if ! netstat -tuln | grep -q \":$port \"; then
                echo \"$port\"
                return 0
            fi
        done
    else
        # Just return the start port
        echo \"$start_port\"
        return 0
    fi
    
    echo \"\"
    return 1
}

show_usage() {
    echo \"Usage: $0 [OPTIONS]\"
    echo
    echo \"Options:\"
    echo \"  --list              List all port mappings\"
    echo \"  --get <service>     Get port for a specific service\"
    echo \"  --set <service> <port> [type] [description]  Set port for a specific service\"
    echo \"  --check <port>      Check if a port is available\"
    echo \"  --find [start]      Find an available port (starting from start or 8000)\"
    echo \"  --db-status         Show database connection status\"
    echo \"  --help              Show this help message\"
    echo
    echo \"Examples:\"
    echo \"  $0 --list\"
    echo \"  $0 --get GRAFANA\"
    echo \"  $0 --set GRAFANA 3001 MONITORING \\\"Grafana dashboard\\\"\"
    echo \"  $0 --check 3001\"
    echo \"  $0 --find 8000\"
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
            if [[ -z \"${2:-}\" ]]; then
                error \"Service name required for get command\"
                show_usage
                exit 1
            fi
            get_port \"$2\"
            ;;
        --set)
            if [[ -z \"${2:-}\" ]] || [[ -z \"${3:-}\" ]]; then
                error \"Service name and port required for set command\"
                show_usage
                exit 1
            fi
            set_port \"$2\" \"$3\" \"${4:-GENERAL}\" \"${5:-}\"
            ;;
        --check)
            if [[ -z \"${2:-}\" ]]; then
                error \"Port number required for check command\"
                show_usage
                exit 1
            fi
            
            if ! [[ \"$2\" =~ ^[0-9]+$ ]]; then
                error \"Invalid port number: $2\"
                exit 1
            fi
            
            if is_port_available \"$2\"; then
                echo -e \"${GREEN}Port $2 is available${NC}\"
            else
                echo -e \"${YELLOW}Port $2 is in use${NC}\"
            fi
            ;;
        --find)
            local start_port=${2:-8000}
            
            if ! [[ \"$start_port\" =~ ^[0-9]+$ ]]; then
                error \"Invalid start port number: $start_port\"
                exit 1
            fi
            
            local available_port=$(find_available_port \"$start_port\")
            if [[ -n \"$available_port\" ]]; then
                echo -e \"${GREEN}Available port: ${NC}$available_port\"
            else
                error \"No available ports found\"
                exit 1
            fi
            ;;
        --db-status)
            if check_db_connection; then
                echo -e \"${GREEN}Database connection: OK${NC}\"
                echo -e \"${GREEN}Host: ${NC}$DB_HOST:$DB_PORT\"
                echo -e \"${GREEN}Database: ${NC}$DB_NAME\"
                echo -e \"${GREEN}User: ${NC}$DB_USER\"
            else
                echo -e \"${RED}Database connection: FAILED${NC}\"
            fi
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            error \"Unknown option: $1\"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ \"${BASH_SOURCE[0]}\" == \"${0}\" ]]; then
    main \"$@\"
fi