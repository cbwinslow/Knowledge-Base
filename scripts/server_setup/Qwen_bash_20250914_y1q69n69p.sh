#!/bin/bash

# Setup backup system
echo "Setting up backup system..."

# Create backup directories
mkdir -p /opt/backups/{system,docker,configs}

# Install backup tools
apt install -y restic rclone

# Create backup script
cat > /opt/backups/backup.sh << 'EOF'
#!/bin/bash

# Backup script for Proxmox server
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups"
RETENTION_DAYS=30

# Function to backup Docker volumes
backup_docker() {
    echo "Backing up Docker volumes..."
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $BACKUP_DIR/docker:/backup alpine tar czf /backup/docker-volumes-$DATE.tar.gz -C /var/lib/docker/volumes .
}

# Function to backup system configs
backup_configs() {
    echo "Backing up system configurations..."
    tar czf $BACKUP_DIR/configs/system-configs-$DATE.tar.gz -C /etc pve
}

# Function to cleanup old backups
cleanup_old() {
    echo "Cleaning up old backups..."
    find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
}

# Run backup functions
backup_docker
backup_configs
cleanup_old

echo "Backup completed: $DATE"
EOF

chmod +x /opt/backups/backup.sh

# Create cron job for daily backups
echo "0 2 * * * root /opt/backups/backup.sh" > /etc/cron.d/proxmox-backup

# Setup rsync for remote backup (example)
cat > /opt/backups/remote-backup.sh << 'EOF'
#!/bin/bash

# Sync backups to remote server
rsync -avz --delete /opt/backups/ user@remote-server:/backup/proxmox/

# Or use rclone for cloud backup
# rclone sync /opt/backups/ gdrive:proxmox-backups
EOF

chmod +x /opt/backups/remote-backup.sh

echo "Backup system setup completed."