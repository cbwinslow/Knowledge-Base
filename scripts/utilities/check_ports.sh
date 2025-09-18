#!/usr/bin/env bash
# check_ports.sh - Check for port conflicts before installing services
set -Eeuo pipefail

LOG="/tmp/CBW-port-check.log"; exec > >(tee -a "$LOG") 2>&1

RED='\033[31m'; GREEN='\033[32m'; YEL='\033[33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }

PORTS_REGISTRY="./tools/PORTS.registry"

check_ports() {
    info "Checking for port conflicts..."
    
    if [ ! -f "$PORTS_REGISTRY" ]; then
        warn "Port registry not found at $PORTS_REGISTRY"
        return 0
    fi
    
    conflicts=0
    while IFS=$'\t' read -r port service; do
        # Skip comments and empty lines
        [[ $port =~ ^#.*$ ]] && continue
        [[ -z $port ]] && continue
        
        if ss -tulpn | grep -q ":$port "; then
            err "Port $port ($service) is already in use!"
            ss -tulpn | grep ":$port " | sed "s/^/  /"
            conflicts=$((conflicts + 1))
        else
            info "Port $port ($service) is free"
        fi
    done < "$PORTS_REGISTRY"
    
    if [ $conflicts -gt 0 ]; then
        err "Found $conflicts port conflicts. Please resolve before proceeding."
        return 1
    else
        info "No port conflicts detected."
        return 0
    fi
}

check_specific_port() {
    local port=$1
    if ss -tulpn | grep -q ":$port "; then
        err "Port $port is in use:"
        ss -tulpn | grep ":$port " | sed "s/^/  /"
        return 1
    else
        info "Port $port is free"
        return 0
    fi
}

# Main execution
case "${1:-}" in
    --port)
        if [ -z "${2:-}" ]; then
            err "Please specify a port to check"
            exit 1
        fi
        check_specific_port "$2"
        ;;
    *)
        check_ports
        ;;
esac