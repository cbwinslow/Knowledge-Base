#!/usr/bin/env bash
#===============================================================================
# ███╗   ███╗ █████╗  ██████╗██████╗ ██╗███╗   ██╗ ██████╗     ███████╗ █████╗ ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██╔════╝██╔══██╗██║████╗  ██║██╔════╝     ██╔════╝██╔══██╗██║████╗  ██║
# ██╔████╔██║███████║██║     ██████╔╝██║██╔██╗ ██║██║  ███╗    █████╗  ███████║██║██╔██╗ ██║
# ██║╚██╔╝██║██╔══██║██║     ██╔══██╗██║██║╚██╗██║██║   ██║    ██╔══╝  ██╔══██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝    ██║     ██║  ██║██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
#===============================================================================
# File: cbw_maintenance.sh
# Description: Maintenance script for CBW infrastructure
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
    echo -e "${BLUE}CBW Infrastructure Maintenance${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Function to backup Docker volumes
backup_volumes() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Backing Up Docker Volumes${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create backup directory
    local backup_dir="/var/backups/cbw/volumes/$(date +%Y%m%d_%H%M%S)"
    info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Get all CBW volumes
    docker volume ls --format '{{.Name}}' | grep -E "^(grafana|prometheus|pg|qdrant|mongo|opensearch|loki)" | while read -r volume; do
        info "Backing up volume: $volume"
        docker run --rm \
            -v "$volume":/data \
            -v "$backup_dir":/backup \
            alpine tar czf "/backup/$volume.tar.gz" -C /data .
    done
    
    info "Volume backup completed to: $backup_dir"
}

# Function to backup system configuration
backup_configuration() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Backing Up System Configuration${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local backup_dir="/var/backups/cbw/config/$(date +%Y%m%d_%H%M%S)"
    info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup important directories
    local config_dirs=(
        "/etc/cbw"
        "/var/lib/cbw"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "Backing up configuration directory: $dir"
            tar czf "$backup_dir/$(basename "$dir").tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")"
        else
            warn "Configuration directory does not exist: $dir"
        fi
    done
    
    # Backup port database
    if [[ -f "/home/cbwinslow/.cbw_port_database.json" ]]; then
        info "Backing up port database"
        cp "/home/cbwinslow/.cbw_port_database.json" "$backup_dir/port_database.json"
    fi
    
    info "Configuration backup completed to: $backup_dir"
}

# Function to cleanup old backups
cleanup_backups() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Cleaning Up Old Backups${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local backup_root="/var/backups/cbw"
    local keep_days=${1:-30}
    
    if [[ -d "$backup_root" ]]; then
        info "Removing backups older than $keep_days days"
        find "$backup_root" -type d -mtime +$keep_days -delete 2>/dev/null || true
    else
        warn "Backup root directory does not exist: $backup_root"
    fi
    
    info "Old backup cleanup completed"
}

# Function to check system resources
check_resources() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking System Resources${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check disk space
    info "Disk space usage:"
    df -h | grep -v tmpfs | (head -1 && grep -E "(cbw|docker|var|home)")
    
    # Check memory usage
    info "Memory usage:"
    free -h
    
    # Check CPU usage
    info "CPU usage (top 5):"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6
    
    # Check Docker resources
    if command -v docker >/dev/null 2>&1; then
        info "Docker resource usage:"
        docker system df -v
    fi
}

# Function to prune Docker resources
prune_docker() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Pruning Docker Resources${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        info "Pruning unused Docker resources"
        docker system prune -f
        docker volume prune -f
    else
        warn "Docker not available"
    fi
}

# Function to restart failed services
restart_failed_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Restarting Failed Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        # Get failed containers
        docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(Exited|Dead)" | while read -r line; do
            local container=$(echo "$line" | awk '{print $1}')
            local status=$(echo "$line" | awk '{print $2}')
            
            if [[ -n "$container" ]]; then
                warn "Container $container is in $status state"
                info "Attempting to restart container: $container"
                docker start "$container" || error "Failed to restart container: $container"
            fi
        done
    else
        warn "Docker not available"
    fi
}

# Function to update and restart services
update_services() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Updating and Restarting Services${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        # Pull latest images
        info "Pulling latest Docker images"
        docker images --format "table {{.Repository}}\t{{.Tag}}" | grep -v "<none>" | tail -n +2 | while read -r line; do
            local repo=$(echo "$line" | awk '{print $1}')
            local tag=$(echo "$line" | awk '{print $2}')
            if [[ -n "$repo" && -n "$tag" ]]; then
                docker pull "$repo:$tag" || warn "Failed to pull image: $repo:$tag"
            fi
        done
        
        # Restart containers to use updated images
        info "Restarting containers to use updated images"
        docker ps --format '{{.Names}}' | while read -r container; do
            if [[ -n "$container" ]]; then
                info "Restarting container: $container"
                docker restart "$container"
            fi
        done
    else
        warn "Docker not available"
    fi
}

# Function to rotate logs
rotate_logs() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Rotating Logs${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Rotate CBW logs
    if [[ -d "/var/log/cbw" ]]; then
        info "Rotating CBW logs"
        find /var/log/cbw -name "*.log" -mtime +7 -exec gzip {} \;
    fi
    
    # Run logrotate if available
    if command -v logrotate >/dev/null 2>&1; then
        info "Running logrotate"
        logrotate -f /etc/logrotate.d/cbw 2>/dev/null || true
    fi
    
    info "Log rotation completed"
}

# Function to check security
check_security() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking Security${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check firewall status
    if command -v ufw >/dev/null 2>&1; then
        info "Firewall status:"
        ufw status verbose | head -10
    else
        warn "UFW not available"
    fi
    
    # Check SSH security
    info "SSH security:"
    if [[ -f "/etc/ssh/sshd_config" ]]; then
        grep -E "^(PasswordAuthentication|PermitRootLogin)" /etc/ssh/sshd_config || echo "SSH configuration not found"
    fi
    
    # Check Fail2Ban status
    if systemctl is-active --quiet fail2ban; then
        info "Fail2Ban: ${GREEN}RUNNING${NC}"
    else
        warn "Fail2Ban: ${YELLOW}NOT RUNNING${NC}"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all               Run all maintenance tasks (default)"
    echo "  --backup            Backup volumes and configuration"
    echo "  --cleanup           Cleanup old backups"
    echo "  --resources         Check system resources"
    echo "  --prune             Prune Docker resources"
    echo "  --restart           Restart failed services"
    echo "  --update            Update and restart services"
    echo "  --logs              Rotate logs"
    echo "  --security          Check security"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --backup"
    echo "  $0 --cleanup"
    echo "  $0 --resources --prune"
}

main() {
    print_header
    
    # Parse arguments
    local run_all=false
    local run_backup=false
    local run_cleanup=false
    local run_resources=false
    local run_prune=false
    local run_restart=false
    local run_update=false
    local run_logs=false
    local run_security=false
    
    if [[ $# -eq 0 ]]; then
        run_all=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --all)
                    run_all=true
                    shift
                    ;;
                --backup)
                    run_backup=true
                    shift
                    ;;
                --cleanup)
                    run_cleanup=true
                    shift
                    ;;
                --resources)
                    run_resources=true
                    shift
                    ;;
                --prune)
                    run_prune=true
                    shift
                    ;;
                --restart)
                    run_restart=true
                    shift
                    ;;
                --update)
                    run_update=true
                    shift
                    ;;
                --logs)
                    run_logs=true
                    shift
                    ;;
                --security)
                    run_security=true
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
    if [[ "$run_all" == true ]] || [[ "$run_backup" == true ]]; then
        if ! backup_volumes; then
            error "Failed to backup Docker volumes"
        fi
        
        if ! backup_configuration; then
            error "Failed to backup system configuration"
        fi
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_cleanup" == true ]]; then
        cleanup_backups
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_resources" == true ]]; then
        check_resources
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_prune" == true ]]; then
        prune_docker
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_restart" == true ]]; then
        restart_failed_services
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_update" == true ]]; then
        update_services
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_logs" == true ]]; then
        rotate_logs
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_security" == true ]]; then
        check_security
    fi
    
    echo
    info "CBW maintenance completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi