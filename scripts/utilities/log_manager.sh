#!/usr/bin/env bash
#===============================================================================
# ██╗      ██████╗  ██████╗ ███████╗    ███╗   ███╗ ██████╗ ███╗   ███╗███████╗███╗   ██╗████████╗
# ██║     ██╔═══██╗██╔════╝ ██╔════╝    ████╗ ████║██╔═══██╗████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
# ██║     ██║   ██║██║  ███╗█████╗      ██╔████╔██║██║   ██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
# ██║     ██║   ██║██║   ██║██╔══╝      ██║╚██╔╝██║██║   ██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
# ███████╗╚██████╔╝╚██████╔╝███████╗    ██║ ╚═╝ ██║╚██████╔╝██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
# ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
#===============================================================================
# File: log_manager.sh
# Description: Comprehensive log management and search tool
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/log_manager.log"
TEMP_DIR="/tmp/log_manager"
LOG_DIRS=("/var/log" "/tmp")
SEARCH_RESULTS_FILE="$TEMP_DIR/search_results.txt"

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
    echo -e "${BLUE}Log Manager - Comprehensive Log Management and Search Tool${NC}"
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
        warn "Running without root privileges - access to some logs may be limited"
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

# Log management functions
list_log_files() {
    local directory=${1:-"/var/log"}
    local pattern=${2:-"*"}
    
    print_section_header "Log Files in $directory"
    
    if [[ ! -d "$directory" ]]; then
        error "Directory $directory does not exist"
        return 1
    fi
    
    echo -e "${GREEN}Size       Modified              File${NC}"
    print_divider
    
    find "$directory" -name "$pattern" -type f 2>/dev/null | while read -r file; do
        if [[ -r "$file" ]]; then
            size=$(du -h "$file" 2>/dev/null | cut -f1)
            modified=$(stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1)
            printf "%-10s %-20s %-50s\n" "$size" "$modified" "$file"
        fi
    done | sort -k3
    
    echo
    local count=$(find "$directory" -name "$pattern" -type f 2>/dev/null | wc -l)
    info "Found $count log files matching pattern '$pattern'"
}

search_in_logs() {
    local search_term=$1
    local directory=${2:-"/var/log"}
    local max_lines=${3:-50}
    
    if [[ -z "$search_term" ]]; then
        error "Search term is required"
        return 1
    fi
    
    print_section_header "Searching for '$search_term' in $directory"
    
    > "$SEARCH_RESULTS_FILE"  # Clear previous results
    
    local found_count=0
    
    find "$directory" -name "*.log" -type f 2>/dev/null | while read -r file; do
        if [[ -r "$file" ]]; then
            # Search in the file
            if grep -l "$search_term" "$file" >/dev/null 2>&1; then
                local file_matches=$(grep -c "$search_term" "$file" 2>/dev/null || echo 0)
                if [[ $file_matches -gt 0 ]]; then
                    echo -e "${GREEN}Found $file_matches matches in: $file${NC}"
                    echo "=== $file ===" >> "$SEARCH_RESULTS_FILE"
                    
                    # Show context lines around matches
                    grep -n -A 2 -B 2 "$search_term" "$file" 2>/dev/null | head -n "$max_lines" >> "$SEARCH_RESULTS_FILE"
                    echo "" >> "$SEARCH_RESULTS_FILE"
                    
                    found_count=$((found_count + file_matches))
                fi
            fi
        fi
    done
    
    if [[ $found_count -gt 0 ]]; then
        echo
        echo -e "${GREEN}Search Results:${NC}"
        print_divider
        cat "$SEARCH_RESULTS_FILE" | head -n 100
        if [[ $(wc -l < "$SEARCH_RESULTS_FILE") -gt 100 ]]; then
            echo -e "${YELLOW}... (showing first 100 lines, full results in $SEARCH_RESULTS_FILE)${NC}"
        fi
        info "Found $found_count matches for '$search_term'"
    else
        echo -e "${YELLOW}No matches found for '$search_term'${NC}"
    fi
}

tail_logs() {
    local log_file=$1
    local lines=${2:-20}
    
    if [[ -z "$log_file" ]]; then
        error "Log file path is required"
        return 1
    fi
    
    if [[ ! -f "$log_file" ]]; then
        error "Log file $log_file does not exist"
        return 1
    fi
    
    if [[ ! -r "$log_file" ]]; then
        error "Log file $log_file is not readable"
        return 1
    fi
    
    print_section_header "Tailing $log_file (last $lines lines)"
    
    tail -n "$lines" "$log_file" | while read -r line; do
        # Colorize common log levels
        if [[ $line =~ [Ee]rror|ERROR|ERR ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $line =~ [Ww]arning|WARN|WARNING ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ $line =~ [Ii]nfo|INFO ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ $line =~ [Dd]ebug|DEBUG ]]; then
            echo -e "${PURPLE}$line${NC}"
        else
            echo "$line"
        fi
    done
}

monitor_logs() {
    local log_file=$1
    
    if [[ -z "$log_file" ]]; then
        error "Log file path is required"
        return 1
    fi
    
    if [[ ! -f "$log_file" ]]; then
        error "Log file $log_file does not exist"
        return 1
    fi
    
    if [[ ! -r "$log_file" ]]; then
        error "Log file $log_file is not readable"
        return 1
    fi
    
    print_header
    echo -e "${GREEN}Monitoring $log_file (Ctrl+C to stop)${NC}"
    print_divider
    
    tail -f "$log_file" | while read -r line; do
        # Colorize common log levels
        if [[ $line =~ [Ee]rror|ERROR|ERR ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $line =~ [Ww]arning|WARN|WARNING ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ $line =~ [Ii]nfo|INFO ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ $line =~ [Dd]ebug|DEBUG ]]; then
            echo -e "${PURPLE}$line${NC}"
        else
            echo "$line"
        fi
    done
}

analyze_log_errors() {
    local log_file=$1
    local hours=${2:-24}
    
    if [[ -z "$log_file" ]]; then
        error "Log file path is required"
        return 1
    fi
    
    if [[ ! -f "$log_file" ]]; then
        error "Log file $log_file does not exist"
        return 1
    fi
    
    if [[ ! -r "$log_file" ]]; then
        error "Log file $log_file is not readable"
        return 1
    fi
    
    print_section_header "Error Analysis for $log_file (Last $hours hours)"
    
    # Calculate timestamp for N hours ago
    local since_timestamp=$(date -d "$hours hours ago" +"%Y-%m-%d %H:%M:%S")
    
    echo -e "${GREEN}Searching for errors since: $since_timestamp${NC}"
    echo
    
    # Find error patterns
    local error_count=0
    local warning_count=0
    local critical_count=0
    
    # Count different types of errors
    error_count=$(grep -i "error" "$log_file" | grep -v -i "warning" | wc -l)
    warning_count=$(grep -i "warning" "$log_file" | wc -l)
    critical_count=$(grep -i -E "critical|fatal|severe" "$log_file" | wc -l)
    
    echo -e "${RED}Critical/Fatal Errors: $critical_count${NC}"
    echo -e "${RED}Other Errors: $error_count${NC}"
    echo -e "${YELLOW}Warnings: $warning_count${NC}"
    echo
    
    # Show sample critical errors
    if [[ $critical_count -gt 0 ]]; then
        echo -e "${RED}Sample Critical Errors:${NC}"
        grep -i -E "critical|fatal|severe" "$log_file" | tail -n 5 | sed "s/^/  /"
        echo
    fi
    
    # Show sample regular errors
    if [[ $error_count -gt 0 ]]; then
        echo -e "${RED}Sample Errors:${NC}"
        grep -i "error" "$log_file" | grep -v -i "warning" | tail -n 5 | sed "s/^/  /"
        echo
    fi
    
    # Show sample warnings
    if [[ $warning_count -gt 0 ]]; then
        echo -e "${YELLOW}Sample Warnings:${NC}"
        grep -i "warning" "$log_file" | tail -n 5 | sed "s/^/  /"
        echo
    fi
    
    info "Log analysis complete"
}

rotate_log() {
    local log_file=$1
    local max_size=${2:-"100M"}
    
    if [[ -z "$log_file" ]]; then
        error "Log file path is required"
        return 1
    fi
    
    if [[ ! -f "$log_file" ]]; then
        error "Log file $log_file does not exist"
        return 1
    fi
    
    local current_size=$(du -h "$log_file" | cut -f1)
    echo -e "${GREEN}Current size of $log_file: $current_size${NC}"
    
    # Check if rotation is needed
    local size_bytes=$(du -b "$log_file" | cut -f1)
    local max_bytes=$(numfmt --from=iec "$max_size")
    
    if [[ $size_bytes -gt $max_bytes ]]; then
        echo -e "${YELLOW}Log file exceeds $max_size, rotating...${NC}"
        
        # Create backup
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="${log_file}.${timestamp}"
        
        if cp "$log_file" "$backup_file"; then
            echo -e "${GREEN}Backup created: $backup_file${NC}"
            
            # Truncate original file
            if truncate -s 0 "$log_file"; then
                echo -e "${GREEN}Log file truncated${NC}
            else
                error "Failed to truncate log file"
                return 1
            fi
        else
            error "Failed to create backup"
            return 1
        fi
    else
        echo -e "${GREEN}Log file size is within limits${NC}"
    fi
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  list [directory] [pattern]      List log files in directory (default: /var/log)"
    echo "  search <term> [dir] [max]       Search for term in logs (default dir: /var/log, max: 50 lines)"
    echo "  tail <file> [lines]             Show last N lines of log file (default: 20)"
    echo "  monitor <file>                  Monitor log file in real-time"
    echo "  analyze <file> [hours]          Analyze errors in log file (default: 24 hours)"
    echo "  rotate <file> [size]            Rotate log file if larger than size (default: 100M)"
    echo "  help                           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 list /var/log *.log"
    echo "  $0 search \"error\" /var/log"
    echo "  $0 tail /var/log/syslog 50"
    echo "  $0 monitor /var/log/nginx/access.log"
    echo "  $0 analyze /var/log/application.log 48"
    echo "  $0 rotate /var/log/large.log 500M"
}

# Main execution
main() {
    # Allow help commands without root
    local command=${1:-"help"}
    
    if [[ "$command" == "help" ]] || [[ "$command" == "--help" ]] || [[ "$command" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    check_root
    create_temp_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        list)
            local dir="${2:-/var/log}"
            local pattern="${3:-*}"
            list_log_files "$dir" "$pattern"
            ;;
        search)
            if [[ -z "${2:-}" ]]; then
                error "Search term required for search command"
                show_usage
                exit 1
            fi
            local term="$2"
            local dir="${3:-/var/log}"
            local max="${4:-50}"
            search_in_logs "$term" "$dir" "$max"
            ;;
        tail)
            if [[ -z "${2:-}" ]]; then
                error "Log file required for tail command"
                show_usage
                exit 1
            fi
            local file="$2"
            local lines="${3:-20}"
            tail_logs "$file" "$lines"
            ;;
        monitor)
            if [[ -z "${2:-}" ]]; then
                error "Log file required for monitor command"
                show_usage
                exit 1
            fi
            local file="$2"
            monitor_logs "$file"
            ;;
        analyze)
            if [[ -z "${2:-}" ]]; then
                error "Log file required for analyze command"
                show_usage
                exit 1
            fi
            local file="$2"
            local hours="${3:-24}"
            analyze_log_errors "$file" "$hours"
            ;;
        rotate)
            if [[ -z "${2:-}" ]]; then
                error "Log file required for rotate command"
                show_usage
                exit 1
            fi
            local file="$2"
            local size="${3:-100M}"
            rotate_log "$file" "$size"
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