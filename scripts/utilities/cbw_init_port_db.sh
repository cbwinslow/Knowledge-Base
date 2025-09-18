#!/usr/bin/env bash
#===============================================================================
# ██████╗ ██████╗ ███████╗██████╗ ██╗      █████╗ ██╗   ██╗
# ██╔══██╗██╔══██╗██╔════╝██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝
# ██████╔╝██████╔╝█████╗  ██████╔╝██║     ███████║ ╚████╔╝ 
# ██╔══██╗██╔═══╝ ██╔══╝  ██╔══██╗██║     ██╔══██║  ╚██╔╝  
# ██████╔╝██║     ███████╗██████╔╝███████╗██║  ██║   ██║   
# ╚═════╝ ╚═╝     ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝   
#===============================================================================
# File: cbw_init_port_db.sh
# Description: Initialize PostgreSQL database for CBW port mapping
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
    echo -e "${BLUE}Initializing CBW Port Mapping Database${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

# Database configuration
DB_HOST="localhost"
DB_PORT="5433"  # Our non-conflicting port
DB_NAME="cbw_infra"
DB_USER="postgres"
DB_PASS="postgres"

# Function to check if PostgreSQL is accessible
check_postgres_access() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Checking PostgreSQL Access${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Try to connect to PostgreSQL
    if PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}PostgreSQL connection successful${NC}"
        echo -e "${GREEN}Host: ${NC}$DB_HOST:$DB_PORT"
        echo -e "${GREEN}User: ${NC}$DB_USER"
        return 0
    else
        error "Cannot connect to PostgreSQL at $DB_HOST:$DB_PORT"
        echo "Please ensure PostgreSQL is running on port $DB_PORT"
        echo "You can start it with: docker run -d --name pg -p $DB_PORT:5432 -e POSTGRES_PASSWORD=$DB_PASS postgres:16"
        return 1
    fi
}

# Function to create database if it doesn't exist
create_database() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Database${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if database exists
    if PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';" | grep -q "1"; then
        echo -e "${GREEN}Database $DB_NAME already exists${NC}"
    else
        echo -e "${YELLOW}Creating database $DB_NAME${NC}"
        if PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"; then
            echo -e "${GREEN}Database $DB_NAME created successfully${NC}"
        else
            error "Failed to create database $DB_NAME"
            return 1
        fi
    fi
    
    return 0
}

# Function to initialize schema
init_schema() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Initializing Schema${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    local schema_file="/home/cbwinslow/cbw_port_mapping_schema.sql"
    
    # Check if schema file exists
    if [[ ! -f "$schema_file" ]]; then
        error "Schema file not found: $schema_file"
        return 1
    fi
    
    echo -e "${YELLOW}Applying schema from $schema_file${NC}"
    
    # Apply schema
    if PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$schema_file"; then
        echo -e "${GREEN}Schema applied successfully${NC}"
    else
        error "Failed to apply schema"
        return 1
    fi
    
    return 0
}

# Function to verify schema
verify_schema() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Verifying Schema${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if table exists
    if PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM cbw_port_mappings;" >/dev/null 2>&1; then
        echo -e "${GREEN}Port mappings table exists${NC}"
        
        # Count records
        local count=$(PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM cbw_port_mappings;")
        echo -e "${GREEN}Records in port mappings table: ${NC}$count"
        
        # Show sample records
        echo -e "${BLUE}Sample port mappings:${NC}"
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT service_name, port_number, service_type FROM cbw_port_mappings ORDER BY service_type, service_name LIMIT 10;" | sed 's/^/  /'
    else
        error "Port mappings table does not exist"
        return 1
    fi
    
    return 0
}

# Function to test database functions
test_functions() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Testing Database Functions${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Test get_port_by_service function
    echo -e "${YELLOW}Testing get_port_by_service function${NC}"
    local grafana_port=$(PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT get_port_by_service('GRAFANA');")
    echo -e "${GREEN}GRAFANA port: ${NC}$grafana_port"
    
    # Test is_port_available function
    echo -e "${YELLOW}Testing is_port_available function${NC}"
    local port_check=$(PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT is_port_available(3001);")
    echo -e "${GREEN}Port 3001 available: ${NC}$port_check"
    
    # Test view
    echo -e "${YELLOW}Testing active port mappings view${NC}"
    echo -e "${BLUE}Active port mappings:${NC}"
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT service_name, port_number, service_type FROM cbw_active_port_mappings ORDER BY service_type, service_name LIMIT 5;" | sed 's/^/  /'
    
    return 0
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --check         Check PostgreSQL access only"
    echo "  --create-db     Create database only"
    echo "  --init-schema   Initialize schema only"
    echo "  --verify        Verify schema only"
    echo "  --test          Test database functions only"
    echo "  --all           Run all initialization steps (default)"
    echo "  --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --check"
    echo "  $0 --create-db"
    echo "  $0 --init-schema"
    echo "  $0 --all"
}

main() {
    print_header
    
    # Parse arguments
    local check_only=false
    local create_db_only=false
    local init_schema_only=false
    local verify_only=false
    local test_only=false
    
    if [[ $# -eq 0 ]]; then
        check_only=true
        create_db_only=true
        init_schema_only=true
        verify_only=true
        test_only=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --check)
                    check_only=true
                    shift
                    ;;
                --create-db)
                    create_db_only=true
                    shift
                    ;;
                --init-schema)
                    init_schema_only=true
                    shift
                    ;;
                --verify)
                    verify_only=true
                    shift
                    ;;
                --test)
                    test_only=true
                    shift
                    ;;
                --all)
                    check_only=true
                    create_db_only=true
                    init_schema_only=true
                    verify_only=true
                    test_only=true
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
    if [[ "$check_only" == true ]]; then
        if ! check_postgres_access; then
            error "PostgreSQL access check failed"
            exit 1
        fi
    fi
    
    if [[ "$create_db_only" == true ]]; then
        if ! create_database; then
            error "Database creation failed"
            exit 1
        fi
    fi
    
    if [[ "$init_schema_only" == true ]]; then
        if ! init_schema; then
            error "Schema initialization failed"
            exit 1
        fi
    fi
    
    if [[ "$verify_only" == true ]]; then
        if ! verify_schema; then
            error "Schema verification failed"
            exit 1
        fi
    fi
    
    if [[ "$test_only" == true ]]; then
        if ! test_functions; then
            error "Function testing failed"
            exit 1
        fi
    fi
    
    echo
    info "CBW port mapping database initialization completed successfully!"
    echo "Database: $DB_NAME"
    echo "Host: $DB_HOST:$DB_PORT"
    echo "User: $DB_USER"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi