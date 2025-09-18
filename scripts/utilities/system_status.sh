#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗███████╗██████╗      ██╗███████╗████████╗ █████╗ ██████╗ 
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗    ███║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗
# ███████╗██║   ██║███████╗   ██║   █████╗  ██████╔╝    ╚██║███████╗   ██║   ███████║██████╔╝
# ╚════██║██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗     ██║╚════██║   ██║   ██╔══██║██╔══██╗
# ███████║╚██████╔╝███████║   ██║   ███████╗██║  ██║     ██║███████║   ██║   ██║  ██║██║  ██║
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
#===============================================================================
# File: system_status.sh
# Description: Comprehensive system status monitoring tool
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/system_status.log"
TEMP_DIR="/tmp/system_status"

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
    echo -e "${BLUE}System Status Monitor - Comprehensive System Health Check${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

print_section_header() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

print_divider() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Running without root privileges - some checks may be limited"
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

# System information functions
get_system_info() {
    print_section_header "System Information"
    
    echo -e "${GREEN}Hostname:${NC} $(hostname)"
    echo -e "${GREEN}Kernel:${NC} $(uname -r)"
    echo -e "${GREEN}Architecture:${NC} $(uname -m)"
    echo -e "${GREEN}Distribution:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${GREEN}Uptime:${NC} $(uptime -p)"
    echo -e "${GREEN}Last Boot:${NC} $(who -b | awk '{print $3" "$4}')"
    
    # CPU information
    echo
    echo -e "${GREEN}CPU:${NC}"
    echo "  Model: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
    echo "  Cores: $(nproc) ($(lscpu | grep "Thread(s) per core" | cut -d: -f2 | xargs) threads per core)"
    echo "  Frequency: $(lscpu | grep "CPU max MHz" | cut -d: -f2 | xargs) MHz max"
    
    # Load average
    echo
    echo -e "${GREEN}Load Average:${NC}"
    read one five fifteen <<< $(cat /proc/loadavg | awk '{print $1" "$2" "$3}')
    echo "  1 min: $one"
    echo "  5 min: $five" 
    echo "  15 min: $fifteen"
}

get_memory_info() {
    print_section_header "Memory Information"
    
    # RAM information
    echo -e "${GREEN}RAM:${NC}"
    total_mem=$(free -h | grep Mem | awk '{print $2}')
    used_mem=$(free -h | grep Mem | awk '{print $3}')
    free_mem=$(free -h | grep Mem | awk '{print $4}')
    avail_mem=$(free -h | grep Mem | awk '{print $7}')
    
    echo "  Total: $total_mem"
    echo "  Used: $used_mem"
    echo "  Free: $free_mem"
    echo "  Available: $avail_mem"
    
    # Memory usage percentage
    mem_percent=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    if (( $(echo "$mem_percent > 80" | bc -l) )); then
        echo -e "  Usage: ${RED}$mem_percent%${NC} (High)"
    elif (( $(echo "$mem_percent > 60" | bc -l) )); then
        echo -e "  Usage: ${YELLOW}$mem_percent%${NC} (Moderate)"
    else
        echo -e "  Usage: ${GREEN}$mem_percent%${NC} (Normal)"
    fi
    
    # Swap information
    echo
    echo -e "${GREEN}Swap:${NC}"
    total_swap=$(free -h | grep Swap | awk '{print $2}')
    used_swap=$(free -h | grep Swap | awk '{print $3}')
    free_swap=$(free -h | grep Swap | awk '{print $4}')
    
    echo "  Total: $total_swap"
    echo "  Used: $used_swap"
    echo "  Free: $free_swap"
    
    if [[ "$total_swap" != "0B" ]]; then
        swap_percent=$(free | grep Swap | awk '{if ($2 > 0) printf("%.1f", $3/$2 * 100.0); else print "0"}')
        echo -e "  Usage: $swap_percent%"
    fi
}

get_disk_info() {
    print_section_header "Disk Information"
    
    echo -e "${GREEN}Filesystem Usage:${NC}"
    df -h | grep -E '^/dev/' | while read line; do
        filesystem=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        avail=$(echo "$line" | awk '{print $4}')
        percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        
        if [[ $percent -gt 90 ]]; then
            color=$RED
        elif [[ $percent -gt 80 ]]; then
            color=$YELLOW
        else
            color=$GREEN
        fi
        
        printf "%-20s %-10s %-10s %-10s ${color}%3s%%${NC} %-20s\n" \
            "$filesystem" "$size" "$used" "$avail" "$percent" "$mount"
    done
    
    # Inode usage
    echo
    echo -e "${GREEN}Inode Usage:${NC}"
    df -i | grep -E '^/dev/' | while read line; do
        filesystem=$(echo "$line" | awk '{print $1}')
        total=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        avail=$(echo "$line" | awk '{print $4}')
        percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        
        if [[ $percent -gt 90 ]]; then
            color=$RED
        elif [[ $percent -gt 80 ]]; then
            color=$YELLOW
        else
            color=$GREEN
        fi
        
        printf "%-20s %-15s %-15s %-15s ${color}%3s%%${NC} %-20s\n" \
            "$filesystem" "$total" "$used" "$avail" "$percent" "$mount"
    done
}

get_network_info() {
    print_section_header "Network Information"
    
    echo -e "${GREEN}Network Interfaces:${NC}"
    ip -br addr show | grep UP | while read line; do
        interface=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        addresses=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')
        echo "  $interface: $state $addresses"
    done
    
    echo
    echo -e "${GREEN}Active Connections:${NC}"
    echo "  TCP: $(ss -t | wc -l) connections"
    echo "  UDP: $(ss -u | wc -l) connections"
    echo "  Listening: $(ss -l | wc -l) ports"
    
    # Top bandwidth usage (if iftop is available)
    if command -v iftop >/dev/null 2>&1; then
        echo
        echo -e "${GREEN}Top Network Connections (last 10s):${NC}"
        timeout 10s iftop -t -s 10 -L 5 2>/dev/null || echo "  Unable to capture network data"
    fi
}

get_service_status() {
    print_section_header "Service Status"
    
    # Common services to check
    services=("docker" "nginx" "redis-server" "postgresql" "mysql" "apache2" "ssh" "cron" "rsyslog")
    
    echo -e "${GREEN}Critical Services:${NC}"
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service"; then
            if systemctl is-active --quiet "$service"; then
                echo -e "  $service: ${GREEN}RUNNING${NC}"
            else
                echo -e "  $service: ${RED}STOPPED${NC}"
            fi
        else
            echo -e "  $service: ${YELLOW}NOT INSTALLED${NC}"
        fi
    done
    
    # Docker containers
    if command -v docker >/dev/null 2>&1; then
        echo
        echo -e "${GREEN}Docker Containers:${NC}"
        container_count=$(docker ps -q | wc -l)
        if [[ $container_count -gt 0 ]]; then
            echo "  Running containers: $container_count"
            docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | sed "s/^/  /" | tail -n +2
        else
            echo "  No containers running"
        fi
    fi
    
    # Systemd failed units
    echo
    echo -e "${GREEN}Failed Units:${NC}"
    failed_units=$(systemctl --failed --no-legend | wc -l)
    if [[ $failed_units -gt 0 ]]; then
        echo -e "  ${RED}$failed_units units failed:${NC}"
        systemctl --failed --no-legend | sed "s/^/    /"
    else
        echo "  No failed units"
    fi
}

get_process_info() {
    print_section_header "Process Information"
    
    # Top 5 CPU consuming processes
    echo -e "${GREEN}Top 5 CPU Consuming Processes:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        user=$(echo "$line" | awk '{print $1}')
        pid=$(echo "$line" | awk '{print $2}')
        cpu=$(echo "$line" | awk '{print $3}')
        mem=$(echo "$line" | awk '{print $4}')
        command=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-50)
        echo "  PID $pid ($user): ${cpu}% CPU, ${mem}% MEM - $command"
    done
    
    # Top 5 Memory consuming processes
    echo
    echo -e "${GREEN}Top 5 Memory Consuming Processes:${NC}"
    ps aux --sort=-%mem | head -6 | tail -5 | while read line; do
        user=$(echo "$line" | awk '{print $1}')
        pid=$(echo "$line" | awk '{print $2}')
        cpu=$(echo "$line" | awk '{print $3}')
        mem=$(echo "$line" | awk '{print $4}')
        command=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-50)
        echo "  PID $pid ($user): ${mem}% MEM, ${cpu}% CPU - $command"
    done
    
    # Zombie processes
    zombie_count=$(ps aux | awk '$8 ~ /^Z/ { print $2 }' | wc -l)
    if [[ $zombie_count -gt 0 ]]; then
        echo
        echo -e "${GREEN}Zombie Processes:${NC}"
        echo "  Found $zombie_count zombie processes"
        ps aux | awk '$8 ~ /^Z/ { printf "    PID %s (%s)\n", $2, $11 }'
    fi
}

get_security_info() {
    print_section_header "Security Information"
    
    # Firewall status
    echo -e "${GREEN}Firewall Status:${NC}"
    if command -v ufw >/dev/null 2>&1; then
        ufw_status=$(ufw status | head -1)
        echo "  UFW: $ufw_status"
    else
        echo "  UFW: ${YELLOW}Not installed${NC}"
    fi
    
    # SSH information
    echo
    echo -e "${GREEN}SSH Information:${NC}"
    if [[ -f /etc/ssh/sshd_config ]]; then
        port=$(grep -E "^Port " /etc/ssh/sshd_config | awk '{print $2}' | head -1)
        port=${port:-22}
        echo "  SSH Port: $port"
        
        password_auth=$(grep -E "^PasswordAuthentication " /etc/ssh/sshd_config | awk '{print $2}' | head -1)
        password_auth=${password_auth:-yes}
        if [[ "$password_auth" == "yes" ]]; then
            echo "  Password Auth: ${YELLOW}Enabled${NC}"
        else
            echo "  Password Auth: Disabled"
        fi
        
        permit_root=$(grep -E "^PermitRootLogin " /etc/ssh/sshd_config | awk '{print $2}' | head -1)
        permit_root=${permit_root:-yes}
        if [[ "$permit_root" == "yes" ]]; then
            echo "  Root Login: ${YELLOW}Permitted${NC}"
        else
            echo "  Root Login: Not permitted"
        fi
    else
        echo "  SSH Config: ${YELLOW}Not found${NC}"
    fi
    
    # Recent login attempts
    echo
    echo -e "${GREEN}Recent Login Attempts:${NC}"
    if [[ -f /var/log/auth.log ]]; then
        failed_logins=$(grep "Failed password" /var/log/auth.log | tail -5)
        if [[ -n "$failed_logins" ]]; then
            echo "  Recent failed login attempts:"
            echo "$failed_logins" | sed "s/^/    /"
        else
            echo "  No recent failed login attempts"
        fi
    else
        echo "  Auth log: ${YELLOW}Not found${NC}"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all, -a     Show all system information (default)"
    echo "  --system, -s  Show system information only"
    echo "  --memory, -m  Show memory information only"
    echo "  --disk, -d    Show disk information only"
    echo "  --network, -n Show network information only"
    echo "  --services, -S Show service status only"
    echo "  --processes, -p Show process information only"
    echo "  --security, -x Show security information only"
    echo "  --help, -h    Show this help message"
    echo
    echo "Examples:"
    echo "  $0              # Show all information"
    echo "  $0 --memory     # Show memory information only"
    echo "  $0 -d           # Show disk information only"
}

# Main execution
main() {
    # Allow help commands without root
    local command=${1:-"--all"}
    
    if [[ "$command" == "help" ]] || [[ "$command" == "--help" ]] || [[ "$command" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    # Require root for most commands (but allow some without)
    # Only certain commands need root
    if [[ "$command" != "--help" ]] && [[ "$command" != "-h" ]] && [[ "$command" != "help" ]]; then
        check_root
    fi
    create_temp_dir
    
    # Default to showing all information
    local show_all=true
    local show_system=false
    local show_memory=false
    local show_disk=false
    local show_network=false
    local show_services=false
    local show_processes=false
    local show_security=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all|-a)
                show_all=true
                shift
                ;;
            --system|-s)
                show_system=true
                show_all=false
                shift
                ;;
            --memory|-m)
                show_memory=true
                show_all=false
                shift
                ;;
            --disk|-d)
                show_disk=true
                show_all=false
                shift
                ;;
            --network|-n)
                show_network=true
                show_all=false
                shift
                ;;
            --services|-S)
                show_services=true
                show_all=false
                shift
                ;;
            --processes|-p)
                show_processes=true
                show_all=false
                shift
                ;;
            --security|-x)
                show_security=true
                show_all=false
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
    
    print_header
    
    # Show requested information
    if [[ "$show_all" == true ]] || [[ "$show_system" == true ]]; then
        get_system_info
        echo
    fi
    
    if [[ "$show_all" == true ]] || [[ "$show_memory" == true ]]; then
        get_memory_info
        echo
    fi
    
    if [[ "$show_all" == true ]] || [[ "$show_disk" == true ]]; then
        get_disk_info
        echo
    fi
    
    if [[ "$show_all" == true ]] || [[ "$show_network" == true ]]; then
        get_network_info
        echo
    fi
    
    if [[ "$show_all" == true ]] || [[ "$show_services" == true ]]; then
        get_service_status
        echo
    fi
    
    if [[ "$show_all" == true ]] || [[ "$show_processes" == true ]]; then
        get_process_info
        echo
    fi
    
    if [[ "$show_all" == true ]] || [[ "$show_security" == true ]]; then
        get_security_info
        echo
    fi
    
    info "System status check completed"
    echo -e "${BLUE}===============================================================================${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi