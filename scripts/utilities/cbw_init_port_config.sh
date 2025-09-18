#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗ ██████╗ ███╗   ██╗████████╗ █████╗ ██╗     ██╗     
# ██╔════╝██║██╔════╝ ████╗  ██║╚══██╔══╝██╔══██╗██║     ██║     
# █████╗  ██║██║  ███╗██╔██╗ ██║   ██║   ███████║██║     ██║     
# ██╔══╝  ██║██║   ██║██║╚██╗██║   ██║   ██╔══██║██║     ██║     
# ██║     ██║╚██████╔╝██║ ╚████║   ██║   ██║  ██║███████╗███████╗
# ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#===============================================================================
# File: cbw_init_port_config.sh
# Description: Initialize CBW port configuration file
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
    echo -e "${BLUE}Initializing CBW Port Configuration${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Check if we have sudo access
check_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo command not available"
        return 1
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        error "sudo access required but not available"
        return 1
    fi
    
    return 0
}

# Initialize port configuration in /etc
init_etc_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Initializing /etc/cbw-ports.conf${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local etc_config="/etc/cbw-ports.conf"
    
    # Check if file exists and has content
    if [[ -f "$etc_config" ]] && [[ -s "$etc_config" ]]; then
        echo -e "${GREEN}Configuration file already exists and has content: ${NC}$etc_config"
        
        # Show current content
        echo -e "${BLUE}Current content:${NC}"
        cat "$etc_config" | sed 's/^/  /'
        
        # Ask if we should update it
        read -p "Do you want to update it with the latest configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Keeping existing configuration${NC}"
            return 0
        fi
    fi
    
    # Create the configuration content
    local config_content="# CBW Universal Port Mapping Configuration
# Format: SERVICE_NAME=PORT_NUMBER
# This file serves as the single source of truth for all service ports

# Monitoring Services
GRAFANA=3001
PROMETHEUS=9091
CADVISOR=8081
LOKI=3100
PROMTAIL=9080
NODE_EXPORTER=9100
DCGM_EXPORTER=9400

# Database Services
POSTGRESQL=5433
QDRANT_HTTP=6333
QDRANT_GRPC=6334
MONGODB=27018
OPENSEARCH=9200
OPENSEARCH_MONITORING=9600
RABBITMQ=5672
RABBITMQ_MANAGEMENT=15672

# API Gateway Services
KONG_PROXY=8000
KONG_PROXY_SSL=8443
KONG_ADMIN=8001
KONG_ADMIN_SSL=8444

# Additional Services
NETDATA=19999
"
    
    # Create temporary file
    local temp_file=$(mktemp)
    echo "$config_content" > "$temp_file"
    
    # Copy to /etc with sudo
    if sudo cp "$temp_file" "$etc_config"; then
        echo -e "${GREEN}Configuration file created successfully: ${NC}$etc_config"
        
        # Set proper permissions
        sudo chmod 644 "$etc_config"
        sudo chown root:root "$etc_config"
        
        echo -e "${GREEN}Permissions set: ${NC}644 (root:root)"
    else
        error "Failed to create configuration file: $etc_config"
        rm -f "$temp_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    return 0
}

# Sync user config with /etc config
sync_configs() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Syncing configurations${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local user_config="/home/cbwinslow/cbw_port_mapping.conf"
    local etc_config="/etc/cbw-ports.conf"
    
    # Check if /etc config exists and has content
    if [[ -f "$etc_config" ]] && [[ -s "$etc_config" ]]; then
        echo -e "${GREEN}Syncing /etc configuration to user configuration${NC}"
        
        # Copy /etc config to user config
        if sudo cp "$etc_config" "$user_config"; then
            echo -e "${GREEN}Configuration synced successfully${NC}"
        else
            error "Failed to sync configuration"
            return 1
        fi
    else
        echo -e "${YELLOW}/etc configuration not found or empty, using user configuration${NC}"
    fi
    
    return 0
}

show_current_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Current Configuration${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local user_config="/home/cbwinslow/cbw_port_mapping.conf"
    local etc_config="/etc/cbw-ports.conf"
    
    echo -e "${BLUE}User configuration ($user_config):${NC}"
    if [[ -f "$user_config" ]]; then
        if [[ -s "$user_config" ]]; then
            cat "$user_config" | sed 's/^/  /'
        else
            echo -e "  ${YELLOW}(empty)${NC}"
        fi
    else
        echo -e "  ${RED}(file not found)${NC}"
    fi
    
    echo
    echo -e "${BLUE}/etc configuration ($etc_config):${NC}"
    if [[ -f "$etc_config" ]]; then
        if [[ -s "$etc_config" ]]; then
            cat "$etc_config" | sed 's/^/  /'
        else
            echo -e "  ${YELLOW}(empty)${NC}"
        fi
    else
        echo -e "  ${RED}(file not found)${NC}"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --init-etc      Initialize /etc/cbw-ports.conf"
    echo "  --sync          Sync configurations between user and /etc"
    echo "  --show          Show current configurations"
    echo "  --all           Run all initialization steps (default)"
    echo "  --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --init-etc"
    echo "  $0 --sync"
    echo "  $0 --show"
    echo "  $0 --all"
}

main() {
    print_header
    
    # Parse arguments
    local init_etc=false
    local sync=false
    local show=false
    
    if [[ $# -eq 0 ]]; then
        init_etc=true
        sync=true
        show=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --init-etc)
                    init_etc=true
                    shift
                    ;;
                --sync)
                    sync=true
                    shift
                    ;;
                --show)
                    show=true
                    shift
                    ;;
                --all)
                    init_etc=true
                    sync=true
                    show=true
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
    
    # Check sudo access if needed
    if [[ "$init_etc" == true ]] || [[ "$sync" == true ]]; then
        if ! check_sudo; then
            error "Cannot proceed without sudo access"
            exit 1
        fi
    fi
    
    # Execute requested actions
    if [[ "$init_etc" == true ]]; then
        if ! init_etc_config; then
            error "Failed to initialize /etc configuration"
            exit 1
        fi
    fi
    
    if [[ "$sync" == true ]]; then
        if ! sync_configs; then
            error "Failed to sync configurations"
            exit 1
        fi
    fi
    
    if [[ "$show" == true ]]; then
        show_current_config
    fi
    
    echo
    info "Port configuration initialization completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi