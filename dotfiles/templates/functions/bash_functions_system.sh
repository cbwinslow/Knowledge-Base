#!/bin/bash
# System Functions - Template
# Category: System Operations
# Description: Functions for system management, process control, and file operations
# Usage: Source this file in your .bashrc or .zshrc
# Author: Knowledge Base Team
# Last Updated: 2025-11-01

# =============================================================================
# Process Management
# =============================================================================

# Function: sys_list_processes
# Description: List all running processes with details
# Usage: sys_list_processes [filter]
# Arguments:
#   $1 - Optional process name filter
# Returns: List of processes
# Example: sys_list_processes nginx
sys_list_processes() {
    if [[ $# -gt 0 ]]; then
        ps aux | grep -i "$1" | grep -v grep
    else
        ps aux
    fi
}

# Function: sys_kill_port
# Description: Kill process running on specific port
# Usage: sys_kill_port <port>
# Arguments:
#   $1 - Port number
# Returns: 0 on success, 1 on failure
# Example: sys_kill_port 8080
sys_kill_port() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Port number required"
        echo "Usage: sys_kill_port <port>"
        return 1
    fi
    
    local port="$1"
    
    echo "Finding process on port $port..."
    local pid=$(lsof -ti:"$port")
    
    if [[ -z "$pid" ]]; then
        echo "No process found on port $port"
        return 1
    fi
    
    echo "Killing process $pid on port $port"
    kill -9 "$pid"
}

# Function: sys_kill_process_by_name
# Description: Kill all processes matching name
# Usage: sys_kill_process_by_name <process_name>
# Arguments:
#   $1 - Process name
# Returns: 0 on success
# Example: sys_kill_process_by_name nginx
sys_kill_process_by_name() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Process name required"
        echo "Usage: sys_kill_process_by_name <process_name>"
        return 1
    fi
    
    local process_name="$1"
    
    echo "Killing all processes matching: $process_name"
    pkill -f "$process_name"
}

# =============================================================================
# Disk and File Management
# =============================================================================

# Function: sys_disk_usage
# Description: Show disk usage in human-readable format
# Usage: sys_disk_usage [path]
# Arguments:
#   $1 - Optional path (default: /)
# Returns: Disk usage information
# Example: sys_disk_usage /home
sys_disk_usage() {
    local path="${1:-/}"
    df -h "$path"
}

# Function: sys_disk_usage_sorted
# Description: Show top directories by disk usage
# Usage: sys_disk_usage_sorted [path] [limit]
# Arguments:
#   $1 - Optional path (default: .)
#   $2 - Optional number of results (default: 10)
# Returns: Sorted disk usage
# Example: sys_disk_usage_sorted /var/log 20
sys_disk_usage_sorted() {
    local path="${1:-.}"
    local limit="${2:-10}"
    
    echo "Top $limit directories by size in $path:"
    du -h "$path" 2>/dev/null | sort -hr | head -n "$limit"
}

# Function: sys_find_large_files
# Description: Find large files in directory
# Usage: sys_find_large_files [path] [size]
# Arguments:
#   $1 - Optional path (default: .)
#   $2 - Optional minimum size in MB (default: 100)
# Returns: List of large files
# Example: sys_find_large_files /var/log 50
sys_find_large_files() {
    local path="${1:-.}"
    local size_mb="${2:-100}"
    
    echo "Finding files larger than ${size_mb}MB in $path..."
    find "$path" -type f -size "+${size_mb}M" -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr
}

# Function: sys_backup_file
# Description: Create timestamped backup of file
# Usage: sys_backup_file <file>
# Arguments:
#   $1 - File to backup
# Returns: 0 on success, 1 on failure
# Example: sys_backup_file /etc/nginx/nginx.conf
sys_backup_file() {
    if [[ $# -lt 1 ]]; then
        echo "Error: File path required"
        echo "Usage: sys_backup_file <file>"
        return 1
    fi
    
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file"
        return 1
    fi
    
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_file"
    echo "Backup created: $backup_file"
}

# Function: sys_backup_directory
# Description: Create compressed backup of directory
# Usage: sys_backup_directory <directory> [destination]
# Arguments:
#   $1 - Directory to backup
#   $2 - Optional destination directory (default: .)
# Returns: 0 on success, 1 on failure
# Example: sys_backup_directory /var/www/html /backups
sys_backup_directory() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Directory path required"
        echo "Usage: sys_backup_directory <directory> [destination]"
        return 1
    fi
    
    local source_dir="$1"
    local dest_dir="${2:-.}"
    
    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Directory not found: $source_dir"
        return 1
    fi
    
    local dir_name=$(basename "$source_dir")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${dest_dir}/${dir_name}_backup_${timestamp}.tar.gz"
    
    echo "Creating backup: $backup_file"
    tar -czf "$backup_file" "$source_dir"
    echo "Backup complete: $backup_file"
}

# =============================================================================
# Network Operations
# =============================================================================

# Function: sys_check_port
# Description: Check if a port is open
# Usage: sys_check_port <host> <port>
# Arguments:
#   $1 - Host address
#   $2 - Port number
# Returns: 0 if port is open, 1 if closed
# Example: sys_check_port localhost 8080
sys_check_port() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Host and port required"
        echo "Usage: sys_check_port <host> <port>"
        return 1
    fi
    
    local host="$1"
    local port="$2"
    
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo "Port $port on $host is OPEN"
        return 0
    else
        echo "Port $port on $host is CLOSED"
        return 1
    fi
}

# Function: sys_list_open_ports
# Description: List all open ports on the system
# Usage: sys_list_open_ports
# Returns: List of open ports
sys_list_open_ports() {
    echo "Listing open ports..."
    if command -v netstat &> /dev/null; then
        netstat -tuln | grep LISTEN
    elif command -v ss &> /dev/null; then
        ss -tuln | grep LISTEN
    else
        echo "Error: Neither netstat nor ss command found"
        return 1
    fi
}

# Function: sys_get_public_ip
# Description: Get public IP address
# Usage: sys_get_public_ip
# Returns: Public IP address
sys_get_public_ip() {
    echo "Fetching public IP address..."
    curl -s ifconfig.me
    echo
}

# Function: sys_get_local_ip
# Description: Get local IP address
# Usage: sys_get_local_ip
# Returns: Local IP address
sys_get_local_ip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ipconfig getifaddr en0
    else
        hostname -I | awk '{print $1}'
    fi
}

# =============================================================================
# System Information
# =============================================================================

# Function: sys_info
# Description: Display system information
# Usage: sys_info
# Returns: System details
sys_info() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
    echo "=== CPU Information ==="
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sysctl -n machdep.cpu.brand_string
    else
        grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs
    fi
    echo ""
    echo "=== Memory Information ==="
    free -h 2>/dev/null || vm_stat
    echo ""
    echo "=== Disk Information ==="
    df -h /
}

# Function: sys_uptime
# Description: Show system uptime and load
# Usage: sys_uptime
# Returns: Uptime information
sys_uptime() {
    uptime
}

# Function: sys_memory_usage
# Description: Show memory usage statistics
# Usage: sys_memory_usage
# Returns: Memory usage details
sys_memory_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vm_stat
    else
        free -h
    fi
}

# Function: sys_cpu_usage
# Description: Show CPU usage
# Usage: sys_cpu_usage
# Returns: CPU usage statistics
sys_cpu_usage() {
    if command -v mpstat &> /dev/null; then
        mpstat 1 1
    else
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " 100 - $1"%"}'
    fi
}

# =============================================================================
# User and Permission Management
# =============================================================================

# Function: sys_list_users
# Description: List all users on the system
# Usage: sys_list_users
# Returns: List of users
sys_list_users() {
    cut -d: -f1 /etc/passwd | sort
}

# Function: sys_list_logged_in_users
# Description: List currently logged in users
# Usage: sys_list_logged_in_users
# Returns: List of logged in users
sys_list_logged_in_users() {
    who
}

# Function: sys_change_file_permissions
# Description: Change file permissions recursively
# Usage: sys_change_file_permissions <path> <permissions>
# Arguments:
#   $1 - Path to file/directory
#   $2 - Permissions (e.g., 755, 644)
# Returns: 0 on success
# Example: sys_change_file_permissions /var/www/html 755
sys_change_file_permissions() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Path and permissions required"
        echo "Usage: sys_change_file_permissions <path> <permissions>"
        return 1
    fi
    
    local path="$1"
    local perms="$2"
    
    echo "Setting permissions $perms on $path..."
    chmod -R "$perms" "$path"
}

# =============================================================================
# Service Management
# =============================================================================

# Function: sys_service_status
# Description: Check status of a system service
# Usage: sys_service_status <service_name>
# Arguments:
#   $1 - Service name
# Returns: Service status
# Example: sys_service_status nginx
sys_service_status() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Service name required"
        echo "Usage: sys_service_status <service_name>"
        return 1
    fi
    
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl status "$service"
    elif command -v service &> /dev/null; then
        service "$service" status
    else
        echo "Error: No service management command found"
        return 1
    fi
}

# Function: sys_service_restart
# Description: Restart a system service
# Usage: sys_service_restart <service_name>
# Arguments:
#   $1 - Service name
# Returns: 0 on success
# Example: sys_service_restart nginx
sys_service_restart() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Service name required"
        echo "Usage: sys_service_restart <service_name>"
        return 1
    fi
    
    local service="$1"
    
    echo "Restarting service: $service"
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart "$service"
    elif command -v service &> /dev/null; then
        sudo service "$service" restart
    else
        echo "Error: No service management command found"
        return 1
    fi
}

# =============================================================================
# Archive Operations
# =============================================================================

# Function: sys_extract
# Description: Extract various archive formats
# Usage: sys_extract <file>
# Arguments:
#   $1 - Archive file
# Returns: 0 on success, 1 on failure
# Example: sys_extract archive.tar.gz
sys_extract() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Archive file required"
        echo "Usage: sys_extract <file>"
        return 1
    fi
    
    if [[ ! -f "$1" ]]; then
        echo "Error: File not found: $1"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *)           echo "Error: Unknown archive format: $1" ;;
    esac
}

# Function: sys_create_tarball
# Description: Create a tarball from directory
# Usage: sys_create_tarball <source> <output>
# Arguments:
#   $1 - Source directory
#   $2 - Output filename
# Returns: 0 on success
# Example: sys_create_tarball /var/www/html website.tar.gz
sys_create_tarball() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Source and output filename required"
        echo "Usage: sys_create_tarball <source> <output>"
        return 1
    fi
    
    local source="$1"
    local output="$2"
    
    echo "Creating tarball: $output"
    tar -czf "$output" "$source"
    echo "Tarball created: $output"
}
