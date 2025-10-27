#!/usr/bin/env bash

#######################################
# Production-Ready Database Backup Script
# 
# This script demonstrates best practices for:
# - Error handling
# - Logging
# - Configuration management
# - Cleanup
# - Notifications
#######################################

set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="${LOG_FILE:-/var/log/db-backup.log}"
readonly CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/backup.conf}"

# Default values
BACKUP_DIR="${BACKUP_DIR:-/var/backups/database}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-}"
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-}"
DRY_RUN="${DRY_RUN:-false}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#######################################
# Logging functions
#######################################

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "${GREEN}$*${NC}"
}

log_warn() {
    log "WARN" "${YELLOW}$*${NC}"
}

log_error() {
    log "ERROR" "${RED}$*${NC}"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "DEBUG" "${BLUE}$*${NC}"
    fi
}

#######################################
# Error handling
#######################################

error_exit() {
    log_error "$1"
    send_notification "FAILED" "$1"
    exit "${2:-1}"
}

cleanup() {
    log_debug "Running cleanup..."
    # Remove temporary files if any
    if [[ -n "${TEMP_FILE:-}" && -f "${TEMP_FILE}" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

trap cleanup EXIT
trap 'error_exit "Script interrupted" 130' INT
trap 'error_exit "Script terminated" 143' TERM

#######################################
# Configuration and validation
#######################################

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        log_warn "Config file not found: $CONFIG_FILE, using defaults"
    fi
}

check_dependencies() {
    local deps=(pg_dump gzip date find)
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error_exit "Missing required commands: ${missing[*]}"
    fi
}

validate_config() {
    if [[ -z "$DB_NAME" ]]; then
        error_exit "DB_NAME is required"
    fi
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory"
    fi
    
    if [[ ! -w "$BACKUP_DIR" ]]; then
        error_exit "Backup directory is not writable: $BACKUP_DIR"
    fi
}

#######################################
# Notification functions
#######################################

send_notification() {
    local status=$1
    local message=$2
    
    if [[ -z "$NOTIFICATION_EMAIL" ]]; then
        return 0
    fi
    
    local subject="Database Backup ${status}: ${DB_NAME}"
    
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL"
        log_debug "Notification sent to $NOTIFICATION_EMAIL"
    else
        log_warn "mail command not found, skipping notification"
    fi
}

#######################################
# Backup functions
#######################################

create_backup() {
    local db_name=$1
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="${BACKUP_DIR}/${db_name}_${timestamp}.sql"
    local compressed_file="${backup_file}.gz"
    
    log_info "Starting backup of database: $db_name"
    
    # Set password if provided
    if [[ -n "${PGPASSWORD:-}" ]]; then
        export PGPASSWORD
    fi
    
    # Create backup
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create backup: $compressed_file"
        return 0
    fi
    
    log_debug "Running pg_dump..."
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$db_name" > "$backup_file" 2>> "$LOG_FILE"; then
        log_info "Database dump created: $backup_file"
    else
        error_exit "Failed to create database dump"
    fi
    
    # Compress backup
    log_debug "Compressing backup..."
    if gzip "$backup_file"; then
        log_info "Backup compressed: $compressed_file"
        
        # Get file size
        local size
        size=$(du -h "$compressed_file" | cut -f1)
        log_info "Backup size: $size"
        
        return 0
    else
        error_exit "Failed to compress backup"
    fi
}

cleanup_old_backups() {
    local db_name=$1
    local retention=$2
    
    log_info "Cleaning up backups older than $retention days"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would remove old backups"
        find "$BACKUP_DIR" -name "${db_name}_*.sql.gz" -mtime +"$retention" -ls 2>/dev/null || true
        return 0
    fi
    
    local count
    count=$(find "$BACKUP_DIR" -name "${db_name}_*.sql.gz" -mtime +"$retention" -type f 2>/dev/null | wc -l)
    
    if [[ $count -gt 0 ]]; then
        find "$BACKUP_DIR" -name "${db_name}_*.sql.gz" -mtime +"$retention" -type f -delete
        log_info "Removed $count old backup(s)"
    else
        log_info "No old backups to remove"
    fi
}

verify_backup() {
    local backup_file=$1
    
    log_info "Verifying backup: $backup_file"
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    # Check if file is a valid gzip file
    if gzip -t "$backup_file" 2>/dev/null; then
        log_info "Backup verification successful"
        return 0
    else
        error_exit "Backup verification failed: file may be corrupted"
    fi
}

#######################################
# Report generation
#######################################

generate_report() {
    local status=$1
    local backup_file=$2
    
    cat << EOF

========================================
Database Backup Report
========================================
Status:          $status
Database:        $DB_NAME
Host:            $DB_HOST:$DB_PORT
Backup File:     $backup_file
Backup Location: $BACKUP_DIR
Retention:       $RETENTION_DAYS days
Timestamp:       $(date '+%Y-%m-%d %H:%M:%S')
========================================

EOF
}

#######################################
# Help and usage
#######################################

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Production-ready database backup script with retention management.

OPTIONS:
    -h, --help              Show this help message
    -d, --database NAME     Database name to backup (required)
    -H, --host HOST         Database host (default: localhost)
    -p, --port PORT         Database port (default: 5432)
    -u, --user USER         Database user (default: postgres)
    -b, --backup-dir DIR    Backup directory (default: /var/backups/database)
    -r, --retention DAYS    Retention period in days (default: 7)
    -e, --email EMAIL       Notification email
    -n, --dry-run           Perform dry run without making changes
    -v, --verbose           Enable verbose output
    -c, --config FILE       Configuration file

ENVIRONMENT VARIABLES:
    PGPASSWORD              PostgreSQL password
    DB_NAME                 Database name
    DB_HOST                 Database host
    DB_PORT                 Database port
    DB_USER                 Database user
    BACKUP_DIR              Backup directory
    RETENTION_DAYS          Retention period
    NOTIFICATION_EMAIL      Notification email
    DRY_RUN                 Dry run mode (true/false)
    DEBUG                   Debug mode (true/false)

EXAMPLES:
    # Basic backup
    $SCRIPT_NAME -d mydb

    # Backup with custom retention
    $SCRIPT_NAME -d mydb -r 30

    # Dry run
    $SCRIPT_NAME -d mydb --dry-run

    # Use config file
    $SCRIPT_NAME -c /etc/backup.conf

    # With notification
    $SCRIPT_NAME -d mydb -e admin@example.com

For more information, see the documentation.
EOF
}

#######################################
# Argument parsing
#######################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--database)
                DB_NAME="$2"
                shift 2
                ;;
            -H|--host)
                DB_HOST="$2"
                shift 2
                ;;
            -p|--port)
                DB_PORT="$2"
                shift 2
                ;;
            -u|--user)
                DB_USER="$2"
                shift 2
                ;;
            -b|--backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -r|--retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -e|--email)
                NOTIFICATION_EMAIL="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                DEBUG=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
}

#######################################
# Main function
#######################################

main() {
    log_info "Starting database backup script"
    log_info "Script: $SCRIPT_NAME"
    
    # Load configuration
    load_config
    
    # Parse command line arguments (override config)
    parse_arguments "$@"
    
    # Validate configuration
    validate_config
    
    # Check dependencies
    check_dependencies
    
    # Create backup
    create_backup "$DB_NAME"
    
    # Find the latest backup
    local latest_backup
    latest_backup=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -n "$latest_backup" ]]; then
        # Verify backup
        verify_backup "$latest_backup"
        
        # Cleanup old backups
        cleanup_old_backups "$DB_NAME" "$RETENTION_DAYS"
        
        # Generate report
        local report
        report=$(generate_report "SUCCESS" "$latest_backup")
        log_info "$report"
        
        # Send notification
        send_notification "SUCCESS" "$report"
        
        log_info "Backup completed successfully"
    else
        error_exit "No backup file found after backup operation"
    fi
}

# Run main function
main "$@"
