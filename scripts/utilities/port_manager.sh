#!/usr/bin/env bash
#===============================================================================
# ██████╗  ██████╗ ███████╗████████╗██╗   ██╗██████╗      ██╗██████╗  █████╗ ██╗   ██╗ █████╗ ███╗   ███╗
# ██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██║   ██║██╔══██╗    ███║██╔══██╗██╔══██╗██║   ██║██╔══██╗████╗ ████║
# ██████╔╝██║   ██║███████╗   ██║   ██║   ██║██████╔╝    ╚██║██████╔╝███████║██║   ██║███████║██╔████╔██║
# ██╔═══╝ ██║   ██║╚════██║   ██║   ██║   ██║██╔══██╗     ██║██╔══██╗██╔══██║╚██╗ ██╔╝██╔══██║██║╚██╔╝██║
# ██║     ╚██████╔╝███████║   ██║   ╚██████╔╝██║  ██║     ██║██║  ██║██║  ██║ ╚████╔╝ ██║  ██║██║ ╚═╝ ██║
# ╚═╝      ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚═╝
#===============================================================================
# File: port_manager.sh
# Description: Comprehensive port management and monitoring tool
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/port_manager.log"
PORTS_REGISTRY="/home/cbwinslow/cloudcurio/tools/PORTS.registry"
TEMP_DIR="/tmp/port_manager"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${PURPLE}[DEBUG]${NC} $*" | tee -a "$LOG_FILE" || true; }

# Utility functions
print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Port Manager - System Port Monitoring and Management${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

print_divider() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
        exit 1
    fi
}

create_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

cleanup() {
    rm -rf "$TEMP_DIR"
    debug "Cleaned up temporary files"
}

trap cleanup EXIT

# Port management functions
list_all_ports() {
    print_header
    info "Registered Ports in System"
    print_divider
    
    if [[ ! -f "$PORTS_REGISTRY" ]]; then
        warn "Port registry not found at $PORTS_REGISTRY"
        return 1
    fi
    
    # Create a formatted table
    printf "%-8s %-30s %-15s %-20s\n" "PORT" "SERVICE" "STATUS" "PROCESS"
    print_divider
    
    while IFS=$'\t' read -r port service || [[ -n "$port" ]]; do
        # Skip comments and empty lines
        [[ $port =~ ^[[:space:]]*#.*$ ]] && continue
        [[ -z $port ]] && continue
        [[ $port =~ ^[[:space:]]*$ ]] && continue
        
        # Trim whitespace
        port=$(echo "$port" | xargs)
        service=$(echo "$service" | xargs)
        
        # Check if port is in use
        if ss -tulpn | grep -q ":$port "; then
            status="IN USE"
            process=$(ss -tulpn | grep ":$port " | awk '{print $NF}' | head -1)
            printf "%-8s %-30s %-15s %-20s\n" "$port" "$service" "${GREEN}$status${NC}" "$process"
        else
            status="FREE"
            printf "%-8s %-30s %-15s %-20s\n" "$port" "$service" "${YELLOW}$status${NC}" "-"
        fi
    done < "$PORTS_REGISTRY"
    
    echo
    info "Total registered ports: $(grep -v '^#' "$PORTS_REGISTRY" | grep -v '^$' | wc -l)"
}

check_specific_port() {
    local port=$1
    
    if [[ -z "$port" ]]; then
        error "Port number is required"
        return 1
    fi
    
    print_header
    info "Checking Port: $port"
    print_divider
    
    if ss -tulpn | grep -q ":$port "; then
        echo -e "${GREEN}Port $port is IN USE${NC}"
        echo
        info "Process Information:"
        ss -tulpn | grep ":$port " | sed "s/^/  /"
        
        # Get more detailed process info
        pid=$(ss -tulpn | grep ":$port " | awk '{print $NF}' | grep -oE '[0-9]+' | head -1)
        if [[ -n "$pid" ]]; then
            echo
            info "Detailed Process Information:"
            echo "  PID: $pid"
            echo "  Command: $(ps -p "$pid" -o comm= 2>/dev/null || echo 'Unknown')"
            echo "  User: $(ps -p "$pid" -o user= 2>/dev/null || echo 'Unknown')"
            echo "  Memory: $(ps -p "$pid" -o rss= 2>/dev/null || echo 'Unknown') KB"
        fi
    else
        echo -e "${YELLOW}Port $port is FREE${NC}"
    fi
}

check_port_conflicts() {
    print_header
    info "Checking for Port Conflicts"
    print_divider
    
    if [[ ! -f "$PORTS_REGISTRY" ]]; then
        warn "Port registry not found at $PORTS_REGISTRY"
        return 1
    fi
    
    conflicts=0
    free_ports=0
    
    while IFS=$'\t' read -r port service || [[ -n "$port" ]]; do
        # Skip comments and empty lines
        [[ $port =~ ^[[:space:]]*#.*$ ]] && continue
        [[ -z $port ]] && continue
        [[ $port =~ ^[[:space:]]*$ ]] && continue
        
        # Trim whitespace
        port=$(echo "$port" | xargs)
        service=$(echo "$service" | xargs)
        
        if ss -tulpn | grep -q ":$port "; then
            error "CONFLICT: Port $port ($service) is already in use"
            ss -tulpn | grep ":$port " | sed "s/^/    /"
            conflicts=$((conflicts + 1))
        else
            debug "Port $port ($service) is free"
            free_ports=$((free_ports + 1))
        fi
    done < "$PORTS_REGISTRY"
    
    echo
    if [[ $conflicts -gt 0 ]]; then
        error "Found $conflicts port conflicts that need to be resolved"
        return 1
    else
        info "All registered ports are free (${free_ports} ports checked)"
        return 0
    fi
}

reserve_port() {
    local port=$1
    local service=$2
    
    if [[ -z "$port" ]] || [[ -z "$service" ]]; then
        error "Port and service name are required"
        return 1
    fi
    
    # Validate port number
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        error "Invalid port number: $port"
        return 1
    fi
    
    # Check if port is already reserved
    if [[ -f "$PORTS_REGISTRY" ]] && grep -E "^[[:space:]]*$port[[:space:]]" "$PORTS_REGISTRY" >/dev/null 2>&1; then
        warn "Port $port is already reserved"
        grep -E "^[[:space:]]*$port[[:space:]]" "$PORTS_REGISTRY"
        return 1
    fi
    
    # Check if port is in use
    if ss -tulpn | grep -q ":$port "; then
        error "Port $port is currently in use and cannot be reserved"
        ss -tulpn | grep ":$port " | sed "s/^/  /"
        return 1
    fi
    
    # Reserve the port
    echo -e "${port}\t${service}" >> "$PORTS_REGISTRY"
    sort -n -o "$PORTS_REGISTRY" "$PORTS_REGISTRY"
    info "Reserved port $port for service $service"
}

release_port() {
    local port=$1
    
    if [[ -z "$port" ]]; then
        error "Port number is required"
        return 1
    fi
    
    if [[ ! -f "$PORTS_REGISTRY" ]]; then
        warn "Port registry not found"
        return 1
    fi
    
    # Check if port is reserved
    if ! grep -E "^[[:space:]]*$port[[:space:]]" "$PORTS_REGISTRY" >/dev/null 2>&1; then
        warn "Port $port is not reserved in the registry"
        return 1
    fi
    
    # Remove the port from registry
    grep -vE "^[[:space:]]*$port[[:space:]]" "$PORTS_REGISTRY" > "${PORTS_REGISTRY}.tmp"
    mv "${PORTS_REGISTRY}.tmp" "$PORTS_REGISTRY"
    info "Released port $port from registry"
}

scan_open_ports() {
    local port_range=${1:-"1-10000"}
    
    print_header
    info "Scanning Open Ports (Range: $port_range)"
    print_divider
    
    echo -e "${BLUE}Protocol   Port       Service    Process${NC}"
    print_divider
    
    # Scan TCP ports
    ss -tuln | grep LISTEN | while read line; do
        port=$(echo "$line" | awk '{print $4}' | cut -d':' -f2)
        if [[ -n "$port" ]] && [[ "$port" =~ ^[0-9]+$ ]]; then
            service=$(echo "$line" | awk '{print $NF}')
            protocol="TCP"
            printf "%-10s %-10s %-10s %-20s\n" "$protocol" "$port" "${service}" "$(ps -p ${service##*pid=} -o comm= 2>/dev/null || echo 'Unknown')"
        fi
    done
    
    # Scan UDP ports
    ss -tuln | grep udp | while read line; do
        port=$(echo "$line" | awk '{print $4}' | cut -d':' -f2)
        if [[ -n "$port" ]] && [[ "$port" =~ ^[0-9]+$ ]]; then
            service=$(echo "$line" | awk '{print $NF}')
            protocol="UDP"
            printf "%-10s %-10s %-10s %-20s\n" "$protocol" "$port" "${service}" "$(ps -p ${service##*pid=} -o comm= 2>/dev/null || echo 'Unknown')"
        fi
    done
    
    echo
    info "Scan complete"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  list                  List all registered ports and their status"
    echo "  check <port>          Check specific port status"
    echo "  conflicts             Check for port conflicts"
    echo "  reserve <port> <name> Reserve a port for a service"
    echo "  release <port>        Release a reserved port"
    echo "  scan [range]          Scan open ports (default: 1-10000)"
    echo "  help                  Show this help message"
    echo
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 check 8080"
    echo "  $0 conflicts"
    echo "  $0 reserve 8081 myservice"
    echo "  $0 release 8081"
    echo "  $0 scan 8000-9000"
}

# Main execution
main() {
    # Allow help commands without root
    local command=${1:-"help"}
    
    if [[ "$command" == "help" ]] || [[ "$command" == "--help" ]] || [[ "$command" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    # Require root for all other commands
    check_root
    create_temp_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        list)
            list_all_ports
            ;;
        check)
            if [[ -z "${2:-}" ]]; then
                error "Port number required for check command"
                show_usage
                exit 1
            fi
            check_specific_port "$2"
            ;;
        conflicts)
            check_port_conflicts
            ;;
        reserve)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                error "Port and service name required for reserve command"
                show_usage
                exit 1
            fi
            reserve_port "$2" "$3"
            ;;
        release)
            if [[ -z "${2:-}" ]]; then
                error "Port number required for release command"
                show_usage
                exit 1
            fi
            release_port "$2"
            ;;
        scan)
            local range="${2:-1-10000}"
            scan_open_ports "$range"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi