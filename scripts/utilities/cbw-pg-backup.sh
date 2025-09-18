#!/bin/bash
# CBW PostgreSQL Backup Script

# Configuration
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="/var/log/postgresql/cbw-pg-backup.log"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting PostgreSQL backup"

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    log "ERROR: PostgreSQL is not running"
    exit 1
fi

# Get list of databases
DATABASES=$(sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | tr -d ' ')

if [ -z "$DATABASES" ]; then
    log "ERROR: No databases found"
    exit 1
fi

log "Found databases: $DATABASES"

# Backup each database
for db in $DATABASES; do
    if [ "$db" != "postgres" ] && [ "$db" != "template0" ] && [ "$db" != "template1" ]; then
        log "Backing up database: $db"
        
        # Create backup file
        BACKUP_FILE="$BACKUP_DIR/${db}_backup_$DATE.sql"
        
        # Perform backup
        if sudo -u postgres pg_dump "$db" > "$BACKUP_FILE"; then
            # Compress the backup
            gzip "$BACKUP_FILE"
            log "Successfully backed up $db to ${BACKUP_FILE}.gz"
        else
            log "ERROR: Failed to backup database $db"
        fi
    fi
done

# Also create a cluster backup
CLUSTER_BACKUP="$BACKUP_DIR/full_cluster_backup_$DATE.tar"
if sudo -u postgres pg_basebackup -D "$BACKUP_DIR/basebackup_$DATE" -Ft -z -P; then
    log "Successfully created cluster backup"
else
    log "WARNING: Failed to create cluster backup"
fi

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete 2>/dev/null
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null

log "PostgreSQL backup completed"