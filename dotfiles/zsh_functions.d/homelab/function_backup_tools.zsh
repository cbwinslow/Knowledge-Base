#!/bin/zsh

# =============================================================================
# BACKUP TOOLS (HOMELAB)
# =============================================================================
# System and data backup utilities
# =============================================================================

# Create system backup
backup_system() {
    local backup_dir="${1:-/backup/system}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/system_backup_$timestamp.tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo "💾 Creating system backup..."
    tar -czf "$backup_file" \
        --exclude=/backup \
        --exclude=/tmp \
        --exclude=/var/tmp \
        --exclude=/var/cache \
        --exclude=/proc \
        --exclude=/sys \
        --exclude=/dev \
        --exclude=/run \
        / 2>/dev/null
    
    echo "✅ System backup created: $backup_file"
}

# Backup specific directories
backup_dirs() {
    local dirs=("$@")
    local backup_dir="/backup/dirs"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        echo "Usage: backup_dirs <dir1> <dir2> ..."
        return 1
    fi
    
    mkdir -p "$backup_dir"
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local basename=$(basename "$dir")
            local backup_file="$backup_dir/${basename}_$timestamp.tar.gz"
            echo "💾 Backing up $dir..."
            tar -czf "$backup_file" -C "$(dirname "$dir")" "$basename"
            echo "✅ Backed up: $backup_file"
        else
            echo "⚠️  Directory not found: $dir"
        fi
    done
}

# Backup databases
backup_databases() {
    local backup_dir="/backup/databases"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$backup_dir"
    
    # PostgreSQL
    if command -v psql >/dev/null 2>&1; then
        echo "💾 Backing up PostgreSQL databases..."
        sudo -u postgres pg_dumpall > "$backup_dir/postgres_$timestamp.sql"
        echo "✅ PostgreSQL backup completed"
    fi
    
    # MySQL/MariaDB
    if command -v mysql >/dev/null 2>&1; then
        echo "💾 Backing up MySQL databases..."
        mysqldump --all-databases > "$backup_dir/mysql_$timestamp.sql"
        echo "✅ MySQL backup completed"
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo "❌ Backup file not found: $backup_file"
        return 1
    fi
    
    echo "⚠️  WARNING: This will restore from backup and may overwrite existing data!"
    read -q "REPLY?Are you sure you want to continue? [y/N] "
    echo
    
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "🔄 Restoring from $backup_file..."
        sudo tar -xzf "$backup_file" -C /
        echo "✅ Restore completed"
    else
        echo "❌ Restore cancelled"
    fi
}